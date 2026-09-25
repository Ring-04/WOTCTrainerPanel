class WOTCTrainerCampaign extends Object abstract;

// Reviewed stock SDK APIs: docs/API-AUDIT.md. Never mutate a history object.
// Every action below either reuses a vanilla completion routine or mirrors a vanilla call
// site one-to-one, and re-reads the submitted state before reporting success.

static function XComGameState_HeadquartersAlien GetAlienHQ()
{
	if (`HQGAME == none || `HQPRES == none || `STRATEGYRULES == none)
		return none;
	return XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien', true));
}

//#############################################################################################
//----------------   AVATAR PROJECT (DOOM)   --------------------------------------------------
//#############################################################################################

// Doom lives in three buckets. The permanent value is the irreversible core
// (XComGameState_HeadquartersAlien.Doom), facility Doom sits on the alien facility mission
// sites, and pending Doom is the amount still animating on the geoscape. GetCurrentDoom(true)
// is the settled total the game itself compares against GetMaxDoom().
static function int AvatarTotal()
{
	local XComGameState_HeadquartersAlien AlienHQ;
	AlienHQ = GetAlienHQ();
	if (AlienHQ == none) return -1;
	return AlienHQ.GetCurrentDoom(true);
}

static function int AvatarPermanent()
{
	local XComGameState_HeadquartersAlien AlienHQ;
	AlienHQ = GetAlienHQ();
	if (AlienHQ == none) return -1;
	return AlienHQ.Doom;
}

static function int AvatarFacility()
{
	local XComGameState_MissionSite Site;
	local XComGameStateHistory History;
	local int Total;
	Total = 0;
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_MissionSite', Site)
	{
		if (Site.Available) Total += Site.Doom;
	}
	return Total;
}

static function int AvatarPending()
{
	local XComGameState_HeadquartersAlien AlienHQ;
	AlienHQ = GetAlienHQ();
	if (AlienHQ == none) return 0;
	return AlienHQ.GetPendingDoom();
}

static function int AvatarMax()
{
	local XComGameState_HeadquartersAlien AlienHQ;
	AlienHQ = GetAlienHQ();
	if (AlienHQ == none) return -1;
	return AlienHQ.GetMaxDoom();
}

// Spends the reduction on facility Doom first, then on the permanent value, which is the order
// the vanilla remove-doom reward uses. FromSites and FromPermanent report the split so the
// panel can show which bucket was actually hit.
static function bool ReduceAvatar(int Amount, out int FromSites, out int FromPermanent, out name ErrorCode)
{
	local XComGameState_HeadquartersAlien AlienHQ, NewAlienHQ;
	local XComGameState_MissionSite Site, NewSite;
	local XComGameStateHistory History;
	local array<XComGameState_MissionSite> Sites;
	local array<int> Touched;
	local XComGameState Change;
	local int I, Best, Before, Take, Remaining, Expected;

	ErrorCode = '';
	FromSites = 0;
	FromPermanent = 0;
	if (Amount <= 0)
	{
		ErrorCode = 'InvalidNumber';
		return false;
	}
	AlienHQ = GetAlienHQ();
	if (AlienHQ == none)
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	Before = AlienHQ.GetCurrentDoom(true);
	if (Before <= 0)
	{
		ErrorCode = 'NothingToRemove';
		return false;
	}

	History = `XCOMHISTORY;
	Sites.Length = 0;
	Touched.Length = 0;
	foreach History.IterateByClassType(class'XComGameState_MissionSite', Site)
	{
		if (Site.Available && Site.Doom > 0) Sites.AddItem(Site);
	}

	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Reduce avatar progress");
	Remaining = Amount;
	// Hit the biggest alien facility first, matching the vanilla reward priority.
	while (Remaining > 0)
	{
		Best = -1;
		for (I = 0; I < Sites.Length; ++I)
		{
			if (Touched.Find(Sites[I].ObjectID) != INDEX_NONE) continue;
			if (Best < 0 || Sites[I].Doom > Sites[Best].Doom) Best = I;
		}
		if (Best < 0) break;
		Touched.AddItem(Sites[Best].ObjectID);
		NewSite = XComGameState_MissionSite(Change.ModifyStateObject(class'XComGameState_MissionSite', Sites[Best].ObjectID));
		Take = Min(Remaining, Sites[Best].Doom);
		NewSite.Doom -= Take;
		Remaining -= Take;
		FromSites += Take;
	}
	if (Remaining > 0)
	{
		NewAlienHQ = XComGameState_HeadquartersAlien(Change.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		Take = Min(Remaining, NewAlienHQ.Doom);
		NewAlienHQ.Doom -= Take;
		Remaining -= Take;
		FromPermanent += Take;
	}
	if (Change.GetNumGameStateObjects() == 0)
	{
		`XCOMHISTORY.CleanupPendingGameState(Change);
		ErrorCode = 'NothingToRemove';
		return false;
	}
	if (!`GAMERULES.SubmitGameState(Change))
	{
		ErrorCode = 'SubmitFailed';
		return false;
	}

	Expected = Before - FromSites - FromPermanent;
	AlienHQ = GetAlienHQ();
	if (AlienHQ == none || AlienHQ.GetCurrentDoom(true) != Expected)
	{
		`log("[WOTCTrainer] Avatar verification failed: expected " $ Expected, true, 'WOTCTrainer');
		ErrorCode = 'VerifyFailed';
		return false;
	}
	`log("[WOTCTrainer] Avatar doom: " $ Before $ " -> " $ Expected
		$ " (facilities -" $ FromSites $ ", permanent -" $ FromPermanent $ ")", true, 'WOTCTrainer');
	return true;
}

//#############################################################################################
//----------------   STRATEGY CAPACITY   ------------------------------------------------------
//#############################################################################################

// BonusPowerProduced and BonusCommCapacity are the fields the vanilla reward handlers write
// (X2StrategyElement_DefaultRewards.GiveAvengerPowerReward and GiveAvengerResCommsReward).
// Both are persistent GameState values, so the change survives save and reload.
static function int PowerProduced()
{
	local XComGameState_HeadquartersXCom HQ;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) return -1;
	return HQ.GetPowerProduced();
}

static function int PowerConsumed()
{
	local XComGameState_HeadquartersXCom HQ;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) return -1;
	return HQ.GetPowerConsumed();
}

static function int PowerBonus()
{
	local XComGameState_HeadquartersXCom HQ;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) return -1;
	return HQ.BonusPowerProduced;
}

