/datum/goai_commander/proc/AddAction(var/name, var/list/preconds, var/list/effects, var/handler, var/cost = null, var/charges = PLUS_INF, var/instant = FALSE)
	if(charges < 1)
		return

	var/datum/goai_action/newaction = new(preconds, effects, cost, name, charges, instant)

	src.actionslist = (isnull(src.actionslist) ? list() : src.actionslist)
	src.actionslist[name] = newaction

	if(handler)
		actionlookup = (isnull(actionlookup) ? list() : actionlookup)
		actionlookup[name] = handler

	if(src.brain)
		src.brain.AddAction(name, preconds, effects, cost, charges, instant)

	return newaction


/datum/goai_commander/proc/HandleAction(var/datum/goai_action/action, var/datum/ActionTracker/tracker)
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

			if(isnull(actionproc))
				tracker.SetFailed()

			else
				call(src, actionproc)(tracker)

				if(action.instant)
					break

		var/safe_ai_delay = max(1, src.ai_tick_delay)
		sleep(safe_ai_delay)


/datum/goai_commander/proc/HandleInstantAction(var/datum/goai_action/action, var/datum/ActionTracker/tracker)
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


/datum/goai_commander/proc/Idle()
	return
