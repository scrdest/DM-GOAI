
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

	states[STATE_CALM] = TRUE
	states[STATE_PANIC] = FALSE

	/* A pseudo-need used to inject a step to movements
	*/
	states[STATE_DISORIENTED] = TRUE
	states[STATE_ORIENTED] = FALSE
	states["HasTakeCoverPath"] = FALSE
	states["HasPanicRunPath"] = FALSE

	return states


/mob/goai/combatant/InitActionsList()
	/* TODO: add Time as a resource! */
	// Name, Req-ts, Effects, Priority, [Charges]

	AddAction(
		"Idle",
		list(),
		list(),
		/mob/goai/combatant/proc/HandleIdling,
		-999
	)

	AddAction(
		"Take Cover Pathfind",
		list(
			STATE_DOWNTIME = TRUE,
			STATE_CALM = TRUE,
			"HasTakeCoverPath" = FALSE,
		),
		list(
			"HasTakeCoverPath" = TRUE,
		),
		/mob/goai/combatant/proc/HandleChooseDirectionalCoverLandmark,
		10,
		PLUS_INF,
		TRUE
	)

	AddAction(
		"Take Cover",
		list(
			STATE_DOWNTIME = TRUE,
			STATE_CALM = TRUE,
			"HasTakeCoverPath" = TRUE,
		),
		list(
			NEED_COVER = NEED_SATISFIED,
			STATE_INCOVER = TRUE,
			"HasTakeCoverPath" = FALSE,
		),
		/mob/goai/combatant/proc/HandleDirectionalCover,
		11
	)

	//AddAction("Cover Leapfrog", list(STATE_DOWNTIME = 1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1), /mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog, 10)
	//AddAction("Directional Cover", list(STATE_DOWNTIME = -1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1, NEED_OBEDIENCE = NEED_SATISFIED), /mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog, 4)
	//AddAction("Directional Cover Leapfrog", list(STATE_DOWNTIME = -1, STATE_CALM = TRUE, "STATE_ORIENTED" = TRUE), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1, NEED_OBEDIENCE = NEED_SATISFIED), /mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog, 4)
	//AddAction("Cover Fire", list(STATE_INCOVER = 1), list(NEED_COVER = NEED_MINIMUM, STATE_INCOVER = 0, NEED_ENEMIES = NEED_SATISFIED), /mob/goai/combatant/proc/HandleIdling, 5)
	//AddAction("Shoot", list(STATE_CANFIRE = 1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1, NEED_OBEDIENCE = NEED_SATISFIED), /mob/goai/combatant/proc/HandleShoot, 10)

	AddAction(
		"Panic Run Pathfind",
		list(
			STATE_PANIC = TRUE,
			"HasPanicRunPath" = FALSE,
		),
		list(
			"HasPanicRunPath" = TRUE,
		),
		/mob/goai/combatant/proc/HandleChoosePanicRunLandmark,
		10,
		PLUS_INF,
		TRUE
	)

	AddAction(
		"Panic Run",
		list(
			STATE_PANIC = TRUE,
			"HasPanicRunPath" = TRUE,
		),
		list(
			NEED_COVER = NEED_SATISFIED,
			NEED_OBEDIENCE = NEED_SATISFIED,
			NEED_COMPOSURE = NEED_SATISFIED,
			"NoPanicRunPath" = FALSE,
		),
		/mob/goai/combatant/proc/HandlePanickedRun,
		11
	)
	//AddAction("Reorient", list(), list("STATE_ORIENTED" = NEED_MAXIMUM), /mob/goai/combatant/proc/HandleReorient, 1)

	AddAction(
		"Plan Path",
		/* This is a bit convoluted: we need this step to insert new actions (Goto<Targ>/HandleObstacle<Obs>) at runtime.
		   We need to pretend this satisfies the Needs or the brain won't ever choose it.
		   The prereq on Oriented = FALSE means we won't re-do this unless we manually reset Oriented to FALSE,
		   which means the AI cannot just Plan Paths all days thinking it would make it happy - it's a one-off.
		   Now, we could use the Charges system, but that would likely be more painful (need to reinsert them back periodically).
		*/
		list(
			STATE_HASWAYPOINT = TRUE,
			STATE_DISORIENTED = TRUE,
			STATE_ORIENTED = FALSE,
			STATE_CALM = TRUE,
		),
		list(
			STATE_DISORIENTED = FALSE,
			STATE_ORIENTED = TRUE,
			NEED_COVER = NEED_SATISFIED,
			NEED_OBEDIENCE = NEED_SATISFIED,
		),
		/mob/goai/combatant/proc/HandleWaypoint,
		-1,
		PLUS_INF,
		TRUE
	)

	return actionslist


/mob/goai/combatant/Equip()
	. = ..()
	GimmeGun()
	return


/mob/goai/combatant/CreateBrain(var/list/custom_actionslist = NONE, var/list/init_memories = null, var/list/init_action = null, var/datum/brain/with_hivemind = null, var/dict/custom_personality = null)
	var/list/new_actionslist = (custom_actionslist ? custom_actionslist : actionslist)
	var/dict/new_personality = (isnull(custom_personality) ? GeneratePersonality() : custom_personality)

	var/datum/brain/concrete/combat/new_brain = new /datum/brain/concrete/combat(new_actionslist, init_memories, src.initial_action, with_hivemind, new_personality, "brain of [src]")

	new_brain.needs = (isnull(src.needs) ? new_brain.needs : src.needs)
	new_brain.states = (isnull(src.states) ? new_brain.states : src.states)
	return new_brain