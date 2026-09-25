class UIWOTCTrainerCampaign extends UIWOTCTrainerBase;

var UIText AvatarInfo, PowerInfo, ContactInfo, QueueInfo, SquadInfo;
var WOTCTrainerButton AvatarButtons[4];

simulated function OnInit()
{
	local int I;
	super.OnInit();
	Root = Spawn(class'UIPanel', self).InitPanel('CampaignRoot');
	Root.AnchorCenter(); Root.SetPosition(-690, -395);
	Spawn(class'UIBGBox', Root).InitBG('Background', 0, 0, 1380, 790);
	AddText(Root, 'Title', class'WOTCTrainerText'.default.CampaignTitle, 30, 20, 700, 50, true);
	AddButton(Root, 'Refresh', class'WOTCTrainerText'.default.Refresh, 1060, 20, 125, 801);
	AddButton(Root, 'Close', class'WOTCTrainerText'.default.Close, 1200, 20, 145, 900);
	AddText(Root, 'AvatarHeader', class'WOTCTrainerText'.default.CampaignHeaderAvatar, 30, 85, 660, 40, true);
	AvatarInfo = AddText(Root, 'AvatarInfo', "", 30, 125, 660, 150);
	AvatarButtons[0] = AddButton(Root, 'AvatarMinus1', class'WOTCTrainerText'.default.CampaignMinus1, 30, 285, 150, 200, 1);
	AvatarButtons[1] = AddButton(Root, 'AvatarMinus2', class'WOTCTrainerText'.default.CampaignMinus2, 190, 285, 150, 200, 2);
	AvatarButtons[2] = AddButton(Root, 'AvatarMinus5', class'WOTCTrainerText'.default.CampaignMinus5, 350, 285, 150, 200, 5);
	AvatarButtons[3] = AddButton(Root, 'AvatarClear', class'WOTCTrainerText'.default.CampaignClear, 510, 285, 150, 210);
	AddText(Root, 'AvatarHelp', class'WOTCTrainerText'.default.CampaignAvatarHelp, 30, 335, 660, 80);
	AddText(Root, 'AbilityHeader', class'WOTCTrainerText'.default.CampaignHeaderAbility, 30, 425, 660, 40, true);
	PowerInfo = AddText(Root, 'PowerInfo', "", 30, 465, 660, 40);
	AddButton(Root, 'Power10', "+10", 30, 510, 150, 300, 10);
	AddButton(Root, 'Power50', "+50", 190, 510, 150, 300, 50);
	AddButton(Root, 'Power100', "+100", 350, 510, 150, 300, 100);
	ContactInfo = AddText(Root, 'ContactInfo', "", 30, 560, 660, 40);
	AddButton(Root, 'Contact1', "+1", 30, 605, 150, 310, 1);
	AddButton(Root, 'Contact2', "+2", 190, 605, 150, 310, 2);
	AddButton(Root, 'Contact5', "+5", 350, 605, 150, 310, 5);
	for (I = 0; I < 4; ++I) AvatarButtons[I].SetDisabled(true);
	AddText(Root, 'QueueHeader', class'WOTCTrainerText'.default.CampaignHeaderQueue, 720, 85, 630, 40, true);
	QueueInfo = AddText(Root, 'QueueInfo', "", 720, 125, 630, 150);
	AddButton(Root, 'ResearchNow', class'WOTCTrainerText'.default.CampaignResearchNow, 720, 285, 300, 400);
	AddButton(Root, 'ProvingNow', class'WOTCTrainerText'.default.CampaignProvingNow, 1030, 285, 320, 401);
	AddButton(Root, 'FacilityNow', class'WOTCTrainerText'.default.CampaignFacilityNow, 720, 331, 300, 402);
	AddButton(Root, 'RefundNow', class'WOTCTrainerText'.default.CampaignRefundNow, 1030, 331, 320, 404);
	AddButton(Root, 'CovertNow', class'WOTCTrainerText'.default.CampaignCovertNow, 720, 377, 630, 403);
	AddText(Root, 'QueueHelp', class'WOTCTrainerText'.default.CampaignQueueHelp $ "<br>" $ class'WOTCTrainerText'.default.CampaignNoProvingGround, 720, 425, 630, 125);
	AddText(Root, 'SquadHeader', class'WOTCTrainerText'.default.CampaignHeaderSquad, 720, 555, 630, 40, true);
	SquadInfo = AddText(Root, 'SquadInfo', "", 720, 595, 630, 50);
	AddButton(Root, 'HealAll', class'WOTCTrainerText'.default.CampaignHealAll, 720, 652, 300, 500);
	AddButton(Root, 'WillAll', class'WOTCTrainerText'.default.CampaignWillAll, 1030, 652, 320, 501);
	ResultText = AddText(Root, 'Result', class'WOTCTrainerText'.default.SaveReminder, 30, 712, 1290, 60);
	RefreshValues();
	`log("[WOTCTrainer] Campaign panel initialized", true, 'WOTCTrainer');
}

simulated function RefreshValues()
{
	local XComGameState_HeadquartersXCom HQ;
	local bool bAvatar;
	local int I;

	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none)
	{
		ResultText.SetText(class'WOTCTrainerText'.default.Unavailable);
		return;
	}
	bAvatar = class'WOTCTrainerCampaign'.static.GetAlienHQ() != none;
	for (I = 0; I < 4; ++I)
		AvatarButtons[I].SetDisabled(!bAvatar);
	if (bAvatar)
	{
		AvatarInfo.SetText(class'WOTCTrainerText'.default.CampaignAvatarPermanent $ ": "
			$ class'WOTCTrainerCampaign'.static.AvatarPermanent() $ "<br>"
			$ class'WOTCTrainerText'.default.CampaignAvatarFacility $ ": "
			$ class'WOTCTrainerCampaign'.static.AvatarFacility() $ "<br>"
			$ class'WOTCTrainerText'.default.CampaignAvatarPending $ ": "
			$ class'WOTCTrainerCampaign'.static.AvatarPending() $ "<br>"
			$ class'WOTCTrainerText'.default.CampaignAvatarTotal $ ": "
			$ class'WOTCTrainerCampaign'.static.AvatarTotal() $ " / " $ class'WOTCTrainerCampaign'.static.AvatarMax());
	}
	else
		AvatarInfo.SetText(class'WOTCTrainerText'.default.Unavailable);
	PowerInfo.SetText(class'WOTCTrainerText'.default.CampaignPowerLabel $ ": "
		$ class'WOTCTrainerCampaign'.static.PowerProduced() $ " / " $ class'WOTCTrainerCampaign'.static.PowerConsumed()
		$ " " $ class'WOTCTrainerText'.default.CampaignBonus $ ": +" $ class'WOTCTrainerCampaign'.static.PowerBonus());
	ContactInfo.SetText(class'WOTCTrainerText'.default.CampaignContactLabel $ ": "
		$ class'WOTCTrainerCampaign'.static.ContactCurrent() $ " / " $ class'WOTCTrainerCampaign'.static.ContactPossible()
		$ " " $ class'WOTCTrainerText'.default.CampaignBonus $ ": +" $ class'WOTCTrainerCampaign'.static.ContactBonus());
	QueueInfo.SetText(class'WOTCTrainerText'.default.CampaignResearchLabel $ ": " $ class'WOTCTrainerCampaign'.static.ResearchQueued() $ "<br>"
		$ class'WOTCTrainerText'.default.CampaignProvingLabel $ ": " $ class'WOTCTrainerCampaign'.static.ProvingGroundQueued() $ "<br>"
		$ class'WOTCTrainerText'.default.CampaignFacilityLabel $ ": " $ class'WOTCTrainerCampaign'.static.FacilityQueued() $ "<br>"
		$ class'WOTCTrainerText'.default.CampaignCovertLabel $ ": " $ class'WOTCTrainerCampaign'.static.CovertQueued());
	SquadInfo.SetText(class'WOTCTrainerText'.default.CampaignWounded $ ": " $ class'WOTCTrainerCampaign'.static.WoundedCount()
		$ "  " $ class'WOTCTrainerText'.default.CampaignResting $ ": " $ class'WOTCTrainerCampaign'.static.RestingCount());
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	RefreshValues();
}

simulated function ConfirmCount(name Kind, int Count, name EmptyCode, string Label, string Help)
{
	if (Count <= 0)
	{
		ShowError(EmptyCode);
		return;
	}
	PendingKind = Kind;
	PendingOld = Count;
	PendingNew = 0;
	ShowConfirmation(Label $ ": " $ ChangeText() $ "<br><br>" $ Help, false);
}

simulated function OnAction(UIButton Sender)
{
	local WOTCTrainerButton Button;
	local XComGameState_HeadquartersXCom HQ;
	local string Label;

	if (bModalPending)
		return;
	Button = WOTCTrainerButton(Sender);
	if (Button == none)
		return;
	if (Button.ActionID == 900) { ClosePanel(); return; }
	if (Button.ActionID == 801) { ResultText.SetText(""); RefreshValues(); return; }
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) { ShowError('Unavailable'); return; }
	if (Button.ActionID == 200 || Button.ActionID == 210)
	{
		PendingKind = 'Avatar';
		PendingOld = class'WOTCTrainerCampaign'.static.AvatarTotal();
		PendingNew = Button.ActionID == 210 ? 0 : Max(0, PendingOld - Button.Payload);
		if (PendingOld <= 0 || PendingNew == PendingOld) { ShowError('NothingToRemove'); return; }
		ShowConfirmation(class'WOTCTrainerText'.default.CampaignAvatarTotal $ " " $ ChangeText()
			$ "<br><br>" $ class'WOTCTrainerText'.default.CampaignAvatarHelp, false);
	}
	else if (Button.ActionID == 300 || Button.ActionID == 310)
	{
		PendingKind = Button.ActionID == 300 ? 'Power' : 'Contacts';
		PendingOld = Button.ActionID == 300 ? class'WOTCTrainerCampaign'.static.PowerBonus() : class'WOTCTrainerCampaign'.static.ContactBonus();
		if (PendingOld < 0 || PendingOld > 2147483647 - Button.Payload) { ShowError('Bounds'); return; }
		PendingNew = PendingOld + Button.Payload;
		Label = Button.ActionID == 300 ? class'WOTCTrainerText'.default.CampaignPowerLabel : class'WOTCTrainerText'.default.CampaignContactLabel;
		ShowConfirmation(Label $ " " $ class'WOTCTrainerText'.default.CampaignBonus $ ": " $ ChangeText(), false);
	}
	else if (Button.ActionID == 400)
		ConfirmCount('Research', class'WOTCTrainerCampaign'.static.ResearchQueued(), 'NothingQueued',
			class'WOTCTrainerText'.default.CampaignResearchLabel, class'WOTCTrainerText'.default.CampaignQueueHelp);
	else if (Button.ActionID == 401)
		ConfirmCount('ProvingGround', class'WOTCTrainerCampaign'.static.ProvingGroundQueued(), 'NothingQueued',
			class'WOTCTrainerText'.default.CampaignProvingLabel, class'WOTCTrainerText'.default.CampaignQueueHelp);
	else if (Button.ActionID == 402)
		ConfirmCount('Facility', class'WOTCTrainerCampaign'.static.FacilityQueued(), 'NothingQueued',
			class'WOTCTrainerText'.default.CampaignFacilityLabel, class'WOTCTrainerText'.default.CampaignQueueHelp);
	else if (Button.ActionID == 403)
		ConfirmCount('Covert', class'WOTCTrainerCampaign'.static.CovertQueued(), 'NothingQueued',
			class'WOTCTrainerText'.default.CampaignCovertLabel, class'WOTCTrainerText'.default.CampaignCovertHelp);
	else if (Button.ActionID == 404)
		ConfirmCount('Refund', class'WOTCTrainerCampaign'.static.FacilityQueued(), 'NothingQueued',
			class'WOTCTrainerText'.default.CampaignRefundNow, class'WOTCTrainerText'.default.CampaignQueueHelp);
	else if (Button.ActionID == 500)
		ConfirmCount('HealAll', class'WOTCTrainerCampaign'.static.WoundedCount(), 'NothingToHeal',
			class'WOTCTrainerText'.default.CampaignHealAll, class'WOTCTrainerText'.default.HealingHelp);
	else if (Button.ActionID == 501)
		ConfirmCount('WillAll', class'WOTCTrainerCampaign'.static.RestingCount(), 'NothingToRestore',
			class'WOTCTrainerText'.default.CampaignWillAll, class'WOTCTrainerText'.default.CampaignWillHelp);
}

simulated function string TransitionName(name Kind)
{
	if (Kind == 'Research') return "research";
	if (Kind == 'ProvingGround') return "proving ground";
	if (Kind == 'Facility') return "facility";
	if (Kind == 'Covert') return "covert action";
	return string(Kind);
}

simulated function OnConfirmed(name Action)
{
	local bool Success, bTransition;
	local name ErrorCode;
	local string Label;
	local int Count;

	bModalPending = false;
	if (Action != 'eUIAction_Accept') { PendingKind = ''; return; }
	if (PendingKind == 'Avatar' || PendingKind == 'Power' || PendingKind == 'Contacts')
		Success = RunDirect(Label, Count, ErrorCode);
	else
	{
		// Completing queued work hands control back to the vanilla flow, which opens its own
		// screen (research completion jumps to the lab). The panel closes first: a trainer left
		// under that screen would stay visible and unclickable under its mouse guard.
		bTransition = PendingKind == 'Research' || PendingKind == 'ProvingGround'
			|| PendingKind == 'Facility' || PendingKind == 'Covert';
		if (bTransition)
			CloseForVanillaTransition(string(PendingKind));
		Success = RunQueue(Label, Count, ErrorCode);
	}
	if (bTransition)
	{
		// The panel is gone, so the outcome only goes to the log.
		`log("[WOTCTrainer] Completing " $ TransitionName(PendingKind) $ " after panel close: "
			$ (Success ? "ok" : ("rejected " $ string(ErrorCode))), true, 'WOTCTrainer');
		PendingKind = '';
		return;
	}
	if (Success)
		ResultText.SetText(class'WOTCTrainerText'.default.Applied @ Label);
	else
	{
		ShowError(ErrorCode);
		if (Count > 0)
			ResultText.SetText(class'WOTCTrainerText'.static.ErrorText(ErrorCode) @ class'WOTCTrainerText'.default.CompletedCount @ string(Count));
	}
	PendingKind = '';
	RefreshValues();
}

