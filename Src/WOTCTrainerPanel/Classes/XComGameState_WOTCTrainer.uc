class XComGameState_WOTCTrainer extends XComGameState_BaseObject;

var int BattleID, MissionID;
struct TrainerFlag
{
	var bool bEnabled;
};
var TrainerFlag Flags[12];
var array<int> ProtectedUnits;

static function XComGameState_WOTCTrainer GetSettings()
{
	local XComGameState_WOTCTrainer Settings;
	local XComGameState_BattleData Battle;
	if (`TACTICALRULES == none) return none;
	Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
	if (Battle == none || Battle.bMultiplayer) return none;
	Settings = XComGameState_WOTCTrainer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_WOTCTrainer', true));
	if (Settings == none || Settings.BattleID != Battle.ObjectID || Settings.MissionID != Battle.m_iMissionID) return none;
	return Settings;
}

static function bool Enabled(int Index, optional int UnitID)
{
	local XComGameState_WOTCTrainer Settings;
	Settings = GetSettings();
	if (Settings == none || Index < 0 || Index > 11) return false;
	if (Index == 1) return Settings.ProtectedUnits.Find(UnitID) != INDEX_NONE;
	return Settings.Flags[Index].bEnabled;
}

static function bool XComSoldier(XComGameState_Unit Unit)
{
	return Unit != none && Unit.IsSoldier() && Unit.GetTeam() == eTeam_XCom && !Unit.bRemovedFromPlay;
}

static function bool Protected(XComGameState_Unit Unit)
{
	return XComSoldier(Unit) && (Enabled(0) || Enabled(1, Unit.ObjectID));
}


