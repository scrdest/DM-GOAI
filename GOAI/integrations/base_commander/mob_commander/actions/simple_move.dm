
/datum/goai/mob_commander/proc/SimpleMove(var/datum/ActionTracker/tracker, var/turf/best_local_pos = null)
	if(!(best_local_pos && istype(best_local_pos)))
		ACTION_RUNTIME_DEBUG_LOG("[src] does not have a bestpos!")
		tracker.SetFailed()
		return

	var/atom/pawn = src.GetPawn()

	if(!pawn)
		ACTION_RUNTIME_DEBUG_LOG("[src] does not have an owned mob!")
		return

	if(!src.active_path || (src.active_path.target != best_local_pos))
		StartNavigateTo(best_local_pos, 0, null)

	var/dist_to_pos = ManhattanDistance(get_turf(pawn), best_local_pos)
	if(dist_to_pos < 1)
		tracker.SetTriggered()

	var/walk_dist = (tracker?.BBGet("StartDist") || 0)
	var/datum/brain/concrete/needybrain = brain

	if(tracker.IsTriggered() && !tracker.is_done)
		if(tracker.TriggeredMoreThan(1))
			tracker.SetDone()

	else if(src.active_path && tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * (20 + walk_dist)))
		if(needybrain)
			needybrain.AddMotive(NEED_COMPOSURE, -MAGICNUM_COMPOSURE_LOSS_FAILMOVE)

		CancelNavigate()
		//brain.SetMemory(MEM_TRUST_BESTPOS, FALSE)
		//brain?.SetMemory("UnreachableTile", src.active_path.target, MEM_TIME_LONGTERM)
		tracker.SetFailed()

	else if(tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * (10 + walk_dist)))
		if(needybrain)
			needybrain.AddMotive(NEED_COMPOSURE, -MAGICNUM_COMPOSURE_LOSS_FAILMOVE)

		CancelNavigate()
		tracker.SetFailed()

	return
