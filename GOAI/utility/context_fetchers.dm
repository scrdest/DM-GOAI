/*
// This file is a library of ContextFetchers that can be plugged into ActionTemplates.
//
//  => MOST OF THE USAGE OF THESE FUNCTIONS WILL BE IN ACTIONTEMPLATE.DM! <=
//
// A ContextFetcher is a simple proc that (optionally) takes the parent Template and
// (optionally) whoever requested the fetch as input and returns
// an array of assoc lists (i.e. a list of key-value maps,
// with each Map representing a set of possible parameters to consider).
//
// Practically, the API is designed to give you access to both the Action's details
// and the requesting entity (mob, for mob AI, or some datum for more abstract AIs).
//
// A Fetcher is bound to 0+ ActionTemplates as a variable.
// An Action is defined as an ActionTemplate + one of the Contexts a Fetcher can return bound together.
//
// The decision engine checks all combinations of ActionTemplates and available Contexts and scores them.
// As such, Make sure you constrain the number of Contexts in the array to just those that are relevant
// AND likely to have reasonable amounts of Utility (e.g. a FireShotgun()'s ContextFetcher probably shouldn't
// return a Context for enemies that are across the map, because it's not practically worth considering).
//
*/

// Macro-ized callsig to make it easy/mandatory to use the proper API conventions
// For those less familiar with macros, pretend this is a normal proc definition with parent/requester/context_args as params.
// (ActionTemplate, Optional<Any>, Optional<assoc>) -> [{Any: Any}]
# define CTXFETCHER_CALL_SIGNATURE(procpath) ##procpath(var/datum/utility_action_template/parent = null, var/requester = null, var/list/context_args = null)
# define CTXFETCHER_FORWARD_ARGS parent, requester, context_args


CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_null)
	// A simple, demo/placeholder Fetcher, always returns null
	return null


CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_turfs_in_view)
	// Returns a simple list of visible turfs, suitable e.g. for pathfinding.

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_turfs_in_view is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/datum/utility_ai/mob_commander/requester_ai = requester

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_turfs_in_view is not an AI @ L[__LINE__] in [__FILE__]!")
		return null

	var/atom/pawn = requester_ai.GetPawn()

	var/list/contexts = list()

	for(var/turf/pos in view(pawn))
		if(isnull(pos))
			continue

		var/list/ctx = list()
		ctx[CTX_KEY_POSITION] = pos
		contexts[++(contexts.len)] = ctx
		//UTILITYBRAIN_DEBUG_LOG("INFO: added position #[posidx] [pos] context [ctx] (len: [ctx?.len]) to contexts (len: [contexts.len]) @ L[__LINE__] in [__FILE__]!")

	return contexts


CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_adjacent_turfs)
	// Returns a simple list of visible turfs, suitable e.g. for pathfinding.

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_turfs_in_view is null @ L[__LINE__] in [__FILE__]!")
		return null

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_turfs_in_view is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/datum/utility_ai/mob_commander/requester_ai = requester

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_turfs_in_view is not an AI @ L[__LINE__] in [__FILE__]!")
		return null

	var/atom/atom_requester = requester_ai.GetPawn()

	if(isnull(atom_requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_adjacent_turfs is not an atom! @ L[__LINE__] in [__FILE__]!")
		return null

	var/list/contexts = list()

	var/filter_type = null
	if(!isnull(context_args))
		var/raw_type = context_args[CTX_KEY_FILTERTYPE]
		filter_type = text2path(raw_type)

	for(var/turf/pos in trangeGeneric(1, atom_requester.x, atom_requester.y, atom_requester.z))
		if(isnull(pos))
			continue

		var/list/ctx = list()

		if(filter_type)
			var/found_type = locate(filter_type) in pos.contents
			if(isnull(found_type))
				continue

			ctx[CTX_KEY_FILTERTYPE] = found_type

		ctx[CTX_KEY_POSITION] = pos
		contexts[++(contexts.len)] = ctx
		//UTILITYBRAIN_DEBUG_LOG("INFO: added position #[posidx] [pos] context [ctx] (len: [ctx?.len]) to contexts (len: [contexts.len]) @ L[__LINE__] in [__FILE__]!")

	return contexts


CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_cardinal_turfs)
	// Returns a simple list of visible turfs, suitable e.g. for pathfinding.

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_cardinal_turfs is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/datum/utility_ai/mob_commander/requester_ai = requester

	if(isnull(requester_ai))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_cardinal_turfs is not an AI @ L[__LINE__] in [__FILE__]!")
		return null

	var/atom/atom_requester = requester_ai.GetPawn()

	var/turf/requester_tile = get_turf(atom_requester)

	if(isnull(requester_tile))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_cardinal_turfs does not have a turf position! @ L[__LINE__] in [__FILE__]!")
		return null

	var/list/contexts = list()

	var/filter_type = null
	if(!isnull(context_args))
		var/raw_type = context_args[CTX_KEY_FILTERTYPE]
		filter_type = text2path(raw_type)

	for(var/turf/pos in requester_tile.CardinalTurfs())
		if(isnull(pos))
			continue

		var/list/ctx = list()

		if(filter_type)
			var/found_type = locate(filter_type) in pos.contents
			if(isnull(found_type))
				continue

			ctx[CTX_KEY_FILTERTYPE] = found_type

		ctx[CTX_KEY_POSITION] = pos
		contexts[++(contexts.len)] = ctx
		//UTILITYBRAIN_DEBUG_LOG("INFO: added position #[posidx] [pos] context [ctx] (len: [ctx?.len]) to contexts (len: [contexts.len]) @ L[__LINE__] in [__FILE__]!")

	return contexts


CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_get_tagged_target)
	// Returns a simple list of gameobjects with the specified tag

	var/list/contexts = list()

	/*var/filter_type = null
	if(!isnull(context_args))
		var/raw_type = context_args[CTX_KEY_FILTERTYPE]
		filter_type = text2path(raw_type)*/

	var/tag_to_find = context_args["tag"]

	if(isnull(tag_to_find))
		UTILITYBRAIN_DEBUG_LOG("WARNING: tag for ctxfetcher_get_tagged_target is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/context_key = context_args["output_context_key"] || "position"
	var/target = locate(tag_to_find)

	if(isnull(tag_to_find))
		UTILITYBRAIN_DEBUG_LOG("WARNING: could not locate tagged entity for ctxfetcher_get_tagged_target @ L[__LINE__] in [__FILE__]!")
		return null

	var/list/ctx = list()
	ctx[context_key] = target

	contexts[++(contexts.len)] = ctx
	return contexts


CTXFETCHER_CALL_SIGNATURE(/proc/__ctxfetcher_get_memory_value_helper)
	// Returns a stored Memory

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for __ctxfetcher_get_memory_value_helper is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/datum/utility_ai/mob_commander/requester_ai = requester

	if(isnull(requester_ai))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for __ctxfetcher_get_memory_value_helper is not an AI @ L[__LINE__] in [__FILE__]!")
		return null

	var/datum/utility_ai/mob_commander/controller = requester

	var/input_key = context_args["key"]

	if(isnull(input_key))
		UTILITYBRAIN_DEBUG_LOG("WARNING: key for __ctxfetcher_get_memory_value_helper is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/datum/brain/requesting_brain = controller.brain

	if(isnull(requesting_brain))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requesting_brain for __ctxfetcher_get_memory_value_helper is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/memory_val = null

	var/source_key = "memory"

	if(!isnull(context_args))
		source_key = context_args["memory_source"] || source_key

	if(!isnull(source_key))
		source_key = lowertext(source_key)

	switch(source_key)
		if("perception", "perceptions")
			to_world_log("Fetching [input_key] from Peceptions")
			memory_val = requesting_brain.perceptions.Get(input_key)

		if("need", "needs")
			to_world_log("Fetching [input_key] from Needs")
			memory_val = requesting_brain?.needs[input_key]

		else
			to_world_log("Fetching [input_key] from Memories")
			memory_val = requesting_brain.GetMemoryValue(input_key)

	return memory_val


CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_get_memory_value)
	// Returns a stored Memory

	var/memory_val = __ctxfetcher_get_memory_value_helper(CTXFETCHER_FORWARD_ARGS)

	var/context_key = context_args["output_context_key"] || "memory"

	var/list/contexts = list()

	var/list/ctx = list()
	ctx[context_key] = memory_val

	contexts[++(contexts.len)] = ctx
	return contexts



CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_get_memory_value_array)
	/* Retrieves a stored Memory, expecting it to be a list.
	// If that is the case, unpacks each list item to a new context.
	//
	// This is handy if you want to build Contexts from a single Memory,
	// for example if you want to write interactables/enemies from a Sense tick
	// but evaluate each item *INDIVIDUALLY*.
	//
	// In contrast, the 'plain' ctxfetcher_get_memory_value would treat the whole
	// Memory'd list as one big Context - which is also okay for other uses (for
	// example, discouraging moving into a tile with multiple enemies having LOS to it).
	*/

	var/raw_memory_val = __ctxfetcher_get_memory_value_helper(CTXFETCHER_FORWARD_ARGS)
	var/list/memory_val = raw_memory_val

	if(!isnull(raw_memory_val))
		ASSERT(!isnull(memory_val))

	var/context_key = context_args["output_context_key"] || "memory"

	var/list/contexts = list()

	for(var/mem_item in memory_val)
		var/list/ctx = list()
		ctx[context_key] = mem_item
		contexts[++(contexts.len)] = ctx

	return contexts

