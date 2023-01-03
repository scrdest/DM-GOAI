/*
// REMINDER: GOAI Brains != organ brains.
// GOAI Brains are abstract datums and are effectively a data structure.
// Since they have their own subloop, we want to be able to clean them up
// so we don't have orphan Brains running empty loops.
*/

// lazily initialized by the first brain to register itself

var/global/list/global_aibrain_registry

# define IS_REGISTERED_AIBRAIN(id) (id && global_aibrain_registry && (id <= global_aibrain_registry.len))

/proc/deregister_ai_brain(var/id)
	// Deletes the AI Brain and deregisters it from the global.

	if(!(global_aibrain_registry))
		return

	if(!(IS_REGISTERED_AI(id)))
		return

	var/datum/brain/aibrain = global_aibrain_registry[id]

	/* We want only valid AIs here; if somehow we get a non-AI here,
	// we want to null it out; regular nulls stay nulls.
	*/

	// Leave a 'hole' in the global list - the indices should NOT be mutable!
	// (the registry is a babby's first SparseSet)
	global_aibrain_registry[id] = null

	if(aibrain)
		qdel(aibrain)

	return


/datum/brain/proc/RegisterBrain()
	// Registry pattern, to facilitate querying all GOAI Brains in verbs

	global_aibrain_registry += src
	src.registry_index = global_aibrain_registry.len

	if(!(src.name))
		src.name = src.registry_index

	return global_aibrain_registry
