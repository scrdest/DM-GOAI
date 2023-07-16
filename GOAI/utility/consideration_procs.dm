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
	// A dumb Consideration input that always returns 100% activation
	return ACTIVATION_FULL


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_never)
	// A dumb Consideration input that always returns 0% activation
	return ACTIVATION_NONE


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_urand)
	// A Consideration input that returns an activation that is uniform random between 0% and 100%
	return rand() * 100


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_arg_not_null)
	// Simple binary Consideration - did we plan a path to this location (using any method)?
	// Primarily intended to 'gate' fancy planned move procs behind planning procs.
	// If there is no plan, the Utility of planned moves will be zero and the Utility of *planning* will be high-ish.
	// If there *is* a plan, the Utility of planning will be low, and the Utility of the move will depend on the tactical situation.

	var/from_ctx = consideration_args["from_context"]
	if(isnull(from_ctx))
		from_ctx = TRUE

	var/inp_key = consideration_args["input_key"] || "input"

	var/candidate = null
	try
		candidate = (from_ctx ? context[inp_key] : consideration_args[inp_key])
	catch(var/exception/e)
		DEBUGLOG_UTILITY_INPUT_FETCHERS("ERROR: [e] on [e.file]:[e.line]. <inp_key='[inp_key]'>")

	if(isnull(candidate))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_arg_not_null Candidate is null @ L[__LINE__] in [__FILE__]")
		return FALSE

	return TRUE


# ifdef GOAI_SS13_SUPPORT

CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_mobhealth_abs)
	// Returns the mob's absolute health. Duh.
	// Note that because we yeeted normalization to the Scoring logic, this will Just Work
	// for any mob, regardless of their default Health pool, as long as we set the Consideration params right.
	// This is more suitable for queries like 'this enemy deals 50 dmg, should I run?' than 'is my health low?'.
	// If you want a variant that will do the latter and not break on varedits, use `health/maxHealth` input instead.

	var/datum/utility_ai/mob_commander/requester_ai = requester

	if(isnull(requester_ai))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("Requester is not an AI (from [requester || "null"] raw val) @ L[__LINE__] in [__FILE__]")
		return null

	var/mob/pawn = requester_ai?.GetPawn()

	if(isnull(pawn))
		return null

	return pawn.health


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_mobhealth_rel)
	// Returns the mob's health as a fraction of their maxHealth.
	// This is suitable for queries like 'is my health low?'.

	var/datum/utility_ai/mob_commander/requester_ai = requester

	if(isnull(requester_ai))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("Requester is not an AI (from [requester || "null"] raw val) @ L[__LINE__] in [__FILE__]")
		return null

	var/mob/pawn = requester_ai?.GetPawn()

	if(isnull(pawn))
		return null

	if(!(pawn?.maxHealth))
		return PLUS_INF

	return (pawn.health / pawn.maxHealth)

