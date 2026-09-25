class WOTCTrainerItems extends Object abstract;

// Reviewed stock SDK APIs: docs/API-AUDIT.md. Never mutate a history object.
// The catalogue is always enumerated from X2ItemTemplateManager.IterateTemplates; no item
// template is ever named in this class, so mods and DLC add themselves to the browser.
static function X2ItemTemplateManager Manager()
{
	return class'X2ItemTemplateManager'.static.GetItemTemplateManager();
}

// Why a template is not offered. An empty Reason means the template can be granted.
// Hidden templates cover resources, quest items, mission items and schematics: granting those
// either duplicates the resource page or injects a story item whose OnAcquiredFn the campaign
// never expected. Infinite items are already unlimited, and PutItemInInventory drops them, so
// granting one would silently do nothing.
static function bool Excluded(X2ItemTemplate Template, out name Reason)
{
	Reason = '';
	if (Template == none) { Reason = 'Unknown'; return true; }
	if (Template.bInfiniteItem) { Reason = 'Infinite'; return true; }
	if (Template.HideInInventory) { Reason = 'Hidden'; return true; }
	if (Template.ItemCat == 'resource') { Reason = 'Resource'; return true; }
	if (X2SchematicTemplate(Template) != none) { Reason = 'Schematic'; return true; }
	if (!Template.HasDisplayData()) { Reason = 'NoDisplay'; return true; }
	return false;
}

static function string Label(X2ItemTemplate Template)
{
	local string Text;
	if (Template == none) return "";
	Text = Template.GetItemFriendlyNameNoStats();
	// The accessor cannot report "absent", so its own error text is the only signal; fall back
	// to the plural form and finally to the internal template name.
	if (InStr(Text, "Error!") == 0)
	{
		Text = Template.GetItemFriendlyNamePlural();
		if (InStr(Text, "Error!") == 0) Text = string(Template.DataName);
	}
	return Text;
}

// Localized name for a template category. Unknown or mod-added categories report their raw
// internal name rather than pretending to be something else.
static function string CategoryText(name Category)
{
	switch (Category)
	{
	case 'weapon': return class'WOTCTrainerText'.default.CatWeapon;
	case 'armor': return class'WOTCTrainerText'.default.CatArmor;
	case 'upgrade': return class'WOTCTrainerText'.default.CatUpgrade;
	case 'ammo': return class'WOTCTrainerText'.default.CatAmmo;
	case 'utility': return class'WOTCTrainerText'.default.CatUtility;
	case 'unlimited': return class'WOTCTrainerText'.default.CatUnlimited;
	case 'combatsim': return class'WOTCTrainerText'.default.CatCombatSim;
	case 'heal': return class'WOTCTrainerText'.default.CatHeal;
	case 'defense': return class'WOTCTrainerText'.default.CatDefense;
	case 'psidefense': return class'WOTCTrainerText'.default.CatPsiDefense;
	case 'psioffense': return class'WOTCTrainerText'.default.CatPsiOffense;
	case 'grenade': return class'WOTCTrainerText'.default.CatGrenade;
	case 'tech': return class'WOTCTrainerText'.default.CatTech;
	case 'skulljack': return class'WOTCTrainerText'.default.CatSkulljack;
	}
	return string(Category);
}

