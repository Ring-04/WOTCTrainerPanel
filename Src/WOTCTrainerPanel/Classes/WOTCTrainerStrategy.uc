class WOTCTrainerStrategy extends Object abstract;

// Reviewed stock SDK APIs: docs/API-AUDIT.md. Never mutate a history object.
static function XComGameState_HeadquartersXCom GetHQ()
{
	if (`HQGAME == none || `HQPRES == none || `STRATEGYRULES == none)
		return none;
	return XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
}

static function name ResourceName(int Index)
{
	switch (Index)
	{
	case 0: return 'Supplies';
	case 1: return 'Intel';
	case 2: return 'AlienAlloy';
	case 3: return 'EleriumDust';
	case 4: return 'EleriumCore';
	case 5: return 'AbilityPoint';
	}
	return '';
}

static function bool ParseAmount(string Text, out int Value)
{
	local int I, Digit;
	Value = 0;
	if (Len(Text) == 0 || Len(Text) > 10)
		return false;
	for (I = 0; I < Len(Text); ++I)
	{
		Digit = Asc(Mid(Text, I, 1)) - 48;
		if (Digit < 0 || Digit > 9 || Value > 214748364 || (Value == 214748364 && Digit > 7))
			return false;
		Value = Value * 10 + Digit;
	}
	return true;
}

static function bool SetResource(int Index, int ExpectedValue, int NewValue, out name ErrorCode)
{
	local XComGameState_HeadquartersXCom HQ, NewHQ;
	local XComGameState Change;
	local name Resource;
	local int OldValue;

	ErrorCode = '';
	HQ = GetHQ();
	Resource = ResourceName(Index);
	if (HQ == none || Resource == '')
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	if (NewValue < 0)
	{
		ErrorCode = 'InvalidNumber';
		return false;
	}
	if (HQ.GetItemByName(Resource) == none)
	{
		ErrorCode = 'MissingResource';
		return false;
	}
	OldValue = HQ.GetResourceAmount(Resource);
	if (OldValue != ExpectedValue || OldValue < 0)
	{
		ErrorCode = 'Stale';
		return false;
	}
	if (OldValue == NewValue)
		return true;

	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Set resource " $ Resource);
	NewHQ = XComGameState_HeadquartersXCom(Change.ModifyStateObject(class'XComGameState_HeadquartersXCom', HQ.ObjectID));
	// Both operands are nonnegative int values, so this difference cannot overflow.
	NewHQ.AddResource(Change, Resource, NewValue - OldValue);
	if (!`GAMERULES.SubmitGameState(Change))
	{
		ErrorCode = 'SubmitFailed';
		return false;
	}
	HQ = GetHQ();
	if (HQ == none || HQ.GetResourceAmount(Resource) != NewValue)
	{
		ErrorCode = 'VerifyFailed';
		`log("[WOTCTrainer] Resource post-submit verification failed: " $ Resource, true, 'WOTCTrainer');
		return false;
	}
	`log("[WOTCTrainer] " $ Resource $ ": " $ OldValue $ " -> " $ NewValue, true, 'WOTCTrainer');
	return true;
}

static function int StaffCount(bool Engineer)
{
	local XComGameState_HeadquartersXCom HQ;
	HQ = GetHQ();
	if (HQ == none)
		return -1;
	return Engineer ? HQ.GetNumberOfEngineers() : HQ.GetNumberOfScientists();
}

static function bool AddStaff(bool Engineer, int ExpectedCount, out string AddedName, out name ErrorCode)
{
	local XComGameState_HeadquartersXCom HQ, NewHQ;
	local XComGameState_Unit Unit;
	local XComGameState Change;
	local name TemplateName;
	local int Before, UnitID;

	ErrorCode = '';
	HQ = GetHQ();
	if (HQ == none)
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	Before = StaffCount(Engineer);
	if (Before < 0 || Before != ExpectedCount || Before == 2147483647)
	{
		ErrorCode = 'Stale';
		return false;
	}
	TemplateName = Engineer ? 'Engineer' : 'Scientist';
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Add " $ TemplateName);
	Unit = class'X2StrategyElement_DefaultRewards'.static.CreatePersonnelUnit(Change, TemplateName, '');
	if (Unit == none)
	{
		`XCOMHISTORY.CleanupPendingGameState(Change);
		ErrorCode = 'SubmitFailed';
		return false;
	}
	NewHQ = XComGameState_HeadquartersXCom(Change.ModifyStateObject(class'XComGameState_HeadquartersXCom', HQ.ObjectID));
	NewHQ.AddToCrew(Change, Unit);
	NewHQ.HandlePowerOrStaffingChange(Change);
	UnitID = Unit.ObjectID;
	AddedName = Unit.GetName(eNameType_Full);
	if (!`GAMERULES.SubmitGameState(Change))
	{
		ErrorCode = 'SubmitFailed';
		return false;
	}
	HQ = GetHQ();
	if (HQ == none || HQ.Crew.Find('ObjectID', UnitID) == INDEX_NONE || StaffCount(Engineer) != Before + 1)
	{
		ErrorCode = 'VerifyFailed';
		`log("[WOTCTrainer] Staff post-submit verification failed: " $ TemplateName $ " ObjectID=" $ UnitID, true, 'WOTCTrainer');
		return false;
	}
	`log("[WOTCTrainer] " $ TemplateName $ ": " $ Before $ " -> " $ StaffCount(Engineer) $ "; Added " $ AddedName $ " ObjectID=" $ UnitID, true, 'WOTCTrainer');
	return true;
}

static function array<StateObjectReference> HealingProjects()
{
	local XComGameState_HeadquartersXCom HQ;
	local XComGameState_HeadquartersProjectHealSoldier Project;
	local XComGameState_Unit Unit;
	local array<StateObjectReference> Result;
	local array<int> SeenUnits;
	local int I;

	HQ = GetHQ();
	if (HQ == none)
		return Result;
	for (I = 0; I < HQ.Projects.Length; ++I)
	{
		Project = XComGameState_HeadquartersProjectHealSoldier(`XCOMHISTORY.GetGameStateForObjectID(HQ.Projects[I].ObjectID));
		if (Project == none || HQ.Crew.Find('ObjectID', Project.ProjectFocus.ObjectID) == INDEX_NONE)
			continue;
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Project.ProjectFocus.ObjectID));
		if (Unit != none && Unit.IsSoldier() && Unit.IsAlive() && !Unit.bCaptured && Unit.GetStatus() == eStatus_Healing && SeenUnits.Find(Unit.ObjectID) == INDEX_NONE)
		{
			Result.AddItem(Project.GetReference());
			SeenUnits.AddItem(Unit.ObjectID);
		}
	}
	return Result;
}

static function bool HealAll(array<StateObjectReference> ExpectedProjects, out int Healed, out name ErrorCode)
{
	local XComGameState_HeadquartersXCom HQ;
	local array<StateObjectReference> CurrentProjects;
	local XComGameState_HeadquartersProjectHealSoldier Project;
	local XComGameState_Unit Unit;
	local HeadquartersOrderInputContext Order;
	local int I, UnitID;
	local float BeforeHP;

	Healed = 0;
	ErrorCode = '';
	if (GetHQ() == none)
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	CurrentProjects = HealingProjects();
	if (CurrentProjects.Length != ExpectedProjects.Length)
	{
		ErrorCode = 'Stale';
		return false;
	}
	for (I = 0; I < ExpectedProjects.Length; ++I)
	{
		if (CurrentProjects.Find('ObjectID', ExpectedProjects[I].ObjectID) == INDEX_NONE)
		{
			ErrorCode = 'Stale';
			return false;
		}
	}
	// Each normal HQ order is a separate legal submission, just as in the game.
	// Do not call a cheat manager: it is optional and would couple us to allowconsole.
	for (I = 0; I < ExpectedProjects.Length; ++I)
	{
		CurrentProjects = HealingProjects();
		if (CurrentProjects.Find('ObjectID', ExpectedProjects[I].ObjectID) == INDEX_NONE)
		{
			ErrorCode = 'Stale';
			return false;
		}
		Project = XComGameState_HeadquartersProjectHealSoldier(`XCOMHISTORY.GetGameStateForObjectID(ExpectedProjects[I].ObjectID));
		UnitID = Project.ProjectFocus.ObjectID;
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
		BeforeHP = Unit.GetCurrentStat(eStat_HP);
		Order.OrderType = eHeadquartersOrderType_UnitHealingCompleted;
		Order.AcquireObjectReference = Project.GetReference();
		class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(Order);
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
		HQ = GetHQ();
		if (HQ == none || HQ.Projects.Find('ObjectID', ExpectedProjects[I].ObjectID) != INDEX_NONE || Unit == none || Unit.GetCurrentStat(eStat_HP) != Unit.GetBaseStat(eStat_HP) || Unit.GetStatus() == eStatus_Healing)
		{
			ErrorCode = 'VerifyFailed';
			`log("[WOTCTrainer] Heal verification failed: ObjectID=" $ UnitID $ "; already healed=" $ Healed, true, 'WOTCTrainer');
			return false;
		}
		++Healed;
		`log("[WOTCTrainer] Healed " $ Unit.GetName(eNameType_Full) $ " ObjectID=" $ UnitID $ " HP: " $ BeforeHP $ " -> " $ Unit.GetCurrentStat(eStat_HP), true, 'WOTCTrainer');
	}
	return true;
}
