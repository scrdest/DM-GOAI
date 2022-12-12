/datum/goai_commander/proc/HandleIdling(var/datum/ActionTracker/tracker)
	world.log << "[src.name] idling..."
	src.Idle()

	if(tracker.IsOlderThan(20))
		tracker.SetDone()

	return