# endif


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_manhattan_distance_to_requester)
	//
	var/datum/utility_ai/mob_commander/requester_ai = requester

	if(isnull(requester_ai))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("Requester is not an AI (from [requester || "null"] raw val) @ L[__LINE__] in [__FILE__]")
		return null

	var/atom/requester_entity = requester_ai?.GetPawn()

	if(isnull(requester_entity))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("Requesting identity is null (from [requester || "null"] raw val) @ L[__LINE__] in [__FILE__]")
		return null

	var/from_ctx = consideration_args?["from_context"]
	if(isnull(from_ctx))
		from_ctx = TRUE

	var/pos_key = consideration_args?["input_key"] || "position"

	var/raw_qry_target = (from_ctx ? context[pos_key] : consideration_args[pos_key])
	if(isnull(raw_qry_target))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_manhattan_distance_to_requester raw_qry_target is null ([raw_qry_target || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/atom/query_target = raw_qry_target
	//DEBUGLOG_UTILITY_INPUT_FETCHERS("Query target is [query_target || "null"] @ L[__LINE__] in [__FILE__]")

	if(isnull(query_target))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_manhattan_distance_to_requester query_target is null ([query_target || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/result = ManhattanDistance(requester_entity, query_target)
	//DEBUGLOG_UTILITY_INPUT_FETCHERS("ManhattanDistance input is [result || "null"] @ L[__LINE__] in [__FILE__]")
	return result


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_chebyshev_distance_to_requester)
	//
	var/datum/utility_ai/mob_commander/requester_ai = requester

	if(isnull(requester_ai))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("Requester is not an AI (from [requester || "null"] raw val) @ L[__LINE__] in [__FILE__]")
		return null

	var/atom/requester_entity = requester_ai?.GetPawn()

	if(isnull(requester_entity))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("Requesting identity is null (from [requester || "null"] raw val) @ L[__LINE__] in [__FILE__]")
		return null

	var/from_ctx = consideration_args?["from_context"]
	if(isnull(from_ctx))
		from_ctx = TRUE

	var/pos_key = consideration_args?["input_key"] || "position"

	var/raw_qry_target = (from_ctx ? context[pos_key] : consideration_args[pos_key])
	if(isnull(raw_qry_target))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_chebyshev_distance_to_requester raw_qry_target is null ([raw_qry_target || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/atom/query_target = raw_qry_target
	//DEBUGLOG_UTILITY_INPUT_FETCHERS("Query target is [query_target || "null"] @ L[__LINE__] in [__FILE__]")

	if(isnull(query_target))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_chebyshev_distance_to_requester query_target is null ([query_target || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/result = ChebyshevDistance(requester_entity, query_target)
	//DEBUGLOG_UTILITY_INPUT_FETCHERS("ManhattanDistance input is [result || "null"] @ L[__LINE__] in [__FILE__]")
	return result


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_manhattan_distance_to_tagged_target)
	//
	var/search_tag = consideration_args?["locate_tag_as_target"]

	if(isnull(search_tag))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("Target tag is null (from [search_tag || "null"] raw val) @ L[__LINE__] in [__FILE__]")
		return null

	var/atom/tag_target = locate(search_tag)

	if(isnull(tag_target))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("Tagged target not found (from [search_tag || "null"] raw val) @ L[__LINE__] in [__FILE__]")
		return null

	var/raw_qry_target = context[CTX_KEY_POSITION]
	//DEBUGLOG_UTILITY_INPUT_FETCHERS("Raw query target is [raw_qry_target || "null"] @ L[__LINE__] in [__FILE__]")

	var/atom/query_target = raw_qry_target
	//DEBUGLOG_UTILITY_INPUT_FETCHERS("Query target is [query_target || "null"] @ L[__LINE__] in [__FILE__]")

	if(isnull(query_target))
		return null

	var/result = ManhattanDistance(tag_target, query_target)
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
	var/blocked = queried_turf.IsBlocked(TRUE, FALSE)

	var/datum/utility_ai/mob_commander/requester_ai = requester

	if(isnull(requester_ai))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("Requester is not an AI (from [requester || "null"] raw val) @ L[__LINE__] in [__FILE__]")
		return null

	var/atom/requester_atom = requester_ai?.GetPawn()

	if(!isnull(requester_atom) && ChebyshevDistance(requester_atom, queried_turf) == 1)
		var/entry_dir = get_dir(requester_atom, queried_turf)
		blocked = blocked || GoaiDirBlocked(queried_turf, entry_dir)

	var/result = (!blocked)
	to_world_log("consideration_input_is_passable result is [result] @ L[__LINE__] in [__FILE__]")
	return result


/proc/_cihelper_get_requester_brain(var/requester, var/caller = null)
	var/datum/utility_ai/mob_commander/controller = requester

	if(isnull(controller))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("[caller] Controller is null ([controller || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/datum/brain/requesting_brain = controller.brain

	return requesting_brain


CONSIDERATION_CALL_SIGNATURE(/proc/_cihelper_get_brain_data)
	// This is not a 'proper' Consideration, but it has the same interface as one; it's a way of DRYing
	// the code to fetch a Memory-ized path for various ACTUAL Considerations (e.g. 'Path Exists' or 'Path Length Is...')
	// These proper Considerations should just forward their callsig to this Helper.

	var/datum/brain/requesting_brain = _cihelper_get_requester_brain(requester, "_cihelper_get_brain_data")

	if(isnull(requesting_brain))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("_cihelper_get_brain_data Brain is null ([requesting_brain || "null"]) @ L[__LINE__] in [__FILE__]")
		return FALSE

	var/input_key = "input"

	if(!isnull(consideration_args))
		input_key = consideration_args["memory_key"] || input_key

	if(isnull(input_key))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("_cihelper_get_brain_data Input Key is null ([input_key || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/source_key = "memory"

	if(!isnull(consideration_args))
		source_key = consideration_args["memory_source"] || source_key

	if(!isnull(source_key))
		source_key = lowertext(source_key)

	var/memory = null

	switch(source_key)
		if("perception", "perceptions")
			to_world_log("Fetching [input_key] from Peceptions")
			memory = requesting_brain.perceptions.Get(input_key)

		if("need", "needs")
			to_world_log("Fetching [input_key] from Needs")
			memory = requesting_brain?.needs[input_key]

		else
			to_world_log("Fetching [input_key] from Memories")
			memory = requesting_brain.GetMemoryValue(input_key)

	return memory


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_has_memory)
	var/memory = _cihelper_get_brain_data(context, requester, consideration_args)
	return !isnull(memory)


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_get_memory_value)
	var/memory = _cihelper_get_brain_data(context, requester, consideration_args)
	return memory


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_get_memory_ghost_turf)
	/*
	// Like consideration_input_get_memory_value(), but specialized to 'ghosts' in memory
	// (i.e. stuff like last known position of something as opposed to its actual location).
	*/
	var/memory = _cihelper_get_brain_data(context, requester, consideration_args)
	var/dict/position_ghost = memory

	if(isnull(position_ghost))
		return null

	var/pos_x = position_ghost[KEY_GHOST_X]
	var/pos_y = position_ghost[KEY_GHOST_Y]
	var/pos_z = position_ghost[KEY_GHOST_Z]

	var/turf/ghost_turf = locate(pos_x, pos_y, pos_z)

	var/raw_loc_type = consideration_args["type_to_fetch"]

	if(isnull(raw_loc_type))
		return ghost_turf

	var/loc_type = text2path(raw_loc_type)
	if(isnull(loc_type))
		return null

	var/found_type = locate(loc_type) in ghost_turf.contents
	return found_type


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_requester_distance_to_memory_value)
	var/atom/memory = _cihelper_get_brain_data(context, requester, consideration_args)

	if(isnull(memory))
		return PLUS_INF

	return ManhattanDistance(memory, requester)


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_candidate_in_brain)
	var/from_ctx = consideration_args["from_context"]
	if(isnull(from_ctx))
		from_ctx = TRUE

	var/pos_key = consideration_args["input_key"] || "position"

	var/candidate = (from_ctx ? context[pos_key] : consideration_args[pos_key])
	if(isnull(candidate))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_candidate_in_brain Candidate is null ([candidate || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/memory = _cihelper_get_brain_data(context, requester, consideration_args)
	var/result = memory == candidate
	return result


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_candidate_in_brain_list)
	var/from_ctx = DEFAULT_IF_NULL(consideration_args["from_context"], TRUE)

	var/pos_key = consideration_args["input_key"] || "position"
	var/candidate = null

	try
		candidate = (from_ctx ? context[pos_key] : consideration_args[pos_key])
	catch(var/exception/e)
		DEBUGLOG_UTILITY_INPUT_FETCHERS("ERROR: [e] on [e.file]:[e.line]. <pos_key='[pos_key]'>")

	if(isnull(candidate))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_candidate_in_brain_list Candidate is null ([candidate || "null"]) <from_ctx=[from_ctx] | pos_key=[pos_key]> @ L[__LINE__] in [__FILE__]")
		return null

	var/raw_memory = _cihelper_get_brain_data(context, requester, consideration_args)
	var/list/memory = raw_memory

	if(!isnull(raw_memory))
		// Throw an error if the memory is not a list
		ASSERT(!isnull(memory))

	for(var/item in memory)
		if (item == candidate)
			return TRUE

	return FALSE


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_relationship_score)
	var/datum/utility_ai/mob_commander/requester_ai = requester

	if(isnull(requester_ai))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_relationship_score requester_ai is null ([requester_ai || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/from_ctx = DEFAULT_IF_NULL(consideration_args?["from_context"], TRUE)

	var/inp_key = consideration_args?["input_key"] || "target"
	var/candidate = null

	try
		candidate = (from_ctx ? context[inp_key] : consideration_args[inp_key])
	catch(var/exception/e)
		DEBUGLOG_UTILITY_INPUT_FETCHERS("ERROR: [e] on [e.file]:[e.line]. <inp_key='[inp_key]'>")

	if(isnull(candidate))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_relationship_score Candidate is null ([candidate || "null"]) <from_ctx=[from_ctx] | inp_key=[inp_key]> @ L[__LINE__] in [__FILE__]")
		return null

	var/result = requester_ai.CheckRelationsTo(candidate)
	return result


CONSIDERATION_CALL_SIGNATURE(/proc/_cihelper_get_planned_path)
	// This is not a 'proper' Consideration, but it has the same interface as one; it's a way of DRYing
	// the code to fetch a Memory-ized path for various ACTUAL Considerations (e.g. 'Path Exists' or 'Path Length Is...')
	// These proper Considerations should just forward their callsig to this Helper.

	var/datum/brain/requesting_brain = _cihelper_get_requester_brain(requester, "_cihelper_get_planned_path")

	if(isnull(requesting_brain))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("_cihelper_get_planned_path Brain is null ([requesting_brain || "null"]) @ L[__LINE__] in [__FILE__]")
		return FALSE

	var/from_ctx = consideration_args?["from_context"]
	DEBUGLOG_UTILITY_INPUT_FETCHERS("_cihelper_get_planned_path from_ctx is [from_ctx] @ L[__LINE__] in [__FILE__]")
	if(isnull(from_ctx))
		from_ctx = TRUE

	var/pos_key = "position"

	if(!isnull(consideration_args))
		pos_key = consideration_args["input_key"] || pos_key

	var/pos = (from_ctx ? context[pos_key] : consideration_args[pos_key])
	//DEBUGLOG_UTILITY_INPUT_FETCHERS("Raw query target is [raw_qry_target || "null"] @ L[__LINE__] in [__FILE__]")

	if(isnull(pos))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("_cihelper_get_planned_path Target Pos is null ([pos || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/path = requesting_brain.GetMemoryValue(MEM_PATH_TO_POS("aitarget"))

	return path



CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_has_planned_path)
	// Simple binary Consideration - did we plan a path to this location (using any method)?
	// Primarily intended to 'gate' fancy planned move procs behind planning procs.
	// If there is no plan, the Utility of planned moves will be zero and the Utility of *planning* will be high-ish.
	// If there *is* a plan, the Utility of planning will be low, and the Utility of the move will depend on the tactical situation.

	var/path = _cihelper_get_planned_path(context, requester, consideration_args)

	if(isnull(path))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_has_planned_path Path is null @ L[__LINE__] in [__FILE__]")
		var/default = consideration_args["default"]
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_has_planned_path Path defaulted to [default || "null"] @ L[__LINE__] in [__FILE__]")
		return default

	return TRUE



CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_is_on_chunkpath)
	// Simple binary Consideration - did we plan a path to this location (using any method)?
	// Primarily intended to 'gate' fancy planned move procs behind planning procs.
	// If there is no plan, the Utility of planned moves will be zero and the Utility of *planning* will be high-ish.
	// If there *is* a plan, the Utility of planning will be low, and the Utility of the move will depend on the tactical situation.

	var/from_ctx = consideration_args["from_context"]
	if(isnull(from_ctx))
		from_ctx = TRUE

	var/pos_key = consideration_args["input_key"] || "position"
	var/candidate = (from_ctx ? context[pos_key] : consideration_args[pos_key])

	if(isnull(candidate))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_is_on_chunkpath Candidate is null @ L[__LINE__] in [__FILE__]")
		return FALSE

	var/list/path = _cihelper_get_planned_path(context, requester, consideration_args)

	if(isnull(path))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_is_on_chunkpath Path is null @ L[__LINE__] in [__FILE__]")
		return FALSE

	for(var/datum/chunk/path_chunk in path)
		if(isnull(path_chunk))
			continue

		if(path_chunk.ContainsAtom(candidate))
			return TRUE

	return FALSE



CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_is_on_chunkpath_gradient)
	// Funkier variant of consideration_input_is_on_chunkpath - instead of a boolean, we'll return
	// *the number of path elements left from the last matching position*.
	//
	// Okay, that sounds complicated. Breaking this down - if our candidate is in the last path position,
	// we return 0 - because there's zero steps to travel left after we are there == it's the closest.
	//
	// If our candidate is not on the path at all, we return the length of the whole path (b/c we'd first
	// have to get on the path, then traverse it all).
	//
	// We go through all this trouble because this yields itself nicely to optimization - we know the best case
	// (if it's zero), and everything beyond that is incrementally worse, so we can avoid that with anti<foo> curves.
	//
	// If we tried to maximize a number instead of minimizing that, we would have a problem as we'd have to a priori
	// know the distance to the target on the best possible path, which kinda goes against the whole 'needing pathfinding' idea.

	var/from_ctx = consideration_args["from_context"]
	if(isnull(from_ctx))
		from_ctx = TRUE

	var/pos_key = consideration_args["input_key"] || "position"
	var/candidate = (from_ctx ? context[pos_key] : consideration_args[pos_key])

	if(isnull(candidate))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_is_on_chunkpath Candidate is null @ L[__LINE__] in [__FILE__]")
		return FALSE

	var/list/path = _cihelper_get_planned_path(context, requester, consideration_args)

	if(isnull(path))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_is_on_chunkpath Path is null @ L[__LINE__] in [__FILE__]")
		return FALSE

	for(var/path_idx = path.len + 0, path_idx > 0, path_idx--)
		var/datum/chunk/path_chunk = path[path_idx]

		if(path_chunk?.ContainsAtom(candidate))
			return path.len - path_idx

	return path.len



CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_is_on_path_gradient)
	// Like consideration_input_is_on_chunkpath_gradient, but works on precise (turf-level) paths instead.

	// The higher this is, the more permissive we are;
	// At 0, only turfs EXACTLY on the path are allowed to terminate.
	// At 1, we can be on the path or adjacent
	// At 2+, it's effectively chunking but with dynamic tile positions (so not cacheable)

	var/from_ctx = consideration_args["from_context"]
	if(isnull(from_ctx))
		from_ctx = TRUE

	var/min_dist_to_path = consideration_args["minimum_distance_to_path_tile"]
	if(isnull(min_dist_to_path))
		min_dist_to_path = 0

	var/pos_key = consideration_args["input_key"] || "position"
	var/candidate = (from_ctx ? context[pos_key] : consideration_args[pos_key])

	if(isnull(candidate))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_is_on_path_gradient Candidate is null @ L[__LINE__] in [__FILE__]")
		return FALSE

	var/list/path = _cihelper_get_planned_path(context, requester, consideration_args)

	if(isnull(path))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_is_on_path_gradient Path is null @ L[__LINE__] in [__FILE__]")
		return FALSE

	for(var/path_idx = path.len + 0, path_idx > 0, path_idx--)
		var/turf/T = path[path_idx]

		if(get_dist(T, candidate) <= min_dist_to_path)
			return path.len - path_idx

	return path.len


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_in_line_of_sight)
	var/datum/utility_ai/mob_commander/requester_ai = requester

	if(isnull(requester_ai))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_in_line_of_sight requester_ai is null ([requester_ai || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/mob/pawn = requester_ai?.GetPawn()

	if(isnull(pawn))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_in_line_of_sight Pawn is null @ L[__LINE__] in [__FILE__]")
		return null

	var/from_ctx = consideration_args["from_context"]
	if(isnull(from_ctx))
		from_ctx = TRUE

	var/pos_key = consideration_args["input_key"] || "position"
	var/candidate = (from_ctx ? context[pos_key] : consideration_args[pos_key])

	if(isnull(candidate))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_input_in_line_of_sight Candidate is null @ L[__LINE__] in [__FILE__]")
		return FALSE

	var/forecasted_impactee = AtomDensityRaytrace(pawn, candidate, list(pawn))

	return ( (forecasted_impactee == candidate) )//|| (get_dist(forecasted_impactee, candidate) == 0) )
