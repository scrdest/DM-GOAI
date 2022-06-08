# define STEP_SIZE 1
# define STEP_COUNT 1



/mob/goai/combatant
	icon = 'icons/uristmob/simpleanimals.dmi'
	icon_state = "ANTAG"

	var/atom/waypoint


/mob/goai/combatant/proc/HandleAction(var/action, var/datum/ActionTracker/tracker)
	MAYBE_LOG("Tracker: [tracker]")
	var/running = 1

	var/list/action_lookup = GetActionLookup()
	if(isnull(action_lookup))
		return

	while (tracker && running)
		running = tracker.IsRunning()

		MAYBE_LOG("Tracker: [tracker] running @ [running]")

		spawn(0)
			// task-specific logic goes here
			MAYBE_LOG("HandleAction action is: [action]!")

			var/mob/goai/combatant/proc/actionproc = ((action in action_lookup) ? action_lookup[action] : null)

			if(isnull(actionproc))
				tracker.SetFailed()

			else
				call(src, actionproc)(tracker)

		sleep(AI_TICK_DELAY)


/*
/mob/goai/combatant/verb/DoAction(Act as anything in actionslist)
	world.log << "DoAction act: [Act]"

	if(!(Act in actionslist))
		return null

	if(!brain)
		return null

	var/datum/ActionTracker/new_actiontracker = brain.DoAction(Act)

	return new_actiontracker


/mob/goai/combatant/proc/CreatePlan(var/list/status, var/list/goal)
	if(!brain)
		return

	var/list/path = brain.CreatePlan(status, goal)
	return path
*/

/*/mob/goai/combatant/proc/DecayNeeds()
	brain.DecayNeeds()*/


/mob/goai/combatant/Life()
	// Movement updates
	spawn(0)
		while(life)
			MovementSystem()
			sleep(AI_TICK_DELAY)

	// AI
	spawn(0)
		while(life)
			LifeTick()
			sleep(AI_TICK_DELAY)

	// Combat system; decoupled from generic planning/actions to make it run
	// *in parallel* to other behaviours - e.g. run-and-gun or fire from cover
	spawn(0)
		while(life)
			FightTick()
			sleep(AI_TICK_DELAY)



/mob/goai/combatant/proc/LifeTick()
	if(brain)
		brain.LifeTick()

		if(brain.running_action_tracker)
			var/tracked_action = brain.running_action_tracker.tracked_action
			if(tracked_action)
				HandleAction(tracked_action, brain.running_action_tracker)

	return


/mob/goai/combatant/proc/Idle()
	if(prob(50))
		randMove()
