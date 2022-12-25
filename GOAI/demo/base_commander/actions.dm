/* In this module:
===================

 - angle2dir helper (might be moved)
 - Misc. actions (not worth their own module yet)

*/


/proc/angle2dir(var/angle)
	var/true_angle = round(CLOCKWISE_ANGLE(angle))
	var/direction = null

	switch (true_angle)
		if (0 to 44) direction = EAST
		if (45 to 89) direction = NORTHEAST
		if (90 to 134) direction = NORTH
		if (135 to 179) direction = NORTHWEST
		if (180 to 224) direction = WEST
		if (225 to 269) direction = SOUTHWEST
		if (270 to 314) direction = SOUTH
		if (315 to 360) direction = SOUTHEAST

	//world.log << "TRUE ANGLE: [true_angle] => DIR: [direction]"
	return direction


/datum/goai/proc/AddAction(var/name, var/list/preconds, var/list/effects, var/handler, var/cost = null, var/charges = PLUS_INF, var/instant = FALSE)
	if(charges < 1)
		return

	var/datum/goai_action/newaction = new(preconds, effects, cost, name, charges, instant)

	actionslist = (isnull(actionslist) ? list() : actionslist)
	actionslist[name] = newaction

	if(handler)
		actionlookup = (isnull(actionlookup) ? list() : actionlookup)
		actionlookup[name] = handler

	if(brain)
		brain.AddAction(name, preconds, effects, cost, charges, instant)

	return newaction


/datum/goai/proc/HandleAction(var/datum/goai_action/action, var/datum/ActionTracker/tracker)
	MAYBE_LOG("Tracker: [tracker]")
	var/running = 1

	var/list/action_lookup = actionlookup // abstract maybe
	if(isnull(action_lookup))
		return

	while (tracker && running)
		// TODO: Interrupts
		running = tracker.IsRunning()

		MAYBE_LOG("[src]: Tracker: [tracker] running @ [running]")

		spawn(0)
			// task-specific logic goes here
			MAYBE_LOG("[src]: HandleAction action is: [action]")

			var/actionproc = action_lookup[action.name]

			/*for(var/alkey in action_lookup)
				world.log << "[src] action lookup: [alkey] => [action_lookup[alkey]]"*/

			//world.log << "[src]: Actionproc for [action] is [actionproc || "null"]"

			if(isnull(actionproc))
				tracker.SetFailed()

			else
				call(src, actionproc)(tracker)

				if(action.instant)
					break

		var/safe_ai_delay = max(1, src.ai_tick_delay)
		sleep(safe_ai_delay)


/datum/goai/proc/HandleInstantAction(var/datum/goai_action/action, var/datum/ActionTracker/tracker)
	MAYBE_LOG("Tracker: [tracker]")

	var/list/action_lookup = actionlookup // abstract maybe
	if(isnull(action_lookup))
		return

	MAYBE_LOG("[src]: Tracker: [tracker] running @ [tracker?.IsRunning()]")
	MAYBE_LOG("[src]: HandleAction action is: [action]")

	var/actionproc = action_lookup[action.name]

	if(isnull(actionproc))
		tracker.SetFailed()

	else
		call(src, actionproc)(tracker)

	return



/datum/goai/proc/Idle()
	return



/datum/goai/proc/HandleIdling(var/datum/ActionTracker/tracker)
	Idle()

	if(tracker.IsOlderThan(20))
		tracker.SetDone()

	return
