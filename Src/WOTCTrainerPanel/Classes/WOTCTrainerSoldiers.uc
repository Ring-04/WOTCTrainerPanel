class WOTCTrainerSoldiers extends Object abstract;

// Stock SDK declarations and call paths were reviewed before implementation.
// See docs/API-AUDIT.md, Phase 2. No history object is modified directly.
static function bool Fail(out name ErrorCode, name Code)
{
	ErrorCode = Code;
	return false;
}

static function array<StateObjectReference> Roster()
{
	local XComGameState_HeadquartersXCom HQ;
	local XComGameState_Unit Unit;
	local array<StateObjectReference> Result;
	local int I;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) return Result;
	for (I = 0; I < HQ.Crew.Length; ++I)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(HQ.Crew[I].ObjectID));
		if (Unit != none && Unit.IsSoldier()) Result.AddItem(Unit.GetReference());
	}
	return Result;
}

static function XComGameState_Unit EditableUnit(int UnitID)
{
	local XComGameState_HeadquartersXCom HQ;
	local XComGameState_Unit Unit;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none || HQ.Crew.Find('ObjectID', UnitID) == INDEX_NONE) return none;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	if (Unit == none || !Unit.IsSoldier() || !Unit.IsAlive() || Unit.bCaptured || Unit.IsOnCovertAction()) return none;
	if (Unit.GetStatus() != eStatus_Active && Unit.GetStatus() != eStatus_Healing) return none;
	return Unit;
}

static function name ClassName(int Index)
{
	switch (Index)
	{
	case 0: return 'Rookie';
	case 1: return 'Ranger';
	case 2: return 'Grenadier';
	case 3: return 'Specialist';
	case 4: return 'Sharpshooter';
	case 5: return 'Reaper';
	case 6: return 'Skirmisher';
	case 7: return 'Templar';
	}
	return '';
}

static function name CharacterName(int Index)
{
	switch (Index)
	{
	case 5: return 'ReaperSoldier';
	case 6: return 'SkirmisherSoldier';
	case 7: return 'TemplarSoldier';
	}
	return 'Soldier';
}

static function string ClassLabel(int Index)
{
	local X2SoldierClassTemplate Template;
	Template = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(ClassName(Index));
	return Template == none ? string(ClassName(Index)) : Template.DisplayName;
}

