/mob/goai
	var/life = 1
	icon = 'icons/mob/human_races/r_human.dmi'
	icon_state = "preview"
	var/list/needs
	var/list/actionslist
	var/list/inventory
	var/list/active_plan

	var/is_planning = 0
	var/selected_action = null
	var/datum/ActionTracker/running_action_tracker = null

	var/list/last_need_update_times
	var/last_mob_update_time
	var/last_action_update_time
	var/planning_iter_cutoff = 30

	var/datum/GOAP/brain


/mob/goai/agent/verb/InspectGoaiLife()
	set src in view(1)
	usr << "X=======================X"
	usr << "| [name] - ALIVE: [life]"

	for (var/need_key in needs)
		usr << "| [need_key]: [needs[need_key]]"

	usr << "X=======================X"


/mob/goai/agent
	var/decay_per_dsecond = 0.1


/mob/goai/New()
	..()

	needs = list()
	needs[MOTIVE_SLEEP] = NEED_THRESHOLD
	needs[MOTIVE_FOOD] = NEED_THRESHOLD

	var/spawn_time = world.time
	last_need_update_times = list()
	last_mob_update_time = spawn_time
	last_action_update_time = spawn_time

	actionslist = list(
		"Eat" = new /datum/Triple (10, list("HasFood" = 1), list(MOTIVE_FOOD = 40, "HasFood" = -1)),
		"Shop" = new /datum/Triple (10, list("Money" = 10), list("HasFood" = 1, "Money" = -10)),
		"Party" = new /datum/Triple (10, list("Money" = 11), list(MOTIVE_SLEEP = 15, "Money" = -11, "Fun" = 40)),
		"Sleep" = new /datum/Triple (10, list(MOTIVE_FOOD = 50), list(MOTIVE_SLEEP = 50)),
		//"DishWash" = new /datum/Triple (10, list("HasDirtyDishes" = 1), list("HasDirtyDishes" = -1, "HasCleanDishes" = 1)),
		"Work" = new /datum/Triple (10, list(MOTIVE_SLEEP = 25), list("Money" = 10)),
		"Idle" = new /datum/Triple (10, list(), list(MOTIVE_SLEEP = 5))
	)

	var/datum/GOAP/demoGoap/new_brain = new /datum/GOAP/demoGoap(actionslist)
	brain = new_brain

	Life()


/mob/goai/proc/Life()
	return 1


/mob/goai/verb/Say(words as text)
	world << "([name]): '[words]'"


/mob/goai/agent/proc/HandleSleeping(var/datum/ActionTracker/tracker)
	AddMotive(MOTIVE_SLEEP, 5)

	if(prob(20))
		Say("Zzzzzzz...")

	if(tracker.IsOlderThan(60))
		world.log << "Setting tracker to done!"
		tracker.is_done = 1


/mob/goai/agent/proc/HandleIdling(var/datum/ActionTracker/tracker)
	Idle()
	AddMotive(MOTIVE_FOOD, -1)
	AddMotive(MOTIVE_SLEEP, 1)

	if(tracker.IsOlderThan(60))
		world.log << "Setting tracker to done!"
		tracker.is_done = 1


/mob/goai/agent/proc/HandleEating(var/datum/ActionTracker/tracker)
	var/obj/food/noms = locate()
	var/dist = ManhattanDistance(src, noms)

	var/time_at_food = ("TimeAt" in tracker.tracker_blackboard ? tracker.tracker_blackboard["TimeAt"] : null)
	world.log << "NOMS DIST: [dist]"
	world.log << "TIME AT NOMS: [time_at_food]"

	if(dist <= 2)
		if(!("TimeAt" in tracker.tracker_blackboard))
			tracker.tracker_blackboard["TimeAt"] = 0
		else
			tracker.tracker_blackboard["TimeAt"] = tracker.tracker_blackboard["TimeAt"] + 1

		Say("OM NOM NOM!")
		AddMotive(MOTIVE_FOOD, 6)

	else
		walk_towards(src, noms, 5)

	if(tracker.tracker_blackboard["TimeAt"] > 10)
		world.log << "Setting tracker to done!"
		tracker.is_done = 1
		AddMotive(MOTIVE_FOOD, 5)


/mob/goai/agent/proc/HandleWorking(var/datum/ActionTracker/tracker)
	var/obj/desk/workdesk = locate()
	tracker.tracker_blackboard["Desk"] = workdesk

	var/dist = ManhattanDistance(src, workdesk)

	world.log << "DESK DIST: [dist]"

	if(dist <= 2)
		if(!("TimeAt" in tracker.tracker_blackboard))
			tracker.tracker_blackboard["TimeAt"] = 0
		else
			tracker.tracker_blackboard["TimeAt"] = tracker.tracker_blackboard["TimeAt"] + 1

		var/curr_time_at = tracker.tracker_blackboard["TimeAt"]
		world.log << "TIME AT DESK: [curr_time_at]"

	else
		walk_towards(src, workdesk, 3)

	if(tracker.tracker_blackboard["TimeAt"] > 30)
		world.log << "Setting tracker to done!"
		tracker.is_done = 1


/mob/goai/agent/proc/HandlePartying(var/datum/ActionTracker/tracker)
	AddMotive(MOTIVE_SLEEP, rand(-1, 2))

	randMove()

	if(tracker.IsOlderThan(30))
		world.log << "Setting tracker to done!"
		tracker.is_done = 1


