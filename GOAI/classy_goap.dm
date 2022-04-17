/datum/GOAP
	var/list/actions
	var/proc/goal_cmp_op = /proc/greater_or_equal_than
	var/proc/get_actions = /datum/GOAP/proc/get_actions
	var/proc/get_preconditions = /datum/GOAP/proc/get_preconditions
	var/proc/get_effects = /datum/GOAP/proc/get_effects
	var/proc/handle_backtrack = /datum/GOAP/proc/handle_backtrack
	var/proc/goal_checker = /datum/GOAP/proc/goal_checker
	var/proc/check_preconds = /datum/GOAP/proc/check_preconds


/datum/GOAP/proc/get_actions()
	var/list/all_actions = list()
	for (var/act in src.actions)
		all_actions.Add(act)

	return all_actions


/datum/GOAP/proc/get_preconditions(var/action)
	var/datum/Triple/actiondata = src.actions[action]
	var/list/preconds = actiondata.middle
	return preconds


/datum/GOAP/proc/get_effects(var/action)
	var/datum/Triple/actiondata = src.actions[action]
	var/list/preconds = actiondata.right
	return preconds


/datum/GOAP/proc/goal_checker(var/pos, var/goal, var/proc/cmp_op = null)
	var/match = 1
	var/list/pos_effects = islist(pos) ? pos : src.get_effects(pos)
	var/proc/comparison = cmp_op ? cmp_op : /proc/greater_or_equal_than

	for (var/state in goal)
		var/goal_val = goal[state]

		if (isnull(goal_val))
			continue

		var/curr_value = (state in pos_effects) ? pos_effects[state] : 0

		var/cmp_result = call(comparison)(curr_value, goal_val)

		if (cmp_result <= 0)
			match = 0
			break

	return match


/datum/GOAP/proc/check_preconds(var/action, var/list/blackboard)
	var/list/preconds = src.get_preconditions(action)
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


/datum/GOAP/proc/handle_backtrack()
	return


/datum/GOAP/New(var/list/actionspace, var/proc/cmp_op = null)
	actions = actionspace
	goal_cmp_op = cmp_op



/datum/GOAP/proc/plan(var/list/start, var/list/goal, var/iter_cutoff, var/datum/GOAP/instance)
	var/list/params = list()
	// You don't have to pass args like this; this is just to make things a bit more readable.
	params["graph"] = actions
	params["start"] = start
	params["goal"] = goal
	params["adjacent"] = instance.get_actions
	params["check_preconds"] = instance.get_preconditions
	params["handle_backtrack"] = instance.handle_backtrack
	//params["handle_backtrack_target"] = src
	/*params["paths"] = null
	params["visited"] = null
	params["neighbor_measure"] = null
	params["goal_measure"] = null*/
	params["goal_check"] = goal_checker
	params["get_effects"] = get_effects
	params["cutoff_iter"] = iter_cutoff
	params["owner"] = instance

	var/datum/Tuple/result = Plan(arglist(params))
	var/list/plan = result ? result.right : null

	return plan



