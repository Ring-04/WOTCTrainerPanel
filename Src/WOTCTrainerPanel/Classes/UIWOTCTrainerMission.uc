// dependson registers WOTCTrainerMission's MissionObjectiveEntry struct in the type table before
// this class is parsed, mirroring how UIDialogueBox.uc:11 pulls in UICallbackData for its own struct.
class UIWOTCTrainerMission extends UIWOTCTrainerBase dependson(WOTCTrainerMission);

var WOTCTrainerButton Objectives[7];
var UIText HUDObjectives, SweepText, DiagnosticText, PageText;
var int PageIndex, SelectedIndex, PendingBattle, PendingPlayer;
var array<name> PendingObjectives;

simulated function OnInit()
{
	local int I;
	super.OnInit();
	Root = Spawn(class'UIPanel', self).InitPanel('MissionRoot'); Root.AnchorCenter(); Root.SetPosition(-690, -395);
	Spawn(class'UIBGBox', Root).InitBG('Background', 0, 0, 1380, 790);
	AddText(Root, 'Title', class'WOTCTrainerText'.default.MissionControl, 40, 25, 1050, 50, true);
	AddText(Root, 'Help', class'WOTCTrainerText'.default.ObjectiveHelp, 40, 80, 1290, 58);
	PageText = AddText(Root, 'Page', "", 40, 146, 640, 32);
	for (I = 0; I < 7; ++I) Objectives[I] = AddButton(Root, name("Objective" $ I), "", 40, 185 + I * 47, 610, I);
	HUDObjectives = AddText(Root, 'HUDObjectives', "", 695, 146, 635, 140);
	SweepText = AddText(Root, 'Sweep', "", 695, 290, 635, 86);
	DiagnosticText = AddText(Root, 'Diagnostics', "", 695, 380, 635, 205);
	AddButton(Root, 'Previous', "<", 40, 545, 100, 80); AddButton(Root, 'Next', ">", 155, 545, 100, 81);
	AddButton(Root, 'Refresh', class'WOTCTrainerText'.default.RefreshObjectives, 275, 545, 375, 82);
	AddButton(Root, 'Complete', class'WOTCTrainerText'.default.CompleteSelected, 40, 595, 300, 90);
	AddButton(Root, 'SkipAI', class'WOTCTrainerText'.default.SkipAI, 360, 595, 290, 93);
	AddButton(Root, 'Restart', class'WOTCTrainerText'.default.RestartMission, 695, 595, 300, 94);
	AddButton(Root, 'Danger', class'WOTCTrainerText'.default.Tabs[7], 1015, 595, 315, 95);
	AddButton(Root, 'RepairAI', class'WOTCTrainerText'.default.RepairAI, 40, 645, 300, 96);
	AddButton(Root, 'RestoreAI', class'WOTCTrainerText'.default.RestoreAI, 360, 645, 290, 97);
	ResultText = AddText(Root, 'Result', class'WOTCTrainerText'.default.MissionLimits, 40, 694, 1080, 80);
	AddButton(Root, 'Close', class'WOTCTrainerText'.default.Close, 1150, 702, 190, 900);
	RefreshValues();
}

simulated function string RoleSuffix(bool bTactical, bool bStrategy, bool bTriad, int Loot)
{
	local string Roles;
	Roles = "";
	if (bTactical) Roles $= class'WOTCTrainerText'.default.RoleTactical;
	if (bStrategy) Roles $= (Roles == "" ? "" : ",") $ class'WOTCTrainerText'.default.RoleStrategy;
	if (bTriad) Roles $= (Roles == "" ? "" : ",") $ class'WOTCTrainerText'.default.RoleTriad;
	if (Roles == "") return "";
	if (Loot > 0) Roles $= "," $ class'WOTCTrainerText'.default.ObjectiveLoot;
	return " (" $ Roles $ ")";
}

