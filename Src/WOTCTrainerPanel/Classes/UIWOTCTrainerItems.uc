class UIWOTCTrainerItems extends UIWOTCTrainerBase;

var array<name> Cats, Filtered;
var array<string> RowLabels;
var WOTCTrainerButton Rows[12], FilterButton, SearchButton, StoryButton;
var UIText Details, PageText, QuantityValue, NoticeText;
var int PageIndex, CategoryIndex, Quantity, Excluded, PendingQuantity;
var name SelectedName;
var string SearchTerm;
var bool bShowStory;

simulated function OnInit()
{
	local int I, J;
	local array<int> Steps;
	super.OnInit();
	Root = Spawn(class'UIPanel', self).InitPanel('ItemsRoot');
	Root.AnchorCenter(); Root.SetPosition(-690, -395);
	Spawn(class'UIBGBox', Root).InitBG('Background', 0, 0, 1380, 790);
	AddText(Root, 'Title', class'WOTCTrainerText'.default.Tabs[4], 30, 20, 600, 50, true);
	AddButton(Root, 'Refresh', class'WOTCTrainerText'.default.Refresh, 1060, 20, 125, 801);
	AddButton(Root, 'Close', class'WOTCTrainerText'.default.Close, 1200, 20, 145, 900);
	PageText = AddText(Root, 'Page', "", 30, 85, 220, 40);
	AddButton(Root, 'Previous', "<", 255, 85, 80, 802);
	AddButton(Root, 'Next', ">", 343, 85, 80, 803);
	SearchButton = AddButton(Root, 'Search', "", 433, 85, 340, 805);
	FilterButton = AddButton(Root, 'Filter', "", 783, 85, 567, 804);
	for (I = 0; I < 12; ++I) Rows[I] = AddButton(Root, name("Item" $ I), "", 30, 135 + I * 48, 560, I);
	Details = AddText(Root, 'Details', "", 610, 130, 740, 160);
	AddText(Root, 'QuantityLabel', class'WOTCTrainerText'.default.QuantityLabel, 610, 300, 300, 40);
	QuantityValue = AddText(Root, 'Quantity', "", 1010, 300, 160, 40);
	Steps.AddItem(1); Steps.AddItem(5); Steps.AddItem(10); Steps.AddItem(50); Steps.AddItem(100); Steps.AddItem(500);
	for (J = 0; J < 6; ++J) AddButton(Root, name("Step" $ J), "+" $ Steps[J], 610 + J * 122, 348, 112, 100 + J, Steps[J]);
	AddButton(Root, 'SetQuantity', class'WOTCTrainerText'.default.SetQuantity, 610, 400, 250, 300);
	AddButton(Root, 'Grant', class'WOTCTrainerText'.default.GrantItem, 870, 400, 250, 400);
	StoryButton = AddButton(Root, 'Story', "", 1130, 400, 220, 807);
	NoticeText = AddText(Root, 'Notice', "", 610, 452, 740, 250);
	ResultText = AddText(Root, 'Result', class'WOTCTrainerText'.default.SaveReminder, 30, 712, 1080, 60);
	Quantity = 1;
	RefreshCatalogue();
}

simulated function name CategoryName()
{
	if (CategoryIndex <= 0 || CategoryIndex > Cats.Length) return '';
	return Cats[CategoryIndex - 1];
}

simulated function RefreshCatalogue()
{
	Cats = class'WOTCTrainerItems'.static.Categories(bShowStory);
	Filtered = class'WOTCTrainerItems'.static.Items(CategoryName(), SearchTerm, bShowStory, RowLabels, Excluded);
	PageIndex = Clamp(PageIndex, 0, Max(0, (Filtered.Length - 1) / 12));
	if (Filtered.Find(SelectedName) == INDEX_NONE) SelectedName = Filtered.Length > 0 ? Filtered[0] : '';
	RefreshRows();
}

