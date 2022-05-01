# define STEP_SIZE 1
# define STEP_COUNT 1



/mob/goai/combatant
	icon = 'icons/uristmob/simpleanimals.dmi'
	icon_state = "ANTAG"


/mob/goai/combatant/GetActionsList()
	/* TODO: add Time as a resource! */
	var/list/new_actionslist = list(
		// Cost, Req-ts, Effects
		//"Idle" = new /datum/Triple (10, list(), list()),
		//"Take Cover" = new /datum/Triple (10, list(), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1)),
		"Take Cover2" = new /datum/Triple (10, list(), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1)),
	)
	return new_actionslist


/mob/goai/combatant/proc/GetActionLookup()
	var/list/action_lookup = list()
	action_lookup["Idle"] = /mob/goai/combatant/proc/HandleIdling
	action_lookup["Take Cover"] = /mob/goai/combatant/proc/HandleTakeCover
	action_lookup["Take Cover2"] = /mob/goai/combatant/proc/HandleTakeCover2
	return action_lookup


/mob/goai/combatant/CreateBrain(var/list/custom_actionslist = null)
	var/list/new_actionslist = (custom_actionslist ? custom_actionslist : actionslist)
	var/datum/brain/concrete/combat/new_brain = new /datum/brain/concrete/combat(new_actionslist)
	return new_brain


/mob/goai/combatant/verb/InspectGoaiLife()
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
			usr << "| [need_key]: [brain.needs[need_key]]"
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


/mob/goai/combatant/proc/FindPathTo(var/trg, var/min_dist = 0, var/avoid = null)
	var/list/path = AStar(get_turf(loc), trg, /turf/proc/CardinalTurfs, /turf/proc/Distance, 0, pathing_dist_cutoff, min_target_dist = min_dist, exclude = avoid)
	return path


/mob/goai/combatant/proc/BuildPathTrackerTo(var/trg, var/min_dist = 0, var/avoid = null, var/inh_frustration = 0)
	var/datum/ActivePathTracker/pathtracker = null
	var/list/path = FindPathTo(trg,  min_dist, avoid)

	if(path)
		pathtracker = new /datum/ActivePathTracker(trg, path, min_dist, inh_frustration)

	return pathtracker


/mob/goai/combatant/proc/StartNavigateTo(var/trg, var/min_dist = 0, var/avoid = null, var/inh_frustration = 0)
	is_repathing = 1

	var/datum/ActivePathTracker/pathtracker = BuildPathTrackerTo(trg, min_dist, inh_frustration)

	if(pathtracker)
		active_path = pathtracker

	is_repathing = 0
	return active_path


/mob/goai/combatant/proc/HandleAction(var/action, var/datum/ActionTracker/tracker)
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

			var/mob/goai/combatant/proc/actionproc = ((action in action_lookup) ? action_lookup[action] : null)

			if(isnull(actionproc))
				tracker.SetFailed()

			else
				call(src, actionproc)(tracker)

		sleep(AI_TICK_DELAY)


/mob/goai/combatant/proc/HandleIdling(var/datum/ActionTracker/tracker)
	active_path = null
	Idle()

	if(tracker.IsOlderThan(20))
		tracker.SetDone()

	return



/mob/goai/combatant/proc/HandleTakeCover(var/datum/ActionTracker/tracker)
	var/turf/best_local_pos = null

	if(active_path && active_path.IsDone())
		active_path = null

	if(active_path && (!(active_path.IsDone())) && active_path.target && active_path.frustration < 2)
		best_local_pos = active_path.target

	world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")

	if(isnull(best_local_pos))
		var/list/processed = list()
		var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Triple/proc/FirstTwoCompare)
		var/list/curr_view = view(src)

		for(var/turf/wall/loc_wall in curr_view)
			var/list/adjacents = loc_wall.CardinalTurfs(TRUE)
			if(!adjacents)
				continue

			for(var/turf/cand in adjacents)
				if(cand in processed)
					continue

				if(!(cand in curr_view))
					continue

				var/cand_dist = ManhattanDistance(cand, src)
				var/open_lines = cand.GetOpenness()

				var/score = -abs(open_lines-6.5)

				var/datum/Triple/cover_triple = new(score, -cand_dist, cand)

				cover_queue.Enqueue(cover_triple)
				processed.Add(cand)

		var/datum/Triple/best_cand_triple = cover_queue.Dequeue()

		best_local_pos = best_cand_triple.right


	if(best_local_pos && (!active_path || active_path.target != best_local_pos))
		world.log << "Navigating to [best_local_pos]"
		StartNavigateTo(best_local_pos)

	if(best_local_pos && src.loc == best_local_pos)
		tracker.SetTriggered()

	var/is_triggered = tracker.IsTriggered()

	if(is_triggered)
		if(tracker.TriggeredMoreThan(10))
			tracker.SetDone()

	else if(active_path && tracker.IsOlderThan(100))
		tracker.SetFailed()

	else if(tracker.IsOlderThan(50))
		tracker.SetFailed()

	return


