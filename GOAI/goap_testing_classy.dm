


/mob/verb/testGetClassyPlansSimple()
	return src.testGetClassyPlans()


/mob/proc/testGetClassyPlans(var/list/state, var/list/goals, var/cutoff)
	var/true_state = state
	var/true_goals = goals
	var/true_cutoff = cutoff

	if(!(state && state.len))
		true_state = list("HasFood" = 0, "HasDirtyDishes" = 2)

	if(!(goals && goals.len))
		//true_goals = list("Fed" = 2, "HasCleanDishes" = 2)
		true_goals = list("Money" = 20)

	if (isnull(cutoff))
		true_cutoff = 30

	var/list/test_actions = list(
		"Eat" = new /datum/Triple (10, list("HasFood" = 1, "HasCleanDishes" = 1), list("HasDirtyDishes" = 1, "HasCleanDishes" = -1, "Fed" = 1, "HasFood" = -1)),
		"Shop" = new /datum/Triple (10, list("Money" = 10), list("HasFood" = 1, "Money" = -10)),
		"Party" = new /datum/Triple (10, list("Money" = 11), list("Rested" = 1, "Money" = -11, "Fun" = 4)),
		"Sleep" = new /datum/Triple (10, list("Fed" = 1), list("Rested" = 10)),
		"DishWash" = new /datum/Triple (10, list("HasDirtyDishes" = 1, "Rested" = 1), list("HasDirtyDishes" = -1, "HasCleanDishes" = 1, "Rested" = -1)),
		"Work" = new /datum/Triple (10, list("Rested" = 1), list("Money" = 10)),
		"Idle" = new /datum/Triple (10, list(), list("Rested" = 1))
	)

	var/datum/GOAP/goap_brain = new /datum/GOAP(test_actions)

	var/list/path = goap_brain.plan(true_state, true_goals, true_cutoff, goap_brain)

	if (path)
		world << "Path: [path] ([path.len])"
		for (var/act in path)
			world << "Step: [act]"

	else
		world << "NO PATH FOUND!"

	world << "   "
