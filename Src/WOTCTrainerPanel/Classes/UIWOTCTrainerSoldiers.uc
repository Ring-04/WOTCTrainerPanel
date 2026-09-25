class UIWOTCTrainerSoldiers extends UIWOTCTrainerBase;

var array<StateObjectReference> Units;
var WOTCTrainerButton Rows[8];
var UIText Details, PageText, Values[9];
var int PageIndex, SelectedID, PendingID, PendingField;
var string PendingLabel;

simulated function OnInit()
{
	local int I, J;
	local array<int> Steps;
	super.OnInit();
	Root = Spawn(class'UIPanel', self).InitPanel('SoldierRoot');
	Root.AnchorCenter(); Root.SetPosition(-690, -395);
	Spawn(class'UIBGBox', Root).InitBG('Background', 0, 0, 1380, 790);
	AddText(Root, 'Title', class'WOTCTrainerText'.default.SoldierEditor, 30, 20, 1000, 50, true);
	AddButton(Root, 'Refresh', class'WOTCTrainerText'.default.Refresh, 1060, 20, 125, 801);
	AddButton(Root, 'Close', class'WOTCTrainerText'.default.Close, 1200, 20, 145, 900);
	PageText = AddText(Root, 'Page', "", 30, 85, 300, 40);
	for (I = 0; I < 8; ++I) Rows[I] = AddButton(Root, name("Soldier" $ I), "", 30, 135 + I * 57, 295, I);
	AddButton(Root, 'Previous', "<", 30, 600, 130, 802);
	AddButton(Root, 'Next', ">", 185, 600, 140, 803);
	Details = AddText(Root, 'Details', "", 350, 80, 990, 116);
	Steps.AddItem(1); Steps.AddItem(5); Steps.AddItem(10); Steps.AddItem(-1); Steps.AddItem(-5); Steps.AddItem(-10);
	for (I = 0; I < 9; ++I)
	{
		AddText(Root, name("Label" $ I), class'WOTCTrainerText'.default.SoldierFields[I], 350, 206 + I * 45, 110, 40);
		Values[I] = AddText(Root, name("Value" $ I), "", 470, 206 + I * 45, 115, 40);
		for (J = 0; J < 6; ++J)
			AddButton(Root, name("Step" $ I $ "_" $ J), (Steps[J] > 0 ? "+" : "") $ Steps[J], 595 + J * 87, 201 + I * 45, 77, 100 + I, Steps[J]);
		if (I < 7) AddButton(Root, name("Default" $ I), class'WOTCTrainerText'.default.RestoreDefault, 1125, 201 + I * 45, 215, 200 + I);
		else AddButton(Root, name("Custom" $ I), class'WOTCTrainerText'.default.SetValue, 1125, 201 + I * 45, 215, 300 + I);
	}
	AddButton(Root, 'Heal', class'WOTCTrainerText'.default.FullHeal, 350, 620, 230, 400);
	AddButton(Root, 'Will', class'WOTCTrainerText'.default.RestoreWill, 595, 620, 255, 401);
	AddButton(Root, 'Traits', class'WOTCTrainerText'.default.RemoveTraits, 865, 620, 225, 402);
	AddButton(Root, 'Rank', class'WOTCTrainerText'.default.RankAndClass, 1105, 620, 235, 403);
	ResultText = AddText(Root, 'Result', class'WOTCTrainerText'.default.SoldierHelp, 30, 690, 1310, 82);
	RefreshRoster();
}

