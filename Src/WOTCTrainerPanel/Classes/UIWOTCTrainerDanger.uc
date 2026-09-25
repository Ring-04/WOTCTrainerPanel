class UIWOTCTrainerDanger extends UIWOTCTrainerBase;

var int SpawnClass, SpawnRank, SpawnCount, SelectedID, TargetRank, RookieClass;
var int PendingClass, PendingRank, PendingCount, PendingID;
var WOTCTrainerButton ClassButton, RankButton, CountButton, TargetButton, RookieClassButton;
var UIText SelectedText;
var string PendingLabel;

simulated function OnInit()
{
	super.OnInit();
	SpawnCount = 1; RookieClass = 1;
	Root = Spawn(class'UIPanel', self).InitPanel('DangerRoot');
	Root.AnchorCenter(); Root.SetPosition(-690, -395);
	Spawn(class'UIBGBox', Root).InitBG('Background', 0, 0, 1380, 790);
	AddText(Root, 'Title', class'WOTCTrainerText'.default.Tabs[7], 40, 25, 1000, 50, true);
	AddText(Root, 'Warning', class'WOTCTrainerText'.default.SaveReminder, 40, 90, 1280, 55);
	AddText(Root, 'SpawnHelp', class'WOTCTrainerText'.default.SpawnHelp, 40, 150, 1260, 110);
	ClassButton = AddButton(Root, 'Class', "", 40, 275, 320, 10);
	RankButton = AddButton(Root, 'Rank', "", 385, 275, 295, 11);
	CountButton = AddButton(Root, 'Count', "", 705, 275, 295, 12);
	AddButton(Root, 'Spawn', class'WOTCTrainerText'.default.SpawnSoldier, 1025, 275, 300, 20);
	SelectedText = AddText(Root, 'Selected', "", 40, 365, 1250, 75);
	RookieClassButton = AddButton(Root, 'RookieClass', "", 40, 455, 430, 13);
	TargetButton = AddButton(Root, 'TargetRank', "", 495, 455, 330, 14);
	AddButton(Root, 'Promote', class'WOTCTrainerText'.default.Promote, 850, 455, 210, 21);
	AddButton(Root, 'Demote', class'WOTCTrainerText'.default.Demote, 1085, 455, 240, 22).SetDisabled(true, class'WOTCTrainerText'.default.UnsafeDemote);
	AddText(Root, 'DisabledHelp', class'WOTCTrainerText'.default.UnsafeDemote, 40, 525, 1280, 90);
	AddButton(Root, 'Revive', class'WOTCTrainerText'.default.Revive, 40, 620, 365, 23).SetDisabled(true, class'WOTCTrainerText'.default.Unsafe);
	AddText(Root, 'ReviveHelp', class'WOTCTrainerText'.default.Unsafe, 430, 620, 800, 50);
	ResultText = AddText(Root, 'Result', "", 40, 690, 1060, 80);
	AddButton(Root, 'Close', class'WOTCTrainerText'.default.Close, 1150, 712, 190, 900);
	RefreshOptions();
}

simulated function RefreshOptions()
{
	local XComGameState_Unit Unit;
	ClassButton.SetText(class'WOTCTrainerText'.default.ClassLabel $ ": " $ class'WOTCTrainerSoldiers'.static.ClassLabel(SpawnClass));
	RankButton.SetText(class'WOTCTrainerText'.default.RankLabel $ ": " $ class'X2ExperienceConfig'.static.GetRankName(SpawnRank, class'WOTCTrainerSoldiers'.static.ClassName(SpawnClass)));
	CountButton.SetText(class'WOTCTrainerText'.default.CountLabel $ ": " $ SpawnCount);
	RookieClassButton.SetText(class'WOTCTrainerText'.default.RookieClass @ class'WOTCTrainerSoldiers'.static.ClassLabel(RookieClass));
	Unit = class'WOTCTrainerSoldiers'.static.EditableUnit(SelectedID);
	if (Unit != none)
	{
		TargetRank = Clamp(TargetRank, Min(7, Unit.GetSoldierRank() + 1), 7);
		SelectedText.SetText(class'WOTCTrainerText'.static.Escape(Unit.GetName(eNameType_Full)) @ "|" @ Unit.GetSoldierClassTemplate().DisplayName @ "|" @ class'X2ExperienceConfig'.static.GetRankName(Unit.GetSoldierRank(), Unit.GetSoldierClassTemplateName()));
		TargetButton.SetText(class'WOTCTrainerText'.default.RankLabel @ class'X2ExperienceConfig'.static.GetRankName(TargetRank, Unit.GetSoldierClassTemplateName()));
		RookieClassButton.SetDisabled(Unit.GetSoldierRank() != 0, class'WOTCTrainerText'.default.UnsafeDemote);
	}
	else
	{
		SelectedText.SetText(class'WOTCTrainerText'.default.SelectSoldierFirst);
		TargetButton.SetText("-");
	}
}

