class UIScreenListener_WOTCTrainerTactical extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIPanel Existing;
	local WOTCTrainerButton Entry;
	local UITacticalHUD HUD;

	`log("[WOTCTrainer] Tactical listener loaded: screen=" $ string(Screen.Class.Name) $ " MCName=" $ string(Screen.MCName), true, 'WOTCTrainer');

	if (!class'WOTCTrainerTactical'.static.Available())
	{
		`log("[WOTCTrainer] Tactical entry unavailable (not a single player WOTC battle)", true, 'WOTCTrainer');
		return;
	}

	HUD = UITacticalHUD(Screen);
	if (HUD == none)
	{
		`log("[WOTCTrainer] Tactical HUD not detected: listener screen is " $ string(Screen.Class.Name), true, 'WOTCTrainer');
		return;
	}
	`log("[WOTCTrainer] Tactical HUD detected: " $ string(HUD.MCName) $ " " $ (HUD.bIsInited ? "inited" : "not-inited"), true, 'WOTCTrainer');

	Existing = Screen.GetChildByName('WOTCTrainerTacticalEntry', false);
	if (Existing != none)
	{
		Entry = WOTCTrainerButton(Existing);
		if (Entry == none)
		{
			`log("[WOTCTrainer] Tactical entry already present but not a trainer button; leaving it alone", true, 'WOTCTrainer');
			return;
		}

		`log("[WOTCTrainer] Tactical entry already present: " $ (Entry.bIsInited ? "inited" : "not-inited"), true, 'WOTCTrainer');
		if (!Entry.bIsInited)
			Entry.RestartEntryWatch();
		return;
	}

	Entry = Screen.Spawn(class'WOTCTrainerButton', Screen);
	Entry.bIsTacticalEntry = true;
	Entry.EntryLabel = class'WOTCTrainerText'.default.Title;
	Entry.ResizeToText = false;
	Entry.InitButton('WOTCTrainerTacticalEntry', Entry.EntryLabel, OnOpen);
	Entry.AnchorTopRight(); Entry.OriginTopRight(); Entry.SetPosition(-35, 160); Entry.SetSize(170, 42);
	`log("[WOTCTrainer] Trainer button created, waiting for flash init", true, 'WOTCTrainer');
	Entry.RestartEntryWatch();
}

event OnReceiveFocus(UIScreen Screen) { OnInit(Screen); }

function OnOpen(UIButton Button)
{
	`log("[WOTCTrainer] Button clicked", true, 'WOTCTrainer');

	if (!class'WOTCTrainerTactical'.static.Available() || `SCREENSTACK.IsInStack(class'UIWOTCTrainerTactical')) return;
	if (UITacticalHUD(`SCREENSTACK.GetCurrentScreen()) == none) return;
	`SCREENSTACK.Push(Button.Spawn(class'UIWOTCTrainerTactical', `PRES));
}

defaultproperties
{
	ScreenClass=class'UITacticalHUD'
}