// Slot names follow the game's own wording, taken from UIArmory_Loadout.m_strInventoryLabels
// in the shipped CHN/INT localization rather than invented here.
static function string SlotText(X2EquipmentTemplate Equipment)
{
	if (Equipment == none) return class'WOTCTrainerText'.default.SlotUnknown;
	switch (Equipment.InventorySlot)
	{
	case eInvSlot_Armor: return class'WOTCTrainerText'.default.SlotArmor;
	case eInvSlot_PrimaryWeapon: return class'WOTCTrainerText'.default.SlotPrimary;
	case eInvSlot_SecondaryWeapon: return class'WOTCTrainerText'.default.SlotSecondary;
	case eInvSlot_HeavyWeapon: return class'WOTCTrainerText'.default.SlotHeavy;
	case eInvSlot_Utility: return class'WOTCTrainerText'.default.SlotUtility;
	case eInvSlot_Mission: return class'WOTCTrainerText'.default.SlotMission;
	case eInvSlot_Backpack: return class'WOTCTrainerText'.default.SlotBackpack;
	case eInvSlot_Loot: return class'WOTCTrainerText'.default.SlotLoot;
	case eInvSlot_GrenadePocket: return class'WOTCTrainerText'.default.SlotGrenade;
	case eInvSlot_CombatSim: return class'WOTCTrainerText'.default.SlotCombatSim;
	case eInvSlot_AmmoPocket: return class'WOTCTrainerText'.default.SlotAmmo;
	case eInvSlot_TertiaryWeapon: return class'WOTCTrainerText'.default.SlotTertiary;
	case eInvSlot_QuaternaryWeapon: return class'WOTCTrainerText'.default.SlotQuaternary;
	case eInvSlot_QuinaryWeapon: return class'WOTCTrainerText'.default.SlotQuinary;
	case eInvSlot_SenaryWeapon: return class'WOTCTrainerText'.default.SlotSenary;
	case eInvSlot_SeptenaryWeapon: return class'WOTCTrainerText'.default.SlotSeptenary;
	}
	return class'WOTCTrainerText'.default.SlotUnknown;
}

static function array<name> Categories()
{
	local X2DataTemplate Data;
	local X2ItemTemplate Template;
	local array<name> Result;
	local name Reason, Swap;
	local int I, J;
	foreach Manager().IterateTemplates(Data, none)
	{
		Template = X2ItemTemplate(Data);
		if (Excluded(Template, Reason)) continue;
		Result.AddItem(Template.ItemCat);
	}
	for (I = 1; I < Result.Length; ++I)
	{
		Swap = Result[I];
		for (J = I; J > 0 && string(Result[J - 1]) > string(Swap); --J)
			Result[J] = Result[J - 1];
		Result[J] = Swap;
	}
	for (I = Result.Length - 1; I > 0; --I)
		if (Result[I] == Result[I - 1]) Result.Remove(I, 1);
	return Result;
}

// Category == '' selects every category. Labels runs parallel to the returned names so the
// panel can draw rows without re-resolving a whole template per frame. ExcludedCount reports
// how many templates the filters above removed, so the panel can say the list is not exhaustive.
static function array<name> Items(name Category, out array<string> Labels, out int ExcludedCount)
{
	local X2DataTemplate Data;
	local X2ItemTemplate Template;
	local array<name> Result;
	local string Text, PreviousLabel;
	local name Key, Reason;
	local int J;
	Result.Length = 0;
	Labels.Length = 0;
	ExcludedCount = 0;
	foreach Manager().IterateTemplates(Data, none)
	{
		Template = X2ItemTemplate(Data);
		if (Excluded(Template, Reason)) { ++ExcludedCount; continue; }
		if (Category != '' && Template.ItemCat != Category) continue;
		Key = Template.DataName;
		Text = Label(Template);
		for (J = Result.Length; J > 0; --J)
		{
			PreviousLabel = Labels[J - 1];
			if (PreviousLabel < Text) break;
			if (PreviousLabel == Text && string(Result[J - 1]) <= string(Key)) break;
		}
		Result.InsertItem(J, Key);
		Labels.InsertItem(J, Text);
	}
	return Result;
}

static function X2ItemTemplate Find(name TemplateName)
{
	return Manager().FindItemTemplate(TemplateName);
}

// Sum over every inventory stack, because GetNumItemInInventory (HQ:4292) reports only the
// first stack that GetItemByName returns. Returns -1 when there is no headquarters state.
static function int OwnedQuantity(name TemplateName)
{
	local XComGameState_HeadquartersXCom HQ;
	local XComGameState_Item Item;
	local int I, Total;
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none) return -1;
	for (I = 0; I < HQ.Inventory.Length; ++I)
	{
		Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(HQ.Inventory[I].ObjectID));
		if (Item != none && Item.GetMyTemplateName() == TemplateName) Total += Item.Quantity;
	}
	return Total;
}