static function bool AddPower(int Amount, out int OldBonus, out int NewBonus, out name ErrorCode)
{
	local XComGameState_HeadquartersXCom HQ, NewHQ;
	local XComGameState Change;

	ErrorCode = '';
	OldBonus = 0;
	NewBonus = 0;
	if (Amount <= 0 || Amount > 10000)
	{
		ErrorCode = 'Bounds';
		return false;
	}
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none)
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	if (HQ.BonusPowerProduced > 2147483647 - Amount)
	{
		ErrorCode = 'Bounds';
		return false;
	}
	OldBonus = HQ.BonusPowerProduced;
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Add avenger power");
	NewHQ = XComGameState_HeadquartersXCom(Change.ModifyStateObject(class'XComGameState_HeadquartersXCom', HQ.ObjectID));
	NewHQ.BonusPowerProduced += Amount;
	NewHQ.DeterminePowerState();
	if (!`GAMERULES.SubmitGameState(Change))
	{
		ErrorCode = 'SubmitFailed';
		return false;
	}
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none || HQ.BonusPowerProduced != OldBonus + Amount)
	{
		ErrorCode = 'VerifyFailed';
		return false;
	}
	NewBonus = HQ.BonusPowerProduced;
	`log("[WOTCTrainer] Avenger power bonus: " $ OldBonus $ " -> " $ NewBonus, true, 'WOTCTrainer');
	return true;
}

static function int ContactPossible()
{
	local XComGameState_HeadquartersXCom HQ;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) return -1;
	return HQ.GetPossibleResContacts();
}

