
/sense/combatant_commander_utility_wayfinder


/sense/combatant_commander_utility_wayfinder/proc/DraftMoveToPrecise(var/datum/utility_ai/mob_commander/owner, var/atom/position, var/max_node_depth = null, var/min_target_dist = null, var/path_ttl = null)
	if(!(owner && istype(owner)))
		RUN_ACTION_DEBUG_LOG("[src] does not have an owner! <[owner]>")
		return

	var/datum/brain/owner_brain = owner.brain
	if(!(owner_brain && istype(owner_brain)))
		RUN_ACTION_DEBUG_LOG("[owner] does not have a brain! <[owner_brain]>")
		return

	var/atom/target_pos = position

	if(isnull(target_pos))
		target_pos = owner_brain.GetMemoryValue("ai_target", null, FALSE, TRUE, TRUE)

	if(isnull(target_pos))
		RUN_ACTION_DEBUG_LOG("Target position is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	var/atom/pawn = owner.GetPawn()

	if(isnull(pawn))
		RUN_ACTION_DEBUG_LOG("Pawn is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	var/_max_node_depth = DEFAULT_IF_NULL(max_node_depth, 60)
	var/_min_target_dist = DEFAULT_IF_NULL(min_target_dist, 1)
	var/_path_ttl = DEFAULT_IF_NULL(path_ttl, 100)

	var/list/path = GoaiAStar(
		start = get_turf(pawn),
		end = get_turf(target_pos),
		adjacent = /proc/fCardinalTurfsNoblocks,
		dist = DEFAULT_GOAI_DISTANCE_PROC,
		max_nodes = 0,
		max_node_depth = _max_node_depth,
		min_target_dist = _min_target_dist,
		min_node_dist = null,
		adj_args = null,
		exclude = null
	)

	if(isnull(path))
		RUN_ACTION_DEBUG_LOG("Path is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	owner_brain.SetMemory(MEM_PATH_TO_POS("aitarget"), path, _path_ttl)
	owner_brain.SetMemory(MEM_PATH_ACTIVE, path, _path_ttl)

	return path


/sense/combatant_commander_utility_wayfinder/ProcessTick(var/owner)
	..(owner)

	if(processing)
		return

	processing = TRUE

	src.DraftMoveToPrecise(owner)

	spawn(src.GetOwnerAiTickrate(owner) * 10)
		// Sense-side delay to avoid spamming view() scans too much
		processing = FALSE
	return