static function string Details(name TemplateName)
{
	local X2ItemTemplate Template;
	local X2EquipmentTemplate Equipment;
	local string Text;
	Template = Find(TemplateName);
	if (Template == none) return "";
	Text = class'WOTCTrainerText'.static.Escape(Label(Template));
	Text $= "<br>" $ class'WOTCTrainerText'.default.InternalName $ ": " $ string(Template.DataName);
	Text $= " | " $ class'WOTCTrainerText'.default.CategoryLabel $ ": " $ CategoryText(Template.ItemCat) $ " | Tier " $ Template.Tier;
	Equipment = X2EquipmentTemplate(Template);
	if (Equipment != none) Text $= " | " $ class'WOTCTrainerText'.default.SlotLabel $ ": " $ SlotText(Equipment);
	Text $= "<br>" $ class'WOTCTrainerText'.default.OwnedLabel $ ": " $ OwnedQuantity(TemplateName);
	if (Template.bAlwaysUnique) Text $= "<br>" $ class'WOTCTrainerText'.default.UniqueNote;
	return Text;
}

// Mirrors the instant-build branch of UIInventory_BuildItems.uc:393 without the cost, build
// project or the upgrade substitution that XComGameState_HeadquartersXCom.uc:4807 GiveItem
// applies, so the granted template is always the one the player picked.
static function bool Grant(name TemplateName, int Quantity, out int NewTotal, out name ErrorCode)
{
	local X2ItemTemplate Template;
	local XComGameState_HeadquartersXCom HQ, NewHQ;
	local XComGameState_Item Item;
	local XComGameState Change;
	local name Reason;
	local int Before;

	NewTotal = 0;
	ErrorCode = '';
	Template = Find(TemplateName);
	HQ = class'WOTCTrainerStrategy'.static.GetHQ();
	if (HQ == none || Template == none)
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	if (Excluded(Template, Reason))
	{
		ErrorCode = 'NotGrantable';
		return false;
	}
	if (Quantity < 1 || Quantity > 9999)
	{
		ErrorCode = 'Bounds';
		return false;
	}
	// A unique item state must stay a single object; stacking it would break the invariant
	// X2ItemTemplate.uc:32 documents, so one copy per confirmation is the safe maximum.
	if (Template.bAlwaysUnique) Quantity = 1;
	Before = OwnedQuantity(TemplateName);
	if (Before < 0 || Before > 2147483647 - Quantity)
	{
		ErrorCode = 'Bounds';
		return false;
	}

	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Add item " $ TemplateName);
	NewHQ = XComGameState_HeadquartersXCom(Change.ModifyStateObject(class'XComGameState_HeadquartersXCom', HQ.ObjectID));
	Item = Template.CreateInstanceFromTemplate(Change);
	Item.Quantity = Quantity;
	Item.OnItemBuilt(Change);
	NewHQ.PutItemInInventory(Change, Item);
	`XEVENTMGR.TriggerEvent('ItemConstructionCompleted', Item, Item, Change);
	if (!`GAMERULES.SubmitGameState(Change))
	{
		ErrorCode = 'SubmitFailed';
		return false;
	}
	NewTotal = OwnedQuantity(TemplateName);
	if (NewTotal != Before + Quantity)
	{
		ErrorCode = 'VerifyFailed';
		`log("[WOTCTrainer] Item post-submit verification failed: " $ TemplateName $ " expected " $ (Before + Quantity) $ " got " $ NewTotal, true, 'WOTCTrainer');
		return false;
	}
	`log("[WOTCTrainer] Item " $ TemplateName $ ": " $ Before $ " -> " $ NewTotal, true, 'WOTCTrainer');
	return true;
}
