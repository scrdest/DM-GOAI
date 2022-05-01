# define STEP_SIZE 1
# define STEP_COUNT 1


/mob/goai
	var/life = 1
	icon = 'icons/mob/human_races/r_human.dmi'
	icon_state = "preview"
	var/list/needs
	var/list/actionslist
	var/list/inventory

	var/datum/ActivePathTracker/active_path

	var/is_repathing = 0

	var/list/last_need_update_times
	var/last_mob_update_time
	var/last_action_update_time

	var/planning_iter_cutoff = 30
	var/pathing_dist_cutoff = 60

	var/datum/brain/brain


/mob/goai/proc/GetActionsList()
	var/list/new_actionslist = list()
	return new_actionslist


/mob/goai/proc/CreateBrain(var/list/custom_actionslist = null)
	var/list/new_actionslist = (custom_actionslist ? custom_actionslist : actionslist)
	var/datum/brain/new_brain = new /datum/brain(new_actionslist)
	return new_brain


/mob/goai/New()
	..()

	needs = list()

	var/spawn_time = world.time
	last_mob_update_time = spawn_time
	actionslist = GetActionsList()

	var/datum/brain/new_brain = CreateBrain(actionslist)
	brain = new_brain

	Life()


/mob/goai/proc/Life()
	return 1


/mob/goai/verb/Say(words as text)
	world << "([name]) says: '[words]'"



/mob/goai/agent
	var/decay_per_dsecond = 0.1


/mob/goai/agent/New()
	..()

	needs = list()
	needs[MOTIVE_SLEEP] = NEED_THRESHOLD
	needs[MOTIVE_FOOD] = NEED_THRESHOLD
	needs[MOTIVE_FUN] = NEED_THRESHOLD


/mob/goai/agent/CreateBrain(var/list/custom_actionslist = null)
	var/list/new_actionslist = (custom_actionslist ? custom_actionslist : actionslist)

	var/datum/brain/concrete/sim/new_brain = new /datum/brain/concrete/sim(new_actionslist)

	return new_brain


/mob/goai/agent/GetActionsList()
	/* TODO: add Time as a resource! */
	var/list/new_actionslist = list(
		"Eat" = new /datum/Triple (10, list(RESOURCE_FOOD = 1), list(MOTIVE_FOOD = 40, RESOURCE_FOOD = -1)),
		"Shop" = new /datum/Triple (10, list(RESOURCE_MONEY = 10), list(RESOURCE_FOOD = 1, RESOURCE_MONEY = -10)),
		"Party" = new /datum/Triple (10, list(RESOURCE_MONEY = 11), list(MOTIVE_SLEEP = 15, RESOURCE_MONEY = -11, MOTIVE_FUN = 40)),
		"Sleep" = new /datum/Triple (10, list(MOTIVE_FOOD = 50), list(MOTIVE_SLEEP = 50)),
		//"DishWash" = new /datum/Triple (10, list("HasDirtyDishes" = 1), list("HasDirtyDishes" = -1, "HasCleanDishes" = 1)),
		"Work" = new /datum/Triple (10, list(MOTIVE_SLEEP = 25), list(RESOURCE_MONEY = 10)),
		"Idle" = new /datum/Triple (10, list(), list(MOTIVE_SLEEP = 5))
	)
	return new_actionslist


/mob/goai/agent/verb/InspectGoaiLife()
	set src in view(1)
	usr << "X=======================X"
	usr << "|"
	usr << "| [name] - ALIVE: [life]"
	usr << "|"

	var/path_list = (active_path ? active_path.path : "<No path for null>")
	var/list/brain_plan = null
	var/plan_len = "<No len for null>"
	var/brain_is_planning = null

	if(brain)
		brain_plan = brain.active_plan
		plan_len = (brain_plan ? brain_plan.len : plan_len)
		brain_is_planning = brain.is_planning

		for (var/need_key in brain.needs)
			usr << "| [need_key]: [needs[need_key]]"
	else
		usr << "| (brainless)"

	usr << "|"
	usr << "| ACTIVE PATH: [active_path] ([path_list])"
	usr << "| ACTIVE PLAN: [brain_plan] ([plan_len])"
	usr << "|"
	usr << "| PLANNING: [brain_is_planning]"
	usr << "| REPATHING: [is_repathing]"
	usr << "|"
	usr << "X=======================X"


