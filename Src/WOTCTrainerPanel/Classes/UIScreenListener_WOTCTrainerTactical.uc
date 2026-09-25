class UIScreenListener_WOTCTrainerTactical extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIButton Entry;
	if (!class'WOTCTrainerTactical'.static.Available() || Screen.GetChildByName('WOTCTrainerTacticalEntry', false) != none) return;
	Entry = Screen.Spawn(class'UIButton', Screen);
	Entry.ResizeToText = false;
	Entry.InitButton('WOTCTrainerTacticalEntry', class'WOTCTrainerText'.default.Title, OnOpen);
	Entry.AnchorTopRight(); Entry.OriginTopRight(); Entry.SetPosition(-35, 160); Entry.SetSize(170, 42);
	`log("[WOTCTrainer] Tactical entry initialized", true, 'WOTCTrainer');
}

event OnReceiveFocus(UIScreen Screen) { OnInit(Screen); }

function OnOpen(UIButton Button)
{
	if (!class'WOTCTrainerTactical'.static.Available() || `SCREENSTACK.IsInStack(class'UIWOTCTrainerTactical')) return;
	if (UITacticalHUD(`SCREENSTACK.GetCurrentScreen()) == none) return;
	`SCREENSTACK.Push(Button.Spawn(class'UIWOTCTrainerTactical', `PRES));
}

defaultproperties
{
	ScreenClass=class'UITacticalHUD'
}
