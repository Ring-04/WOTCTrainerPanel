class X2EventListener_WOTCTrainer extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2EventListenerTemplate Template;
	`CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template, 'WOTCTrainerTacticalEvents');
	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = false;
	Template.AddEvent('AbilityActivated', OnAbility);
	Template.AddEvent('PlayerTurnBegun', OnTurn);
	Templates.AddItem(Template);
	return Templates;
}

static function EventListenerReturn OnAbility(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_WOTCTrainer Settings;
	local XComGameState_Unit Unit;
	local XComGameState_Ability Ability;
	local XComGameState Change;
	if (GameState == none || GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt) return ELR_NoInterrupt;
	Settings = class'XComGameState_WOTCTrainer'.static.GetSettings();
	Unit = XComGameState_Unit(EventSource);
	Ability = XComGameState_Ability(EventData);
	if (Settings == none || Ability == none || Unit == none) return ELR_NoInterrupt;
	Unit = class'WOTCTrainerTactical'.static.UnitByID(Unit.ObjectID);
	if (Unit == none) return ELR_NoInterrupt;
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Maintain tactical settings");
	class'WOTCTrainerTactical'.static.Maintain(Change, Unit, Settings, Ability.GetMyTemplateName(), Ability.GetSourceWeapon() != none && Ability.GetMyTemplate().Hostility == eHostility_Offensive);
	if (Change.GetNumGameStateObjects() > 0) `TACTICALRULES.SubmitGameState(Change);
	else `XCOMHISTORY.CleanupPendingGameState(Change);
	return ELR_NoInterrupt;
}

static function EventListenerReturn OnTurn(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_WOTCTrainer Settings;
	local XComGameState_Unit Unit, NewUnit;
	local XComGameState_Player Player;
	local XComGameState Change;
	Settings = class'XComGameState_WOTCTrainer'.static.GetSettings();
	Player = XComGameState_Player(EventSource);
	if (Settings == none || Player == none || Player.GetTeam() != eTeam_XCom) return ELR_NoInterrupt;
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Turn settings");
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (!class'XComGameState_WOTCTrainer'.static.XComSoldier(Unit) || !Unit.IsAlive()) continue;
		if ((Settings.Flags[0].bEnabled || Settings.Flags[9].bEnabled || Settings.Flags[10].bEnabled || Settings.Flags[11].bEnabled) && Unit.AffectedByEffectNames.Find('WOTCTrainerEffect') == INDEX_NONE)
		{
			NewUnit = XComGameState_Unit(Change.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
			class'WOTCTrainerTactical'.static.EnsureEffect(Change, NewUnit);
		}
		class'WOTCTrainerTactical'.static.Maintain(Change, Unit, Settings, '', false);
	}
	if (Change.GetNumGameStateObjects() > 0) `TACTICALRULES.SubmitGameState(Change);
	else `XCOMHISTORY.CleanupPendingGameState(Change);
	return ELR_NoInterrupt;
}