simulated function RefreshValues()
{
	local XComGameState_ObjectivesList HUD;
	local array<MissionObjectiveEntry> List;
	local int I, Index, OpenTactical;
	local string Label;
	List = class'WOTCTrainerMission'.static.Objectives();
	PageIndex = Clamp(PageIndex, 0, Max(0, (List.Length - 1) / 7));
	PageText.SetText(class'WOTCTrainerText'.default.InternalObjectives @ "|" @ (PageIndex + 1) $ "/" $ Max(1, (List.Length + 6) / 7));
	for (I = 0; I < 7; ++I)
	{
		Index = PageIndex * 7 + I;
		Objectives[I].SetDisabled(Index >= List.Length);
		if (Index < List.Length)
		{
			Objectives[I].SetText((List[Index].bCompleted ? "[X] " : "[ ] ") $ string(List[Index].ObjectiveName)
				$ RoleSuffix(List[Index].bTactical, List[Index].bStrategy, List[Index].bTriad, List[Index].LootTableCount));
			Objectives[I].SetSelected(Index == SelectedIndex);
			if (List[Index].bTactical && !List[Index].bCompleted) ++OpenTactical;
		}
		else Objectives[I].SetText("-");
	}
	HUD = XComGameState_ObjectivesList(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_ObjectivesList', true));
	Label = class'WOTCTrainerText'.default.HUDObjectives;
	if (HUD != none) for (I = 0; I < HUD.ObjectiveDisplayInfos.Length; ++I)
	{
		if (HUD.ObjectiveDisplayInfos[I].HideInTactical || HUD.ObjectiveDisplayInfos[I].GPObjective) continue;
		Label $= "<br>" $ (HUD.ObjectiveDisplayInfos[I].ShowCompleted ? "[X] " : (HUD.ObjectiveDisplayInfos[I].ShowFailed ? "[!] " : "[ ] ")) $ HUD.ObjectiveDisplayInfos[I].DisplayLabel;
	}
	HUDObjectives.SetText(Label);
	SweepText.SetText(OpenTactical > 0
		? class'WOTCTrainerText'.default.LootSweepBlocked $ "<br>" $ class'WOTCTrainerText'.default.SweepNote
		: class'WOTCTrainerText'.default.SweepNote);
	DiagnosticText.SetText(class'WOTCTrainerMission'.static.Diagnostics() $ "<br>" $ class'WOTCTrainerMission'.static.BlockerText());
}

simulated function OnAction(UIButton Sender)
{
	local WOTCTrainerButton Button;
	local array<MissionObjectiveEntry> List;
	local XComGameState_BattleData Battle;
	local XComGameState_Player Player;
	local UITacticalHUD HUD;
	local UIWOTCTrainerMissionDanger Danger;
	if (bModalPending) return;
	Button = WOTCTrainerButton(Sender); if (Button == none) return;
	if (Button.ActionID == 900) { ClosePanel(); return; }
	if (Button.ActionID == 80 || Button.ActionID == 81) { PageIndex += Button.ActionID == 80 ? -1 : 1; RefreshValues(); return; }
	if (Button.ActionID == 82)
	{
		RefreshValues(); HUD = UITacticalHUD(`SCREENSTACK.GetScreen(class'UITacticalHUD'));
		if (HUD != none && HUD.m_kObjectivesControl != none) HUD.m_kObjectivesControl.RefreshObjectivesDisplay(XComGameState_ObjectivesList(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_ObjectivesList', true)), true);
		return;
	}
	if (Button.ActionID >= 0 && Button.ActionID < 7) { SelectedIndex = PageIndex * 7 + Button.ActionID; RefreshValues(); return; }
	Battle = class'WOTCTrainerMission'.static.BattleData(); if (Battle == none) return;
	PendingBattle = Battle.ObjectID;
	if (Button.ActionID == 90)
	{
		List = class'WOTCTrainerMission'.static.Objectives();
		if (SelectedIndex < 0 || SelectedIndex >= List.Length || List[SelectedIndex].bCompleted) { ShowError('NoObjectives'); return; }
		PendingKind = 'Complete'; PendingObjectives.Length = 0;
		PendingObjectives.AddItem(List[SelectedIndex].ObjectiveName);
		ShowConfirmation(string(PendingObjectives[0]) $ ": " $ class'WOTCTrainerText'.default.IncompleteLabel $ class'WOTCTrainerText'.default.Arrow $ class'WOTCTrainerText'.default.CompletedLabel, true);
	}
	else if (Button.ActionID == 93)
	{
		Player = class'WOTCTrainerMission'.static.TurnPlayer();
		if (Player == none) { ShowError('AIBusy'); return; }
		PendingKind = 'SkipAI'; PendingPlayer = Player.ObjectID;
		ShowConfirmation(class'WOTCTrainerText'.default.SkipAIHelp $ "<br><br>" $ class'WOTCTrainerText'.default.TurnOwner $ ": " $ class'WOTCTrainerMission'.static.TurnPlayerLabel(), true);
	}
	else if (Button.ActionID == 94)
	{
		PendingKind = 'Restart'; ShowConfirmation(class'WOTCTrainerText'.default.RestartHelp, true);
	}
	else if (Button.ActionID == 95)
	{
		Danger = Spawn(class'UIWOTCTrainerMissionDanger', Movie.Pres); Movie.Stack.Push(Danger);
	}
	else if (Button.ActionID == 96 || Button.ActionID == 97)
	{
		PendingKind = Button.ActionID == 96 ? 'AIOn' : 'AIOff';
		ShowConfirmation(class'WOTCTrainerText'.default.AIHangHelp $ "<br><br>" $ class'WOTCTrainerText'.default.AIHangNote, true);
	}
}

simulated function OnConfirmed(name Action)
{
	local name ErrorCode;
	local bool Success;
	local int Count;
	local XComGameState_BattleData Battle;
	bModalPending = false;
	if (Action != 'eUIAction_Accept') { PendingKind = ''; return; }
	Battle = class'WOTCTrainerMission'.static.BattleData();
	if (Battle == none || Battle.ObjectID != PendingBattle) { ShowError('Stale'); return; }
	if (PendingKind == 'Complete') Success = class'WOTCTrainerMission'.static.Complete(PendingObjectives, PendingBattle, ErrorCode);
	else if (PendingKind == 'SkipAI') Success = class'WOTCTrainerMission'.static.SkipAI(PendingPlayer, ErrorCode);
	else if (PendingKind == 'AIOn' || PendingKind == 'AIOff')
	{
		Count = class'WOTCTrainerMission'.static.SetAISkip(PendingKind == 'AIOn', ErrorCode);
		Success = ErrorCode == '';
		PendingOld = PendingKind == 'AIOn' ? 0 : 1; PendingNew = PendingKind == 'AIOn' ? 1 : 0;
	}
	else if (PendingKind == 'Restart')
	{
		if (!class'WOTCTrainerTactical'.static.CanEdit() || Battle.m_bIsTutorial || Battle.m_bIsIronman) { ShowError('Unsupported'); return; }
		`log("[WOTCTrainer] Mission: current progress -> restart requested", true, 'WOTCTrainer');
		if (`PRES.m_kNarrative != none) `PRES.m_kNarrative.RestoreNarrativeCounters();
		PC.RestartLevel(); return;
	}
	if (!Success) { ShowError(ErrorCode); PendingKind = ''; RefreshValues(); return; }
	if (PendingKind == 'AIOn' || PendingKind == 'AIOff')
		ResultText.SetText(class'WOTCTrainerText'.default.Applied @ class'WOTCTrainerText'.default.AIHangScope @ ChangeText() @ "|" @ string(Count));
	else ResultText.SetText(class'WOTCTrainerText'.default.Applied @ class'WOTCTrainerText'.default.CompletedLabel);
	PendingKind = ''; RefreshValues();
}