static function int ContactCurrent()
{
	local XComGameState_HeadquartersXCom HQ;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) return -1;
	return HQ.GetCurrentResContacts();
}

static function int ContactBonus()
{
	local XComGameState_HeadquartersXCom HQ;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) return -1;
	return HQ.BonusCommCapacity;
}

static function bool AddContacts(int Amount, out int OldBonus, out int NewBonus, out name ErrorCode)
{
	local XComGameState_HeadquartersXCom HQ, NewHQ;
	local XComGameState Change;

	ErrorCode = '';
	OldBonus = 0;
	NewBonus = 0;
	if (Amount <= 0 || Amount > 100)
	{
		ErrorCode = 'Bounds';
		return false;
	}
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none)
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	if (HQ.BonusCommCapacity > 2147483647 - Amount)
	{
		ErrorCode = 'Bounds';
		return false;
	}
	OldBonus = HQ.BonusCommCapacity;
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Add resistance contacts");
	NewHQ = XComGameState_HeadquartersXCom(Change.ModifyStateObject(class'XComGameState_HeadquartersXCom', HQ.ObjectID));
	NewHQ.BonusCommCapacity += Amount;
	if (!`GAMERULES.SubmitGameState(Change))
	{
		ErrorCode = 'SubmitFailed';
		return false;
	}
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none || HQ.BonusCommCapacity != OldBonus + Amount)
	{
		ErrorCode = 'VerifyFailed';
		return false;
	}
	NewBonus = HQ.BonusCommCapacity;
	`log("[WOTCTrainer] Resistance contact capacity bonus: " $ OldBonus $ " -> " $ NewBonus, true, 'WOTCTrainer');
	return true;
}

//#############################################################################################
//----------------   QUEUE COMPLETION   -------------------------------------------------------
//#############################################################################################

static function bool ProjectRemaining(int ProjectID)
{
	local XComGameState_HeadquartersXCom HQ;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) return true;
	return HQ.Projects.Find('ObjectID', ProjectID) != INDEX_NONE;
}

static function XComGameState_HeadquartersProject FacilityProject(int ProjectID)
{
	local XComGameState_HeadquartersProject Project;
	Project = XComGameState_HeadquartersProject(`XCOMHISTORY.GetGameStateForObjectID(ProjectID));
	if (Project == none) return none;
	if (XComGameState_HeadquartersProjectBuildFacility(Project) != none) return Project;
	if (XComGameState_HeadquartersProjectUpgradeFacility(Project) != none) return Project;
	if (XComGameState_HeadquartersProjectClearRoom(Project) != none) return Project;
	return none;
}

static function int ResearchQueued()
{
	local XComGameState_HeadquartersXCom HQ;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none || HQ.GetCurrentResearchProject() == none) return 0;
	return 1;
}

static function int ProvingGroundQueued()
{
	local XComGameState_HeadquartersXCom HQ;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersProjectProvingGround Project;
	local int I, Count;

	Count = 0;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) return 0;
	Facility = HQ.GetFacilityByName('ProvingGround');
	if (Facility == none) return 0;
	for (I = 0; I < Facility.BuildQueue.Length; ++I)
	{
		Project = XComGameState_HeadquartersProjectProvingGround(`XCOMHISTORY.GetGameStateForObjectID(Facility.BuildQueue[I].ObjectID));
		if (Project != none) ++Count;
	}
	return Count;
}

static function int FacilityQueued()
{
	local XComGameState_HeadquartersXCom HQ;
	local int I, Count;

	Count = 0;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) return 0;
	for (I = 0; I < HQ.Projects.Length; ++I)
	{
		if (FacilityProject(HQ.Projects[I].ObjectID) != none) ++Count;
	}
	return Count;
}

static function int CovertQueued()
{
	local XComGameState_CovertAction Action;
	local XComGameStateHistory History;
	local int Count;

	Count = 0;
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_CovertAction', Action)
	{
		if (Action.bStarted && !Action.bCompleted) ++Count;
	}
	return Count;
}

