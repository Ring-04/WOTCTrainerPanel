class UIWOTCTrainerBase extends UIScreen;

var UIPanel Root;
var UIText ResultText;
var bool bModalPending;
var int PendingOld, PendingNew;
var name PendingKind;

// The screen this panel was opened on top of. It is cleared as soon as that screen goes away:
// a trainer panel never outlives its host and never keeps a reference to a removed screen.
var UIScreen HostScreen;

//==============================================================================
//  PANEL LIFECYCLE
//==============================================================================

simulated function OnInit()
{
	super.OnInit();
	HostScreen = FindHostScreen();
	`log("[WOTCTrainer] Panel opened on " $ (HostScreen != none ? string(HostScreen.Class.Name) : "no host screen")
		$ " (" $ string(Class.Name) $ ")", true, 'WOTCTrainer');
	SetTimer(0.5, true, nameof(WatchHost));
}

simulated function OnRemoved()
{
	super.OnRemoved();
	ClearTimer(nameof(WatchHost));
}

// Safety net for stack changes that raise no listener signal, for example re-pushing a screen the
// movie already has loaded. Signals handle the normal cases instantly; this only catches the rest.
simulated function WatchHost()
{
	if (Movie == none || Movie.Stack == none || Movie.Stack.Screens.Find(self) == INDEX_NONE)
	{
		ClearTimer(nameof(WatchHost));
		return;
	}
	if (IsCoveredByForeignScreen())
		CloseTrainers("screen changed");
	else if (HostScreen != none && !HostIsAlive())
		CloseTrainers("host screen gone");
}

// The host is the first real screen below this panel. UIScreenStack keeps a UIMouseGuard directly
// under every screen that consumes mouse events and peels transient screens onto the top of the
// stack, so neither counts as the screen this panel belongs to.
simulated function UIScreen FindHostScreen()
{
	local int I, MyIndex;
	local UIScreen Candidate;

	if (Movie == none || Movie.Stack == none)
		return none;
	MyIndex = Movie.Stack.Screens.Find(self);
	if (MyIndex == INDEX_NONE)
		return none;
	for (I = MyIndex + 1; I < Movie.Stack.Screens.Length; ++I)
	{
		Candidate = Movie.Stack.Screens[I];
		if (Candidate == none || Candidate == self)
			continue;
		if (IsTrainerScreen(Candidate) || IsTransientScreen(Candidate))
			continue;
		return Candidate;
	}
	return none;
}

simulated function bool HostIsAlive()
{
	if (HostScreen == none || Movie == none || Movie.Stack == none)
		return false;
	return Movie.Stack.Screens.Find(HostScreen) != INDEX_NONE;
}

// True when something other than the trainer family sits above this panel: the game has moved on.
simulated function bool IsCoveredByForeignScreen()
{
	local int I, MyIndex;
	local UIScreen Candidate;

	MyIndex = Movie.Stack.Screens.Find(self);
	if (MyIndex == INDEX_NONE)
		return false;
	for (I = 0; I < MyIndex; ++I)
	{
		Candidate = Movie.Stack.Screens[I];
		if (Candidate == none || Candidate == self)
			continue;
		if (IsTrainerScreen(Candidate) || IsTransientScreen(Candidate))
			continue;
		return true;
	}
	return false;
}

static function bool IsTrainerScreen(UIScreen TestScreen)
{
	return TestScreen != none && TestScreen.IsA('UIWOTCTrainerBase');
}

// ForceStackOrder keeps these peeled onto the top of the stack and UIMouseGuard sits under the
// screen it guards; none of them means the game has switched to another screen.
static function bool IsTransientScreen(UIScreen TestScreen)
{
	if (TestScreen == none)
		return true;
	return TestScreen.IsA('UIDialogueBox')
		|| TestScreen.IsA('UITooltipMgr')
		|| TestScreen.IsA('UIProgressDialogue')
		|| TestScreen.IsA('UIRedScreen')
		|| TestScreen.IsA('UIMultiplayerDisconnectPopup')
		|| TestScreen.IsA('UIMouseGuard');
}

// Topmost trainer panel in the stack, if there is one.
static function UIWOTCTrainerBase FindTrainer(UIScreenStack Stack)
{
	local int I;
	local UIWOTCTrainerBase Trainer;

	if (Stack == none)
		return none;
	for (I = 0; I < Stack.Screens.Length; ++I)
	{
		Trainer = UIWOTCTrainerBase(Stack.Screens[I]);
		if (Trainer != none)
			return Trainer;
	}
	return none;
}

// Removes every trainer panel from the stack. OnlyHost != none limits this to the panels that were
// opened on that one screen.
static function int RemoveTrainers(UIScreenStack Stack, string Reason, optional UIScreen OnlyHost)
{
	local int I, Removed;
	local UIWOTCTrainerBase Trainer;

	if (Stack == none)
		return 0;
	for (I = 0; I < Stack.Screens.Length; ++I)
	{
		Trainer = UIWOTCTrainerBase(Stack.Screens[I]);
		if (Trainer == none || (OnlyHost != none && Trainer.HostScreen != OnlyHost))
			continue;
		Trainer.HostScreen = none;
		Stack.Pop(Trainer, false);
		`log("[WOTCTrainer] Trainer panel removed: " $ string(Trainer.Class.Name) $ " (" $ Reason $ ")", true, 'WOTCTrainer');
		++Removed;
		--I;
	}
	return Removed;
}

