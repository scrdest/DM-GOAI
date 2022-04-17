
/mob/goai
	var/life = 1
	icon = 'icons/mob/human_races/r_human.dmi'
	icon_state = "preview"
	var/list/needs = list()
	var/list/actionslist
	var/list/inventory
	var/list/active_plan

	var/selected_action = null
	var/datum/ActionTracker/running_action = null

	var/last_mob_update_time
	var/last_action_update_time
	var/planning_iter_cutoff = 30


/mob/verb/InspectGoaiLife()
	var/list/targetlist = typesof(/mob/goai/agent in world)
	for(var/targtype in targetlist)
		var/mob/goai/agent/M = locate(targtype)
		usr << "[M.name] - [M.life]"


/mob/goai/agent
	var/tiredness = NEED_THRESHOLD
	var/hunger = NEED_THRESHOLD

	var/decay_per_dsecond = 0.01


/mob/goai/New()
	..()

	var/spawn_time = world.time
	last_mob_update_time = spawn_time
	last_action_update_time = spawn_time

	actionslist = get_actions_agent()

	Life()


/mob/goai/proc/Life()
	return 1


/mob/goai/agent/verb/DoAction(Act as anything in actionslist)
	world.log << "DoAction act: [Act]"

	if(!(Act in actionslist))
		return null

	var/datum/ActionTracker/new_action = new /datum/ActionTracker(Act)
	world.log << "New Tracker: [new_action] [new_action.tracked_action] @ [new_action.creation_time]"
	running_action = new_action

	return running_action


/mob/goai/agent/proc/CreatePlan(var/list/status, var/list/goal)
	var/list/path = null

	var/list/params = list()
	// You don't have to pass args like this; this is just to make things a bit more readable.
	params["graph"] = mob_actions
	params["start"] = status
	params["goal"] = goal
	params["adjacent"] = /proc/get_actions_agent
	params["check_preconds"] = /proc/check_preconds_agent
	params["goal_check"] = /proc/goal_checker_agent
	params["get_effects"] = /proc/get_effects_agent
	params["cutoff_iter"] = planning_iter_cutoff


	var/datum/Tuple/result = Plan(arglist(params))

	if (result)
		path = result.right

	return path


/mob/goai/agent/Life()
	while(src.life)
		TirednessDecay()
		HungerDecay()

		if(tiredness < NEED_THRESHOLD && prob(10))
			world << "[src.name] *yawn*"

		if(hunger < NEED_THRESHOLD && prob(10))
			world << "[src.name] *rumble*"

		src.needs[MOTIVE_SLEEP] = src.tiredness
		src.needs[MOTIVE_FOOD] = src.hunger

		if(running_action) // processing action
			world << "ACTIVE ACTION: [running_action.tracked_action]"
			var/running_is_finished = 0

			if(running_action.is_done)
				running_is_finished = 1

			else if(running_action.is_failed)
				running_is_finished = 1

			if(running_is_finished)
				running_action = null

		else if(selected_action) // ready to go
			world << "SELECTED ACTION: [selected_action]"
			running_action = DoAction(selected_action)
			selected_action = null

		else if(active_plan && active_plan.len)
			world << "ACTIVE PLAN: [active_plan] ([active_plan.len])"
			if(active_plan.len) //step done, move on to the next
				selected_action = lpop(active_plan)

		else //no plan & need to make one
			var/list/curr_state = list()
			var/list/goal_state = list()

			for (var/need_key in needs)
				var/need_val = needs[need_key]
				curr_state[need_key] = need_val

				if (need_val < NEED_THRESHOLD)
					world.log << "[src.name] needs [need_key]"
					goal_state[need_key] = NEED_SAFELEVEL

				if (goal_state && goal_state.len)
					world.log << "Creating plan!"
					active_plan = CreatePlan(curr_state, goal_state)
					world.log << (active_plan ? "Created plan [active_plan]" : "Failed to create a plan")

				else //satisfied, can be lazy
					Idle()

		sleep(5)


/mob/goai/agent/Move()
	..()
	TirednessDecay()


/mob/goai/agent/proc/Idle() //make this an action later!
	if(prob(10))
		var/moving_to = 0 // otherwise it always picks 4, fuck if I know.   Did I mention fuck BYOND
		moving_to = pick(SOUTH, NORTH, WEST, EAST)
		dir = moving_to			//How about we turn them the direction they are moving, yay.
		Move(get_step(src,moving_to))


/mob/goai/agent/proc/TirednessDecay()
	var/deltaT = (world.time - last_mob_update_time)
	var/cand_tiredness = max(0, (tiredness - deltaT * decay_per_dsecond))
	tiredness = cand_tiredness
	world.log << "Curr energy [tiredness]"


/mob/goai/agent/proc/HungerDecay()
	var/deltaT = (world.time - last_mob_update_time)
	var/cand_hunger = max(0, (hunger - deltaT * decay_per_dsecond))
	hunger = cand_hunger
	world.log << "Curr hunger [hunger]"
