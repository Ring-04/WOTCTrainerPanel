class WOTCTrainerText extends Object abstract;

var localized string Title;
var localized string PhaseNotice;
var localized string Tabs[8];
var localized string Resources[6];
var localized string CurrentValue;
var localized string QuickAdd;
var localized string SetValue;
var localized string Confirm;
var localized string Cancel;
var localized string Close;
var localized string Arrow;
var localized string Engineers;
var localized string Scientists;
var localized string AddEngineer;
var localized string AddScientist;
var localized string PersonnelHelp;
var localized string HealAll;
var localized string HealingCount;
var localized string HealingHelp;
var localized string NothingToHeal;
var localized string PendingPhase;
var localized string Applied;
var localized string Added;
var localized string CompletedCount;
var localized string InvalidNumber;
var localized string Unavailable;
var localized string Stale;
var localized string SubmitFailed;
var localized string VerifyFailed;
var localized string MissingResource;
var localized string SaveReminder;
var localized string InputTitle;
var localized string SoldierEditor, Refresh, Barracks, RestoreDefault, FullHeal, RestoreWill, RemoveTraits, RankAndClass;
var localized string SoldierFields[9];
var localized string SoldierHelp, TemplateDefault, SpawnHelp, SpawnSoldier, Promote, Demote, UnsafeDemote, Revive, Unsafe;
var localized string ClassLabel, RankLabel, CountLabel, RookieClass, SelectSoldierFirst, CountInput;
var localized string Bounds, Unsupported, FactionLocked, UnitUnavailable, HealFirst, WillFirst, XPCap, NoWillProject;
var localized string TacticalToggles[12], TacticalActions[5], TacticalHelp, TacticalUnavailable, Teleport, SelectedUnit, ActionPoints, OnLabel, OffLabel;

static function string ToggleText(bool Enabled) { return Enabled ? default.OnLabel : default.OffLabel; }

static function string Escape(string Value)
{
	return Repl(Repl(Repl(Value, "&", "&amp;"), "<", "&lt;"), ">", "&gt;");
}

static function string ErrorText(name Code)
{
	switch (Code)
	{
	case 'TacticalUnavailable': return default.TacticalUnavailable;
	case 'Bounds': return default.Bounds;
	case 'Unsupported': return default.Unsupported;
	case 'FactionLocked': return default.FactionLocked;
	case 'UnitUnavailable': return default.UnitUnavailable;
	case 'HealFirst': return default.HealFirst;
	case 'WillFirst': return default.WillFirst;
	case 'XPCap': return default.XPCap;
	case 'NoWillProject': return default.NoWillProject;
	case 'NothingToHeal': return default.NothingToHeal;
	case 'InvalidNumber': return default.InvalidNumber;
	case 'Stale': return default.Stale;
	case 'MissingResource': return default.MissingResource;
	case 'SubmitFailed': return default.SubmitFailed;
	case 'VerifyFailed': return default.VerifyFailed;
	}
	return default.Unavailable;
}