// OnProjectCompleted is the routine the strategy tick calls when a project timer expires (the
// project completion loop inside XComGameState_HeadquartersXCom.Update) and the routine
// UIChooseProject calls for an instant Proving Ground project. Every implementation issues its
// own headquarters order, so nothing else needs to be unpacked here.
static function bool CompleteResearchNow(out name ErrorCode)
{
	local XComGameState_HeadquartersXCom HQ;
	local XComGameState_HeadquartersProjectResearch Project;
	local int ProjectID;

	ErrorCode = '';
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none)
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	Project = HQ.GetCurrentResearchProject();
	if (Project == none)
	{
		ErrorCode = 'NothingQueued';
		return false;
	}
	ProjectID = Project.ObjectID;
	Project.OnProjectCompleted();
	if (ProjectRemaining(ProjectID))
	{
		`log("[WOTCTrainer] Research completion verification failed: ObjectID=" $ ProjectID, true, 'WOTCTrainer');
		ErrorCode = 'VerifyFailed';
		return false;
	}
	`log("[WOTCTrainer] Research project completed: ObjectID=" $ ProjectID, true, 'WOTCTrainer');
	return true;
}

static function bool CompleteProvingGroundNow(out int Completed, out name ErrorCode)
{
	local XComGameState_HeadquartersXCom HQ;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersProjectProvingGround Project;
	local array<int> IDs;
	local int I;

	ErrorCode = '';
	Completed = 0;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none)
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	Facility = HQ.GetFacilityByName('ProvingGround');
	if (Facility == none)
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	IDs.Length = 0;
	for (I = 0; I < Facility.BuildQueue.Length; ++I)
	{
		Project = XComGameState_HeadquartersProjectProvingGround(`XCOMHISTORY.GetGameStateForObjectID(Facility.BuildQueue[I].ObjectID));
		if (Project != none) IDs.AddItem(Project.ObjectID);
	}
	if (IDs.Length == 0)
	{
		ErrorCode = 'NothingQueued';
		return false;
	}
	for (I = 0; I < IDs.Length; ++I)
	{
		Project = XComGameState_HeadquartersProjectProvingGround(`XCOMHISTORY.GetGameStateForObjectID(IDs[I]));
		if (Project == none) continue;
		Project.OnProjectCompleted();
		if (ProjectRemaining(IDs[I]))
		{
			`log("[WOTCTrainer] Proving ground verification failed: ObjectID=" $ IDs[I], true, 'WOTCTrainer');
			ErrorCode = 'VerifyFailed';
			return false;
		}
		++Completed;
	}
	`log("[WOTCTrainer] Proving ground projects completed: " $ Completed, true, 'WOTCTrainer');
	return true;
}

static function bool CompleteFacilityNow(out int Completed, out name ErrorCode)
{
	local XComGameState_HeadquartersXCom HQ;
	local XComGameState_HeadquartersProject Project;
	local array<int> IDs;
	local int I;

	ErrorCode = '';
	Completed = 0;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none)
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	IDs.Length = 0;
	for (I = 0; I < HQ.Projects.Length; ++I)
	{
		if (FacilityProject(HQ.Projects[I].ObjectID) != none) IDs.AddItem(HQ.Projects[I].ObjectID);
	}
	if (IDs.Length == 0)
	{
		ErrorCode = 'NothingQueued';
		return false;
	}
	for (I = 0; I < IDs.Length; ++I)
	{
		Project = XComGameState_HeadquartersProject(`XCOMHISTORY.GetGameStateForObjectID(IDs[I]));
		if (Project == none) continue;
		Project.OnProjectCompleted();
		if (ProjectRemaining(IDs[I]))
		{
			`log("[WOTCTrainer] Facility verification failed: ObjectID=" $ IDs[I], true, 'WOTCTrainer');
			ErrorCode = 'VerifyFailed';
			return false;
		}
		++Completed;
	}
	`log("[WOTCTrainer] Facility projects completed: " $ Completed, true, 'WOTCTrainer');
	return true;
}

// CompleteCovertAction is the routine both the vanilla console cheat and the geoscape tick
// call. bCompleted has to be set here as well: only Update() sets it normally, and leaving it
// false would let the next strategy tick pay out the rewards a second time. bAmbushed is
// cleared so the finished action cannot re-enter the ambush branch of that same tick.
static function bool CompleteCovertNow(out int Completed, out name ErrorCode)
{
	local XComGameState_CovertAction Action, NewAction;
	local XComGameStateHistory History;
	local array<int> IDs;
	local XComGameState Change;
	local int I;

	ErrorCode = '';
	Completed = 0;
	History = `XCOMHISTORY;
	IDs.Length = 0;
	foreach History.IterateByClassType(class'XComGameState_CovertAction', Action)
	{
		if (Action.bStarted && !Action.bCompleted) IDs.AddItem(Action.ObjectID);
	}
	if (IDs.Length == 0)
	{
		ErrorCode = 'NothingQueued';
		return false;
	}
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Complete covert actions");
	for (I = 0; I < IDs.Length; ++I)
	{
		NewAction = XComGameState_CovertAction(Change.ModifyStateObject(class'XComGameState_CovertAction', IDs[I]));
		NewAction.bCompleted = true;
		NewAction.bAmbushed = false;
		NewAction.CompleteCovertAction(Change);
	}
	if (!`GAMERULES.SubmitGameState(Change))
	{
		ErrorCode = 'SubmitFailed';
		return false;
	}
	for (I = 0; I < IDs.Length; ++I)
	{
		Action = XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(IDs[I]));
		if (Action == none || !Action.bCompleted)
		{
			`log("[WOTCTrainer] Covert action verification failed: ObjectID=" $ IDs[I], true, 'WOTCTrainer');
			ErrorCode = 'VerifyFailed';
			return false;
		}
		++Completed;
	}
	`log("[WOTCTrainer] Covert actions completed: " $ Completed, true, 'WOTCTrainer');
	return true;
}

// Refunds the construction cost of every facility still being built, using the same
// RefundStrategyCost call the vanilla cancel-construction path uses. Facility upgrades are
// skipped because vanilla does not refund those either.
static function bool RefundFacilityNow(out int Refunded, out name ErrorCode)
{
	local XComGameState_HeadquartersXCom HQ, NewHQ;
	local XComGameState_HeadquartersProjectBuildFacility Project;
	local XComGameState_FacilityXCom Facility;
	local X2FacilityTemplate Template;
	local XComGameState Change;
	local int I;

	ErrorCode = '';
	Refunded = 0;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none)
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Refund facility construction");
	NewHQ = XComGameState_HeadquartersXCom(Change.ModifyStateObject(class'XComGameState_HeadquartersXCom', HQ.ObjectID));
	for (I = 0; I < HQ.Projects.Length; ++I)
	{
		Project = XComGameState_HeadquartersProjectBuildFacility(`XCOMHISTORY.GetGameStateForObjectID(HQ.Projects[I].ObjectID));
		if (Project == none) continue;
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Project.ProjectFocus.ObjectID));
		if (Facility == none) continue;
		Template = Facility.GetMyTemplate();
		if (Template == none) continue;
		NewHQ.RefundStrategyCost(Change, Template.Cost, NewHQ.FacilityBuildCostScalars, Project.SavedDiscountPercent);
		++Refunded;
	}
	if (Refunded == 0)
	{
		`XCOMHISTORY.CleanupPendingGameState(Change);
		ErrorCode = 'NothingQueued';
		return false;
	}
	if (!`GAMERULES.SubmitGameState(Change))
	{
		ErrorCode = 'SubmitFailed';
		return false;
	}
	`log("[WOTCTrainer] Facility construction refunds issued: " $ Refunded, true, 'WOTCTrainer');
	return true;
}

//#############################################################################################
//----------------   BULK SOLDIER RECOVERY   --------------------------------------------------
//#############################################################################################

static function int WoundedCount()
{
	local XComGameState_Unit Unit;
	local XComGameStateHistory History;
	local int Count;

	Count = 0;
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (!class'XComGameState_WOTCTrainer'.static.XComSoldier(Unit) || !Unit.IsAlive()) continue;
		if (Unit.IsInjured() || Unit.GetStatus() == eStatus_Healing) ++Count;
	}
	return Count;
}

static function int RestingCount()
{
	local XComGameState_Unit Unit;
	local XComGameStateHistory History;
	local int Count;

	Count = 0;
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (!class'XComGameState_WOTCTrainer'.static.XComSoldier(Unit) || !Unit.IsAlive()) continue;
		if (Unit.NeedsWillRecovery()) ++Count;
	}
	return Count;
}

static function bool RestingUnit(int UnitID, XComGameState_HeadquartersXCom HQ)
{
	local XComGameState_HeadquartersProjectRecoverWill Project;
	local int I;

	if (HQ == none) return false;
	for (I = 0; I < HQ.Projects.Length; ++I)
	{
		Project = XComGameState_HeadquartersProjectRecoverWill(`XCOMHISTORY.GetGameStateForObjectID(HQ.Projects[I].ObjectID));
		if (Project != none && Project.ProjectFocus.ObjectID == UnitID) return true;
	}
	return false;
}

