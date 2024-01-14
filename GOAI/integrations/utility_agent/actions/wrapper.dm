
/datum/utility_ai/mob_commander/proc/WrapFunction(var/datum/ActionTracker/tracker, var/func_proc, var/list/func_args)
	to_world_log("Calling WrapFunction [func_proc]")

	if(isnull(tracker))
		RUN_ACTION_DEBUG_LOG("ActionTracker is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(isnull(func_proc))
		RUN_ACTION_DEBUG_LOG("func_proc is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		tracker.SetFailed()
		return

	if(tracker.IsStopped())
		return

	var/true_func_proc = func_proc
	if(!ispath(func_proc))
		true_func_proc = STR_TO_PROC(func_proc)

	if(isnull(true_func_proc))
		RUN_ACTION_DEBUG_LOG("true_func_proc is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		tracker.SetFailed()
		return

	call(true_func_proc)(arglist(func_args))
	tracker.SetDone()

	return
