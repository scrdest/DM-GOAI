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


CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_null)
	// A simple, demo/placeholder Fetcher, always returns null
	return null


CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_turfs_in_view)
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


CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_adjacent_turfs)
	// Returns a simple list of visible turfs, suitable e.g. for pathfinding.

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_adjacent_turfs is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/atom/atom_requester = requester

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
		contexts.len++; contexts[contexts.len] = ctx
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

	var/target = locate(tag_to_find)

	if(isnull(tag_to_find))
		UTILITYBRAIN_DEBUG_LOG("WARNING: could not locate tagged entity for ctxfetcher_get_tagged_target @ L[__LINE__] in [__FILE__]!")
		return null

	contexts.Add(target)
	return contexts
