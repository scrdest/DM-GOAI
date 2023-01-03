/datum/goai/mob_commander/combat_commander
	name = "combat commander"


/datum/goai/mob_commander/combat_commander/Life()
	. = ..()

	// Perception updates
	spawn(0)
		while(src.life)
			src.SensesSystem()
			sleep(COMBATAI_SENSE_TICK_DELAY)

	// Movement updates
	spawn(0)
		while(src.life)
			src.MovementSystem()
			sleep(COMBATAI_MOVE_TICK_DELAY)

	// AI
	spawn(0)
		while(src.life)
			// Fix the tickrate to prevent runaway loops in case something messes with it.
			// Doing it here is nice, because it saves us from sanitizing it all over the place.
			src.ai_tick_delay = max((src?.ai_tick_delay || 0), 1)

			// Run the Life update function.
			src.LifeTick()

			// Wait until the next update tick.
			sleep(src.ai_tick_delay)

	// Combat system; decoupled from generic planning/actions to make it run
	// *in parallel* to other behaviours - e.g. run-and-gun or fire from cover
	spawn(0)
		while(src.life)
			if(src.pawn)
				src.FightTick()

			sleep(COMBATAI_FIGHT_TICK_DELAY)



/datum/goai/mob_commander/combat_commander/LifeTick()
	//world.log << "Mob Commander [src.name] [src] <[src.pawn]> LifeTick()"

	// quick hack:
	var/datum/brain/concrete/combatbrain = brain
	var/panicking = GetState(STATE_PANIC, FALSE)
	var/is_different = FALSE

	if(combatbrain && (combatbrain.GetNeed(NEED_COMPOSURE, NEED_SATISFIED) < NEED_THRESHOLD))
		is_different = (panicking != TRUE)
		panicking = TRUE

	else if(combatbrain && (combatbrain.GetNeed(NEED_COMPOSURE, NEED_SATISFIED) >= NEED_THRESHOLD))
		is_different = (panicking != FALSE)
		panicking = FALSE

	if(is_different)
		SetState(STATE_PANIC, panicking)


	if(brain)
		if(brain.last_plan_successful)
			//brain.SetMemory(MEM_TRUST_BESTPOS, TRUE)
		else
			//world.log << "[src]: Getting disoriented!"
			SetState(STATE_DISORIENTED, TRUE)
			//brain.SetMemory(MEM_TRUST_BESTPOS, FALSE, 1000)

		brain.LifeTick()

		for(var/datum/ActionTracker/instant_action_tracker in brain.pending_instant_actions)
			var/tracked_instant_action = instant_action_tracker?.tracked_action
			if(tracked_instant_action)
				HandleInstantAction(tracked_instant_action, instant_action_tracker)

		if(brain.running_action_tracker)
			var/tracked_action = brain.running_action_tracker.tracked_action
			//world.log << "MobComm [src] - RUNNING ACTIoN [tracked_action]"

			if(tracked_action)
				HandleAction(tracked_action, brain.running_action_tracker)


	return
