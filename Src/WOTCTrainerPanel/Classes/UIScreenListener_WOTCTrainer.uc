class UIScreenListener_WOTCTrainer extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIButton Entry;
	if (class'WOTCTrainerStrategy'.static.GetHQ() == none)
		return;
	if (Screen.GetChildByName('WOTCTrainerEntry', false) != none)
		return;
	Entry = Screen.Spawn(class'UIButton', Screen);
	Entry.ResizeToText = false;
	Entry.InitButton('WOTCTrainerEntry', class'WOTCTrainerText'.default.Title, OnOpen);
	Entry.AnchorTopRight();
	Entry.OriginTopRight();
	Entry.SetPosition(-35, 155);
	Entry.SetSize(170, 42);
	`log("[WOTCTrainer] Strategy entry initialized", true, 'WOTCTrainer');
}

event OnReceiveFocus(UIScreen Screen)
{
	OnInit(Screen);
}

function OnOpen(UIButton Button)
{
	local UIScreen Top;
	if (class'WOTCTrainerStrategy'.static.GetHQ() == none || `SCREENSTACK.IsInStack(class'UIWOTCTrainer'))
		return;
	Top = `SCREENSTACK.GetCurrentScreen();
	// The persistent Avenger HUD is also present behind other modal screens.
	if (UIFacilityGrid(Top) == none && UIStrategyMap(Top) == none)
		return;
	`GAME.GetGeoscape().Pause();
	`SCREENSTACK.Push(Button.Spawn(class'UIWOTCTrainer', `HQPRES));
}

defaultproperties
{
	ScreenClass=class'UIAvengerHUD'
}
