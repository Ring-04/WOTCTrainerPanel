class UIWOTCTrainerTactical extends UIWOTCTrainerBase;

var WOTCTrainerButton Toggles[12];
var UIText SelectedText;
var int SelectedID, PendingID, PendingIndex;
var bool PendingEnabled;
var string PendingLabel;

simulated function OnInit()
{
	local int I;
	super.OnInit();
	Root = Spawn(class'UIPanel', self).InitPanel('TacticalRoot');
	Root.AnchorCenter(); Root.SetPosition(-690, -395);
	Spawn(class'UIBGBox', Root).InitBG('Background', 0, 0, 1380, 790);
	AddText(Root, 'Title', class'WOTCTrainerText'.default.Title @ "|" @ class'WOTCTrainerText'.default.Tabs[5], 40, 25, 1000, 50, true);
	for (I = 0; I < 8; ++I)
		AddButton(Root, name("Tab" $ I), class'WOTCTrainerText'.default.Tabs[I], 40 + I * 162, 100, 148, 800 + I).SetDisabled(I < 5, class'WOTCTrainerText'.default.PendingPhase);
	for (I = 0; I < 12; ++I)
		Toggles[I] = AddButton(Root, name("Toggle" $ I), "", 40 + (I / 6) * 650, 167 + (I % 6) * 49, 625, I);
	SelectedText = AddText(Root, 'Selected', "", 40, 470, 1280, 50);
	AddText(Root, 'Help', class'WOTCTrainerText'.default.TacticalHelp, 40, 514, 1280, 75);
	for (I = 0; I < 5; ++I)
		AddButton(Root, name("Action" $ I), class'WOTCTrainerText'.default.TacticalActions[I], 40 + I * 260, 602, 245, 100 + I);
	AddButton(Root, 'Teleport', class'WOTCTrainerText'.default.Teleport, 40, 651, 245, 110).SetDisabled(true, class'WOTCTrainerText'.default.Unsafe);
	AddButton(Root, 'Revive', class'WOTCTrainerText'.default.Revive, 300, 651, 385, 111).SetDisabled(true, class'WOTCTrainerText'.default.Unsafe);
	ResultText = AddText(Root, 'Result', class'WOTCTrainerText'.default.SaveReminder, 40, 712, 1080, 70);
	AddButton(Root, 'Close', class'WOTCTrainerText'.default.Close, 1150, 712, 190, 900);
	RefreshValues();
}

simulated function RefreshValues()
{
	local XComGameState_Unit Unit;
	local XComTacticalController Controller;
	local int I;
	Controller = XComTacticalController(PC);
	if (Controller != none) SelectedID = Controller.GetActiveUnitStateRef().ObjectID;
	Unit = class'WOTCTrainerTactical'.static.UnitByID(SelectedID);
	if (Unit == none) SelectedText.SetText(class'WOTCTrainerText'.default.TacticalUnavailable);
	else SelectedText.SetText(class'WOTCTrainerText'.default.SelectedUnit @ class'WOTCTrainerText'.static.Escape(Unit.GetName(eNameType_Full)) @ "| HP" @ int(Unit.GetCurrentStat(eStat_HP)) $ "/" $ int(Unit.GetMaxStat(eStat_HP)) @ "|" @ class'WOTCTrainerText'.default.ActionPoints @ Unit.ActionPoints.Length);
	for (I = 0; I < 12; ++I)
	{
		Toggles[I].SetText(class'WOTCTrainerText'.default.TacticalToggles[I] $ ": " $ class'WOTCTrainerText'.static.ToggleText(class'XComGameState_WOTCTrainer'.static.Enabled(I, SelectedID)));
		Toggles[I].SetSelected(class'XComGameState_WOTCTrainer'.static.Enabled(I, SelectedID));
	}
}

simulated function OnReceiveFocus() { super.OnReceiveFocus(); if (Root != none) RefreshValues(); }

simulated function OnAction(UIButton Sender)
{
	local WOTCTrainerButton Button;
	local XComGameState_Unit Unit;
	if (bModalPending) return;
	Button = WOTCTrainerButton(Sender);
	if (Button == none) return;
	if (Button.ActionID == 900) { ClosePanel(); return; }
	if (Button.ActionID == 806) { OpenPage(class'UIWOTCTrainerMission'); return; }
	if (Button.ActionID == 807) { OpenPage(class'UIWOTCTrainerMissionDanger'); return; }
	if (!class'WOTCTrainerTactical'.static.CanEdit()) { ShowError('TacticalUnavailable'); return; }
	RefreshValues(); PendingID = SelectedID;
	if (Button.ActionID >= 0 && Button.ActionID < 12)
	{
		PendingKind = 'Toggle'; PendingIndex = Button.ActionID;
		PendingEnabled = class'XComGameState_WOTCTrainer'.static.Enabled(PendingIndex, PendingID);
		PendingLabel = class'WOTCTrainerText'.default.TacticalToggles[PendingIndex] $ ": " $ class'WOTCTrainerText'.static.ToggleText(PendingEnabled) $ class'WOTCTrainerText'.default.Arrow $ class'WOTCTrainerText'.static.ToggleText(!PendingEnabled);
		ShowConfirmation(PendingLabel, PendingIndex == 11);
	}
	else if (Button.ActionID >= 100 && Button.ActionID < 105)
	{
		Unit = class'WOTCTrainerTactical'.static.UnitByID(PendingID);
		if (Unit == none) { ShowError('TacticalUnavailable'); return; }
		PendingKind = 'Action'; PendingIndex = Button.ActionID - 100;
		PendingOld = class'WOTCTrainerTactical'.static.ActionValue(Unit, PendingIndex);
		PendingNew = class'WOTCTrainerTactical'.static.ActionTarget(Unit, PendingIndex);
		PendingLabel = class'WOTCTrainerText'.default.TacticalActions[PendingIndex] $ ": " $ ChangeText();
		ShowConfirmation(PendingLabel, false);
	}
}

simulated function OnConfirmed(name Action)
{
	local bool Success;
	local name ErrorCode;
	bModalPending = false;
	if (Action != 'eUIAction_Accept') { PendingKind = ''; return; }
	if (PendingKind == 'Toggle') Success = class'WOTCTrainerTactical'.static.SetToggle(PendingIndex, PendingID, PendingEnabled, !PendingEnabled, ErrorCode);
	else if (PendingKind == 'Action') Success = class'WOTCTrainerTactical'.static.DoAction(PendingID, PendingIndex, PendingOld, ErrorCode);
	if (Success) ResultText.SetText(class'WOTCTrainerText'.default.Applied @ PendingLabel);
	else ShowError(ErrorCode);
	PendingKind = ''; RefreshValues();
}