simulated function bool RunDirect(out string Label, out int Count, out name ErrorCode)
{
	local bool Success;
	local int OldVal, NewVal, FromSites, FromPermanent;

	ErrorCode = '';
	Label = "";
	Count = 0;
	OldVal = 0;
	NewVal = 0;
	FromSites = 0;
	FromPermanent = 0;
	Success = false;
	if (PendingKind == 'Avatar')
	{
		Success = class'WOTCTrainerCampaign'.static.ReduceAvatar(PendingOld - PendingNew, FromSites, FromPermanent, ErrorCode);
		Label = class'WOTCTrainerText'.default.CampaignAvatarTotal $ ": " $ ChangeText();
		if (Success)
			Label $= " | " $ class'WOTCTrainerText'.default.CampaignAvatarFromSites $ " " $ FromSites
				$ ", " $ class'WOTCTrainerText'.default.CampaignAvatarFromPermanent $ " " $ FromPermanent;
	}
	else if (PendingKind == 'Power' || PendingKind == 'Contacts')
	{
		if (PendingKind == 'Power')
			Success = class'WOTCTrainerCampaign'.static.AddPower(PendingNew - PendingOld, OldVal, NewVal, ErrorCode);
		else
			Success = class'WOTCTrainerCampaign'.static.AddContacts(PendingNew - PendingOld, OldVal, NewVal, ErrorCode);
		Label = (PendingKind == 'Power' ? class'WOTCTrainerText'.default.CampaignPowerLabel : class'WOTCTrainerText'.default.CampaignContactLabel)
			$ " " $ class'WOTCTrainerText'.default.CampaignBonus $ ": " $ OldVal $ class'WOTCTrainerText'.default.Arrow $ NewVal;
	}
	return Success;
}