static function bool HealAllNow(out int Count, out name ErrorCode)
{
	local array<StateObjectReference> Projects;

	ErrorCode = '';
	Count = 0;
	Projects = class'WOTCTrainerStrategy'.static.HealingProjects();
	return class'WOTCTrainerStrategy'.static.HealAll(Projects, Count, ErrorCode);
}

// Will below maximum is exactly what the game reads as Tired, so one pass restores will and
// clears fatigue together. Soldiers already resting in the infirmary go through their own
// recover-will project, which keeps the staff slot, the notification and the project cleanup
// on the vanilla path; the rest get the same two writes the project itself performs.
static function bool RestoreWillAllNow(out int Count, out name ErrorCode)
{
	local XComGameState_HeadquartersXCom HQ;
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersProjectRecoverWill Project;
	local XComGameStateHistory History;
	local array<int> Pending;
	local XComGameState Change;
	local int I, J, ProjectID;

	ErrorCode = '';
	Count = 0;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none)
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	for (I = 0; I < HQ.Projects.Length; ++I)
	{
		Project = XComGameState_HeadquartersProjectRecoverWill(`XCOMHISTORY.GetGameStateForObjectID(HQ.Projects[I].ObjectID));
		if (Project == none) continue;
		ProjectID = Project.ObjectID;
		Project.OnProjectCompleted();
		if (ProjectRemaining(ProjectID))
		{
			`log("[WOTCTrainer] Will recovery verification failed: ObjectID=" $ ProjectID, true, 'WOTCTrainer');
			ErrorCode = 'VerifyFailed';
			return false;
		}
		++Count;
	}

	History = `XCOMHISTORY;
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Restore will");
	Pending.Length = 0;
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (!class'XComGameState_WOTCTrainer'.static.XComSoldier(Unit) || !Unit.IsAlive()) continue;
		if (!Unit.NeedsWillRecovery() || RestingUnit(Unit.ObjectID, HQ)) continue;
		Unit = XComGameState_Unit(Change.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetCurrentStat(eStat_Will, Unit.GetMaxStat(eStat_Will));
		Unit.UpdateMentalState();
		Pending.AddItem(Unit.ObjectID);
		++Count;
	}
	if (Pending.Length == 0)
	{
		`XCOMHISTORY.CleanupPendingGameState(Change);
		if (Count == 0)
		{
			ErrorCode = 'NothingToRestore';
			return false;
		}
		return true;
	}
	if (!`GAMERULES.SubmitGameState(Change))
	{
		ErrorCode = 'SubmitFailed';
		return false;
	}
	for (J = 0; J < Pending.Length; ++J)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Pending[J]));
		if (Unit == none || Unit.NeedsWillRecovery() || Unit.GetMentalState() < eMentalState_Ready)
		{
			`log("[WOTCTrainer] Will restore verification failed: ObjectID=" $ Pending[J], true, 'WOTCTrainer');
			ErrorCode = 'VerifyFailed';
			return false;
		}
	}
	`log("[WOTCTrainer] Will restored for " $ Count $ " soldiers", true, 'WOTCTrainer');
	return true;
}
