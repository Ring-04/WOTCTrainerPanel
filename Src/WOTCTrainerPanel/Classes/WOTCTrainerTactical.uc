class WOTCTrainerTactical extends Object abstract;

static function bool Available()
{
	local XComGameState_BattleData Battle;
	if (`TACTICALRULES == none || `PRES == none) return false;
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
	return Battle != none && !Battle.bMultiplayer;
}

static function bool CanEdit()
{
	local XComGameState_Player Player;
	if (!Available() || !`TACTICALRULES.IsInState('TurnPhase_UnitActions') || `TACTICALRULES.IsDoingLatentSubmission()) return false;
	Player = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID));
	return Player != none && Player.GetTeam() == eTeam_XCom;
}

static function XComGameState_Unit UnitByID(int UnitID)
{
	local XComGameState_Unit Unit;
	if (!Available()) return none;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
	if (!class'XComGameState_WOTCTrainer'.static.XComSoldier(Unit) || !Unit.IsAlive()) return none;
	return Unit;
}

static function bool EnsureEffect(XComGameState Change, XComGameState_Unit Unit)
{
	local EffectAppliedData Data;
	local X2Effect Effect;
	local name Result;
	if (Unit.AffectedByEffectNames.Find('WOTCTrainerEffect') != INDEX_NONE) return true;
	Data.EffectRef.LookupType = TELT_AbilityTargetEffects;
	Data.EffectRef.TemplateEffectLookupArrayIndex = 0;
	Data.EffectRef.SourceTemplateName = 'WOTCTrainerPassive';
	Data.PlayerStateObjectRef = Unit.ControllingPlayer;
	Data.SourceStateObjectRef = Unit.GetReference(); Data.TargetStateObjectRef = Unit.GetReference();
	Effect = class'X2Effect'.static.GetX2Effect(Data.EffectRef);
	if (Effect == none) return false;
	Result = Effect.ApplyEffect(Data, Unit, Change);
	return Result == 'AA_Success' || Result == 'AA_DuplicateEffectIgnored';
}

static function bool SetToggle(int Index, int UnitID, bool Expected, bool Enable, out name ErrorCode)
{
	local XComGameState_WOTCTrainer Settings;
	local XComGameState_BattleData Battle;
	local XComGameState_Unit Unit, NewUnit;
	local XComGameState Change;
	local int I;
	ErrorCode = '';
	if (!CanEdit() || Index < 0 || Index > 11 || (Index == 1 && UnitByID(UnitID) == none)) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'TacticalUnavailable');
	if (class'XComGameState_WOTCTrainer'.static.Enabled(Index, UnitID) != Expected) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'Stale');
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	Settings = XComGameState_WOTCTrainer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_WOTCTrainer', true));
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Tactical toggle");
	if (Settings == none) Settings = XComGameState_WOTCTrainer(Change.CreateNewStateObject(class'XComGameState_WOTCTrainer'));
	else Settings = XComGameState_WOTCTrainer(Change.ModifyStateObject(class'XComGameState_WOTCTrainer', Settings.ObjectID));
	if (Settings.BattleID != Battle.ObjectID || Settings.MissionID != Battle.m_iMissionID)
	{
		for (I = 0; I < 12; ++I) Settings.Flags[I].bEnabled = false;
		Settings.ProtectedUnits.Length = 0;
	}
	Settings.BattleID = Battle.ObjectID; Settings.MissionID = Battle.m_iMissionID;
	if (Index == 1)
	{
		Settings.ProtectedUnits.RemoveItem(UnitID);
		if (Enable) Settings.ProtectedUnits.AddItem(UnitID);
	}
	else Settings.Flags[Index].bEnabled = Enable;
	if (Enable)
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			if (!class'XComGameState_WOTCTrainer'.static.XComSoldier(Unit) || !Unit.IsAlive()) continue;
			if (Index == 1 && Unit.ObjectID != UnitID) continue;
			NewUnit = XComGameState_Unit(Change.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
			if (!EnsureEffect(Change, NewUnit))
			{
				`XCOMHISTORY.CleanupPendingGameState(Change);
				return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'Unsupported');
			}
			Maintain(Change, NewUnit, Settings, '', false);
		}
	}
	if (!`TACTICALRULES.SubmitGameState(Change)) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'SubmitFailed');
	if (class'XComGameState_WOTCTrainer'.static.Enabled(Index, UnitID) != Enable) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'VerifyFailed');
	`log("[WOTCTrainer] Tactical flag=" $ Index $ " unit=" $ UnitID $ ": " $ Expected $ " -> " $ Enable, true, 'WOTCTrainer');
	return true;
}

// Only create copies for fields that really need changing, avoiding empty event submissions.
static function Maintain(XComGameState Change, XComGameState_Unit Unit, XComGameState_WOTCTrainer Settings, name UsedAbility, bool WeaponAttack)
{
	local XComGameState_Unit NewUnit;
	local XComGameState_Item Item;
	local XComGameState_Ability Ability;
	local array<XComGameState_Item> Items;
	local int I, Charges;
	local bool RestoreStandard, RestoreMove;
	if (Settings == none || !class'XComGameState_WOTCTrainer'.static.XComSoldier(Unit) || !Unit.IsAlive()) return;
	RestoreStandard = Settings.Flags[2].bEnabled || (Settings.Flags[4].bEnabled && WeaponAttack);
	RestoreMove = Settings.Flags[3].bEnabled && (UsedAbility == 'StandardMove' || UsedAbility == '');
	if (Unit.IsAbleToAct() && Unit.ControllingPlayer == `TACTICALRULES.GetCachedUnitActionPlayerRef())
	{
		if (RestoreStandard && Unit.ActionPoints.Length < 2)
		{
			NewUnit = XComGameState_Unit(Change.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
			while (NewUnit.ActionPoints.Length < (Settings.Flags[2].bEnabled ? 2 : 1)) NewUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
		}
		else if (RestoreMove && Unit.ActionPoints.Find(class'X2CharacterTemplateManager'.default.MoveActionPoint) == INDEX_NONE)
		{
			NewUnit = XComGameState_Unit(Change.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
			NewUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);
		}
	}
	if (Settings.Flags[5].bEnabled || Settings.Flags[6].bEnabled)
	{
		Items = Unit.GetAllInventoryItems(Change);
		foreach Items(Item)
		{
			if (Item.GetClipSize() > 0 && Item.Ammo < Item.GetClipSize())
			{
				Item = XComGameState_Item(Change.ModifyStateObject(class'XComGameState_Item', Item.ObjectID));
				Item.Ammo = Item.GetClipSize();
			}
		}
	}
	if (Settings.Flags[7].bEnabled || Settings.Flags[8].bEnabled)
	{
		for (I = 0; I < Unit.Abilities.Length; ++I)
		{
			Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Unit.Abilities[I].ObjectID));
			if (Ability == none) continue;
			Charges = Ability.iCharges;
			if (Settings.Flags[8].bEnabled && Ability.GetMyTemplate().AbilityCharges != none) Charges = Max(Charges, Ability.GetMyTemplate().AbilityCharges.GetInitialCharges(Ability, Unit));
			if ((Settings.Flags[7].bEnabled && Ability.iCooldown > 0) || Charges > Ability.iCharges)
			{
				Ability = XComGameState_Ability(Change.ModifyStateObject(class'XComGameState_Ability', Ability.ObjectID));
				if (Settings.Flags[7].bEnabled) Ability.iCooldown = 0;
				Ability.iCharges = Charges;
			}
		}
	}
}