/mob/goai/combatant/proc/HandleTakeCover2(var/datum/ActionTracker/tracker)
	var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)
	var/turf/best_local_pos = tracker.BBGet("bestpos", null)

	if(active_path && active_path.IsDone())
		active_path = null

	if(isnull(best_local_pos) && active_path && (!(active_path.IsDone())) && active_path.target && active_path.frustration < 2)
		best_local_pos = active_path.target

	world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")

	if(isnull(best_local_pos))
		var/list/processed = list()
		var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Triple/proc/FirstTwoCompare)
		var/list/curr_view = oview(src)

		for(var/turf/wall/loc_wall in curr_view)
			var/list/adjacents = loc_wall.CardinalTurfs(TRUE)
			if(!adjacents)
				continue

			for(var/turf/cand in adjacents)
				if(cand in processed)
					continue

				if(!(cand in curr_view))
					continue

				var/cand_dist = ManhattanDistance(cand, src)
				if(cand_dist < 3)
					// we want substantial moves only
					continue

				var/open_lines = cand.GetOpenness()

				var/score = -abs(open_lines-pick(
					10; 3,
					10; 4,
					20; 5,
					100; 6,
					50; 7
				))

				var/datum/Triple/cover_triple = new(score, -cand_dist, cand)

				cover_queue.Enqueue(cover_triple)
				processed.Add(cand)

		var/datum/Triple/best_cand_triple = cover_queue.Dequeue()

		best_local_pos = best_cand_triple.right
		tracker.BBSet("bestpos", best_local_pos)


	if(best_local_pos && (!active_path || active_path.target != best_local_pos))
		world.log << "Navigating to [best_local_pos]"
		StartNavigateTo(best_local_pos)

	if(best_local_pos && src.loc == best_local_pos)
		tracker.SetTriggered()

	var/is_triggered = tracker.IsTriggered()

	if(is_triggered)
		if(tracker.TriggeredMoreThan(10))
			tracker.SetDone()

	else if(active_path && tracker.IsOlderThan(100))
		tracker.SetFailed()

	else if(tracker.IsOlderThan(50))
		tracker.SetFailed()

	return

.
/*
/mob/goai/combatant/verb/DoAction(Act as anything in actionslist)
	world.log << "DoAction act: [Act]"

	if(!(Act in actionslist))
		return null

	if(!brain)
		return null

	var/datum/ActionTracker/new_actiontracker = brain.DoAction(Act)

	return new_actiontracker


/mob/goai/combatant/proc/CreatePlan(var/list/status, var/list/goal)
	if(!brain)
		return

	var/list/path = brain.CreatePlan(status, goal)
	return path
*/

/*/mob/goai/combatant/proc/DecayNeeds()
	brain.DecayNeeds()*/


/mob/goai/combatant/Life()
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


/mob/goai/combatant/proc/MovementSystem()
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

		if(active_path.frustration > 7 && (is_repathing <= 0) && followup_step && followup_step != active_path.target)
			// repath
			var/frustr_x = followup_step.x
			var/frustr_y = followup_step.y
			world.log << "FRUSTRATIoN, repath avoiding [next_step] @ ([frustr_x], [frustr_y])!"
			StartNavigateTo(active_path.target, active_path.min_dist, next_step, active_path.frustration)


	if(!(active_path.path.len))
		world.log << "Setting path to Done"
		active_path.SetDone()

	return


/mob/goai/combatant/proc/LifeTick()
	if(brain)
		brain.LifeTick()

		if(brain.running_action_tracker)
			var/tracked_action = brain.running_action_tracker.tracked_action
			if(tracked_action)
				HandleAction(tracked_action, brain.running_action_tracker)

	return


/mob/goai/combatant/Move()
	..()


/mob/goai/combatant/proc/randMove()
	var/moving_to = 0 // otherwise it always picks 4
	moving_to = pick(SOUTH, NORTH, WEST, EAST)
	dir = moving_to //How about we turn them the direction they are moving, yay.
	Move(get_step(src,moving_to))


/mob/goai/combatant/proc/Idle()
	if(prob(50))
		randMove()
