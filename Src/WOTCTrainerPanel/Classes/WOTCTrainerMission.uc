class WOTCTrainerMission extends Object abstract;

// Read-only projection of MissionObjectiveDefinition (XGGameData.uc:302-323). The struct
// carries no localized text, so the internal ObjectiveName is all that can be shown here.
struct MissionObjectiveEntry
{
	var name ObjectiveName;
	var int Index;
	var bool bCompleted;
	var bool bTactical;
	var bool bStrategy;
	var bool bTriad;
	var int LootTableCount;
};

static function XComGameState_BattleData BattleData()
{
	if (!class'WOTCTrainerTactical'.static.Available()) return none;
	return XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
}

static function array<name> IncompleteObjectives()
{
	local XComGameState_BattleData Battle;
	local array<name> Names;
	local int I;
	Battle = BattleData();
	if (Battle == none) return Names;
	for (I = 0; I < Battle.MapData.ActiveMission.MissionObjectives.Length; ++I)
		if (!Battle.MapData.ActiveMission.MissionObjectives[I].bCompleted)
			Names.AddItem(Battle.MapData.ActiveMission.MissionObjectives[I].ObjectiveName);
	return Names;
}

static function array<MissionObjectiveEntry> Objectives()
{
	local XComGameState_BattleData Battle;
	local array<MissionObjectiveEntry> Result;
	local MissionObjectiveEntry Entry;
	local int I;
	Battle = BattleData();
	if (Battle == none) return Result;
	for (I = 0; I < Battle.MapData.ActiveMission.MissionObjectives.Length; ++I)
	{
		Entry.ObjectiveName = Battle.MapData.ActiveMission.MissionObjectives[I].ObjectiveName;
		Entry.Index = I;
		Entry.bCompleted = Battle.MapData.ActiveMission.MissionObjectives[I].bCompleted;
		Entry.bTactical = Battle.MapData.ActiveMission.MissionObjectives[I].bIsTacticalObjective;
		Entry.bStrategy = Battle.MapData.ActiveMission.MissionObjectives[I].bIsStrategyObjective;
		Entry.bTriad = Battle.MapData.ActiveMission.MissionObjectives[I].bIsTriadObjective;
		Entry.LootTableCount = Battle.MapData.ActiveMission.MissionObjectives[I].SuccessLootTables.Length;
		Result.AddItem(Entry);
	}
	return Result;
}

// Mirrors XComGameState_BattleData.SetVictoriousPlayer (BattleData.uc:833-867) for the local
// winner, because that call inside EndBattle is what actually decides campaign success. Vanilla
// falls through to bLocalPlayerWon = true when the mission site or the success predicate cannot
// be resolved, so those cases must stay permissive here too, or the trainer would refuse to
// confirm a victory that the game itself would record as a success.
static function bool MissionWillCountAsSuccess()
{
	local XComGameState_BattleData Battle;
	local XComGameState_MissionSite Mission;
	local X2MissionSourceTemplate Source;
	Battle = BattleData();
	if (Battle == none) return false;
	Mission = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(Battle.m_iMissionID));
	if (Mission == none) return true;
	Source = Mission.GetMissionSource();
	if (Source == none || Source.WasMissionSuccessfulFn == none) return true;
	return Source.WasMissionSuccessfulFn(Battle);
}

// Describes what the mission source still requires, using the same predicates the vanilla
// sources use (X2StrategyElement_DefaultMissionSources.uc:2801-2810).
static function string BlockerText()
{
	local array<MissionObjectiveEntry> List;
	local string Text, Blockers;
	local int I, TacticalOpen, StrategyOpen, TacticalTotal, StrategyTotal;
	List = Objectives();
	for (I = 0; I < List.Length; ++I)
	{
		if (List[I].bTactical)
		{
			++TacticalTotal;
			if (!List[I].bCompleted)
			{
				++TacticalOpen;
				Blockers $= (Blockers == "" ? "" : ", ") $ string(List[I].ObjectiveName);
			}
		}
		if (List[I].bStrategy)
		{
			++StrategyTotal;
			if (!List[I].bCompleted) ++StrategyOpen;
		}
	}
	if (MissionWillCountAsSuccess()) return class'WOTCTrainerText'.default.VictoryReady;
	Text = class'WOTCTrainerText'.default.VictoryBlockedBy;
	if (TacticalTotal > 0 && TacticalOpen > 0)
		Text $= "<br>" $ class'WOTCTrainerText'.default.RoleTactical $ ": " $ TacticalOpen $ "/" $ TacticalTotal $ " " $ class'WOTCTrainerText'.default.IncompleteLabel $ " (" $ Blockers $ ")";
	if (StrategyTotal > 0 && StrategyOpen > 0)
		Text $= "<br>" $ class'WOTCTrainerText'.default.RoleStrategy $ ": " $ StrategyOpen $ "/" $ StrategyTotal $ " " $ class'WOTCTrainerText'.default.IncompleteLabel;
	if (TacticalTotal == 0 && StrategyTotal == 0) Text $= "<br>" $ class'WOTCTrainerText'.default.RoleNone;
	return Text;
}