static function bool SpawnSoldiers(int ClassIndex, int Rank, int Count, int ExpectedCount, out array<StateObjectReference> Added, out name ErrorCode)
{
	local XComGameState_HeadquartersXCom HQ, NewHQ;
	local XComGameState_ResistanceFaction Faction;
	local XComGameState_Unit Unit;
	local X2SoldierClassTemplate Template;
	local XComGameState Change;
	local array<StateObjectReference> Before;
	local int I;
	local name SoldierClass;
	ErrorCode = '';
	Added.Length = 0;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) return Fail(ErrorCode, 'Unavailable');
	Before = Roster();
	if (Before.Length != ExpectedCount) return Fail(ErrorCode, 'Stale');
	if (ClassIndex < 0 || ClassIndex > 7 || Count < 1 || Count > 20 || Rank < 0 || Rank > 7) return Fail(ErrorCode, 'Bounds');
	// A classless rookie and a named class cannot be represented simultaneously.
	if ((ClassIndex == 0 && Rank != 0) || (ClassIndex > 0 && Rank == 0)) return Fail(ErrorCode, 'Bounds');
	SoldierClass = ClassName(ClassIndex);
	Template = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(SoldierClass);
	if (Template == none || Rank >= class'X2ExperienceConfig'.static.GetMaxRank() || Rank > Template.GetMaxConfiguredRank()) return Fail(ErrorCode, 'Unsupported');
	if (ClassIndex >= 5)
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_ResistanceFaction', Faction)
			if (Faction.GetChampionCharacterName() == CharacterName(ClassIndex)) break;
		if (Faction == none || Faction.GetChampionCharacterName() != CharacterName(ClassIndex) || !Faction.bMetXCom) return Fail(ErrorCode, 'FactionLocked');
	}
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Spawn soldiers");
	NewHQ = XComGameState_HeadquartersXCom(Change.ModifyStateObject(class'XComGameState_HeadquartersXCom', HQ.ObjectID));
	for (I = 0; I < Count; ++I)
	{
		Unit = class'X2StrategyElement_DefaultRewards'.static.CreatePersonnelUnit(Change, CharacterName(ClassIndex), '', true);
		if (Unit == none)
		{
			`XCOMHISTORY.CleanupPendingGameState(Change);
			Added.Length = 0;
			return Fail(ErrorCode, 'SubmitFailed');
		}
		if (Faction != none) Unit.FactionRef = Faction.GetReference();
		while (Unit.GetSoldierRank() < Rank)
		{
			Unit.RankUpSoldier(Change, SoldierClass);
			if (Unit.GetSoldierRank() == 1) Unit.ApplySquaddieLoadout(Change, NewHQ);
		}
		Unit.StartingRank = Rank;
		Unit.SetXPForRank(Rank);
		Unit.bNeedsNewClassPopup = false;
		Unit.ApplyBestGearLoadout(Change);
		NewHQ.AddToCrew(Change, Unit);
		Added.AddItem(Unit.GetReference());
	}
	NewHQ.HandlePowerOrStaffingChange(Change);
	if (!`GAMERULES.SubmitGameState(Change)) return Fail(ErrorCode, 'SubmitFailed');
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	Before = Roster();
	if (HQ == none || Before.Length != ExpectedCount + Count) return Fail(ErrorCode, 'VerifyFailed');
	for (I = 0; I < Added.Length; ++I)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Added[I].ObjectID));
		if (Unit == none || HQ.Crew.Find('ObjectID', Unit.ObjectID) == INDEX_NONE || Unit.GetSoldierRank() != Rank || Unit.GetSoldierClassTemplateName() != SoldierClass) return Fail(ErrorCode, 'VerifyFailed');
		`log("[WOTCTrainer] Added " $ SoldierClass $ " " $ Unit.GetName(eNameType_Full) $ " ObjectID=" $ Unit.ObjectID $ " Rank=" $ Rank, true, 'WOTCTrainer');
	}
	`log("[WOTCTrainer] Barracks: " $ ExpectedCount $ " -> " $ Before.Length, true, 'WOTCTrainer');
	return true;
}

static function ECharStatType StatType(int Index)
{
	switch (Index)
	{
	case 0: return eStat_HP;
	case 1: return eStat_Offense;
	case 2: return eStat_Mobility;
	case 3: return eStat_Will;
	case 4: return eStat_Hacking;
	case 5: return eStat_Dodge;
	case 6: return eStat_Defense;
	}
	return eStat_MAX;
}

static function int Value(XComGameState_Unit Unit, int Field)
{
	if (Unit == none) return -1;
	if (Field >= 0 && Field <= 6) return int(Unit.GetBaseStat(StatType(Field)));
	if (Field == 7) return Unit.AbilityPoints;
	if (Field == 8) return Unit.GetXPValue();
	return -1;
}

static function int MaxXP(XComGameState_Unit Unit)
{
	local int Rank;
	Rank = Unit.GetSoldierRank();
	if (Rank + 2 < class'X2ExperienceConfig'.static.GetMaxRank())
		return Max(0, class'X2ExperienceConfig'.static.GetRequiredXp(Rank + 2) - 1);
	// AddXp in the stock SDK indexes GetMaxRank at high ranks; do not enter that branch.
	return -1;
}

