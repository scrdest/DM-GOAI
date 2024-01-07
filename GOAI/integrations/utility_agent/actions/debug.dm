// Those Actions are only used for development, either as placeholders or for emitting debugging data.

/datum/utility_ai/mob_commander/proc/PrintArg(var/datum/ActionTracker/tracker, var/printarg)
	if(isnull(tracker))
		RUN_ACTION_DEBUG_LOG("ActionTracker is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(tracker.IsStopped())
		return

	to_world("PrintArg action from [src] - printarg is: [printarg || "null"]")

	tracker.SetDone()
	return


/datum/utility_ai/mob_commander/proc/GlobalWorldstateFlipBoolean(var/datum/ActionTracker/tracker, var/list/worldstate_keys)
	if(isnull(tracker))
		RUN_ACTION_DEBUG_LOG("ActionTracker is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(tracker.IsStopped())
		return

	if(isnull(global.global_worldstate)) { global.global_worldstate = list() }

	for(var/worldstate_key in worldstate_keys)
		//to_world("Iterating over worldstate key [worldstate_key]")
		var/current = global.global_worldstate[worldstate_key]

		if(isnull(current))
			current = FALSE

		var/newval = !current
		//to_world("Worldstate key [worldstate_key] - current [current], new [newval]")
		global.global_worldstate[worldstate_key] = newval

	tracker.SetDone()
	return
