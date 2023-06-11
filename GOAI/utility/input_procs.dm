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

/proc/consideration_input_always(var/list/context, var/requester = null) // (<assoc>, Any) -> float
	// A dumb debug Consideration input that always returns 100% activation
	return ACTIVATION_FULL


/proc/consideration_input_urand(var/list/context, var/requester = null) // (<assoc>, Any) -> float
	// A Consideration input that returns an activation that is uniform random between 0% and 100%
	return rand() * 100


# ifdef GOAI_SS13_SUPPORT

/proc/consideration_input_mobhealth_abs(var/list/context, var/requester = null) // (<assoc>, Any) -> float
	// Returns the mob's absolute health. Duh.
	// Note that because we yeeted normalization to the Scoring logic, this will Just Work
	// for any mob, regardless of their default Health pool, as long as we set the Consideration params right.
	// This is more suitable for queries like 'this enemy deals 50 dmg, should I run?' than 'is my health low?'.
	// If you want a variant that will do the latter and not break on varedits, use `health/maxHealth` input instead.
	var/mob/pawn = requester

	if(isnull(pawn))
		return null

	return mob.health

/proc/consideration_input_mobhealth_rel(var/list/context, var/requester = null) // (<assoc>, Any) -> float
	// Returns the mob's health as a fraction of their maxHealth.
	// This is suitable for queries like 'is my health low?'.
	var/mob/pawn = requester

	if(isnull(pawn))
		return null

	if(!(mob?.maxHealth))
		return PLUS_INF

	return (mob.health / mob.maxHealth)

# endif


/proc/consideration_input_manhattan_distance_to_requester(var/list/context, var/requester = null) // (<assoc>, Any) -> float
	// Returns the mob's health as a fraction of their maxHealth.
	// This is suitable for queries like 'is my health low?'.
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