static function bool SetValue(int UnitID, int Field, int Expected, int NewValue, out name ErrorCode)
{
	local XComGameState_Unit Unit;
	local XComGameState Change;
	local ECharStatType Stat;
	local float OldCurrent;
	ErrorCode = '';
	Unit = EditableUnit(UnitID);
	if (Unit == none) return Fail(ErrorCode, 'UnitUnavailable');
	if (Field < 0 || Field > 8 || NewValue < 0 || NewValue > (Field < 7 ? 1000 : 100000)) return Fail(ErrorCode, 'Bounds');
	if ((Field == 0 || Field == 2 || Field == 3) && NewValue < 1) return Fail(ErrorCode, 'Bounds');
	if (Value(Unit, Field) != Expected) return Fail(ErrorCode, 'Stale');
	if (Field == 0 && Unit.IsInjured()) return Fail(ErrorCode, 'HealFirst');
	if (Field == 3 && Unit.NeedsWillRecovery()) return Fail(ErrorCode, 'WillFirst');
	if (Field == 8 && (MaxXP(Unit) < 0 || NewValue > MaxXP(Unit))) return Fail(ErrorCode, 'XPCap');
	if (Expected == NewValue) return true;
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Edit soldier");
	Unit = XComGameState_Unit(Change.ModifyStateObject(class'XComGameState_Unit', UnitID));
	if (Field < 7)
	{
		Stat = StatType(Field);
		OldCurrent = Unit.GetCurrentStat(Stat);
		Unit.SetBaseMaxStat(Stat, NewValue);
		Unit.SetCurrentStat(Stat, FClamp(OldCurrent + NewValue - Expected, 0, Unit.GetMaxStat(Stat)));
		if (Field == 3) Unit.UpdateMentalState();
	}
	else if (Field == 7)
	{
		Unit.AbilityPoints = NewValue;
		`XEVENTMGR.TriggerEvent('AbilityPointsChange', Unit, , Change);
	}
	else Unit.AddXp(NewValue - Expected);
	if (!`GAMERULES.SubmitGameState(Change)) return Fail(ErrorCode, 'SubmitFailed');
	Unit = EditableUnit(UnitID);
	if (Unit == none || Value(Unit, Field) != NewValue) return Fail(ErrorCode, 'VerifyFailed');
	`log("[WOTCTrainer] Soldier " $ UnitID $ " field=" $ Field $ ": " $ Expected $ " -> " $ NewValue, true, 'WOTCTrainer');
	return true;
}

static function bool Promote(int UnitID, int ExpectedRank, int NewRank, int RookieClassIndex, out name ErrorCode)
{
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersXCom HQ;
	local XComGameState Change;
	local X2SoldierClassTemplate Template;
	local name SoldierClass;
	ErrorCode = '';
	Unit = EditableUnit(UnitID);
	if (Unit == none || Unit.GetStatus() != eStatus_Active) return Fail(ErrorCode, 'UnitUnavailable');
	if (Unit.GetSoldierRank() != ExpectedRank) return Fail(ErrorCode, 'Stale');
	if (NewRank <= ExpectedRank || NewRank > 7 || NewRank >= class'X2ExperienceConfig'.static.GetMaxRank()) return Fail(ErrorCode, 'Bounds');
	SoldierClass = Unit.GetSoldierClassTemplateName();
	if (ExpectedRank == 0)
	{
		if (RookieClassIndex < 1 || RookieClassIndex > 4 || Unit.GetMyTemplateName() != 'Soldier') return Fail(ErrorCode, 'Unsupported');
		SoldierClass = ClassName(RookieClassIndex);
	}
	Template = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(SoldierClass);
	if (Template == none || Template.bBlockRankingUp || NewRank > Template.GetMaxConfiguredRank()) return Fail(ErrorCode, 'Unsupported');
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Promote soldier");
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	HQ = XComGameState_HeadquartersXCom(Change.ModifyStateObject(class'XComGameState_HeadquartersXCom', HQ.ObjectID));
	Unit = XComGameState_Unit(Change.ModifyStateObject(class'XComGameState_Unit', UnitID));
	while (Unit.GetSoldierRank() < NewRank)
	{
		Unit.RankUpSoldier(Change, SoldierClass);
		if (Unit.GetSoldierRank() == 1) Unit.ApplySquaddieLoadout(Change, HQ);
	}
	Unit.StartingRank = Max(Unit.StartingRank, NewRank);
	Unit.SetXPForRank(NewRank);
	Unit.bNeedsNewClassPopup = false;
	if (!`GAMERULES.SubmitGameState(Change)) return Fail(ErrorCode, 'SubmitFailed');
	Unit = EditableUnit(UnitID);
	if (Unit == none || Unit.GetSoldierRank() != NewRank) return Fail(ErrorCode, 'VerifyFailed');
	`log("[WOTCTrainer] Soldier " $ UnitID $ " Rank: " $ ExpectedRank $ " -> " $ NewRank $ " Class=" $ SoldierClass, true, 'WOTCTrainer');
	return true;
}

static function bool Heal(int UnitID, int ExpectedHP, out name ErrorCode)
{
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersProjectHealSoldier Project;
	local array<StateObjectReference> Projects;
	local HeadquartersOrderInputContext Order;
	local int I;
	ErrorCode = '';
	Unit = EditableUnit(UnitID);
	if (Unit == none) return Fail(ErrorCode, 'UnitUnavailable');
	if (int(Unit.GetCurrentStat(eStat_HP)) != ExpectedHP) return Fail(ErrorCode, 'Stale');
	Projects = class'WOTCTrainerStrategy'.static.HealingProjects();
	for (I = 0; I < Projects.Length; ++I)
	{
		Project = XComGameState_HeadquartersProjectHealSoldier(`XCOMHISTORY.GetGameStateForObjectID(Projects[I].ObjectID));
		if (Project.ProjectFocus.ObjectID != UnitID) continue;
		Order.OrderType = eHeadquartersOrderType_UnitHealingCompleted;
		Order.AcquireObjectReference = Project.GetReference();
		class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(Order);
		Unit = EditableUnit(UnitID);
		if (Unit == none || Unit.IsInjured() || Unit.GetStatus() == eStatus_Healing) return Fail(ErrorCode, 'VerifyFailed');
		`log("[WOTCTrainer] Soldier " $ UnitID $ " HP: " $ ExpectedHP $ " -> " $ Unit.GetCurrentStat(eStat_HP), true, 'WOTCTrainer');
		return true;
	}
	return Fail(ErrorCode, 'NothingToHeal');
}

static function bool RestoreWill(int UnitID, int ExpectedWill, out name ErrorCode)
{
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersXCom HQ;
	local XComGameState_HeadquartersProjectRecoverWill Project;
	local int I, ProjectID;
	ErrorCode = '';
	Unit = EditableUnit(UnitID);
	if (Unit == none) return Fail(ErrorCode, 'UnitUnavailable');
	if (int(Unit.GetCurrentStat(eStat_Will)) != ExpectedWill) return Fail(ErrorCode, 'Stale');
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	for (I = 0; I < HQ.Projects.Length; ++I)
	{
		Project = XComGameState_HeadquartersProjectRecoverWill(`XCOMHISTORY.GetGameStateForObjectID(HQ.Projects[I].ObjectID));
		if (Project == none || Project.ProjectFocus.ObjectID != UnitID) continue;
		ProjectID = Project.ObjectID;
		Project.OnProjectCompleted();
		HQ = class'WOTCTrainerStrategy'.static.GetHQ();
		Unit = EditableUnit(UnitID);
		if (Unit == none || HQ == none || HQ.Projects.Find('ObjectID', ProjectID) != INDEX_NONE || Unit.NeedsWillRecovery() || Unit.GetMentalState(true) != eMentalState_Ready) return Fail(ErrorCode, 'VerifyFailed');
		`log("[WOTCTrainer] Soldier " $ UnitID $ " Will: " $ ExpectedWill $ " -> " $ Unit.GetCurrentStat(eStat_Will), true, 'WOTCTrainer');
		return true;
	}
	if (!Unit.NeedsWillRecovery()) return true;
	return Fail(ErrorCode, 'NoWillProject');
}

static function bool RemoveTraits(int UnitID, int Expected, out name ErrorCode)
{
	local XComGameState_Unit Unit;
	local XComGameState Change;
	local int I;
	ErrorCode = '';
	Unit = EditableUnit(UnitID);
	if (Unit == none) return Fail(ErrorCode, 'UnitUnavailable');
	if (Unit.GetNumTraits() != Expected) return Fail(ErrorCode, 'Stale');
	for (I = 0; I < Unit.NegativeTraits.Length; ++I)
		if (X2TraitTemplate(class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager().FindEventListenerTemplate(Unit.NegativeTraits[I].TraitName)) == none) return Fail(ErrorCode, 'Unsupported');
	if (Expected == 0) return true;
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Recover traits");
	Unit = XComGameState_Unit(Change.ModifyStateObject(class'XComGameState_Unit', UnitID));
	Unit.RecoverFromAllTraits(Change);
	`XEVENTMGR.TriggerEvent('UnitTraitsChanged', Unit, , Change);
	if (!`GAMERULES.SubmitGameState(Change)) return Fail(ErrorCode, 'SubmitFailed');
	Unit = EditableUnit(UnitID);
	if (Unit == none || Unit.GetNumTraits() != 0) return Fail(ErrorCode, 'VerifyFailed');
	`log("[WOTCTrainer] Soldier " $ UnitID $ " NegativeTraits: " $ Expected $ " -> 0", true, 'WOTCTrainer');
	return true;
}
