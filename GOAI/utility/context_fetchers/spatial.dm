
CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_in_pawn_turf)
	// Stuff wot is where we stand

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_in_pawn_turf is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/datum/utility_ai/mob_commander/requester_ai = requester

	if(isnull(requester_ai))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_in_pawn_turf is not an AI @ L[__LINE__] in [__FILE__]!")
		return null

	var/atom/atom_requester = requester_ai.GetPawn()

	if(!istype(atom_requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: pawn for ctxfetcher_in_pawn_turf is not an atom! @ L[__LINE__] in [__FILE__]!")
		return null

	var/turf/requester_tile = get_turf(atom_requester)

	if(isnull(requester_tile))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_in_pawn_turf does not have a turf position! @ L[__LINE__] in [__FILE__]!")
		return null

	var/list/contexts = list()
	var/context_key = context_args?["output_context_key"] || "position"
	var/raw_type = context_args?[CTX_KEY_FILTERTYPE]
	var/require_filtered_type = DEFAULT_IF_NULL(context_args?["require_filtered_type"], TRUE)
	var/filter_output_key = null

	var/filter_type = null

	if(!isnull(raw_type))
		filter_type = text2path(raw_type)
		filter_output_key = context_args?["filter_output_key"]

	var/list/ctx = list()
	var/found_type = null

	if(filter_type)
		found_type = locate(filter_type) in requester_tile.contents
		if(!isnull(found_type) && !isnull(filter_output_key))
			ctx[filter_output_key] = found_type

	if(!isnull(found_type) || !(filter_type && require_filtered_type))
		ctx[context_key] = requester_tile
		contexts[++(contexts.len)] = ctx

	//UTILITYBRAIN_DEBUG_LOG("INFO: added position #[posidx] [pos] context [ctx] (len: [ctx?.len]) to contexts (len: [contexts.len]) @ L[__LINE__] in [__FILE__]!")

	return contexts


CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_turfs_in_view)
	// Returns a simple list of visible turfs, suitable e.g. for pathfinding.

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_turfs_in_view is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/datum/utility_ai/mob_commander/requester_ai = requester

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_turfs_in_view is not an AI @ L[__LINE__] in [__FILE__]!")
		return null

	var/datum/brain/requesting_brain = requester_ai.brain

	if(!istype(requesting_brain))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requesting_brain for ctxfetcher_turfs_in_view is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/min_dist = context_args["min_dist"]
	var/max_dist = context_args["max_dist"]
	var/no_dense = context_args["no_dense"] || FALSE

	var/list/contexts = list()
	var/context_key = context_args["output_context_key"] || "position"
	var/raw_type = context_args?[CTX_KEY_FILTERTYPE]
	var/filter_output_key = null

	var/filter_type = null

	if(!isnull(raw_type))
		filter_type = text2path(raw_type)
		filter_output_key = context_args?["filter_output_key"]

	var/list/curr_view = requesting_brain.perceptions[SENSE_SIGHT_CURR]

	var/atom/pawn = requester_ai.GetPawn()
	var/valid_pawn = istype(pawn)

	var/valid_min_dist = (!isnull(min_dist) && valid_pawn)
	var/valid_max_dist = (!isnull(max_dist) && valid_pawn)

	if(!istype(curr_view))
		UTILITYBRAIN_DEBUG_LOG("WARNING: curr_view for ctxfetcher_turfs_in_view is not a list @ L[__LINE__] in [__FILE__]!")
		return contexts

	for(var/turf/pos in curr_view)
		if(isnull(pos))
			continue

		if(no_dense && pos.density)
			continue

		if(valid_min_dist || valid_max_dist)
			var/pos_dist = get_dist(pawn, pos)

			if(valid_min_dist && pos_dist < min_dist)
				continue

			if(valid_max_dist && pos_dist > max_dist)
				continue

		var/list/ctx = list()

		if(filter_type)
			var/found_type = locate(filter_type) in pos.contents

			if(isnull(found_type))
				continue

			if(!isnull(filter_output_key))
				ctx[filter_output_key] = found_type

		ctx[context_key] = pos
		contexts[++(contexts.len)] = ctx

	return contexts


CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_adjacent_turfs)
	// Returns a simple list of visible turfs, suitable e.g. for pathfinding.

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_turfs_in_view is null @ L[__LINE__] in [__FILE__]!")
		return null

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_turfs_in_view is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/datum/utility_ai/requester_ai = requester

	if(!istype(requester_ai))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_turfs_in_view is not an AI @ L[__LINE__] in [__FILE__]!")
		return null

	var/atom/atom_requester = requester_ai.GetPawn()

	if(!istype(atom_requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: pawn for ctxfetcher_adjacent_turfs is not an atom! @ L[__LINE__] in [__FILE__]!")
		return null

	var/list/contexts = list()
	var/context_key = context_args["output_context_key"] || "position"
	var/raw_type = context_args?[CTX_KEY_FILTERTYPE]
	var/filter_output_key = null

	var/filter_type = null

	if(!isnull(raw_type))
		filter_type = text2path(raw_type)
		filter_output_key = context_args?["filter_output_key"]

	// only output the filter value - mostly for adapting to procs that only take one arg
	var/filter_only = context_args?["filter_only"] || FALSE

	for(var/turf/pos in trangeGeneric(1, atom_requester.x, atom_requester.y, atom_requester.z))
		if(isnull(pos))
			continue

		var/list/ctx = list()

		if(filter_type)
			var/found_type = locate(filter_type) in pos.contents

			if(isnull(found_type))
				continue

			if(!isnull(filter_output_key))
				ctx[filter_output_key] = found_type

		if(!filter_only)
			ctx[context_key] = pos

		contexts[++(contexts.len)] = ctx
		//UTILITYBRAIN_DEBUG_LOG("INFO: added position #[posidx] [pos] context [ctx] (len: [ctx?.len]) to contexts (len: [contexts.len]) @ L[__LINE__] in [__FILE__]!")

	return contexts


CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_cardinal_turfs)
	// Returns a simple list of adjacent turfs, suitable e.g. for pathfinding.

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_cardinal_turfs is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/datum/utility_ai/requester_ai = requester

	if(!istype(requester_ai))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_cardinal_turfs is not an AI @ L[__LINE__] in [__FILE__]!")
		return null

	var/atom/atom_requester = requester_ai.GetPawn()

	if(!istype(atom_requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: pawn for ctxfetcher_cardinal_turfs is not an atom! @ L[__LINE__] in [__FILE__]!")
		return null

	var/turf/requester_tile = get_turf(atom_requester)

	if(isnull(requester_tile))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_cardinal_turfs does not have a turf position! @ L[__LINE__] in [__FILE__]!")
		return null

	var/list/contexts = list()
	var/context_key = context_args?["output_context_key"] || "position"
	var/raw_type = context_args?[CTX_KEY_FILTERTYPE]

	// only output the filter value - mostly for adapting to procs that only take one arg
	var/filter_only = context_args?["filter_only"] || FALSE

	// include starting tile in the list
	var/add_current = context_args?["add_current"] || FALSE

	var/filter_output_key = null

	var/filter_type = null

	if(!isnull(raw_type))
		filter_type = text2path(raw_type)
		filter_output_key = context_args?["filter_output_key"]

	var/list/nearby_turfs = requester_tile.CardinalTurfs()
	if(add_current)
		nearby_turfs.Add(requester_tile)

	for(var/turf/pos in nearby_turfs)
		if(isnull(pos))
			continue

		var/list/ctx = list()

		if(filter_type)
			var/found_type = locate(filter_type) in pos.contents
			if(isnull(found_type))
				continue

			if(!isnull(filter_output_key))
				ctx[filter_output_key] = found_type

		if(!filter_only)
			ctx[context_key] = pos

		contexts[++(contexts.len)] = ctx
		//UTILITYBRAIN_DEBUG_LOG("INFO: added position #[posidx] [pos] context [ctx] (len: [ctx?.len]) to contexts (len: [contexts.len]) @ L[__LINE__] in [__FILE__]!")

	return contexts
