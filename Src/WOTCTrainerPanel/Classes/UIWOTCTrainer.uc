class UIWOTCTrainer extends UIWOTCTrainerBase;

var UIPanel ResourcePage, PersonnelPage, SoldierPage;
var WOTCTrainerButton TabButtons[8];
var UIText ResourceValues[6];
var UIText EngineerValue, ScientistValue, HealingValue;
var int ActiveTab, PendingResource;


var array<StateObjectReference> PendingHealing;

simulated function OnInit()
{
	local int I, J;
	local array<int> Steps;
	super.OnInit();
	Root = Spawn(class'UIPanel', self).InitPanel('TrainerRoot');
	Root.AnchorCenter();
	Root.SetPosition(-690, -395);
	Spawn(class'UIBGBox', Root).InitBG('TrainerBackground', 0, 0, 1380, 790);
	AddText(Root, 'Title', class'WOTCTrainerText'.default.Title, 40, 25, 1000, 45, true);
	AddText(Root, 'Notice', class'WOTCTrainerText'.default.PhaseNotice, 40, 80, 1280, 52);
	for (I = 0; I < 8; ++I)
	{
		TabButtons[I] = AddButton(Root, name("Tab" $ I), class'WOTCTrainerText'.default.Tabs[I], 40 + I * 162, 142, 148, I);
		if (I > 2 && I != 7)
			TabButtons[I].SetDisabled(true, class'WOTCTrainerText'.default.PendingPhase);
	}
	ResourcePage = Spawn(class'UIPanel', Root).InitPanel('Resources');
	ResourcePage.SetPosition(40, 220);
	AddText(ResourcePage, 'CurrentHeader', class'WOTCTrainerText'.default.CurrentValue, 230, 0, 185, 40);
	AddText(ResourcePage, 'QuickHeader', class'WOTCTrainerText'.default.QuickAdd, 450, 0, 600, 40);
	Steps.AddItem(10); Steps.AddItem(50); Steps.AddItem(100); Steps.AddItem(500); Steps.AddItem(1000);
	for (I = 0; I < 6; ++I)
	{
		AddText(ResourcePage, name("ResourceLabel" $ I), class'WOTCTrainerText'.default.Resources[I], 0, 55 + I * 63, 220, 43);
		ResourceValues[I] = AddText(ResourcePage, name("ResourceValue" $ I), "", 230, 55 + I * 63, 200, 43);
		for (J = 0; J < Steps.Length; ++J)
			AddButton(ResourcePage, name("Quick" $ I $ "_" $ J), "+" $ Steps[J], 450 + J * 116, 53 + I * 63, 102, 100 + I, Steps[J]);
		AddButton(ResourcePage, name("Set" $ I), class'WOTCTrainerText'.default.SetValue, 1060, 53 + I * 63, 200, 200 + I);
	}
	PersonnelPage = Spawn(class'UIPanel', Root).InitPanel('Personnel');
	PersonnelPage.SetPosition(40, 230);
	AddText(PersonnelPage, 'PersonnelHelp', class'WOTCTrainerText'.default.PersonnelHelp, 0, 0, 1240, 90);
	EngineerValue = AddText(PersonnelPage, 'Engineers', "", 0, 130, 650, 60);
	ScientistValue = AddText(PersonnelPage, 'Scientists', "", 0, 230, 650, 60);
	AddButton(PersonnelPage, 'AddEngineer', class'WOTCTrainerText'.default.AddEngineer, 750, 130, 430, 300);
	AddButton(PersonnelPage, 'AddScientist', class'WOTCTrainerText'.default.AddScientist, 750, 230, 430, 301);
	AddButton(PersonnelPage, 'SpawnSoldier', class'WOTCTrainerText'.default.SpawnSoldier, 750, 335, 430, 500);
	SoldierPage = Spawn(class'UIPanel', Root).InitPanel('Soldiers');
	SoldierPage.SetPosition(40, 230);
	AddText(SoldierPage, 'HealingHelp', class'WOTCTrainerText'.default.HealingHelp, 0, 0, 1240, 150);
	HealingValue = AddText(SoldierPage, 'HealingCount', "", 0, 185, 680, 60);
	AddButton(SoldierPage, 'HealAll', class'WOTCTrainerText'.default.HealAll, 750, 185, 430, 400);
	AddButton(SoldierPage, 'SoldierEditor', class'WOTCTrainerText'.default.SoldierEditor, 750, 295, 430, 501);
	ResultText = AddText(Root, 'Result', class'WOTCTrainerText'.default.SaveReminder, 40, 680, 1060, 85);
	AddButton(Root, 'Close', class'WOTCTrainerText'.default.Close, 1150, 712, 190, 900);
	SelectTab(0);
	`log("[WOTCTrainer] Panel initialized", true, 'WOTCTrainer');
}





simulated function SelectTab(int Index)
{
	local int I;
	if (Index < 0 || Index > 2)
		return;
	ActiveTab = Index;
	ResourcePage.Hide(); PersonnelPage.Hide(); SoldierPage.Hide();
	if (Index == 0) ResourcePage.Show();
	if (Index == 1) PersonnelPage.Show();
	if (Index == 2) SoldierPage.Show();
	for (I = 0; I < 8; ++I)
		TabButtons[I].SetSelected(I == Index);
	RefreshValues();
}

simulated function RefreshValues()
{
	local XComGameState_HeadquartersXCom HQ;
	local array<StateObjectReference> Projects;
	local int I;
	if (ResourcePage == none)
		return;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none)
	{
		ResultText.SetText(class'WOTCTrainerText'.default.Unavailable);
		return;
	}
	for (I = 0; I < 6; ++I)
		ResourceValues[I].SetText(string(HQ.GetResourceAmount(class'WOTCTrainerStrategy'.static.ResourceName(I))));
	EngineerValue.SetText(class'WOTCTrainerText'.default.Engineers $ ": " $ HQ.GetNumberOfEngineers());
	ScientistValue.SetText(class'WOTCTrainerText'.default.Scientists $ ": " $ HQ.GetNumberOfScientists());
	Projects = class'WOTCTrainerStrategy'.static.HealingProjects();
	HealingValue.SetText(class'WOTCTrainerText'.default.HealingCount $ ": " $ Projects.Length);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	RefreshValues();
}

simulated function OnAction(UIButton Sender)
{
	local WOTCTrainerButton Button;
	local XComGameState_HeadquartersXCom HQ;
	local TInputDialogData Input;
	local string Label;
	if (bModalPending)
		return;
	Button = WOTCTrainerButton(Sender);
	if (Button == none)
		return;
	if (Button.ActionID == 900) { ClosePanel(); return; }
	if (Button.ActionID == 7 || Button.ActionID == 500) { Movie.Stack.Push(Spawn(class'UIWOTCTrainerDanger', Movie.Pres)); return; }
	if (Button.ActionID == 501) { Movie.Stack.Push(Spawn(class'UIWOTCTrainerSoldiers', Movie.Pres)); return; }
	if (Button.ActionID < 8) { SelectTab(Button.ActionID); return; }
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) { ShowError('Unavailable'); return; }
	if (Button.ActionID >= 100 && Button.ActionID < 106)
	{
		PendingResource = Button.ActionID - 100;
		PendingOld = HQ.GetResourceAmount(class'WOTCTrainerStrategy'.static.ResourceName(PendingResource));
		if (PendingOld < 0 || PendingOld > 2147483647 - Button.Payload) { ShowError('InvalidNumber'); return; }
		PendingNew = PendingOld + Button.Payload;
		ConfirmResource();
	}
	else if (Button.ActionID >= 200 && Button.ActionID < 206)
	{
		PendingResource = Button.ActionID - 200;
		PendingOld = HQ.GetResourceAmount(class'WOTCTrainerStrategy'.static.ResourceName(PendingResource));
		Input.strTitle = class'WOTCTrainerText'.default.Resources[PendingResource] @ class'WOTCTrainerText'.default.InputTitle;
		Input.strInputBoxText = string(PendingOld);
		Input.iMaxChars = 10;
		Input.fnCallbackAccepted = OnInputAccepted;
		Input.fnCallbackCancelled = OnInputCancelled;
		bModalPending = true;
		Movie.Pres.UIInputDialog(Input);
	}
	else if (Button.ActionID == 300 || Button.ActionID == 301)
	{
		PendingKind = Button.ActionID == 300 ? 'Engineer' : 'Scientist';
		PendingOld = class'WOTCTrainerStrategy'.static.StaffCount(PendingKind == 'Engineer');
		if (PendingOld < 0 || PendingOld == 2147483647) { ShowError('Unavailable'); return; }
		PendingNew = PendingOld + 1;
		Label = PendingKind == 'Engineer' ? class'WOTCTrainerText'.default.Engineers : class'WOTCTrainerText'.default.Scientists;
		ShowConfirmation(Label $ ": " $ ChangeText(), false);
	}
	else if (Button.ActionID == 400)
	{
		PendingHealing = class'WOTCTrainerStrategy'.static.HealingProjects();
		if (PendingHealing.Length == 0) { ResultText.SetText(class'WOTCTrainerText'.default.NothingToHeal); return; }
		PendingKind = 'Heal';
		PendingOld = PendingHealing.Length;
		PendingNew = 0;
		ShowConfirmation(class'WOTCTrainerText'.default.HealingCount $ ": " $ ChangeText() $ "<br><br>" $ class'WOTCTrainerText'.default.HealingHelp, true);
	}
}



simulated function OnInputAccepted(string InputText)
{
	bModalPending = false;
	if (!class'WOTCTrainerStrategy'.static.ParseAmount(InputText, PendingNew)) { ShowError('InvalidNumber'); return; }
	ConfirmResource();
}

simulated function OnInputCancelled(string InputText)
{
	bModalPending = false;
	PendingKind = '';
}

simulated function ConfirmResource()
{
	PendingKind = 'Resource';
	ShowConfirmation(class'WOTCTrainerText'.default.Resources[PendingResource] $ ": " $ ChangeText(), false);
}



simulated function OnConfirmed(name Action)
{
	local bool Success;
	local name ErrorCode;
	local string AddedName, Label;
	local int Healed;
	bModalPending = false;
	if (Action != 'eUIAction_Accept') { PendingKind = ''; return; }
	if (PendingKind == 'Resource')
	{
		Success = class'WOTCTrainerStrategy'.static.SetResource(PendingResource, PendingOld, PendingNew, ErrorCode);
		Label = class'WOTCTrainerText'.default.Resources[PendingResource] $ ": " $ ChangeText();
	}
	else if (PendingKind == 'Engineer' || PendingKind == 'Scientist')
	{
		Success = class'WOTCTrainerStrategy'.static.AddStaff(PendingKind == 'Engineer', PendingOld, AddedName, ErrorCode);
		Label = (PendingKind == 'Engineer' ? class'WOTCTrainerText'.default.Engineers : class'WOTCTrainerText'.default.Scientists) $ ": " $ ChangeText();
		Label $= " | " $ class'WOTCTrainerText'.default.Added @ AddedName;
	}
	else if (PendingKind == 'Heal')
	{
		Success = class'WOTCTrainerStrategy'.static.HealAll(PendingHealing, Healed, ErrorCode);
		Label = class'WOTCTrainerText'.default.HealingCount $ ": " $ ChangeText();
	}
	else { ErrorCode = 'Unavailable'; }
	if (Success)
		ResultText.SetText(class'WOTCTrainerText'.default.Applied @ Label);
	else
	{
		ShowError(ErrorCode);
		if (PendingKind == 'Heal')
			ResultText.SetText(class'WOTCTrainerText'.static.ErrorText(ErrorCode) @ class'WOTCTrainerText'.default.CompletedCount @ string(Healed));
	}
	PendingKind = '';
	PendingHealing.Length = 0;
	RefreshValues();
}







