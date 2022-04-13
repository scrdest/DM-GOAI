# define PLUS_INF 1.#INF
# define GOAP_KEY_SRC "source"

/proc/AddItem(var/oldval, var/newval)
	if(isnull(newval) || newval == 0)
		return oldval
	var/total = oldval + newval
	world.log << "OLDV [oldval] + NEWV [newval] = [total]"
	return total


/proc/update_counts(var/list/old_state, var/list/new_state, var/default = 0, var/proc/op = null)
	var/proc/update_op = isnull(op) ? /proc/AddItem : op
	var/list/result_state = old_state.Copy()

	for (var/key in new_state)
		if (key == GOAP_KEY_SRC)
			continue
		var/old_val = (key in result_state) ? result_state[key] : default
		world.log << "UpdKey: [key], [result_state[key]], [old_val]"
		var/add_val = new_state[key]
		var/result = call(update_op)(old_val, add_val)

		//if((!(key in old_state)) || (result != 0))
		result_state[key] = result

	return result_state


/proc/action_graph_dist(var/start, var/end, var/list/graph, var/default_cost = 0)
	var/cost = default_cost
	/* UNFINISHED! */
	cost += roll(1, 2) - 1
	return cost


/proc/graph_neighbor_cost(var/curr_pos, var/neighbor_key, var/list/graph)
	var/cost = PLUS_INF
	var/datum/Triple/action_data = (neighbor_key in graph) ? graph[neighbor_key] : null
	if (action_data && action_data.left)
		cost = action_data.left

	return cost


/proc/evaluate_neighbor(var/list/graph, var/proc/check_preconds, var/neigh, var/current_pos, var/goal, var/list/blackboard = null, var/blackboard_default = 0, var/proc/blackboard_update_op = null, var/proc/neighbor_measure = null, var/proc/goal_measure = null, var/proc/get_effects)
	var/proc/actual_neigh_measure = neighbor_measure ? neighbor_measure : /proc/graph_neighbor_cost
	var/proc/actual_goal_measure = goal_measure ? goal_measure : /proc/action_graph_dist
	var/list/actual_blackboard = blackboard ? blackboard : list()

	var/is_valid = call(check_preconds)(neigh, actual_blackboard)

	var/effects = actual_blackboard.Copy()
	var/list/curr_source = (GOAP_KEY_SRC in effects) ? effects[GOAP_KEY_SRC].Copy() : list()
	curr_source.Add(current_pos)

	effects[GOAP_KEY_SRC] = curr_source

	var/datum/Tuple/result = null
	if (!is_valid)
		result = new /datum/Tuple(PLUS_INF, effects)
		return result

	if (get_effects)
		var/list/new_effects = call(get_effects)(neigh)
		effects = update_counts(effects, new_effects, blackboard_default, blackboard_update_op)

	var/neigh_distance = call(actual_neigh_measure)(current_pos, neigh, graph)
	var/goal_distance = call(actual_goal_measure)(neigh, goal)

	var/heuristic = neigh_distance + goal_distance

	result = new /datum/Tuple(heuristic, effects)
	return result


/proc/rebuild_effects(graph, action_plan, get_effects, blackboard_default = 0, blackboard_update_op = null)
	// MISBEHAVING!!!
	var/list/rebuilt_blackboard = list()

	for (var/action in action_plan)
		world.log << "REBUILD ACT [action]"
		var/list/act_effects = list()

		if (islist(action))
			var/list/state = action
			var/is_state = 0

			for (var/stitm in state)
				world.log << "STITM [stitm]"

				if (stitm in graph)
					var/list/statitm_fx = call(get_effects)(stitm)
					act_effects = update_counts(act_effects, statitm_fx, blackboard_default, blackboard_update_op)

				else
					is_state = 1

			if (is_state)
				act_effects = update_counts(act_effects, state, blackboard_default, blackboard_update_op)

		else
			act_effects = call(get_effects)(action)

		rebuilt_blackboard = update_counts(rebuilt_blackboard, act_effects, blackboard_default, blackboard_update_op)

	return rebuilt_blackboard



/datum/State
	var/list/L


/datum/State/New(var/state_vars)
	L = state_vars


/datum/Tuple
	var/left = null
	var/right = null


/datum/Tuple/New(var/fst, var/snd)
	left = fst
	right = snd


/datum/Triple
	var/left = null
	var/middle = null
	var/right = null


/datum/Triple/New(var/new_left, var/new_mid, var/new_right)
	left = new_left
	middle = new_mid
	right = new_right


/datum/Quadruple
	var/first = null
	var/second = null
	var/third = null
	var/fourth = null