simulated function RefreshRows()
{
	local int I, Index, Owned;
	PageText.SetText(class'WOTCTrainerText'.default.ItemsLabel @ Filtered.Length @ "|" @ (PageIndex + 1) $ "/" $ Max(1, (Filtered.Length + 11) / 12));
	FilterButton.SetText(class'WOTCTrainerText'.default.CategoryLabel $ ": "
		$ (CategoryIndex == 0 ? class'WOTCTrainerText'.default.ItemAll : class'WOTCTrainerItems'.static.CategoryText(CategoryName()))
		$ " (" $ Filtered.Length $ ")");
	SearchButton.SetText(class'WOTCTrainerText'.default.ItemSearch $ ": "
		$ (SearchTerm == "" ? class'WOTCTrainerText'.default.ItemSearchAll : class'WOTCTrainerText'.static.Escape(SearchTerm)));
	StoryButton.SetText(class'WOTCTrainerText'.default.ItemStory $ ": " $ class'WOTCTrainerText'.static.ToggleText(bShowStory));
	StoryButton.SetSelected(bShowStory);
	for (I = 0; I < 12; ++I)
	{
		Index = PageIndex * 12 + I;
		Rows[I].SetDisabled(Index >= Filtered.Length);
		if (Index < Filtered.Length)
		{
			Rows[I].SetText(class'WOTCTrainerText'.static.Escape(RowLabels[Index]));
			Rows[I].SetSelected(Filtered[Index] == SelectedName);
		}
		else Rows[I].SetText("-");
	}
	Owned = class'WOTCTrainerItems'.static.OwnedQuantity(SelectedName);
	if (SelectedName == '' || Owned < 0) Details.SetText(class'WOTCTrainerText'.default.ItemEmpty);
	else Details.SetText(class'WOTCTrainerItems'.static.Details(SelectedName));
	QuantityValue.SetText(string(Quantity));
	// The story warning replaces the general help while it is active, so both fit the text box.
	NoticeText.SetText((bShowStory ? "" : class'WOTCTrainerText'.default.ItemHelp $ "<br><br>")
		$ (bShowStory ? class'WOTCTrainerText'.default.ItemStoryWarn $ "<br><br>" : "")
		$ class'WOTCTrainerText'.default.ItemExcluded @ Excluded $ " "
		$ (bShowStory ? class'WOTCTrainerText'.default.ItemExcludedWhyStory : class'WOTCTrainerText'.default.ItemExcludedWhy));
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if (Root != none) RefreshCatalogue();
}

simulated function OnAction(UIButton Sender)
{
	local WOTCTrainerButton Button;
	local TInputDialogData Input;
	local int Index;
	if (bModalPending) return;
	Button = WOTCTrainerButton(Sender);
	if (Button == none) return;
	if (Button.ActionID == 900) { ClosePanel(); return; }
	if (Button.ActionID == 801) { RefreshCatalogue(); return; }
	if (Button.ActionID == 802 || Button.ActionID == 803) { PageIndex += Button.ActionID == 802 ? -1 : 1; RefreshRows(); return; }
	if (Button.ActionID == 807)
	{
		bShowStory = !bShowStory;
		PageIndex = 0;
		RefreshCatalogue();
		return;
	}
	if (Button.ActionID == 804)
	{
		CategoryIndex = CategoryIndex >= Cats.Length ? 0 : CategoryIndex + 1;
		PageIndex = 0;
		RefreshCatalogue();
		return;
	}
	if (Button.ActionID >= 0 && Button.ActionID < 12)
	{
		Index = PageIndex * 12 + Button.ActionID;
		if (Index < Filtered.Length) SelectedName = Filtered[Index];
		Quantity = 1;
		RefreshRows();
		return;
	}
	if (Button.ActionID >= 100 && Button.ActionID < 106)
	{
		Quantity = Clamp(Quantity + Button.Payload, 1, 999);
		QuantityValue.SetText(string(Quantity));
		return;
	}
	if (Button.ActionID == 805)
	{
		Input.strTitle = class'WOTCTrainerText'.default.ItemSearch;
		Input.strInputBoxText = SearchTerm;
		Input.iMaxChars = 24;
		Input.fnCallbackAccepted = OnInputAccepted;
		Input.fnCallbackCancelled = OnInputCancelled;
		PendingKind = 'Search';
		bModalPending = true;
		Movie.Pres.UIInputDialog(Input);
		return;
	}
	if (Button.ActionID == 300)
	{
		Input.strTitle = class'WOTCTrainerText'.default.QuantityLabel;
		Input.strInputBoxText = string(Quantity);
		Input.iMaxChars = 3;
		Input.fnCallbackAccepted = OnInputAccepted;
		Input.fnCallbackCancelled = OnInputCancelled;
		PendingKind = 'Quantity';
		bModalPending = true;
		Movie.Pres.UIInputDialog(Input);
		return;
	}
	if (Button.ActionID == 400) ConfirmGrant();
}

