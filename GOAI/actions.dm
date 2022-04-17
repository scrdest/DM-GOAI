
var/global/list/mob_actions = list(
	"Eat" = new /datum/Triple (10, list("HasFood" = 1), list(MOTIVE_FOOD = 40, "HasFood" = -1)),
	"Shop" = new /datum/Triple (10, list("Money" = 10), list("HasFood" = 1, "Money" = -10)),
	"Party" = new /datum/Triple (10, list("Money" = 11), list(MOTIVE_SLEEP = 15, "Money" = -11, "Fun" = 40)),
	"Sleep" = new /datum/Triple (10, list(MOTIVE_FOOD = 30), list(MOTIVE_SLEEP = 50)),
	//"DishWash" = new /datum/Triple (10, list("HasDirtyDishes" = 1), list("HasDirtyDishes" = -1, "HasCleanDishes" = 1)),
	"Work" = new /datum/Triple (10, list(MOTIVE_SLEEP = 1), list("Money" = 10)),
	"Idle" = new /datum/Triple (10, list(), list(MOTIVE_SLEEP = 5))
)

/proc/get_actions_agent()
	var/list/all_actions = list()
	for (var/act in mob_actions)
		all_actions.Add(act)
	return all_actions


/proc/get_preconds_agent(var/action)
	var/datum/Triple/actiondata = mob_actions[action]
	var/list/preconds = actiondata.middle
	return preconds


/proc/get_effects_agent(var/action)
	var/datum/Triple/actiondata = mob_actions[action]
	var/list/effects = actiondata.right
	return effects


/proc/check_preconds_agent(var/action, var/list/blackboard)
	var/match = 1
	var/list/preconds = get_preconds_agent(action)

	for (var/req_key in preconds)
		var/req_val = preconds[req_key]
		if (isnull(req_val))
			continue

		var/blackboard_val = (req_key in blackboard) ? blackboard[req_key] : null
		if (isnull(blackboard_val) || (blackboard_val < req_val))
			match = 0
			break


	return match


/proc/goal_checker_agent(var/pos, var/goal, var/proc/cmp_op = null)
	var/match = 1
	var/list/pos_effects = islist(pos) ? pos : get_effects_agent(pos)
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


/datum/ActionTracker
	var/tracked_action

	var/is_done = 0
	var/is_failed = 0

	var/creation_time = null
	var/last_check_time = null


/datum/ActionTracker/New(var/action)
	tracked_action = action
	var/curr_time = world.time

	creation_time = curr_time
	last_check_time = curr_time
