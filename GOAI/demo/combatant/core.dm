/* In this module:
===================

 - Mob definition
 - HandleAction core logic
 - AI Mainloop (Life()/LifeTick())
 - Init for subsystems per AI (by extension - it's in Life())

*/

# define STEP_SIZE 1
# define STEP_COUNT 1



/mob/goai/combatant
	icon = 'icons/uristmob/simpleanimals.dmi'
	icon_state = "ANTAG"

	var/atom/waypoint

	// Optional - for map editor. Set this to force initial action. Must be valid (in available actions).
	var/initial_action = null


/mob/goai/combatant/proc/HandleAction(var/action, var/datum/ActionTracker/tracker)
	MAYBE_LOG("Tracker: [tracker]")
	var/running = 1

	var/list/action_lookup = GetActionLookup()
	if(isnull(action_lookup))
		return

	while (tracker && running)
		// TODO: Interrupts
		running = tracker.IsRunning()

		MAYBE_LOG("[src]: Tracker: [tracker] running @ [running]")

		spawn(0)
			// task-specific logic goes here
			MAYBE_LOG("[src]: HandleAction action is: [action]!")

			var/mob/goai/combatant/actionproc = ((action in action_lookup) ? action_lookup[action] : null)

			if(isnull(actionproc))
				tracker.SetFailed()

			else
				call(src, actionproc)(tracker)

		sleep(COMBATAI_AI_TICK_DELAY)


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
			SensesSystem()
			sleep(COMBATAI_SENSE_TICK_DELAY)

	// Movement updates
	spawn(0)
		while(life)
			MovementSystem()
			sleep(COMBATAI_MOVE_TICK_DELAY)

	// AI
	spawn(0)
		while(life)
			LifeTick()
			sleep(COMBATAI_AI_TICK_DELAY)

	// Combat system; decoupled from generic planning/actions to make it run
	// *in parallel* to other behaviours - e.g. run-and-gun or fire from cover
	spawn(0)
		while(life)
			FightTick()
			sleep(COMBATAI_FIGHT_TICK_DELAY)



/mob/goai/combatant/proc/LifeTick()
	// quick hack:
	var/datum/brain/concrete/combatbrain = brain

	if(combatbrain && (combatbrain.GetMotive(NEED_COMPOSURE) || NEED_SATISFIED) < NEED_THRESHOLD)
		SetState(STATE_PANIC, 1)

	var/curr_panic_state = GetState(STATE_PANIC)
	if(curr_panic_state >= 1)
		if(prob(5))
			// Break PANIC state eventually
			// TODO: Refactor, this is a hacky POC solution
			SetState(STATE_PANIC, -1)

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
