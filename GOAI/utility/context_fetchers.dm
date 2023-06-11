/*
// This file is a library of ContextFetchers that can be plugged into ActionTemplates..
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


/proc/ctxfetcher_null(var/datum/utility_action_template/parent = null, var/requester = null) // (ActionTemplate, Optional<Any>) -> [{Any: Any}]
	// A simple, demo/placeholder Fetcher, always returns null
	return null


/proc/ctxfetcher_turfs_in_view(var/datum/utility_action_template/parent = null, var/requester = null) // (ActionTemplate, Optional<Any>) -> [{Any: Any}]
	// Returns a simple list of visible turfs, suitable e.g. for pathfinding.

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_turfs_in_view is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/list/contexts = list()

	for(var/turf/pos in view(requester))
		if(isnull(pos))
			continue

		var/list/ctx = list()
		ctx[CTX_KEY_POSITION] = pos
		contexts.len++; contexts[contexts.len] = ctx
		//UTILITYBRAIN_DEBUG_LOG("INFO: added position #[posidx] [pos] context [ctx] (len: [ctx?.len]) to contexts (len: [contexts.len]) @ L[__LINE__] in [__FILE__]!")

	return contexts


/proc/ctxfetcher_adjacent_turfs(var/datum/utility_action_template/parent = null, var/requester = null) // (ActionTemplate, Optional<Any>) -> [{Any: Any}]
	// Returns a simple list of visible turfs, suitable e.g. for pathfinding.

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_adjacent_turfs is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/atom/atom_requester = requester

	if(isnull(atom_requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_adjacent_turfs is not an atom! @ L[__LINE__] in [__FILE__]!")
		return null

	var/list/contexts = list()

	for(var/turf/pos in trangeGeneric(1, atom_requester.x, atom_requester.y, atom_requester.z))
		if(isnull(pos))
			continue

		var/list/ctx = list()
		ctx[CTX_KEY_POSITION] = pos
		contexts.len++; contexts[contexts.len] = ctx
		//UTILITYBRAIN_DEBUG_LOG("INFO: added position #[posidx] [pos] context [ctx] (len: [ctx?.len]) to contexts (len: [contexts.len]) @ L[__LINE__] in [__FILE__]!")

	return contexts
