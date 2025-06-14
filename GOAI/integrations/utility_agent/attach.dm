/datum/utility_ai/proc/_announce_observer(var/event_source)
	to_world_log("[src] observed event for [event_source]")
	return


/proc/AttachUtilityCommanderTo(var/mob/M, var/datum/utility_ai/commander = null, var/type_on_new = null)
	// Attaches a Utility AI to a mob.
	// PARAMS:
	// - M: mob to attach to
	// - commander: optional; preexisting AI to attach to the mob
	// - type_on_new: optional; if creating a new AI, what type to use. Defaults to a combat mob AI.
	set waitfor = FALSE

	var/datum/utility_ai/mob_commander/new_commander = commander

	if(isnull(commander))
		var/true_newtype = type_on_new || /datum/utility_ai/mob_commander
		new_commander = new true_newtype()

	new_commander.pawn = REFERENCE_PAWN(M)

	var/dict/pawn_attachments = M.attachments

	if(isnull(pawn_attachments))
		pawn_attachments = new()
		M.attachments = pawn_attachments

	M.attachments[ATTACHMENT_CONTROLLER_BACKREF] = new_commander.registry_index
	M.attachments["commander_removeme"] = new_commander
	M.attachments["aibrain_removeme"] = new_commander.brain

	var/datum/utility_ai/mob_commander/mobcommander = new_commander
	var/is_mobcommander = istype(mobcommander)

	if(is_mobcommander)
		new_commander.name = "AI of [M?.real_name || M?.name] (#[rand(0, 100000)])"
		new_commander.brain.name = "Brain of [new_commander.name]"

	new_commander.UpdateBrain()
	new_commander.InitRelations()

	while(!GLOB)
		sleep(1)

	GLOB.mob_equipped_event.register(M, new_commander, TYPE_PROC_REF(/datum/utility_ai, _announce_observer))
	//GLOB.gun_dry_event.register(M, new_commander, TYPE_PROC_REF(/datum/utility_ai, _announce_observer))
	GLOB.shot_at_event.register(M, new_commander, TYPE_PROC_REF(/datum/utility_ai, _announce_observer))
	GLOB.meleed_by_event.register(M, new_commander, TYPE_PROC_REF(/datum/utility_ai, _announce_observer))

	/*
	GLOB.mob_equipped_event.register_global(new_commander, TYPE_PROC_REF(/datum/utility_ai, _announce_observer))
	GLOB.shot_at_event.register_global(new_commander, TYPE_PROC_REF(/datum/utility_ai, _announce_observer))
	GLOB.meleed_by_event.register_global(new_commander, TYPE_PROC_REF(/datum/utility_ai, _announce_observer))
	*/

	# ifdef GOAI_SS13_SUPPORT
	# ifdef GOAI_DELETE_SS13_AI
	var/mob/living/L = M
	if(istype(L))
		QDEL_NULL(L.ai_holder)
	# endif
	# endif