/datum/Quadruple/New(var/new_first, var/new_second, var/new_third, var/new_fourth)
	first = new_first
	second = new_second
	third = new_third
	fourth = new_fourth



/datum/Quadruple/proc/QuadCompare(var/datum/Quadruple/left, var/datum/Quadruple/right)
	// returns 1 if Right > Left
	// returns -1 if Right < Left
	// return 0 if Right == Left

	if (right.first > left.first)
		return 1

	if (right.first < left.first)
		return -1

	if (right.second > left.second)
		return 1

	if (right.second < left.second)
		return -1

	if (right.third > left.third)
		return 1

	if (right.third < left.third)
		return -1

	if (right.fourth > left.fourth)
		return 1

	if (right.fourth < left.fourth)
		return -1

	return 0



/datum/Quadruple/proc/ActionCompare(var/datum/Quadruple/left, var/datum/Quadruple/right)
	// returns 1 if Right > Left
	// returns -1 if Right < Left
	// return 0 if Right == Left

	if (right.first > left.first)
		return 1

	if (right.first < left.first)
		return -1

	if (right.second > left.second)
		return 1

	if (right.second < left.second)
		return -1

	return 0



/proc/SearchIteration(var/list/graph, var/list/start, var/list/goal, var/proc/adjacent, var/proc/check_preconds, var/paths = null, var/PriorityQueue/queue = null, var/visited = null, var/proc/neighbor_measure, var/proc/goal_measure, var/proc/goal_check, var/proc/get_effects, var/cutoff_iter = null, var/max_queue_size = null, var/proc/pqueue_key_gen = null, var/list/blackboard = null, var/blackboard_default = 0, var/proc/blackboard_update_op = null, var/curr_cost = 0, var/curr_iter = 0)
	world.log << "    "
	world.log << "CURR ITER: [curr_iter]"
	world.log << "CURR POS: [start]"
	var/list/_paths = isnull(paths) ? list() : paths
	var/PriorityQueue/_pqueue = isnull(queue) ? new /PriorityQueue(/datum/Quadruple/proc/ActionCompare) : queue

	world.log << "START BB is [blackboard]"
	for (var/bbitem in blackboard)
		world.log << "START BB ITEM: [bbitem] @ [blackboard[bbitem]]"

	var/list/_blackboard = isnull(blackboard) ? list() : blackboard.Copy()

	var/list/updated_state = update_counts(_blackboard, start, blackboard_default, blackboard_update_op)

	var/goal_check_result = call(goal_check)(updated_state, goal, null)
	if (goal_check_result > 0)
		world.log << "GOAL CHECK SUCCEEDED."
		var/raw_final_result = updated_state[GOAP_KEY_SRC]
		var/list/full_final_result = islist(start) ? list(raw_final_result, start) : raw_final_result + list(start)
		var/datum/Tuple/final_result = new /datum/Tuple(0, full_final_result)

		return final_result

	var/proc/neighbor_measurer = (neighbor_measure ? neighbor_measure : /proc/graph_neighbor_cost)
	var/proc/goal_measurer = (goal_measure ? goal_measure : /proc/action_graph_dist)

	if (visited)
		var/curr_visit_count = visited[start] ? visited[start] : 0
		visited[start] = curr_visit_count + 1

	var/list/neighbors = call(adjacent)(start)

	for (var/neigh in neighbors)
		if (visited && visited[neigh])
			continue

		var/datum/Tuple/evaluation = evaluate_neighbor(graph, check_preconds, neigh, start, goal, updated_state, blackboard_default, blackboard_update_op, neighbor_measurer, goal_measurer, get_effects)
		var/heuristic = evaluation.left
		var/effects = evaluation.right
		var/source = (GOAP_KEY_SRC in effects) ? effects[GOAP_KEY_SRC] : null

		var/datum/Triple/stored_data = _paths[neigh] ? _paths[neigh] : new /datum/Triple(PLUS_INF, null, null)
		var/stored_neigh_cost = stored_data.left

		var/total_cost = curr_cost + heuristic

		if (total_cost < stored_neigh_cost)
			_paths[neigh] = new /datum/Triple(total_cost, start, source)

		var/priority_key = (pqueue_key_gen ? call(pqueue_key_gen)(curr_iter, curr_cost, heuristic) : curr_iter)

		var/datum/Quadruple/cand_tuple = new /datum/Quadruple (priority_key, total_cost, neigh, source)

		if (total_cost < PLUS_INF && (!(cand_tuple in _pqueue)))
			_pqueue.Enqueue(cand_tuple)

			if (!isnull(max_queue_size))
				_pqueue.L.Cut(1, max_queue_size)

	if (_pqueue.L.len <= 0)
		world.log << "Exhausted all candidates before a path was found!"
		return


	var/datum/Quadruple/next_cand_tuple = _pqueue.Dequeue()
	var/cand_cost = next_cand_tuple.second
	var/cand_pos = next_cand_tuple.third
	world.log << "CAND: [next_cand_tuple.third]"
	var/list/source_pos = next_cand_tuple.fourth
	world.log << "CAND SRCp: [source_pos]"
	/*for (var/srcpit in source_pos)
		world.log << "SRCp item: [srcpit]"*/

	var/list/action_stack = list(source_pos ? source_pos.Copy() : list())
	action_stack.Add(cand_pos)
	/*for (var/actpit in source_pos)
		world.log << "ACTp item: [actpit]"*/

	var/cand_blackboard = rebuild_effects(graph, action_stack, get_effects, blackboard_default, blackboard_update_op)
	cand_blackboard[GOAP_KEY_SRC] = source_pos
	for (var/blit in cand_blackboard)
		world.log << "BLIT: [blit] = [cand_blackboard[blit]]"

	var/list/new_params = list()
	new_params["graph"] = graph
	new_params["start"] = cand_pos
	new_params["goal"] = goal
	new_params["adjacent"] = adjacent
	new_params["check_preconds"] = check_preconds
	new_params["paths"] = paths
	new_params["visited"] = visited
	new_params["neighbor_measure"] = neighbor_measure
	new_params["goal_measure"] = goal_measure
	new_params["goal_check"] = goal_check
	new_params["get_effects"] = get_effects
	new_params["cutoff_iter"] = cutoff_iter
	new_params["max_queue_size"] = max_queue_size
	new_params["pqueue_key_gen"] = pqueue_key_gen
	new_params["blackboard"] = cand_blackboard
	new_params["blackboard_default"] = blackboard_default
	new_params["blackboard_update_op"] = blackboard_update_op
	new_params["curr_cost"] = cand_cost
	new_params["curr_iter"] = curr_iter + 1


	var/datum/Tuple/result = new /datum/Tuple (1, new_params)
	var/list/pathli = result.right
	world.log << "Result tuple: ([result.left], [pathli] ([pathli.len]))"
	return result


