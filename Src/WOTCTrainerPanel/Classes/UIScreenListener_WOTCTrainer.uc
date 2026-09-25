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
	if (class'WOTCTrainerStrategy'.static.GetHQ() == none)
		return;
	Top = `SCREENSTACK.GetCurrentScreen();
	// The persistent Avenger HUD is also present behind other modal screens.
	if (UIFacilityGrid(Top) == none && UIStrategyMap(Top) == none)
		return;
	// A new trainer always starts from a clean stack: anything left over from an earlier screen is
	// removed first, so two panels of the family can never be alive at the same time.
	class'UIWOTCTrainerBase'.static.RemoveTrainers(`SCREENSTACK, "reopening strategy trainer");
	`GAME.GetGeoscape().Pause();
	`SCREENSTACK.Push(Button.Spawn(class'UIWOTCTrainer', `HQPRES), Button.Movie);
	`log("[WOTCTrainer] Strategy panel opened on " $ (Button.Screen != none ? string(Button.Screen.Class.Name) : "no host screen"), true, 'WOTCTrainer');
}

defaultproperties
{
	ScreenClass=class'UIAvengerHUD'
}
