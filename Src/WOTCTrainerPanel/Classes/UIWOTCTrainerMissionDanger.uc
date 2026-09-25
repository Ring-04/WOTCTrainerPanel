class UIWOTCTrainerMissionDanger extends UIWOTCTrainerBase;

var array<name> PendingObjectives;
var int PendingBattle;
var UIText BlockerText;

simulated function OnInit()
{
	super.OnInit();
	Root = Spawn(class'UIPanel', self).InitPanel('MissionDanger'); Root.AnchorCenter(); Root.SetPosition(-590, -330);
	Spawn(class'UIBGBox', Root).InitBG('Background', 0, 0, 1180, 660);
	AddText(Root, 'Title', class'WOTCTrainerText'.default.Tabs[7], 40, 25, 1000, 50, true);
	AddText(Root, 'Warning', class'WOTCTrainerText'.default.EndMissionHelp, 40, 88, 1090, 100);
	BlockerText = AddText(Root, 'Blocker', "", 40, 192, 1090, 84);
	AddButton(Root, 'CompleteAll', class'WOTCTrainerText'.default.CompleteAll, 40, 286, 515, 10);
	AddButton(Root, 'Victory', class'WOTCTrainerText'.default.EndVictory, 590, 286, 545, 11);
	AddButton(Root, 'SameSeed', class'WOTCTrainerText'.default.SameSeed, 40, 344, 515, 13).SetDisabled(true, class'WOTCTrainerText'.default.SameSeedWhy);
	AddButton(Root, 'Failure', class'WOTCTrainerText'.default.EndFailure, 590, 344, 545, 12);
	AddButton(Root, 'Evac', class'WOTCTrainerText'.default.EvacSquad, 40, 402, 515, 14).SetDisabled(true, class'WOTCTrainerText'.default.Unsafe);
	AddText(Root, 'SameSeedWhy', class'WOTCTrainerText'.default.SameSeedWhy, 40, 458, 1090, 42);
	AddText(Root, 'Limits', class'WOTCTrainerText'.default.MissionLimits, 40, 504, 1090, 52);
	ResultText = AddText(Root, 'Result', class'WOTCTrainerText'.default.SaveReminder, 40, 562, 860, 60);
	AddButton(Root, 'Close', class'WOTCTrainerText'.default.Close, 950, 566, 185, 900);
	RefreshValues();
}

simulated function RefreshValues()
{
	BlockerText.SetText(class'WOTCTrainerMission'.static.BlockerText());
}

simulated function OnAction(UIButton Sender)
{
	local WOTCTrainerButton Button;
	local XComGameState_BattleData Battle;
	if (bModalPending) return;
	Button = WOTCTrainerButton(Sender); if (Button == none) return;
	if (Button.ActionID == 900) { ClosePanel(); return; }
	Battle = class'WOTCTrainerMission'.static.BattleData(); if (Battle == none) return;
	PendingBattle = Battle.ObjectID;
	if (Button.ActionID == 10)
	{
		PendingKind = 'All'; PendingObjectives = class'WOTCTrainerMission'.static.IncompleteObjectives();
		PendingOld = PendingObjectives.Length; PendingNew = 0;
		if (PendingObjectives.Length == 0) { ShowError('NoObjectives'); return; }
		ShowConfirmation(class'WOTCTrainerText'.default.CompleteAll @ ChangeText(), true);
	}
	else if (Button.ActionID == 11 || Button.ActionID == 12)
	{
		PendingKind = Button.ActionID == 11 ? 'Victory' : 'Failure';
		ShowConfirmation(class'WOTCTrainerText'.default.ActiveMission $ class'WOTCTrainerText'.default.Arrow $ (PendingKind == 'Victory' ? class'WOTCTrainerText'.default.EndVictory : class'WOTCTrainerText'.default.EndFailure)
			$ "<br><br>" $ class'WOTCTrainerMission'.static.BlockerText(), true);
	}
}

simulated function OnConfirmed(name Action)
{
	local name ErrorCode;
	local bool Success;
	local XComGameState_BattleData Battle;
	bModalPending = false;
	if (Action != 'eUIAction_Accept') { PendingKind = ''; return; }
	Battle = class'WOTCTrainerMission'.static.BattleData();
	if (Battle == none || Battle.ObjectID != PendingBattle) { ShowError('Stale'); return; }
	if (PendingKind == 'All') Success = class'WOTCTrainerMission'.static.Complete(PendingObjectives, PendingBattle, ErrorCode);
	else if (PendingKind == 'Victory' || PendingKind == 'Failure')
	{
		Success = class'WOTCTrainerMission'.static.EndMission(PendingKind == 'Victory', ErrorCode);
		if (Success) { ClosePanel(); return; }
	}
	if (Success) ResultText.SetText(class'WOTCTrainerText'.default.Applied @ ChangeText());
	else ShowError(ErrorCode);
	PendingKind = ''; RefreshValues();
}
