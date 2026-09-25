class UIWOTCTrainerBase extends UIScreen;

var UIPanel Root;
var UIText ResultText;
var bool bModalPending;
var int PendingOld, PendingNew;
var name PendingKind;

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

simulated function ClosePanel()
{
	if (!bModalPending)
		Movie.Stack.Pop(self);
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