static function int ActionValue(XComGameState_Unit Unit, int Action)
{
	local XComGameState_Ability Ability;
	local XComGameState_Item Item;
	local int I, Total;
	if (Unit == none) return -1;
	if (Action == 0) return int(Unit.GetCurrentStat(eStat_HP));
	if (Action == 1 || Action == 2) return Unit.ActionPoints.Length;
	if (Action == 3)
	{
		Item = Unit.GetItemInSlot(eInvSlot_PrimaryWeapon);
		return Item == none ? -1 : Item.Ammo;
	}
	if (Action == 4)
	{
		for (I = 0; I < Unit.Abilities.Length; ++I)
		{
			Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Unit.Abilities[I].ObjectID));
			if (Ability != none && Ability.iCooldown > 0) ++Total;
		}
		return Total;
	}
	return -1;
}

static function int ActionTarget(XComGameState_Unit Unit, int Action)
{
	local XComGameState_Item Item;
	if (Action == 0) return int(Unit.GetMaxStat(eStat_HP));
	if (Action == 1 || Action == 2) return Unit.ActionPoints.Length + 1;
	if (Action == 3) { Item = Unit.GetItemInSlot(eInvSlot_PrimaryWeapon); return Item == none ? -1 : Item.GetClipSize(); }
	return 0;
}

static function bool DoAction(int UnitID, int Action, int Expected, out name ErrorCode)
{
	local XComGameState_Unit Unit;
	local XComGameState_Item Item;
	local XComGameState_Ability Ability;
	local XComGameState Change;
	local int I, Target;
	ErrorCode = '';
	Unit = UnitByID(UnitID);
	if (!CanEdit() || Unit == none || !Unit.IsAbleToAct() || Action < 0 || Action > 4) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'TacticalUnavailable');
	if (ActionValue(Unit, Action) != Expected) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'Stale');
	Target = ActionTarget(Unit, Action);
	if (Target < 0 || ((Action == 1 || Action == 2) && Target > 100)) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'Bounds');
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Tactical unit action");
	Unit = XComGameState_Unit(Change.ModifyStateObject(class'XComGameState_Unit', UnitID));
	if (Action == 0) Unit.SetCurrentStat(eStat_HP, Target);
	else if (Action == 1 || Action == 2) Unit.ActionPoints.AddItem(Action == 1 ? class'X2CharacterTemplateManager'.default.StandardActionPoint : class'X2CharacterTemplateManager'.default.MoveActionPoint);
	else if (Action == 3)
	{
		Item = Unit.GetItemInSlot(eInvSlot_PrimaryWeapon);
		Item = XComGameState_Item(Change.ModifyStateObject(class'XComGameState_Item', Item.ObjectID)); Item.Ammo = Target;
	}
	else
	{
		for (I = 0; I < Unit.Abilities.Length; ++I)
		{
			Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Unit.Abilities[I].ObjectID));
			if (Ability == none || Ability.iCooldown <= 0) continue;
			Ability = XComGameState_Ability(Change.ModifyStateObject(class'XComGameState_Ability', Ability.ObjectID)); Ability.iCooldown = 0;
		}
	}
	if (!`TACTICALRULES.SubmitGameState(Change)) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'SubmitFailed');
	Unit = UnitByID(UnitID);
	if (Unit == none || ActionValue(Unit, Action) != Target) return class'WOTCTrainerSoldiers'.static.Fail(ErrorCode, 'VerifyFailed');
	`log("[WOTCTrainer] Tactical unit=" $ UnitID $ " action=" $ Action $ ": " $ Expected $ " -> " $ Target, true, 'WOTCTrainer');
	return true;
}

