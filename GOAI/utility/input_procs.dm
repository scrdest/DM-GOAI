/*
// A Consideration is a Utility scorer that takes in Inputs and produces Activations.
// This file is a library of Inputs that can be plugged into Considerations.
// The API is very simple - an Input is a plain-old proc. It takes in an assoc list (or null) and optionally any type representing the logical 'owner' of the decision
// and outputs a float representing the value to use for scoring.
// The float will be normalized downstream by the Consideration's parameters, so you don't need to worry about that.
*/

# define DEBUG_UTILITY_INPUT_FETCHERS 1

# ifdef DEBUG_UTILITY_INPUT_FETCHERS
# define DEBUGLOG_UTILITY_INPUT_FETCHERS(X) to_world_log(X)
# else
# define DEBUGLOG_UTILITY_INPUT_FETCHERS(X)
# endif


// Macro-ized callsig to make it easy/mandatory to use the proper API conventions
// For those less familiar with macros, pretend this is a normal proc definition with context/requester/consideration_args as params.
# define CONSIDERATION_CALL_SIGNATURE(procpath) ##procpath(var/list/context = null, var/requester = null, var/list/consideration_args = null)


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_always)
	// A dumb debug Consideration input that always returns 100% activation
	return ACTIVATION_FULL


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_urand)
	// A Consideration input that returns an activation that is uniform random between 0% and 100%
	return rand() * 100


# ifdef GOAI_SS13_SUPPORT

CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_mobhealth_abs)
	// Returns the mob's absolute health. Duh.
	// Note that because we yeeted normalization to the Scoring logic, this will Just Work
	// for any mob, regardless of their default Health pool, as long as we set the Consideration params right.
	// This is more suitable for queries like 'this enemy deals 50 dmg, should I run?' than 'is my health low?'.
	// If you want a variant that will do the latter and not break on varedits, use `health/maxHealth` input instead.
	var/mob/pawn = requester

	if(isnull(pawn))
		return null

	return mob.health


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_mobhealth_rel)
	// Returns the mob's health as a fraction of their maxHealth.
	// This is suitable for queries like 'is my health low?'.
	var/mob/pawn = requester

	if(isnull(pawn))
		return null

	if(!(mob?.maxHealth))
		return PLUS_INF

	return (mob.health / mob.maxHealth)

# endif


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_manhattan_distance_to_requester)
	//
	var/atom/requester_entity = requester

	if(isnull(requester_entity))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("Requesting identity is null (from [requester || "null"] raw val) @ L[__LINE__] in [__FILE__]")
		return null

	var/raw_qry_target = context[CTX_KEY_POSITION]
	//DEBUGLOG_UTILITY_INPUT_FETCHERS("Raw query target is [raw_qry_target || "null"] @ L[__LINE__] in [__FILE__]")

	var/atom/query_target = raw_qry_target
	//DEBUGLOG_UTILITY_INPUT_FETCHERS("Query target is [query_target || "null"] @ L[__LINE__] in [__FILE__]")

	if(isnull(query_target))
		return null

	var/result = ManhattanDistance(requester_entity, query_target)
	//DEBUGLOG_UTILITY_INPUT_FETCHERS("ManhattanDistance input is [result || "null"] @ L[__LINE__] in [__FILE__]")
	return result



CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_is_passable)
	//
	var/default_from_arg = consideration_args?["default"]
	var/default = isnull(default_from_arg) ? TRUE : default_from_arg

	var/raw_queried_object = context[CTX_KEY_POSITION]
	//DEBUGLOG_UTILITY_INPUT_FETCHERS("Raw query target is [raw_qry_target || "null"] @ L[__LINE__] in [__FILE__]")

	var/turf/queried_turf = raw_queried_object
	//DEBUGLOG_UTILITY_INPUT_FETCHERS("Query target is [query_target || "null"] @ L[__LINE__] in [__FILE__]")

	if(isnull(raw_queried_object))
		return default

	var/raw_find_type = consideration_args?["locate_type_as_target"]
	var/find_type = text2path(raw_find_type)
	to_world_log("consideration_input_is_passable find_type is [find_type || "null"] ([raw_find_type || "null"]) @ L[__LINE__] in [__FILE__]")

	if(!isnull(find_type))
		var/atom/found_instance = (locate(find_type) in queried_turf.contents)

		if(isnull(found_instance))
			to_world_log("consideration_input_is_passable found_instance is null @ L[__LINE__] in [__FILE__]")
			return default

		var/datum/directional_blocker/dirblocker = found_instance.GetBlockerData(TRUE, TRUE)

		if(isnull(dirblocker))
			to_world_log("consideration_input_is_passable DirBlocker is null @ L[__LINE__] in [__FILE__]")
			return TRUE

		var/instance_result = !(dirblocker.is_active && dirblocker.block_all)
		to_world_log("consideration_input_is_passable instance_result is [instance_result] @ L[__LINE__] in [__FILE__]")
		return instance_result

	// Basic implementation not using colliders yet!!!
	var/result = !(queried_turf.IsBlocked(TRUE, FALSE))
	to_world_log("consideration_input_is_passable result is [result] @ L[__LINE__] in [__FILE__]")
	return result

