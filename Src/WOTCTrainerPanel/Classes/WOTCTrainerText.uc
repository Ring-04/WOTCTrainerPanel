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
var localized string MissionControl, ObjectiveHelp, MissionState, Enemies, Reinforcements, InvalidTiles, PendingSubmission, NoEnemiesHint;
var localized string RefreshObjectives, CompleteSelected, SkipAI, RestartMission, MissionLimits, InternalObjectives, HUDObjectives;
var localized string IncompleteLabel, CompletedLabel, SkipAIHelp, RestartHelp, EndMissionHelp, CompleteAll, EndVictory, EndFailure, SameSeed, EvacSquad, ActiveMission;
var localized string AIBusy, CompleteFirst, NoObjectives;
var localized string RepairAI, RestoreAI, AIHangHelp, AIHangNote, AIHangScope;
var localized string RoleTactical, RoleStrategy, RoleTriad, RoleNone, ObjectiveLoot, ObjectiveList;
var localized string VictoryReady, VictoryBlockedBy, TurnOwner, SweepNote, SameSeedWhy, LootSweepBlocked;
var localized string TeamXCom, TeamAlien, TeamLost, TeamResistance, TeamNeutral, TeamOne, TeamTwo, TeamOther;
var localized string ItemHelp, ItemExcluded, ItemExcludedWhy, ItemsLabel, ItemAll, ItemEmpty, QuantityLabel, SetQuantity;
var localized string ItemSearch, ItemSearchAll, ItemStory, ItemStoryWarn, ItemExcludedWhyStory;
var localized string GrantItem, GrantHelp, InternalName, CategoryLabel, SlotLabel, OwnedLabel, UniqueNote, NotGrantable;
var localized string CatWeapon, CatArmor, CatUpgrade, CatAmmo, CatUtility, CatUnlimited, CatCombatSim;
var localized string CatHeal, CatDefense, CatPsiDefense, CatPsiOffense, CatGrenade, CatTech, CatSkulljack;
var localized string SlotUnknown, SlotArmor, SlotPrimary, SlotSecondary, SlotHeavy, SlotUtility, SlotMission, SlotBackpack;
var localized string SlotLoot, SlotGrenade, SlotCombatSim, SlotAmmo, SlotTertiary, SlotQuaternary, SlotQuinary, SlotSenary, SlotSeptenary;
var localized string CampaignTitle, CampaignHeaderAvatar, CampaignAvatarPermanent, CampaignAvatarFacility, CampaignAvatarPending;
var localized string CampaignAvatarTotal, CampaignAvatarMax, CampaignMinus1, CampaignMinus2, CampaignMinus5, CampaignClear;
var localized string CampaignAvatarHelp, CampaignAvatarFromSites, CampaignAvatarFromPermanent;
var localized string CampaignHeaderAbility, CampaignPowerLabel, CampaignContactLabel, CampaignBonus;
var localized string CampaignHeaderQueue, CampaignResearchLabel, CampaignProvingLabel, CampaignFacilityLabel, CampaignCovertLabel;
var localized string CampaignResearchNow, CampaignProvingNow, CampaignFacilityNow, CampaignCovertNow, CampaignRefundNow;
var localized string CampaignQueueHelp, CampaignCovertHelp, CampaignNoProvingGround, CampaignNothingQueued, CampaignNothingToRemove, CampaignNothingToRestore;
var localized string CampaignCompleted, CampaignRefunded, CampaignHeaderSquad, CampaignWounded, CampaignResting;
var localized string CampaignHealAll, CampaignWillAll, CampaignWillHelp;

static function string ToggleText(bool Enabled) { return Enabled ? default.OnLabel : default.OffLabel; }

static function string TeamText(ETeam Team)
{
	switch (Team)
	{
	case eTeam_XCom: return default.TeamXCom;
	case eTeam_Alien: return default.TeamAlien;
	case eTeam_TheLost: return default.TeamLost;
	case eTeam_Resistance: return default.TeamResistance;
	case eTeam_Neutral: return default.TeamNeutral;
	case eTeam_One: return default.TeamOne;
	case eTeam_Two: return default.TeamTwo;
	}
	return default.TeamOther;
}

static function string Escape(string Value)
{
	return Repl(Repl(Repl(Value, "&", "&amp;"), "<", "&lt;"), ">", "&gt;");
}

static function string ErrorText(name Code)
{
	switch (Code)
	{
	case 'AIBusy': return default.AIBusy;
	case 'CompleteFirst': return default.CompleteFirst;
	case 'NoObjectives': return default.NoObjectives;
	case 'TacticalUnavailable': return default.TacticalUnavailable;
	case 'Bounds': return default.Bounds;
	case 'Unsupported': return default.Unsupported;
	case 'FactionLocked': return default.FactionLocked;
	case 'UnitUnavailable': return default.UnitUnavailable;
	case 'HealFirst': return default.HealFirst;
	case 'WillFirst': return default.WillFirst;
	case 'XPCap': return default.XPCap;
	case 'NoWillProject': return default.NoWillProject;
	case 'NotGrantable': return default.NotGrantable;
	case 'NothingToHeal': return default.NothingToHeal;
	case 'InvalidNumber': return default.InvalidNumber;
	case 'Stale': return default.Stale;
	case 'MissingResource': return default.MissingResource;
	case 'SubmitFailed': return default.SubmitFailed;
	case 'VerifyFailed': return default.VerifyFailed;
	case 'NothingQueued': return default.CampaignNothingQueued;
	case 'NothingToRemove': return default.CampaignNothingToRemove;
	case 'NothingToRestore': return default.CampaignNothingToRestore;
	}
	return default.Unavailable;
}