/mob/goai/agent/proc/FindPathTo(var/trg, var/min_dist = 0, var/avoid = null)
	var/list/path = AStar(get_turf(loc), trg, /turf/proc/CardinalTurfs, /turf/proc/Distance, 0, pathing_dist_cutoff, min_target_dist = min_dist, exclude = avoid)
	return path


/mob/goai/agent/proc/BuildPathTrackerTo(var/trg, var/min_dist = 0, var/avoid = null, var/inh_frustration = 0)
	var/datum/ActivePathTracker/pathtracker = null
	var/list/path = FindPathTo(trg,  min_dist, avoid)

	if(path)
		pathtracker = new /datum/ActivePathTracker(trg, path, min_dist, inh_frustration)

	return pathtracker


/mob/goai/agent/proc/StartNavigateTo(var/trg, var/min_dist = 0, var/avoid = null, var/inh_frustration = 0)
	is_repathing = 1

	var/datum/ActivePathTracker/pathtracker = BuildPathTrackerTo(trg, min_dist, inh_frustration)

	if(pathtracker)
		active_path = pathtracker

	is_repathing = 0
	return active_path


/mob/goai/agent/proc/HandleSleeping(var/datum/ActionTracker/tracker)
	var/obj/bed/sleeploc = locate()
	if(!sleeploc)
		tracker.SetFailed()

	var/dist = ManhattanDistance(src, sleeploc)

	if(dist <= 1)
		if(!("TimeAt" in tracker.tracker_blackboard))
			tracker.tracker_blackboard["TimeAt"] = 0
		else
			tracker.tracker_blackboard["TimeAt"] = tracker.tracker_blackboard["TimeAt"] + 1

		AddMotive(MOTIVE_SLEEP, 5)

		if(prob(20))
			Say("Zzzzzzz...")


	if(dist > 0)
		if(!active_path || (active_path.target != sleeploc))
			StartNavigateTo(sleeploc, 0)

		else if(active_path)
			active_path.frustration++


	if(brain && brain.needs)
		var/sleepiness = GetMotive(MOTIVE_SLEEP)
		if(sleepiness && sleepiness > NEED_SATISFIED)
			tracker.SetDone()


	else if(tracker.tracker_blackboard["TimeAt"] > 10)
		tracker.SetDone()


	else if(tracker.IsOlderThan(600))
		tracker.SetFailed()


/mob/goai/agent/proc/HandleIdling(var/datum/ActionTracker/tracker)
	Idle()
	AddMotive(MOTIVE_FOOD, -1)
	AddMotive(MOTIVE_SLEEP, 1)

	if(tracker.IsOlderThan(20))
		tracker.SetDone()

	return


/mob/goai/agent/proc/HandleEating(var/datum/ActionTracker/tracker)
	var/obj/food/noms = locate()
	if(!noms)
		tracker.SetFailed()

	var/dist = ManhattanDistance(src, noms)

	var/time_at = ("TimeAt" in tracker.tracker_blackboard ? tracker.tracker_blackboard["TimeAt"] : null)
	world.log << "NOMS DIST: [dist]"
	world.log << "TIME AT NOMS: [time_at]"

	if(dist <= 1)
		if(!("TimeAt" in tracker.tracker_blackboard))
			tracker.tracker_blackboard["TimeAt"] = 0
		else
			tracker.tracker_blackboard["TimeAt"] = tracker.tracker_blackboard["TimeAt"] + 1

		Say("OM NOM NOM!")
		AddMotive(MOTIVE_FOOD, 6)

	if(dist > 0)
		if(!active_path || (active_path.target != noms))
			StartNavigateTo(noms, 0)

	else if(tracker.tracker_blackboard["TimeAt"] > 10)
		tracker.SetDone()
		AddMotive(MOTIVE_FOOD, 5)

	else if(tracker.IsOlderThan(600))
		tracker.SetFailed()


