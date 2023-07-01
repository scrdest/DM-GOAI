/datum/utility_ai/mob_commander/proc/StepTo(var/datum/ActionTracker/tracker, var/atom/position)
	/*
	// Simple movement Action; just does a single step to a target position.
	*/
	if(isnull(tracker))
		RUN_ACTION_DEBUG_LOG("Tracker position is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(tracker.IsStopped())
		return

	if(isnull(position))
		RUN_ACTION_DEBUG_LOG("Target position is null | <@[src]> | [__FILE__] -> L[__LINE__]")

	var/atom/pawn = src.GetPawn()

	if(isnull(pawn))
		RUN_ACTION_DEBUG_LOG("Pawn is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(pawn.x == position.x && pawn.y == position.y && pawn.z == position.z)
		tracker.SetDone()
		return

	var/succeeded = step_towards(pawn, position)

	if(!succeeded)
		var/bb_failures = tracker.BBSetDefault("failed_steps", 0)
		tracker.BBSet("failed_steps", ++bb_failures)

		if(bb_failures > 3)
			tracker.SetFailed()

	return


/datum/utility_ai/mob_commander/proc/MoveTo(var/datum/ActionTracker/tracker, var/atom/position)
	/*
	// Fancier movement Action; persist an Astar path to avoid getting stuck
	*/
	if(isnull(tracker))
		RUN_ACTION_DEBUG_LOG("Tracker position is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(tracker.IsStopped())
		return

	if(isnull(position))
		RUN_ACTION_DEBUG_LOG("Target position is null | <@[src]> | [__FILE__] -> L[__LINE__]")

	var/atom/pawn = src.GetPawn()

	if(isnull(pawn))
		RUN_ACTION_DEBUG_LOG("Pawn is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(pawn.x == position.x && pawn.y == position.y && pawn.z == position.z)
		tracker.SetDone()
		return

	var/list/chunkypath = tracker.BBGet("path")

	if(isnull(chunkypath))
		chunkypath = ChunkyAStar(pawn, position)
		tracker.BBSet("path", chunkypath)

	var/succeeded = FALSE

	if(!succeeded)
		var/bb_failures = tracker.BBSetDefault("failed_steps", 0)
		tracker.BBSet("failed_steps", ++bb_failures)

		if(bb_failures > 3)
			tracker.SetFailed()

	return