simulated function RefreshRoster()
{
	local int I, Index;
	local XComGameState_Unit Unit;
	Units = class'WOTCTrainerSoldiers'.static.Roster();
	PageIndex = Clamp(PageIndex, 0, Max(0, (Units.Length - 1) / 8));
	PageText.SetText(class'WOTCTrainerText'.default.Barracks @ Units.Length @ "|" @ (PageIndex + 1) $ "/" $ Max(1, (Units.Length + 7) / 8));
	if (Units.Find('ObjectID', SelectedID) == INDEX_NONE) SelectedID = Units.Length > 0 ? Units[0].ObjectID : 0;
	for (I = 0; I < 8; ++I)
	{
		Index = PageIndex * 8 + I;
		Rows[I].SetDisabled(Index >= Units.Length);
		if (Index < Units.Length)
		{
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Units[Index].ObjectID));
			Rows[I].SetText(class'WOTCTrainerText'.static.Escape(Unit.GetName(eNameType_Full)));
			Rows[I].SetSelected(Unit.ObjectID == SelectedID);
		}
		else Rows[I].SetText("-");
	}
	RefreshDetails();
}

simulated function RefreshDetails()
{
	local XComGameState_Unit Unit;
	local string Country, Label;
	local int I;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(SelectedID));
	if (Unit == none)
	{
		Details.SetText(class'WOTCTrainerText'.default.UnitUnavailable);
		for (I = 0; I < 9; ++I) Values[I].SetText("-");
		return;
	}
	Country = string(Unit.GetCountry());
	if (Unit.GetCountryTemplate() != none) Country = Unit.GetCountryTemplate().DisplayName;
	Label = class'WOTCTrainerText'.static.Escape(Unit.GetName(eNameType_Full)) @ class'WOTCTrainerText'.static.Escape(Unit.GetNickName()) @ "|" @ Country;
	Label $= "<br>" $ Unit.GetSoldierClassTemplate().DisplayName @ "|" @ class'X2ExperienceConfig'.static.GetRankName(Unit.GetSoldierRank(), Unit.GetSoldierClassTemplateName());
	Label $= " | " $ Unit.GetMentalStateLabel() $ " | ID " $ Unit.ObjectID;
	if (class'WOTCTrainerSoldiers'.static.EditableUnit(SelectedID) == none) Label $= "<br>" $ class'WOTCTrainerText'.default.UnitUnavailable;
	Details.SetText(Label);
	for (I = 0; I < 9; ++I) Values[I].SetText(string(class'WOTCTrainerSoldiers'.static.Value(Unit, I)));
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (Root != none) RefreshRoster();
}