/mob/goai/agent/proc/HandleWorking(var/datum/ActionTracker/tracker)
	var/obj/desk/workdesk = locate()
	if(!workdesk)
		tracker.SetFailed()

	tracker.tracker_blackboard["Desk"] = workdesk

	var/dist = ManhattanDistance(src, workdesk)

	world.log << "DESK DIST: [dist]"

	if(dist <= 0)
		if(!("TimeAt" in tracker.tracker_blackboard))
			tracker.tracker_blackboard["TimeAt"] = 0
		else
			tracker.tracker_blackboard["TimeAt"] = tracker.tracker_blackboard["TimeAt"] + 1

		var/curr_time_at = tracker.tracker_blackboard["TimeAt"]
		world.log << "TIME AT DESK: [curr_time_at]"
		AddMotive(MOTIVE_FUN, -0.25)

	if(dist > 0)
		if(!active_path || (active_path.target != workdesk))
			StartNavigateTo(workdesk, 0)

	if(tracker.tracker_blackboard["TimeAt"] > 10)
		tracker.SetDone()

	if(tracker.IsOlderThan(600))
		tracker.SetFailed()


/mob/goai/agent/proc/HandlePartying(var/datum/ActionTracker/tracker)
	AddMotive(MOTIVE_SLEEP, rand(-1, 2))
	AddMotive(MOTIVE_FUN, 5)

	randMove()

	if(tracker.IsOlderThan(40))
		tracker.SetDone()


/mob/goai/agent/proc/HandleShopping(var/datum/ActionTracker/tracker)
	var/obj/vending/vendor = locate()
	if(!vendor)
		tracker.SetFailed()

	tracker.tracker_blackboard["Vendor"] = vendor

	var/dist = ChebyshevDistance(src, vendor)

	world.log << "VENDOR DIST: [dist]"

	if(dist <= 1)
		if(!("TimeAt" in tracker.tracker_blackboard))
			tracker.tracker_blackboard["TimeAt"] = 0
		else
			tracker.tracker_blackboard["TimeAt"] = tracker.tracker_blackboard["TimeAt"] + 1

	if(dist > 1)
		if(!active_path || (active_path.target != vendor))
			StartNavigateTo(vendor, 1)

	if(tracker.tracker_blackboard["TimeAt"] > 5)
		tracker.SetDone()

	if(tracker.IsOlderThan(600))
		tracker.SetFailed()


/mob/goai/agent/proc/GetActionLookup()
	var/list/action_lookup = list()
	action_lookup["Sleep"] = /mob/goai/agent/proc/HandleSleeping
	action_lookup["Idle"] = /mob/goai/agent/proc/HandleIdling
	action_lookup["Eat"] = /mob/goai/agent/proc/HandleEating
	action_lookup["Work"] = /mob/goai/agent/proc/HandleWorking
	action_lookup["Party"] = /mob/goai/agent/proc/HandlePartying
	action_lookup["Shop"] = /mob/goai/agent/proc/HandleShopping
	return action_lookup


/mob/goai/agent/proc/HandleAction(var/action, var/datum/ActionTracker/tracker)
	MAYBE_LOG("Tracker: [tracker]")
	var/running = 1

	var/list/action_lookup = GetActionLookup()
	if(isnull(action_lookup))
		return

	while (tracker && running)
		running = tracker.IsRunning()

		MAYBE_LOG("Tracker: [tracker] running @ [running]")

		spawn(0)
			// task-specific logic goes here
			MAYBE_LOG("HandleAction action is: [action]!")

			var/mob/goai/agent/proc/actionproc = ((action in action_lookup) ? action_lookup[action] : null)

			if(isnull(actionproc))
				tracker.SetFailed()

			else
				call(src, actionproc)(tracker)

		sleep(AI_TICK_DELAY)


