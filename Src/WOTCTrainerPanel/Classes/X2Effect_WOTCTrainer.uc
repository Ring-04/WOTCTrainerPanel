class X2Effect_WOTCTrainer extends X2Effect_Persistent;

function bool ProvidesDamageImmunity(XComGameState_Effect EffectState, name DamageType)
{
	local XComGameState_Unit Unit;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	return class'XComGameState_WOTCTrainer'.static.Protected(Unit);
}

function bool PreDeathCheck(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState)
{
	if (!class'XComGameState_WOTCTrainer'.static.Protected(UnitState)) return false;
	UnitState.SetCurrentStat(eStat_HP, Max(1, int(UnitState.GetCurrentStat(eStat_HP))));
	return true;
}

function bool PreBleedoutCheck(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState)
{
	return PreDeathCheck(NewGameState, UnitState, EffectState);
}

function int ModifyDamageFromDestructible(XComGameState_Destructible DestructibleState, int IncomingDamage, XComGameState_Unit TargetUnit, XComGameState_Effect EffectState)
{
	return class'XComGameState_WOTCTrainer'.static.Protected(TargetUnit) ? -IncomingDamage : 0;
}

function bool StandardAttack(XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState)
{
	return class'XComGameState_WOTCTrainer'.static.XComSoldier(Attacker) && Target != none && Attacker.IsEnemyUnit(Target) && AbilityState != none
		&& AbilityState.GetMyTemplate().Hostility == eHostility_Offensive && X2AbilityToHitCalc_StandardAim(AbilityState.GetMyTemplate().AbilityToHitCalc) != none;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo Modifier;
	if (!StandardAttack(Attacker, Target, AbilityState)) return;
	Modifier.Value = 1000;
	Modifier.Reason = class'WOTCTrainerText'.default.Title;
	if (class'XComGameState_WOTCTrainer'.static.Enabled(9)) { Modifier.ModType = eHit_Success; ShotModifiers.AddItem(Modifier); }
	if (class'XComGameState_WOTCTrainer'.static.Enabled(10)) { Modifier.ModType = eHit_Crit; ShotModifiers.AddItem(Modifier); }
}

function bool ChangeHitResultForAttacker(XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult)
{
	if (!StandardAttack(Attacker, TargetUnit, AbilityState)) return false;
	if (CurrentResult != eHit_Miss && CurrentResult != eHit_Graze && CurrentResult != eHit_Success && CurrentResult != eHit_Crit) return false;
	if (class'XComGameState_WOTCTrainer'.static.Enabled(10) && (CurrentResult != eHit_Miss || class'XComGameState_WOTCTrainer'.static.Enabled(9)))
	{
		NewHitResult = eHit_Crit; return true;
	}
	if (class'XComGameState_WOTCTrainer'.static.Enabled(9) && (CurrentResult == eHit_Miss || CurrentResult == eHit_Graze))
	{
		NewHitResult = eHit_Success; return true;
	}
	return false;
}

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local XComGameState_Unit Target;
	Target = XComGameState_Unit(TargetDamageable);
	if (!class'XComGameState_WOTCTrainer'.static.Enabled(11) || !class'XComGameState_WOTCTrainer'.static.XComSoldier(Attacker) || Target == none || AbilityState == none) return 0;
	if (!Attacker.IsEnemyUnit(Target) || !Target.IsAlive() || AppliedData.SourceStateObjectRef.ObjectID != Attacker.ObjectID || CurrentDamage <= 0) return 0;
	return Max(0, int(Target.GetCurrentStat(eStat_HP) + Target.GetCurrentStat(eStat_ShieldHP) + Target.GetCurrentStat(eStat_ArmorMitigation)) + 100 - CurrentDamage);
}

defaultproperties
{
	EffectName="WOTCTrainerEffect"
	DuplicateResponse=eDupe_Ignore
}