/mob/goai/agent/proc/HandleAction(var/action, var/datum/ActionTracker/tracker)
	MAYBE_LOG("Tracker: [tracker]")
	var/running = 1
	while (tracker && running)
		running = tracker.IsRunning()

		MAYBE_LOG("Tracker: [tracker] running @ [running]")

		spawn(0)
			// task-specific logic goes here
			MAYBE_LOG("HandleAction action is: [action]!")

			if(0)
				world.log << "We never should have gotten to this point in code!"

			// All of these should be looked up from an assoc
			else if (action == "Sleep")
				HandleSleeping(tracker)

			else if (action == "Idle")
				HandleIdling(tracker)

			else if (action == "Eat")
				HandleEating(tracker)

			else if (action == "Work")
				HandleWorking(tracker)

			else if (action == "Party")
				HandlePartying(tracker)

			else if (prob(10))
				world.log << "Setting tracker to done!"
				tracker.is_done = 1

		sleep(AI_TICK_DELAY)


/mob/goai/agent/verb/DoAction(Act as anything in actionslist)
	world.log << "DoAction act: [Act]"

	if(!(Act in actionslist))
		return null

	var/datum/ActionTracker/new_actiontracker = new /datum/ActionTracker(Act)
	world.log << "New Tracker: [new_actiontracker] [new_actiontracker.tracked_action] @ [new_actiontracker.creation_time]"
	running_action_tracker = new_actiontracker
	spawn(0)
		HandleAction(Act, new_actiontracker)

	return new_actiontracker


/mob/goai/agent/proc/CreatePlan(var/list/status, var/list/goal)
	var/list/path = null

	var/list/params = list()
	// You don't have to pass args like this; this is just to make things a bit more readable.
	params["start"] = status
	params["goal"] = goal
	/* For functional API variant:
	params["graph"] = mob_actions
	params["adjacent"] = /proc/get_actions_agent
	params["check_preconds"] = /proc/check_preconds_agent
	params["goal_check"] = /proc/goal_checker_agent
	params["get_effects"] = /proc/get_effects_agent
	*/
	params["cutoff_iter"] = planning_iter_cutoff


	var/datum/Tuple/result = brain.Plan(arglist(params))

	if (result)
		path = result.right

	return path


/mob/goai/agent/proc/DecayNeeds()
	for (var/need_key in needs)
		MotiveDecay(need_key, null) // TODO: change this null to an assoc list lookup

	last_mob_update_time = world.time


/mob/goai/agent/Life()
	while(src.life)
		LifeTick()
		sleep(AI_TICK_DELAY)


/mob/goai/agent/proc/LifeTick()
	DecayNeeds()
	var/tiredness = needs[MOTIVE_SLEEP]
	var/hunger = needs[MOTIVE_FOOD]

	if(tiredness < NEED_THRESHOLD && prob(10))
		world << "[src.name] *yawn*"

	if(hunger < NEED_THRESHOLD && prob(10))
		world << "[src.name] *rumble*"

	if(running_action_tracker) // processing action
		var/running_is_active = running_action_tracker.IsRunning()
		world << "ACTIVE ACTION: [running_action_tracker.tracked_action] @ [running_is_active]"

		if(running_action_tracker.IsStopped())
			running_action_tracker = null

	else if(selected_action) // ready to go
		world << "SELECTED ACTION: [selected_action]"
		running_action_tracker = DoAction(selected_action)
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

			if (goal_state && goal_state.len && (!is_planning))
				world.log << "Creating plan!"
				is_planning = 1
				spawn(0)
					active_plan = CreatePlan(curr_state, goal_state)
					world.log << (active_plan ? "Created plan [active_plan]" : "Failed to create a plan")
					is_planning = 0

			else //satisfied, can be lazy
				Idle()


/mob/goai/agent/Move()
	..()


/mob/goai/agent/proc/randMove() //make this an action later!
	var/moving_to = 0 // otherwise it always picks 4
	moving_to = pick(SOUTH, NORTH, WEST, EAST)
	dir = moving_to //How about we turn them the direction they are moving, yay.
	Move(get_step(src,moving_to))


/mob/goai/agent/proc/Idle() //make this an action later!
	if(prob(10))
		randMove()


/mob/goai/agent/proc/ChangeMotive(var/motive_key, var/value)
	if(isnull(motive_key))
		return

	var/fixed_value = min(NEED_MAXIMUM, max(NEED_MINIMUM, (value)))
	needs[motive_key] = fixed_value
	last_need_update_times[motive_key] = world.time
	world.log << "Curr [motive_key] = [needs[motive_key]]"


/mob/goai/agent/proc/AddMotive(var/motive_key, var/amt)
	if(isnull(motive_key))
		return

	var/curr_val = needs[motive_key]
	ChangeMotive(motive_key, curr_val + amt)


/mob/goai/agent/proc/MotiveDecay(var/motive_key, var/custom_decay_rate = null)
	var/now = world.time
	var/decay_rate = (isnull(custom_decay_rate) ? decay_per_dsecond : custom_decay_rate)

	if(!(motive_key in last_need_update_times))
		last_need_update_times[motive_key] = now

	var/last_update_time = last_need_update_times[motive_key]
	var/deltaT = (world.time - last_update_time)
	var/curr_value = needs[motive_key]
	var/cand_tiredness = curr_value - deltaT * decay_rate

	ChangeMotive(motive_key, cand_tiredness)