simulated function bool RunQueue(out string Label, out int Count, out name ErrorCode)
{
	local bool Success;

	ErrorCode = '';
	Label = "";
	Count = 0;
	Success = false;
	if (PendingKind == 'Research')
	{
		Success = class'WOTCTrainerCampaign'.static.CompleteResearchNow(ErrorCode);
		Label = class'WOTCTrainerText'.default.CampaignResearchLabel $ ": " $ ChangeText();
	}
	else if (PendingKind == 'ProvingGround')
	{
		Success = class'WOTCTrainerCampaign'.static.CompleteProvingGroundNow(Count, ErrorCode);
		Label = class'WOTCTrainerText'.default.CampaignProvingLabel $ " " $ class'WOTCTrainerText'.default.CampaignCompleted $ ": " $ Count;
	}
	else if (PendingKind == 'Facility')
	{
		Success = class'WOTCTrainerCampaign'.static.CompleteFacilityNow(Count, ErrorCode);
		Label = class'WOTCTrainerText'.default.CampaignFacilityLabel $ " " $ class'WOTCTrainerText'.default.CampaignCompleted $ ": " $ Count;
	}
	else if (PendingKind == 'Covert')
	{
		Success = class'WOTCTrainerCampaign'.static.CompleteCovertNow(Count, ErrorCode);
		Label = class'WOTCTrainerText'.default.CampaignCovertLabel $ " " $ class'WOTCTrainerText'.default.CampaignCompleted $ ": " $ Count;
	}
	else if (PendingKind == 'Refund')
	{
		Success = class'WOTCTrainerCampaign'.static.RefundFacilityNow(Count, ErrorCode);
		Label = class'WOTCTrainerText'.default.CampaignRefundNow $ " " $ class'WOTCTrainerText'.default.CampaignRefunded $ ": " $ Count;
	}
	else if (PendingKind == 'HealAll')
	{
		Success = class'WOTCTrainerCampaign'.static.HealAllNow(Count, ErrorCode);
		Label = class'WOTCTrainerText'.default.CampaignHealAll $ " " $ class'WOTCTrainerText'.default.CampaignCompleted $ ": " $ Count;
	}
	else if (PendingKind == 'WillAll')
	{
		Success = class'WOTCTrainerCampaign'.static.RestoreWillAllNow(Count, ErrorCode);
		Label = class'WOTCTrainerText'.default.CampaignWillAll $ " " $ class'WOTCTrainerText'.default.CampaignCompleted $ ": " $ Count;
	}
	else ErrorCode = 'Unavailable';
	return Success;
}