// Only one trainer panel family may exist at a time, so anything left over from an earlier screen
// is closed before a new panel opens.
simulated function CloseTrainers(string Reason)
{
	if (Movie == none || Movie.Stack == none)
		return;
	RemoveTrainers(Movie.Stack, Reason);
}

// Trainer actions that hand control back to a vanilla flow (completing research, a proving ground
// project, a facility or a covert action) must not leave the panel behind: that flow pushes its own
// screen, and a trainer left underneath would stay visible but unclickable under that screen's
// mouse guard.
simulated function CloseForVanillaTransition(string Action)
{
	if (Movie == none || Movie.Stack == none)
		return;
	`log("[WOTCTrainer] Auto-closing trainer before transition: " $ Action, true, 'WOTCTrainer');
	RemoveTrainers(Movie.Stack, "vanilla transition: " $ Action);
}

// Opens a page above this panel, in the same movie. A stale copy of the page is closed first so a
// page can never be stacked on itself.
simulated function UIWOTCTrainerBase OpenPage(class<UIWOTCTrainerBase> PageClass)
{
	local UIWOTCTrainerBase Page;

	if (PageClass == none || Movie == none || Movie.Stack == none)
		return none;
	Page = UIWOTCTrainerBase(Movie.Stack.GetFirstInstanceOf(PageClass));
	if (Page != none)
		Page.ClosePanel();
	Page = Spawn(PageClass, Movie.Pres);
	if (Page != none)
		Movie.Stack.Push(Page, Movie);
	return Page;
}

//==============================================================================
//  COMMON UI
//==============================================================================

simulated function UIText AddText(UIPanel Parent, name ControlName, string Label, float PosX, float PosY, float W, float H, optional bool TitleFont)
{
	local UIText Text;
	Text = Spawn(class'UIText', Parent);
	Text.bIsNavigable = false;
	Text.InitText(ControlName, Label, TitleFont);
	Text.SetPosition(PosX, PosY);
	Text.SetSize(W, H);
	return Text;
}

simulated function WOTCTrainerButton AddButton(UIPanel Parent, name ControlName, string Label, float PosX, float PosY, float W, int Action, optional int Value)
{
	local WOTCTrainerButton Button;
	Button = Spawn(class'WOTCTrainerButton', Parent);
	Button.InitButton(ControlName, Label, OnAction);
	Button.SetPosition(PosX, PosY);
	Button.SetSize(W, 42);
	Button.ActionID = Action;
	Button.Payload = Value;
	return Button;
}

simulated function string ChangeText()
{
	return string(PendingOld) $ class'WOTCTrainerText'.default.Arrow $ string(PendingNew);
}

simulated function ShowConfirmation(string Body, bool Warning)
{
	local TDialogueBoxData Dialog;
	Dialog.strTitle = class'WOTCTrainerText'.default.Confirm;
	Dialog.strText = Warning ? Body $ "<br><br>" $ class'WOTCTrainerText'.default.SaveReminder : Body;
	Dialog.strAccept = class'WOTCTrainerText'.default.Confirm;
	Dialog.strCancel = class'WOTCTrainerText'.default.Cancel;
	Dialog.eType = Warning ? eDialog_Warning : eDialog_Normal;
	Dialog.isModal = true;
	Dialog.fnCallback = OnConfirmed;
	bModalPending = true;
	Movie.Pres.UIRaiseDialog(Dialog);
}

simulated function ShowError(name Code)
{
	ResultText.SetText(class'WOTCTrainerText'.static.ErrorText(Code));
	`log("[WOTCTrainer] Operation rejected: " $ Code, true, 'WOTCTrainer');
}

// Removes this panel from the screen stack wherever it sits in the stack, not just from the top.
simulated function ClosePanel()
{
	local UIScreenStack Stack;

	if (bModalPending)
		return;
	if (Movie == none || Movie.Stack == none)
		return;
	Stack = Movie.Stack;
	if (Stack.Screens.Find(self) == INDEX_NONE)
		return;
	HostScreen = none;
	`log("[WOTCTrainer] Trainer panel removed: " $ string(Class.Name) $ " (close)", true, 'WOTCTrainer');
	Stack.Pop(self, false);
}

simulated function bool OnUnrealCommand(int Cmd, int Arg)
{
	if (CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg) && (Cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE || Cmd == class'UIUtilities_Input'.const.FXS_BUTTON_B))
	{
		ClosePanel();
		return true;
	}
	return super.OnUnrealCommand(Cmd, Arg);
}

simulated function OnAction(UIButton Sender) {}
simulated function OnConfirmed(name Action) { bModalPending = false; }

defaultproperties
{
	Package="NONE"
	bConsumeMouseEvents=true
	bHideOnLoseFocus=false
	bAnimateOnInit=false
	bAnimateOut=false
	InputState=eInputState_Consume
}