static function bool Complete(array<name> Names, int ExpectedBattle, out name ErrorCode)
{
	local XComGameState_BattleData Battle;
	local XComGameState Change;
	local array<name> Remaining;
	local int I;
	ErrorCode = '';
	Battle = BattleData();
	if (!class'WOTCTrainerTactical'.static.CanEdit() || Battle == none || Battle.m_bIsTutorial || `TACTICALRULES.HasTacticalGameEnded()) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'TacticalUnavailable');
	if (Battle.ObjectID != ExpectedBattle) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'Stale');
	Remaining = IncompleteObjectives();
	if (Names.Length == 0) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'NoObjectives');
	for (I = 0; I < Names.Length; ++I)
		if (Remaining.Find(Names[I]) == INDEX_NONE) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'Stale');
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Complete mission objectives");
	Battle = XComGameState_BattleData(Change.ModifyStateObject(class'XComGameState_BattleData', Battle.ObjectID));
	for (I = 0; I < Names.Length; ++I) Battle.CompleteObjective(Names[I]);
	if (!`TACTICALRULES.SubmitGameState(Change)) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'SubmitFailed');
	Remaining = IncompleteObjectives();
	for (I = 0; I < Names.Length; ++I)
	{
		if (Remaining.Find(Names[I]) != INDEX_NONE) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'VerifyFailed');
		`log("[WOTCTrainer] Objective " $ Names[I] $ ": incomplete -> completed", true, 'WOTCTrainer');
	}
	return true;
}

static function bool CanEnd(bool Victory, out name ErrorCode)
{
	local XComGameState_BattleData Battle;
	local XGBattle_SP Visualizer;
	ErrorCode = '';
	Battle = BattleData();
	if (!class'WOTCTrainerTactical'.static.CanEdit() || Battle == none || Battle.m_bIsTutorial || Battle.VictoriousPlayer.ObjectID != 0 || `TACTICALRULES.HasTacticalGameEnded()) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'TacticalUnavailable');
	Visualizer = XGBattle_SP(`BATTLE);
	if (Visualizer == none || Visualizer.GetHumanPlayer() == none || Visualizer.GetAIPlayer() == none) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'Unsupported');
	if (Victory && !MissionWillCountAsSuccess()) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'CompleteFirst');
	return true;
}

static function bool EndMission(bool Victory, out name ErrorCode)
{
	local XGBattle_SP Battle;
	if (!CanEnd(Victory, ErrorCode)) return false;
	Battle = XGBattle_SP(`BATTLE);
	`log("[WOTCTrainer] Mission: active -> requested " $ (Victory ? "victory" : "failure") $ " via EndBattle", true, 'WOTCTrainer');
	`TACTICALRULES.EndBattle(Victory ? Battle.GetHumanPlayer() : Battle.GetAIPlayer());
	return true;
}

