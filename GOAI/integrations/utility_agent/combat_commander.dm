/datum/utility_ai/mob_commander
	name = "utility AI commander"

	# ifdef GOAI_LIBRARY_FEATURES
	var/atom/pawn
	# endif

	# ifdef GOAI_SS13_SUPPORT
	var/weakref/pawn_ref
	# endif

	var/datum/ActivePathTracker/active_path

	var/is_repathing = 0
	var/is_moving = 0


/datum/utility_ai/mob_commander/proc/GetPawn()
	var/atom/movable/mypawn = null

	# ifdef GOAI_LIBRARY_FEATURES
	mypawn = (mypawn || src.pawn)
	# endif

	# ifdef GOAI_SS13_SUPPORT
	mypawn = (mypawn || (pawn_ref?.resolve()))
	# endif

	return mypawn


/datum/utility_ai/mob_commander/Life()
	. = ..()

	// Perception updates
	/*spawn(0)
		while(src.life)
			src.SensesSystem()
			sleep(COMBATAI_SENSE_TICK_DELAY)
	*/


	// Movement updates
	spawn(0)
		while(src.life)
			src.MovementSystem()
			sleep(COMBATAI_MOVE_TICK_DELAY)


	// AI
	spawn(0)
		while(src.life)
			var/cleaned_up = src.CheckForCleanup()
			if(cleaned_up)
				return

			// Run the Life update function.
			src.LifeTick()

			// Fix the tickrate to prevent runaway loops in case something messes with it.
			// Doing it here is nice, because it saves us from sanitizing it all over the place.
			src.ai_tick_delay = max((src?.ai_tick_delay || 0), 1)

			// Wait until the next update tick.
			sleep(src.ai_tick_delay)

	/*
	// Combat system; decoupled from generic planning/actions to make it run
	// *in parallel* to other behaviours - e.g. run-and-gun or fire from cover
	spawn(0)
		while(src.life)
			var/atom/movable/mypawn = src.GetPawn()
			if(mypawn)
				src.FightTick()

			sleep(COMBATAI_FIGHT_TICK_DELAY)
	*/


/datum/utility_ai/mob_commander/LifeTick()
	if(brain)
		brain.LifeTick()

		for(var/datum/ActionTracker/instant_action_tracker in brain.pending_instant_actions)
			var/tracked_instant_action = instant_action_tracker?.tracked_action
			if(tracked_instant_action)
				src.HandleInstantAction(tracked_instant_action, instant_action_tracker)

		PUT_EMPTY_LIST_IN(brain.pending_instant_actions)

		if(brain.running_action_tracker)
			var/tracked_action = brain.running_action_tracker.tracked_action

			if(tracked_action)
				src.HandleAction(tracked_action, brain.running_action_tracker)


	return


/datum/utility_ai/mob_commander/combat_commander
