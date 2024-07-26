/*
// For messy, historical reasons, the core AI loop had once been implemented in the Brain class rather than the AI class
// (namely: the AI object came later by factoring out the AI from the mob class).
//
// This is that LEGACY implementation - the AI proper calls into the Brain's API.
//
// This is (or at least should be) unincluded at the moment.
// Not much will happen if you untick this and/or the other Brain-based decision API components,
// but this is deprecated, possibly under-maintained and probably just... unnecessary.
*/

/datum/utility_ai/proc/LifeTick()
	if(paused)
		return

	if(brain)
		brain.LifeTick()

		for(var/datum/ActionTracker/instant_action_tracker in brain.pending_instant_actions)
			var/tracked_instant_action = instant_action_tracker?.tracked_action
			if(tracked_instant_action)
				src.HandleInstantAction(tracked_instant_action, instant_action_tracker)

		PUT_EMPTY_LIST_IN(brain.pending_instant_actions)

		if(brain.running_action_tracker)
			var/tracked_action = brain.running_action_tracker.tracked_action

			if(tracked_action)
				src.HandleAction(tracked_action, brain.running_action_tracker)

	return TRUE
