
/mob/goai/combatant/InitStates()
	states = ..()

	/* Controls autonomy; if FALSE, agent has specific overriding orders,
	// otherwise can 'smart idle' (i.e. wander about, but stil tacticool,
	// as opposed to just sitting in place).
	//
	// Can be used as a precondition to/signal of running more micromanaged behaviours.
	//
	// With Sim-style needs, TRUE can be also used to let the NPC take care
	// of any non-urgent motives; partying ANTAGs, why not?)
	*/
	states[STATE_DOWNTIME] = TRUE

	/* Simple item tracker. */
	states[STATE_HASGUN] = (locate(/obj/gun) in src.contents) ? 1 : 0

	/* Controls if the agent is *allowed & able* to engage using *anything*
	// Can be used to force 'hold fire' or simulate the hands being occupied
	// during special actions / while using items.
	*/
	states[STATE_CANFIRE] = 1

	/*
	*/
	states[STATE_PANIC] = -1

	return states


/mob/goai/combatant/GetActionsList()
	/* TODO: add Time as a resource! */
	var/list/new_actionslist = list(
		// Cost, Req-ts, Effects
		"Idle" = new /datum/Triple (-999, list(), list(NEED_COVER = NEED_SATISFIED, NEED_OBEDIENCE = NEED_SATISFIED, NEED_COMPOSURE = NEED_SATISFIED, STATE_PANIC = -1)),
		"Take Cover" = new /datum/Triple (10, list(STATE_DOWNTIME = 1, STATE_PANIC = -1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1)),
		//"Cover Leapfrog" = new /datum/Triple (10, list(STATE_DOWNTIME = 1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1)),
		//"Directional Cover" = new /datum/Triple (4, list(STATE_DOWNTIME = -1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1, NEED_OBEDIENCE = NEED_SATISFIED)),
		"Directional Cover Leapfrog" = new /datum/Triple (4, list(STATE_DOWNTIME = -1, STATE_PANIC = -1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1, NEED_OBEDIENCE = NEED_SATISFIED)),
		//"Cover Fire" = new /datum/Triple (5, list(STATE_INCOVER = 1), list(NEED_COVER = NEED_MINIMUM, STATE_INCOVER = 0, NEED_ENEMIES = NEED_SATISFIED)),
		//"Shoot" = new /datum/Triple (10, list(STATE_CANFIRE = 1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1, NEED_OBEDIENCE = NEED_SATISFIED)),
		"Panic Run" = new /datum/Triple (10, list(STATE_PANIC = 1), list(NEED_COVER = NEED_SATISFIED, NEED_OBEDIENCE = NEED_SATISFIED, NEED_COMPOSURE = NEED_SATISFIED, STATE_PANIC = -1)),
	)
	return new_actionslist


/mob/goai/combatant/Equip()
	. = ..()
	GimmeGun()
	return


/mob/goai/combatant/proc/GetActionLookup()
	var/list/action_lookup = list()
	action_lookup["Idle"] = /mob/goai/combatant/proc/HandleIdling
	action_lookup["Take Cover"] = /mob/goai/combatant/proc/HandleDirectionalCover
	action_lookup["Cover Leapfrog"] = /mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog
	action_lookup["Directional Cover"] = /mob/goai/combatant/proc/HandleDirectionalCover
	action_lookup["Directional Cover Leapfrog"] = /mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog
	action_lookup["Cover Fire"] = /mob/goai/combatant/proc/HandleIdling
	action_lookup["Shoot"] = /mob/goai/combatant/proc/HandleShoot
	action_lookup["Panic Run"] = /mob/goai/combatant/proc/HandlePanickedRun
	return action_lookup


/mob/goai/combatant/CreateBrain(var/list/custom_actionslist = NONE, var/list/init_memories = null, var/list/init_action = null, var/datum/brain/with_hivemind = null, var/dict/custom_personality = null)
	var/list/new_actionslist = (custom_actionslist ? custom_actionslist : actionslist)
	var/dict/new_personality = (isnull(custom_personality) ? generate_personality() : custom_personality)

	var/datum/brain/concrete/combat/new_brain = new /datum/brain/concrete/combat(new_actionslist, init_memories, src.initial_action, with_hivemind, new_personality, "brain of [src]")

	new_brain.needs = src.states
	new_brain.states = src.states
	return new_brain