simulated function ConfirmGrant()
{
	local int Owned, NewTotal;
	local X2ItemTemplate Template;
	local bool bStory;
	Owned = class'WOTCTrainerItems'.static.OwnedQuantity(SelectedName);
	if (SelectedName == '' || Owned < 0) { ShowError('Unavailable'); return; }
	if (Owned > 2147483647 - Quantity) { ShowError('Bounds'); return; }
	NewTotal = Owned + Quantity;
	Template = class'WOTCTrainerItems'.static.Find(SelectedName);
	bStory = class'WOTCTrainerItems'.static.IsStory(Template);
	PendingKind = 'Grant';
	PendingQuantity = Quantity;
	PendingOld = Owned;
	PendingNew = NewTotal;
	ShowConfirmation(class'WOTCTrainerItems'.static.Label(Template)
		$ ": " $ ChangeText() $ "<br><br>"
		$ (bStory ? class'WOTCTrainerText'.default.ItemStoryWarn $ "<br><br>" : "")
		$ class'WOTCTrainerText'.default.GrantHelp, bStory);
}

simulated function OnInputAccepted(string InputText)
{
	bModalPending = false;
	if (PendingKind == 'Search')
	{
		SearchTerm = InputText;
		PendingKind = '';
		PageIndex = 0;
		RefreshCatalogue();
		return;
	}
	PendingKind = '';
	if (!class'WOTCTrainerStrategy'.static.ParseAmount(InputText, PendingNew)) { ShowError('InvalidNumber'); return; }
	if (PendingNew < 1 || PendingNew > 999) { ShowError('Bounds'); return; }
	Quantity = PendingNew;
	QuantityValue.SetText(string(Quantity));
}

simulated function OnInputCancelled(string InputText)
{
	bModalPending = false;
	PendingKind = '';
}

simulated function OnConfirmed(name Action)
{
	local bool Success;
	local name ErrorCode;
	local int NewTotal;
	bModalPending = false;
	if (Action != 'eUIAction_Accept') { PendingKind = ''; return; }
	if (PendingKind != 'Grant') { PendingKind = ''; return; }
	if (SelectedName == '' || class'WOTCTrainerItems'.static.OwnedQuantity(SelectedName) != PendingOld) { ShowError('Stale'); PendingKind = ''; return; }
	Success = class'WOTCTrainerItems'.static.Grant(SelectedName, PendingQuantity, bShowStory, NewTotal, ErrorCode);
	if (Success)
		ResultText.SetText(class'WOTCTrainerText'.default.Applied @ class'WOTCTrainerItems'.static.Label(class'WOTCTrainerItems'.static.Find(SelectedName)) $ ": " $ ChangeText());
	else ShowError(ErrorCode);
	PendingKind = '';
	Quantity = 1;
	RefreshRows();
}