/*
/mob/goai/agent/verb/DoAction(Act as anything in actionslist)
	world.log << "DoAction act: [Act]"

	if(!(Act in actionslist))
		return null

	if(!brain)
		return null

	var/datum/ActionTracker/new_actiontracker = brain.DoAction(Act)

	return new_actiontracker


/mob/goai/agent/proc/CreatePlan(var/list/status, var/list/goal)
	if(!brain)
		return

	var/list/path = brain.CreatePlan(status, goal)
	return path
*/

/*/mob/goai/agent/proc/DecayNeeds()
	brain.DecayNeeds()*/


/mob/goai/agent/Life()
	// Movement updates
	spawn(0)
		while(life)
			MovementSystem()
			sleep(AI_TICK_DELAY)

	// AI
	spawn(0)
		while(life)
			LifeTick()
			sleep(AI_TICK_DELAY)


/mob/goai/agent/proc/MovementSystem()
	if(!(active_path))
		return

	var/atom/next_step = ((active_path.path && active_path.path.len) ? active_path.path[1] : null)
	if(next_step == src.loc)
		lpop(active_path.path)
		next_step = ((active_path.path && active_path.path.len) ? lpop(active_path.path) : null)

	var/atom/followup_step = ((active_path.path && active_path.path.len >= 2) ? active_path.path[2] : null)

	if(next_step)
		step_towards(src, next_step, 0)

		var/success = ((src.x == next_step.x) && (src.y == next_step.y))

		if(success)
			active_path.frustration = 0
			lpop(active_path.path)

		else
			active_path.frustration++

		if(active_path.frustration > 2)
			randMove()

		if(active_path.frustration > 7 && (is_repathing <= 0) && followup_step)
			// repath
			var/frustr_x = followup_step.x
			var/frustr_y = followup_step.y
			world.log << "FRUSTRATIoN, repath avoiding [next_step] @ ([frustr_x], [frustr_y])!"
			StartNavigateTo(active_path.target, active_path.min_dist, next_step, active_path.frustration)

	return


/mob/goai/agent/proc/LifeTick()
	if(brain)
		brain.LifeTick()

		if(brain.running_action_tracker)
			var/tracked_action = brain.running_action_tracker.tracked_action
			if(tracked_action)
				HandleAction(tracked_action, brain.running_action_tracker)

	return


/mob/goai/agent/Move()
	..()


/mob/goai/agent/proc/randMove()
	var/moving_to = 0 // otherwise it always picks 4
	moving_to = pick(SOUTH, NORTH, WEST, EAST)
	dir = moving_to //How about we turn them the direction they are moving, yay.
	Move(get_step(src,moving_to))


/mob/goai/agent/proc/Idle()
	if(prob(10))
		randMove()


/mob/goai/agent/proc/GetMotive(var/motive_key)
	if(isnull(motive_key))
		return

	var/datum/brain/concrete/sim/simbrain = brain

	if(!simbrain)
		return

	return simbrain.GetMotive(motive_key)


/mob/goai/agent/proc/ChangeMotive(var/motive_key, var/value)
	if(isnull(motive_key))
		return

	var/datum/brain/concrete/sim/simbrain = brain

	if(!simbrain)
		return

	simbrain.ChangeMotive(motive_key, value)


/mob/goai/agent/proc/AddMotive(var/motive_key, var/amt)
	if(isnull(motive_key))
		return

	var/datum/brain/concrete/sim/simbrain = brain

	if(!simbrain)
		return

	simbrain.AddMotive(motive_key, amt)


/mob/goai/agent/proc/MotiveDecay(var/motive_key, var/custom_decay_rate = null)
	if(isnull(motive_key))
		return

	var/datum/brain/concrete/sim/simbrain = brain

	if(!simbrain)
		return

	simbrain.MotiveDecay(motive_key, custom_decay_rate)
	needs = brain.needs
