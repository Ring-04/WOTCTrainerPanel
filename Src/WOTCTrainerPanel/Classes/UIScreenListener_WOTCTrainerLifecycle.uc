// Trainer panels belong to the screen they were opened on. Vanilla flows push their own screens
// while a trainer can be open (research completion jumps to the lab, mission end swaps the tactical
// screens, the Avenger swaps the facility grid), and a trainer left underneath one of those stays
// visible but unclickable: the new screen's UIMouseGuard swallows every mouse event aimed at it.
// This listener closes the trainer the moment its host is covered or removed.
class UIScreenListener_WOTCTrainerLifecycle extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIScreenStack Stack;

	if (Screen == none || Screen.Movie == none)
		return;
	if (class'UIWOTCTrainerBase'.static.IsTrainerScreen(Screen) || class'UIWOTCTrainerBase'.static.IsTransientScreen(Screen))
		return;
	Stack = Screen.Movie.Stack;
	if (class'UIWOTCTrainerBase'.static.FindTrainer(Stack) == none)
		return;
	`log("[WOTCTrainer] Host screen lost focus: " $ string(Screen.Class.Name), true, 'WOTCTrainer');
	class'UIWOTCTrainerBase'.static.RemoveTrainers(Stack, "screen changed to " $ string(Screen.Class.Name));
}

event OnRemoved(UIScreen Screen)
{
	local UIScreenStack Stack;

	if (Screen == none || Screen.Movie == none)
		return;
	if (class'UIWOTCTrainerBase'.static.IsTrainerScreen(Screen) || class'UIWOTCTrainerBase'.static.IsTransientScreen(Screen))
		return;
	Stack = Screen.Movie.Stack;
	if (class'UIWOTCTrainerBase'.static.FindTrainer(Stack) == none)
		return;
	if (class'UIWOTCTrainerBase'.static.RemoveTrainers(Stack, "host screen removed: " $ string(Screen.Class.Name), Screen) > 0)
		`log("[WOTCTrainer] Host screen removed: " $ string(Screen.Class.Name), true, 'WOTCTrainer');
}
