
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

	/* A pseudo-need used to inject a step to movements
	*/
	states["STATE_ORIENTED"] = NEED_MINIMUM

	return states


/mob/goai/combatant/InitActionsList()
	/* TODO: add Time as a resource! */
	// Cost, Req-ts, Effects
	AddAction("Idle", list(), list(), /mob/goai/combatant/proc/HandleIdling, -999)
	AddAction("Take Cover", list(STATE_DOWNTIME = 1, STATE_PANIC = -1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1), /mob/goai/combatant/proc/HandleDirectionalCover, 10)
	//AddAction("Cover Leapfrog", list(STATE_DOWNTIME = 1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1), /mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog, 10)
	//AddAction("Directional Cover", list(STATE_DOWNTIME = -1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1, NEED_OBEDIENCE = NEED_SATISFIED), /mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog, 4)
	AddAction("Directional Cover Leapfrog", list(STATE_DOWNTIME = -1, STATE_PANIC = -1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1, NEED_OBEDIENCE = NEED_SATISFIED), /mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog, 4)
	//AddAction("Cover Fire", list(STATE_INCOVER = 1), list(NEED_COVER = NEED_MINIMUM, STATE_INCOVER = 0, NEED_ENEMIES = NEED_SATISFIED), /mob/goai/combatant/proc/HandleIdling, 5)
	//AddAction("Shoot", list(STATE_CANFIRE = 1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1, NEED_OBEDIENCE = NEED_SATISFIED), /mob/goai/combatant/proc/HandleShoot, 10)
	AddAction("Panic Run", list(STATE_PANIC = 1), list(NEED_COVER = NEED_SATISFIED, NEED_OBEDIENCE = NEED_SATISFIED, NEED_COMPOSURE = NEED_SATISFIED, STATE_PANIC = -1), /mob/goai/combatant/proc/HandlePanickedRun, 10)
	//AddAction("Reorient", list(), list("STATE_ORIENTED" = NEED_MAXIMUM), /mob/goai/combatant/proc/HandleReorient, 1)

	return actionslist


/mob/goai/combatant/Equip()
	. = ..()
	GimmeGun()
	return


/mob/goai/combatant/CreateBrain(var/list/custom_actionslist = NONE, var/list/init_memories = null, var/list/init_action = null, var/datum/brain/with_hivemind = null, var/dict/custom_personality = null)
	var/list/new_actionslist = (custom_actionslist ? custom_actionslist : actionslist)
	var/dict/new_personality = (isnull(custom_personality) ? GeneratePersonality() : custom_personality)

	var/datum/brain/concrete/combat/new_brain = new /datum/brain/concrete/combat(new_actionslist, init_memories, src.initial_action, with_hivemind, new_personality, "brain of [src]")

	new_brain.needs = src.states
	new_brain.states = src.states
	return new_brain