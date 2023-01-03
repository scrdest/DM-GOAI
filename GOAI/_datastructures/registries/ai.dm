// lazily initialized by the first AI to register itself
var/global/list/global_goai_registry

# define IS_REGISTERED_AI(id) (id && global_goai_registry && (id <= global_goai_registry.len))

/proc/deregister_ai(var/id, var/delete_ai=TRUE, var/delete_ai_brain=TRUE)
	// Deletes the AI and deregisters it from the global.

	if(!(global_goai_registry))
		return

	if(!(IS_REGISTERED_AI(id)))
		return

	var/datum/goai/ai = global_goai_registry[id]

	/* We want only valid AIs here; if somehow we get a non-AI here,
	// we want to null it out; regular nulls stay nulls.
	*/

	// Leave a 'hole' in the global list - the indices should NOT be mutable!
	// (the registry is a babby's first SparseSet)
	global_goai_registry[id] = null

	if(ai)
		if(delete_ai_brain && ai.brain)
			qdel(ai.brain)
			ai.brain = null

		if(delete_ai)
			qdel(ai)

	return



/datum/goai/proc/RegisterAI()
	// Registry pattern, to facilitate querying all GOAI AIs in verbs

	global_goai_registry += src
	src.registry_index = global_goai_registry.len

	if(!(src.name))
		src.name = src.registry_index

	return global_goai_registry
