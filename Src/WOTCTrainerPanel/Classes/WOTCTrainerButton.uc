class WOTCTrainerButton extends UIButton;

var int ActionID;
var int Payload;

// Marks the single button that opens the trainer from the tactical HUD. Only that
// button re-applies its flash state: it is spawned while the tactical HUD is still
// loading, and the vanilla tactical panels re-push their flash content the same way
// (see UITacticalHUD_AbilityContainer.OnInit).
var bool bIsTacticalEntry;
var string EntryLabel;
var int EntryWatchCount;

simulated function OnInit()
{
	super.OnInit();

	if (bIsTacticalEntry)
	{
		`log("[WOTCTrainer] Trainer button spawned: MCPath=" $ string(MCPath) $ " " $ (bIsInited ? "inited" : "not-inited"), true, 'WOTCTrainer');
		ApplyEntryState();
	}
}

// Starts (or restarts) watching the flash movie clip of the tactical entry button.
// Runs from the entry actor, so it keeps working even when the flash init is missed.
simulated function RestartEntryWatch()
{
	if (!bIsTacticalEntry) return;

	EntryWatchCount = 0;
	ApplyEntryState();
	SetTimer(1.0, true, nameof(WatchEntryFlash));
}

simulated function WatchEntryFlash()
{
	++EntryWatchCount;
	ApplyEntryState();

	if (bIsInited)
	{
		ClearTimer(nameof(WatchEntryFlash));
		`log("[WOTCTrainer] Trainer button ready after " $ EntryWatchCount $ " flash check(s)", true, 'WOTCTrainer');
		return;
	}

	`log("[WOTCTrainer] Trainer button flash not inited yet (check " $ EntryWatchCount $ ")", true, 'WOTCTrainer');

	// The button is created while the tactical loading screen is still up; panels created
	// in that window can miss their flash init. Once the movie has settled, ask flash for
	// the child movie clip again, then give up after a few more checks.
	if (EntryWatchCount == 3 && ParentPanel != none)
	{
		`log("[WOTCTrainer] Trainer button re-requesting flash movie clip", true, 'WOTCTrainer');
		ParentPanel.LoadChild(self);
	}
	else if (EntryWatchCount >= 6)
	{
		ClearTimer(nameof(WatchEntryFlash));
		`log("[WOTCTrainer] Trainer button flash init FAILED", true, 'WOTCTrainer');
	}
}

// UIPanel setters only push to flash when their mirrored value changes, so reset the
// mirrors first: this forces the full state to flash again after a late or repeated
// flash init.
simulated function ApplyEntryState()
{
	local int SavedAnchor, SavedOrigin;
	local float SavedX, SavedY, SavedWidth, SavedHeight;

	if (!bIsTacticalEntry) return;

	SavedAnchor = Anchor;
	SavedOrigin = Origin;
	SavedX = X;
	SavedY = Y;
	SavedWidth = Width;
	SavedHeight = Height;

	Anchor = class'UIUtilities'.const.ANCHOR_NONE;
	Origin = class'UIUtilities'.const.ANCHOR_NONE;
	X = 0; Y = 0;
	Width = 0; Height = 0;
	Alpha = 0;
	Text = "";
	bIsVisible = false;

	SetAnchor(SavedAnchor);
	SetOrigin(SavedOrigin);
	SetPosition(SavedX, SavedY);
	SetSize(SavedWidth, SavedHeight);
	SetAlpha(100);
	if (MC != none)
		MC.SetBool("_visible", true);
	Show();
	SetText(EntryLabel);
	MoveToHighestDepth();
}

defaultproperties
{
	ResizeToText=false
	bAnimateOnInit=false
}
