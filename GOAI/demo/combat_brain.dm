
/datum/brain/concrete/combat


/datum/brain/concrete/combat/New(var/list/actions)
	..()

	needs = list()
	needs[NEED_COVER] = NEED_MINIMUM

	var/spawn_time = world.time
	last_need_update_times = list()
	last_mob_update_time = spawn_time
	last_action_update_time = spawn_time

	actionslist = actions

	var/datum/GOAP/demoGoap/new_planner = new /datum/GOAP/demoGoap(actionslist)
	planner = new_planner
