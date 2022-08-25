/datum/ActionTracker
	var/datum/goai_action/tracked_action
	var/timeout_ds = null
	var/list/tracker_blackboard

	var/is_done = 0
	var/is_failed = 0

	var/creation_time = null
	var/trigger_time = null
	var/last_check_time = null


/datum/ActionTracker/New(var/datum/goai_action/action, var/timeout = null)
	tracked_action = action || tracked_action
	timeout_ds = timeout
	tracker_blackboard = list()

	var/curr_time = world.time
	creation_time = curr_time
	last_check_time = curr_time

	spawn(0)
		Run()


/datum/ActionTracker/proc/BBGet(var/key, var/default = null)
	var/rval = default
	if (key in tracker_blackboard)
		rval = tracker_blackboard[key]
	return rval


/datum/ActionTracker/proc/BBSet(var/key, var/val)
	tracker_blackboard[key] = val
	return 1


/datum/ActionTracker/proc/BBSetDefault(var/key, var/default = null)
	var/rval = default
	if (key in tracker_blackboard)
		rval = tracker_blackboard[key]
	else
		tracker_blackboard[key] = rval
	return rval


/datum/ActionTracker/proc/IsOlderThan(var/max_lag_ds, var/relativeTo = null)
	var/curr_time = isnull(relativeTo) ? world.time : relativeTo
	var/timeDelta = curr_time - creation_time

	var/result = (timeDelta >= max_lag_ds) ? TRUE : FALSE

	// Need to update last visit time
	last_check_time = world.time

	return result


/datum/ActionTracker/proc/TriggeredMoreThan(var/max_lag_ds, var/relativeTo = null)
	if(isnull(trigger_time))
		return 0

	var/curr_time = isnull(relativeTo) ? world.time : relativeTo
	var/timeDelta = curr_time - trigger_time

	var/result = (timeDelta >= max_lag_ds) ? TRUE : FALSE

	// Need to update last visit time
	last_check_time = world.time

	return result


/datum/ActionTracker/proc/IsCheckStale(var/max_lag_ds, var/relativeTo = null)
	var/curr_time = isnull(relativeTo) ? world.time : relativeTo
	var/timeDelta = curr_time - last_check_time

	var/result = (timeDelta >= max_lag_ds) ? TRUE : FALSE

	return result


/datum/ActionTracker/proc/IsStopped()
	var/result = (is_done || is_failed)
	last_check_time = world.time
	return result


/datum/ActionTracker/proc/IsRunning()
	var/result = !IsStopped()
	return result


/datum/ActionTracker/proc/IsTriggered()
	var/result = !isnull(trigger_time)
	return result


/datum/ActionTracker/proc/IsAbandoned()
	if (isnull(timeout_ds))
		// tasks w/o a timeout are never abandonable
		return FALSE

	var/result = IsCheckStale(timeout_ds, world.time)
	return result


/datum/ActionTracker/proc/CheckAbandoned()
	var/abandoned = IsAbandoned()
	if(abandoned)
		SetFailed()
	return abandoned


/datum/ActionTracker/proc/SetTriggered()
	if(!IsTriggered())
		world.log << "Setting tracker to triggered!"
		trigger_time = world.time
	return


/datum/ActionTracker/proc/ResetTriggered()
	world.log << "Setting tracker to non-triggered!"
	trigger_time = null
	return


/datum/ActionTracker/proc/SetDone()
	if(!is_done)
		world.log << "Setting tracker to done!"
		tracked_action.ReduceCharges(1)
		is_done = TRUE

	return


/datum/ActionTracker/proc/SetFailed()
	if(!is_failed)
		world.log << "Setting tracker to failed!"
		tracked_action.ReduceCharges(1)
		is_failed = TRUE

	return


/datum/ActionTracker/proc/Run()
	while (IsRunning())
		CheckAbandoned()

		if(isnull(tracked_action))
			SetFailed()

		sleep(AI_TICK_DELAY)