simulated function OnAction(UIButton Sender)
{
	local WOTCTrainerButton Button;
	local XComGameState_Unit Unit;
	local TInputDialogData Input;
	local UIWOTCTrainerDanger Danger;
	if (bModalPending) return;
	Button = WOTCTrainerButton(Sender);
	if (Button == none) return;
	if (Button.ActionID == 900) { ClosePanel(); return; }
	if (Button.ActionID == 801) { RefreshRoster(); return; }
	if (Button.ActionID == 802 || Button.ActionID == 803) { PageIndex += Button.ActionID == 802 ? -1 : 1; RefreshRoster(); return; }
	if (Button.ActionID >= 0 && Button.ActionID < 8)
	{
		if (PageIndex * 8 + Button.ActionID < Units.Length) SelectedID = Units[PageIndex * 8 + Button.ActionID].ObjectID;
		RefreshRoster(); return;
	}
	Unit = class'WOTCTrainerSoldiers'.static.EditableUnit(SelectedID);
	if (Unit == none) { ShowError('UnitUnavailable'); return; }
	if (Button.ActionID == 403)
	{
		Danger = UIWOTCTrainerDanger(OpenPage(class'UIWOTCTrainerDanger'));
		if (Danger != none) Danger.SelectedID = SelectedID;
		return;
	}
	PendingID = SelectedID;
	PendingKind = 'Value';
	if (Button.ActionID >= 100 && Button.ActionID < 109)
	{
		PendingField = Button.ActionID - 100;
		PendingOld = class'WOTCTrainerSoldiers'.static.Value(Unit, PendingField);
		if (PendingOld < 0 || PendingOld > 100000) { ShowError('Bounds'); return; }
		PendingNew = PendingOld + Button.Payload;
		PendingLabel = class'WOTCTrainerText'.default.SoldierFields[PendingField];
	}
	else if (Button.ActionID >= 200 && Button.ActionID < 207)
	{
		PendingField = Button.ActionID - 200;
		PendingOld = class'WOTCTrainerSoldiers'.static.Value(Unit, PendingField);
		PendingNew = int(Unit.GetMyTemplate().GetCharacterBaseStat(class'WOTCTrainerSoldiers'.static.StatType(PendingField)));
		PendingLabel = class'WOTCTrainerText'.default.SoldierFields[PendingField] @ class'WOTCTrainerText'.default.TemplateDefault;
	}
	else if (Button.ActionID == 307 || Button.ActionID == 308)
	{
		PendingField = Button.ActionID - 300;
		PendingOld = class'WOTCTrainerSoldiers'.static.Value(Unit, PendingField);
		PendingLabel = class'WOTCTrainerText'.default.SoldierFields[PendingField];
		Input.strTitle = PendingLabel @ class'WOTCTrainerText'.default.SetValue;
		Input.strInputBoxText = string(PendingOld); Input.iMaxChars = 6;
		Input.fnCallbackAccepted = OnInputAccepted; Input.fnCallbackCancelled = OnInputCancelled;
		bModalPending = true; Movie.Pres.UIInputDialog(Input); return;
	}
	else if (Button.ActionID == 400)
	{
		PendingKind = 'Heal'; PendingOld = int(Unit.GetCurrentStat(eStat_HP)); PendingNew = int(Unit.GetBaseStat(eStat_HP));
		PendingLabel = class'WOTCTrainerText'.default.FullHeal;
	}
	else if (Button.ActionID == 401)
	{
		PendingKind = 'Will'; PendingOld = int(Unit.GetCurrentStat(eStat_Will)); PendingNew = int(Unit.GetMaxStat(eStat_Will));
		PendingLabel = class'WOTCTrainerText'.default.RestoreWill;
	}
	else if (Button.ActionID == 402)
	{
		PendingKind = 'Traits'; PendingOld = Unit.GetNumTraits(); PendingNew = 0;
		PendingLabel = class'WOTCTrainerText'.default.RemoveTraits;
	}
	else return;
	ConfirmEdit();
}

simulated function ConfirmEdit()
{
	ShowConfirmation(PendingLabel $ ": " $ ChangeText(), true);
}

simulated function OnInputAccepted(string InputText)
{
	bModalPending = false;
	if (!class'WOTCTrainerStrategy'.static.ParseAmount(InputText, PendingNew)) { ShowError('Bounds'); return; }
	ConfirmEdit();
}

simulated function OnInputCancelled(string InputText) { bModalPending = false; PendingKind = ''; }

simulated function OnConfirmed(name Action)
{
	local bool Success;
	local name ErrorCode;
	bModalPending = false;
	if (Action != 'eUIAction_Accept') { PendingKind = ''; return; }
	switch (PendingKind)
	{
	case 'Value': Success = class'WOTCTrainerSoldiers'.static.SetValue(PendingID, PendingField, PendingOld, PendingNew, ErrorCode); break;
	case 'Heal': Success = class'WOTCTrainerSoldiers'.static.Heal(PendingID, PendingOld, ErrorCode); break;
	case 'Will': Success = class'WOTCTrainerSoldiers'.static.RestoreWill(PendingID, PendingOld, ErrorCode); break;
	case 'Traits': Success = class'WOTCTrainerSoldiers'.static.RemoveTraits(PendingID, PendingOld, ErrorCode); break;
	}
	if (Success) ResultText.SetText(class'WOTCTrainerText'.default.Applied @ PendingLabel $ ": " $ ChangeText());
	else ShowError(ErrorCode);
	PendingKind = ''; RefreshRoster();
}
