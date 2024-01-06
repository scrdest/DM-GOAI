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
