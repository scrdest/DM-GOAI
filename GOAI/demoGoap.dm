# define PLUS_INF 1.#INF
# define GOAP_KEY_SRC "source"

# ifdef DEBUG_LOGGING
# define MAYBE_LOG(X) world.log << X
# define MAYBE_LOG_TOSTR(X) world.log << #X + ": [X]"
# else
# define MAYBE_LOG(X)
# define MAYBE_LOG_TOSTR(X)
# endif

// Demo implementation
/datum/GOAP/demoGoap


/datum/GOAP/demoGoap/update_op(var/old_val, var/new_val)
	var/result = old_val + new_val
	return result


/datum/GOAP/demoGoap/compare_op(var/curr_val, var/targ_val)
	var/result = curr_val >= targ_val
	return result


/datum/GOAP/demoGoap/neighbor_dist(var/curr_pos, var/neighbor_key)
	/* This is a simple heuristic that looks up the neighbor cost from the action triple as-is.
	//
	// o curr_pos - current position, go figure; unused, only here for interface consistency
	// o neighbor_key - string representing the candidate action/position
	// o graph - assoc list representing the action graph; should have the neighbor_key as a key innit.
	*/
	var/cost = PLUS_INF
	var/datum/Triple/action_data = (neighbor_key in graph) ? graph[neighbor_key] : null
	if (action_data && action_data.left)
		cost = action_data.left

	return cost


/datum/GOAP/demoGoap/goal_dist(var/start, var/end)
	/* This is a heuristic that fuzzes the default uniform value by a random small amount.
	// This is a variant of the default_dist so all the same caveats apply.
	//
	// This stops the search from getting stuck on one action in all iterations in some cases,
	// but at the cost of (1) losing determinism, & (2) sometimes creating sub-optimal paths
	// (in plain terms - overly-long but still *valid* plans).
	//
	// o start - start state (current pos for neighbor measure, neighbor for goal measure)
	// o end - end state (neighbor for neighbor measure, goal for goal measure)
	// o graph - assoc list representing the action graph (not actually used here, just for consistency)
	*/
	var/cost = 0
	cost -= ((roll(1, 4) - 1) / 4) // empirically, more uniform (i.e. less rolls) randomness seems to work better for some reason
	return cost


/datum/GOAP/demoGoap/check_preconds(var/current_pos, var/list/blackboard)
	MAYBE_LOG("Current Pos: [current_pos]")
	MAYBE_LOG("Graph: [graph]")
	MAYBE_LOG("Graph @ Pos: [graph[current_pos]]")
	var/datum/Triple/actiondata = graph[current_pos]
	var/list/preconds = actiondata.middle
	var/match = 1

	for (var/req_key in preconds)
		var/req_val = preconds[req_key]
		if (isnull(req_val))
			continue

		var/blackboard_val = (req_key in blackboard) ? blackboard[req_key] : null
		if (isnull(blackboard_val) || (blackboard_val < req_val))
			match = 0
			break

	return match


/datum/GOAP/demoGoap/get_effects(var/action_key)
	var/datum/Triple/actiondata = graph[action_key]
	var/list/effects = actiondata.right
	return effects
