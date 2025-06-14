// lazily initialized by the first AI to register itself
GLOBAL_LIST_EMPTY(global_goai_registry)

# define IS_REGISTERED_AI(id) GLOBAL_ARRAY_LOOKUP_BOUNDS_CHECK(id, global_goai_registry)

/proc/deregister_ai(var/id, var/delete_ai=TRUE, var/delete_ai_brain=TRUE)
	// Deletes the AI and deregisters it from the global.

	if(!(GOAI_LIBBED_GLOB_ATTR(global_goai_registry)))
		return

	if(!(IS_REGISTERED_AI(id)))
		return

	var/datum/utility_ai/ai = GOAI_LIBBED_GLOB_ATTR(global_goai_registry[id])

	/* We want only valid AIs here; if somehow we get a non-AI here,
	// we want to null it out; regular nulls stay nulls.
	*/

	// Leave a 'hole' in the global list - the indices should NOT be mutable!
	// (the registry is a babby's first SparseSet)
	GOAI_LIBBED_GLOB_ATTR(global_goai_registry[id]) = null

	if(ai)
		if(delete_ai_brain && ai.brain)
			qdel(ai.brain)
			ai.brain = null

		if(delete_ai)
			qdel(ai)

	return



/datum/utility_ai/proc/RegisterAI()
	// Registry pattern, to facilitate querying all GOAI AIs in verbs

	if(isnull(GOAI_LIBBED_GLOB_ATTR(global_goai_registry)))
		GOAI_LIBBED_GLOB_ATTR(global_goai_registry) = list()

	if(src.registry_index)
		// already done, fix up the registry to be sure and return
		GOAI_LIBBED_GLOB_ATTR(global_goai_registry[src.registry_index]) = src
		return GOAI_LIBBED_GLOB_ATTR(global_goai_registry)

	GOAI_LIBBED_GLOB_ATTR(global_goai_registry) += src
	src.registry_index = GOAI_LIBBED_GLOB_ATTR(global_goai_registry.len)

	if(!(src.name))
		src.name = src.registry_index

	return GOAI_LIBBED_GLOB_ATTR(global_goai_registry)