/proc/Plan(var/list/graph, var/list/start, var/list/goal, var/proc/adjacent, var/proc/check_preconds, var/proc/handle_backtrack, var/paths = null, var/visited = null, var/proc/neighbor_measure, var/proc/goal_measure, var/proc/goal_check, var/proc/get_effects, var/cutoff_iter, var/max_queue_size = null, var/proc/pqueue_key_gen, var/blackboard_default = 0, var/proc/blackboard_update_op = null)
	var/curr_iter = 0
	var/continue_search = 1

	var/list/true_paths = isnull(paths) ? list() : paths
	var/list/next_params = list()
	var/datum/Tuple/result = null
	var/PriorityQueue/queue = new /PriorityQueue (/datum/Quadruple/proc/ActionCompare)

	next_params["graph"] = graph
	next_params["start"] = start
	next_params["goal"] = goal
	next_params["queue"] = queue
	next_params["adjacent"] = adjacent
	next_params["check_preconds"] = check_preconds
	next_params["paths"] = true_paths
	next_params["visited"] = visited
	next_params["neighbor_measure"] = neighbor_measure
	next_params["goal_measure"] = goal_measure
	next_params["goal_check"] = goal_check
	next_params["get_effects"] = get_effects
	next_params["cutoff_iter"] = cutoff_iter
	next_params["max_queue_size"] = max_queue_size
	next_params["pqueue_key_gen"] = pqueue_key_gen
	next_params["blackboard_default"] = blackboard_default
	next_params["blackboard_update_op"] = blackboard_update_op

	while(next_params && continue_search):
		result = SearchIteration(arglist(next_params))
		continue_search = result ? result.left : 0
		var/list/new_params = result.right

		next_params = new_params

		if (continue_search > 0)

			if (!isnull(cutoff_iter)) // 0 is *technically* valid, so let's use ifnull...
				curr_iter = curr_iter + 1
				if (curr_iter >= cutoff_iter):
					// raise NoPathError(f"Path not found within {cutoff_iter} iterations!")
					world.log << "Path not found within [cutoff_iter] iterations!"
					return


	world.log << "Broken out of the Plan loop!"
	var/datum/Triple/best_opt = result ? result.right : null
	var/best_path = best_opt

	for (var/best_path_elem in best_path)
		world.log << "BEST PATH ELEM: [best_path_elem]"

	if (handle_backtrack):
		for (var/parent_elem in best_path)
			call(handle_backtrack)(parent_elem)

	return result


/proc/GetActions(var/list/graph)
	var/list/actions = list()
	for (var/key in graph)
		actions.Add(key)

	return actions
