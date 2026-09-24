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

static function string ErrorText(name Code)
{
	switch (Code)
	{
	case 'InvalidNumber': return default.InvalidNumber;
	case 'Stale': return default.Stale;
	case 'MissingResource': return default.MissingResource;
	case 'SubmitFailed': return default.SubmitFailed;
	case 'VerifyFailed': return default.VerifyFailed;
	}
	return default.Unavailable;
}