static function bool SkipAI(int ExpectedPlayerID, out name ErrorCode)
{
	local XComGameState_Player Player;
	local XComGameStateContext_TacticalGameRule Context;
	ErrorCode = '';
	if (!class'WOTCTrainerTactical'.static.Available() || `TACTICALRULES.IsDoingLatentSubmission() || !`TACTICALRULES.IsInState('TurnPhase_UnitActions') || `TACTICALRULES.HasTacticalGameEnded()) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'AIBusy');
	Player = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID));
	if (Player == none || Player.PlayerClassName == Name("XGPlayer") || Player.GetTeam() == eTeam_XCom) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'AIBusy');
	if (Player.ObjectID != ExpectedPlayerID) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'Stale');
	Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_SkipTurn);
	Context.PlayerRef = Player.GetReference(); Context.SetSendGameState(true);
	`TACTICALRULES.SubmitGameStateContext(Context);
	Context.SetSendGameState(false);
	`log("[WOTCTrainer] AI player=" $ ExpectedPlayerID $ ": active turn -> skip requested", true, 'WOTCTrainer');
	return true;
}

static function XComGameState_Player TurnPlayer()
{
	if (!class'WOTCTrainerTactical'.static.Available()) return none;
	return XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID));
}

static function string TurnPlayerLabel()
{
	local XComGameState_Player Player;
	Player = TurnPlayer();
	if (Player == none) return "-";
	return class'WOTCTrainerText'.static.Escape(Player.GetGameStatePlayerName()) $ " (" $ class'WOTCTrainerText'.static.TeamText(Player.GetTeam()) $ ")";
}

static function XGAIPlayer AIPlayerFor(ETeam Team)
{
	local XComGameState_Player Player;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', Player)
		if (Player.GetTeam() == Team) return XGAIPlayer(Player.GetVisualizer());
	return none;
}

static function bool AISkipEnabled(ETeam Team)
{
	local XGAIPlayer AI;
	AI = AIPlayerFor(Team);
	return AI != none && AI.m_bSkipAI;
}

// m_bSkipAI is the switch the vanilla SkipAI console command and the SeqAct_SkipAI Kismet
// node set (XGAIPlayer.uc:20, consumed at :269 by EndTurn(ePlayerEndTurnType_AI) and :864).
// It is transient visualizer state, so it is not part of any game state and never saved.
static function int SetAISkip(bool Skip, out name ErrorCode)
{
	local XComGameState_Player Player;
	local XGAIPlayer AI;
	local int Count;
	ErrorCode = '';
	if (!class'WOTCTrainerTactical'.static.Available() || `TACTICALRULES.HasTacticalGameEnded()) { class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'TacticalUnavailable'); return 0; }
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', Player)
	{
		AI = XGAIPlayer(Player.GetVisualizer());
		if (AI == none || AI.m_bSkipAI == Skip) continue;
		AI.m_bSkipAI = Skip;
		++Count;
	}
	if (Count == 0 && AIPlayerFor(eTeam_Alien) == none && AIPlayerFor(eTeam_TheLost) == none) { class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'Unsupported'); return 0; }
	`log("[WOTCTrainer] AI turn control: " $ (Skip ? "disabled" : "restored") $ " on " $ Count $ " AI player(s)", true, 'WOTCTrainer');
	return Count;
}

static function string Diagnostics()
{
	local XComGameState_BattleData Battle;
	local XComGameState_Unit Unit;
	local XComGameState_AIReinforcementSpawner Spawner;
	local array<MissionObjectiveEntry> List;
	local int XComCount, EnemyCount, LostCount, InvalidTiles, Reinforcements, Done, Total, I;
	local string Result;
	Battle = BattleData();
	if (Battle == none) return class'WOTCTrainerText'.default.TacticalUnavailable;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (!Unit.IsAlive() || Unit.bRemovedFromPlay) continue;
		if (Unit.GetTeam() == eTeam_XCom) ++XComCount;
		if (Unit.GetTeam() == eTeam_Alien) ++EnemyCount;
		if (Unit.GetTeam() == eTeam_TheLost) ++LostCount;
		if (`XWORLD.IsTileOutOfRange(Unit.TileLocation)) ++InvalidTiles;
	}
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_AIReinforcementSpawner', Spawner)
		if (Spawner.SpawnedUnitIDs.Length == 0) ++Reinforcements;
	List = Objectives();
	for (I = 0; I < List.Length; ++I) { ++Total; if (List[I].bCompleted) ++Done; }
	Result = class'WOTCTrainerText'.default.MissionState @ string(`TACTICALRULES.GetStateName()) $ " | ID" @ Battle.m_iMissionID;
	Result $= "<br>XCOM: " $ XComCount $ " | " $ class'WOTCTrainerText'.default.Enemies $ ": " $ EnemyCount $ " | " $ class'WOTCTrainerText'.static.TeamText(eTeam_TheLost) $ ": " $ LostCount;
	Result $= "<br>" $ class'WOTCTrainerText'.default.Reinforcements $ ": " $ Reinforcements $ " | " $ class'WOTCTrainerText'.default.InvalidTiles $ ": " $ InvalidTiles;
	Result $= "<br>" $ class'WOTCTrainerText'.default.PendingSubmission $ ": " $ class'WOTCTrainerText'.static.ToggleText(`TACTICALRULES.IsDoingLatentSubmission()) $ " | " $ class'WOTCTrainerText'.default.TurnOwner $ ": " $ TurnPlayerLabel();
	Result $= "<br>" $ class'WOTCTrainerText'.default.ObjectiveList $ ": " $ Done $ "/" $ Total $ " " $ class'WOTCTrainerText'.default.CompletedLabel;
	Result $= "<br>" $ class'WOTCTrainerText'.default.AIHangScope $ ": " $ class'WOTCTrainerText'.static.TeamText(eTeam_Alien) $ " " $ class'WOTCTrainerText'.static.ToggleText(AISkipEnabled(eTeam_Alien)) $ " | " $ class'WOTCTrainerText'.static.TeamText(eTeam_TheLost) $ " " $ class'WOTCTrainerText'.static.ToggleText(AISkipEnabled(eTeam_TheLost));
	if (EnemyCount == 0 && LostCount == 0) Result $= "<br>" $ class'WOTCTrainerText'.default.NoEnemiesHint;
	return Result;
}
