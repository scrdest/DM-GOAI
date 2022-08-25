/mob/goai/combatant/proc/HandleOpenDoor(var/datum/ActionTracker/tracker)
	if(!tracker)
		return

	if(tracker.IsOlderThan(COMBATAI_AI_TICK_DELAY * 10))
		tracker.SetFailed()
		return

	if(!brain)
		world.log << "[src] HandleOpenDoor - no brain!"
		tracker.SetFailed()
		return

	var/obj/cover/door/obstruction = brain.GetMemoryValue(MEM_OBSTRUCTION, null)

	if(isnull(obstruction))
		world.log << "[src] HandleOpenDoor - no Obstruction!"
		tracker.SetFailed()
		return

	if(!istype(obstruction))
		world.log << "[src] HandleOpenDoor - wrong type!"
		tracker.SetFailed()
		return

	if(tracker.IsRunning() && obstruction.open)
		if(get_dist(get_turf(src), get_turf(obstruction)) < 1)
			tracker.SetDone()
			return

	var/list/path_to_door = tracker.BBGet("PathToDoor", null)

	if(isnull(path_to_door) || !active_path)
		path_to_door = StartNavigateTo(obstruction, 1, refresh_loc_memories = FALSE)
		tracker.BBSet("PathToDoor", path_to_door)

	if(get_dist(src, obstruction) < 2)
		if(!(obstruction.open))
			obstruction.pOpen()
			StartNavigateTo(obstruction, 0, refresh_loc_memories = FALSE)

	//SetState(STATE_DISORIENTED, TRUE)
	return


/mob/goai/combatant/proc/HandleOpenAutodoor(var/datum/ActionTracker/tracker)
	if(!tracker)
		return

	if(tracker.IsOlderThan(COMBATAI_AI_TICK_DELAY * 10))
		tracker.SetFailed()
		return

	if(!brain)
		world.log << "[src] HandleOpenAutodoor - no brain!"
		tracker.SetFailed()
		return

	var/obj/cover/autodoor/obstruction = brain.GetMemoryValue(MEM_OBSTRUCTION, null)

	if(isnull(obstruction))
		world.log << "[src] HandleOpenAutodoor - no Obstruction!"
		tracker.SetFailed()
		return

	if(!istype(obstruction))
		world.log << "[src] HandleOpenAutodoor - wrong type!"
		tracker.SetFailed()
		return

	if(tracker.IsRunning() && obstruction.open)
		if(get_dist(get_turf(src), get_turf(obstruction)) < 1)
			tracker.SetDone()
			return

	var/list/path_to_door = tracker.BBGet("PathToDoor", null)

	if(isnull(path_to_door) || !active_path)
		path_to_door = StartNavigateTo(obstruction, 1)
		tracker.BBSet("PathToDoor", path_to_door)

	if(get_dist(src, obstruction) < 2)
		if(!(obstruction.open))
			obstruction.pOpen()
			StartNavigateTo(obstruction, 0)

	return
