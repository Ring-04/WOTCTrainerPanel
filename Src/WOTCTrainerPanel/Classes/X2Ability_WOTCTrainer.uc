class X2Ability_WOTCTrainer extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2AbilityTemplate Template;
	local X2Effect_WOTCTrainer Effect;
	`CREATE_X2ABILITY_TEMPLATE(Template, 'WOTCTrainerPassive');
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bIsPassive = true;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Effect = new class'X2Effect_WOTCTrainer';
	Effect.BuildPersistentEffect(1, true, false);
	Template.AddTargetEffect(Effect);
	Templates.AddItem(Template);
	return Templates;
}
