class WOTCTrainerStrategy extends Object abstract;

// Reviewed stock SDK APIs: docs/API-AUDIT.md. Never mutate a history object.
static function XComGameState_HeadquartersXCom GetHQ()
{
	if (`HQGAME == none || `HQPRES == none || `STRATEGYRULES == none)
		return none;
	return XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
}

static function name ResourceName(int Index)
{
	switch (Index)
	{
	case 0: return 'Supplies';
	case 1: return 'Intel';
	case 2: return 'AlienAlloy';
	case 3: return 'EleriumDust';
	case 4: return 'EleriumCore';
	case 5: return 'AbilityPoint';
	}
	return '';
}

static function bool ParseAmount(string Text, out int Value)
{
	local int I, Digit;
	Value = 0;
	if (Len(Text) == 0 || Len(Text) > 10)
		return false;
	for (I = 0; I < Len(Text); ++I)
	{
		Digit = Asc(Mid(Text, I, 1)) - 48;
		if (Digit < 0 || Digit > 9 || Value > 214748364 || (Value == 214748364 && Digit > 7))
			return false;
		Value = Value * 10 + Digit;
	}
	return true;
}

static function bool SetResource(int Index, int ExpectedValue, int NewValue, out name ErrorCode)
{
	local XComGameState_HeadquartersXCom HQ, NewHQ;
	local XComGameState Change;
	local name Resource;
	local int OldValue;

	ErrorCode = '';
	HQ = GetHQ();
	Resource = ResourceName(Index);
	if (HQ == none || Resource == '')
	{
		ErrorCode = 'Unavailable';
		return false;
	}
	if (NewValue < 0)
	{
		ErrorCode = 'InvalidNumber';
		return false;
	}
	if (HQ.GetItemByName(Resource) == none)
	{
		ErrorCode = 'MissingResource';
		return false;
	}
	OldValue = HQ.GetResourceAmount(Resource);
	if (OldValue != ExpectedValue || OldValue < 0)
	{
		ErrorCode = 'Stale';
		return false;
	}
	if (OldValue == NewValue)
		return true;

	Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("[WOTCTrainer] Set resource " $ Resource);
	NewHQ = XComGameState_HeadquartersXCom(Change.ModifyStateObject(class'XComGameState_HeadquartersXCom', HQ.ObjectID));
	// Both operands are nonnegative int values, so this difference cannot overflow.
	NewHQ.AddResource(Change, Resource, NewValue - OldValue);
	if (!`GAMERULES.SubmitGameState(Change))
	{
		ErrorCode = 'SubmitFailed';
		return false;
	}
	HQ = GetHQ();
	if (HQ == none || HQ.GetResourceAmount(Resource) != NewValue)
	{
		ErrorCode = 'VerifyFailed';
		`log("[WOTCTrainer] Resource post-submit verification failed: " $ Resource, true, 'WOTCTrainer');
		return false;
	}
	`log("[WOTCTrainer] " $ Resource $ ": " $ OldValue $ " -> " $ NewValue, true, 'WOTCTrainer');
	return true;
}