simulated function OnAction(UIButton Sender)
{
	local WOTCTrainerButton Button;
	local TInputDialogData Input;
	local XComGameState_Unit Unit;
	local array<StateObjectReference> Units;
	if (bModalPending) return;
	Button = WOTCTrainerButton(Sender);
	if (Button == none) return;
	if (Button.ActionID == 900) { ClosePanel(); return; }
	if (Button.ActionID == 10) { SpawnClass = (SpawnClass + 1) % 8; SpawnRank = SpawnClass == 0 ? 0 : Max(1, SpawnRank); }
	else if (Button.ActionID == 11) { if (SpawnClass != 0) SpawnRank = SpawnRank % 7 + 1; }
	else if (Button.ActionID == 13) RookieClass = RookieClass % 4 + 1;
	else if (Button.ActionID == 14) TargetRank = TargetRank % 7 + 1;
	else if (Button.ActionID == 12)
	{
		Input.strTitle = class'WOTCTrainerText'.default.CountInput;
		Input.strInputBoxText = string(SpawnCount); Input.iMaxChars = 2;
		Input.fnCallbackAccepted = OnCountAccepted; Input.fnCallbackCancelled = OnCountCancelled;
		bModalPending = true; Movie.Pres.UIInputDialog(Input);
	}
	else if (Button.ActionID == 20)
	{
		Units = class'WOTCTrainerSoldiers'.static.Roster();
		PendingKind = 'Spawn'; PendingClass = SpawnClass; PendingRank = SpawnRank; PendingCount = SpawnCount;
		PendingOld = Units.Length; PendingNew = PendingOld + SpawnCount;
		PendingLabel = class'WOTCTrainerText'.default.Barracks @ ChangeText() $ "<br>" $ class'WOTCTrainerSoldiers'.static.ClassLabel(SpawnClass) @ "x" @ SpawnCount @ "|" @ class'X2ExperienceConfig'.static.GetRankName(SpawnRank, class'WOTCTrainerSoldiers'.static.ClassName(SpawnClass));
		ShowConfirmation(PendingLabel, true);
	}
	else if (Button.ActionID == 21)
	{
		Unit = class'WOTCTrainerSoldiers'.static.EditableUnit(SelectedID);
		if (Unit == none) { ShowError('UnitUnavailable'); return; }
		PendingKind = 'Promote'; PendingID = SelectedID; PendingClass = RookieClass;
		PendingOld = Unit.GetSoldierRank(); PendingNew = TargetRank;
		PendingLabel = class'WOTCTrainerText'.static.Escape(Unit.GetName(eNameType_Full)) @ class'WOTCTrainerText'.default.RankLabel @ ChangeText();
		if (PendingOld == 0) PendingLabel $= "<br>" $ class'WOTCTrainerText'.default.ClassLabel @ Unit.GetSoldierClassTemplate().DisplayName $ class'WOTCTrainerText'.default.Arrow $ class'WOTCTrainerSoldiers'.static.ClassLabel(RookieClass);
		ShowConfirmation(PendingLabel, true);
	}
	RefreshOptions();
}

simulated function OnCountAccepted(string InputText)
{
	local int Count;
	bModalPending = false;
	if (!class'WOTCTrainerStrategy'.static.ParseAmount(InputText, Count) || Count < 1 || Count > 20) { ShowError('Bounds'); return; }
	SpawnCount = Count; RefreshOptions();
}

simulated function OnCountCancelled(string InputText) { bModalPending = false; }

simulated function OnConfirmed(name Action)
{
	local array<StateObjectReference> Added;
	local name ErrorCode;
	local bool Success;
	bModalPending = false;
	if (Action != 'eUIAction_Accept') { PendingKind = ''; return; }
	if (PendingKind == 'Spawn') Success = class'WOTCTrainerSoldiers'.static.SpawnSoldiers(PendingClass, PendingRank, PendingCount, PendingOld, Added, ErrorCode);
	else if (PendingKind == 'Promote') Success = class'WOTCTrainerSoldiers'.static.Promote(PendingID, PendingOld, PendingNew, PendingClass, ErrorCode);
	if (Success) ResultText.SetText(class'WOTCTrainerText'.default.Applied @ PendingLabel);
	else ShowError(ErrorCode);
	PendingKind = ''; RefreshOptions();
}
