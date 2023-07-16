

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
