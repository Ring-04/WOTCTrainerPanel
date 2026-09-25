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
	// Built the way the vanilla tactical HUD builds the buttons it expects the mouse to click
	// (UITacticalHUD_CommanderHUD): PC button styling plus a click delegate.
	Entry.InitButton('WOTCTrainerTacticalEntry', Entry.EntryLabel, OnOpen, eUIButtonStyle_BUTTON_WHEN_MOUSE);
	Entry.AnchorTopRight();
	Entry.OriginTopRight();
	Entry.SetPosition(-35, 160);
	Entry.SetSize(170, 42);
	`log("[WOTCTrainer] Trainer button created, waiting for flash init", true, 'WOTCTrainer');
	Entry.RestartEntryWatch();
}

event OnReceiveFocus(UIScreen Screen)
{
	OnInit(Screen);
}

function OnOpen(UIButton Button)
{
	local UIMovie Movie;
	local UIScreen Host;
	local UIScreenStack Stack;
	local UIWOTCTrainerBase Panel;

	`log("[WOTCTrainer] Tactical panel requested", true, 'WOTCTrainer');

	if (!class'WOTCTrainerTactical'.static.Available())
	{
		`log("[WOTCTrainer] Tactical panel rejected: not a single player WOTC battle", true, 'WOTCTrainer');
		return;
	}
	if (Button == none)
		return;

	// The button lives inside the tactical HUD, so that screen is the host this panel belongs to -
	// not whatever happens to be on top of the stack at the moment of the click.
	Movie = Button.Movie;
	Host = Button.Screen;
	if (Host == none || Movie == none)
	{
		`log("[WOTCTrainer] Tactical panel rejected: no host screen for the entry button", true, 'WOTCTrainer');
		return;
	}
	Stack = Movie.Stack;
	if (Stack == none)
	{
		`log("[WOTCTrainer] Tactical panel rejected: no screen stack", true, 'WOTCTrainer');
		return;
	}
	if (Stack.GetCurrentScreen() != Host)
		`log("[WOTCTrainer] Tactical HUD is not the top screen (" $ string(Stack.GetCurrentClass().Name) $ "); opening anyway", true, 'WOTCTrainer');

	// At most one trainer panel family may exist, so anything left over is closed first.
	class'UIWOTCTrainerBase'.static.RemoveTrainers(Stack, "reopening tactical trainer");

	Panel = Button.Spawn(class'UIWOTCTrainerTactical', `PRES);
	if (Panel == none)
	{
		`log("[WOTCTrainer] Tactical panel rejected: spawn failed", true, 'WOTCTrainer');
		return;
	}
	Stack.Push(Panel, Movie);
	`log("[WOTCTrainer] Tactical panel opened on " $ string(Host.Class.Name), true, 'WOTCTrainer');
}

defaultproperties
{
	ScreenClass=class'UITacticalHUD'
}
