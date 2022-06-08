# define STEP_SIZE 1
# define STEP_COUNT 1



/mob/goai/combatant
	icon = 'icons/uristmob/simpleanimals.dmi'
	icon_state = "ANTAG"

	var/atom/waypoint


/mob/goai/combatant/InitStates()
	states = ..()

	/* Controls autonomy; if FALSE, agent has specific overriding orders,
	// otherwise can 'smart idle' (i.e. wander about, but stil tacticool,
	// as opposed to just sitting in place).
	//
	// Can be used as a precondition to/signal of running more micromanaged behaviours.
	//
	// With Sim-style needs, TRUE can be also used to let the NPC take care
	// of any non-urgent motives; partying ANTAGs, why not?)
	*/
	states[STATE_DOWNTIME] = TRUE

	/* Simple item tracker. */
	states[STATE_HASGUN] = (locate(/obj/gun) in src.contents) ? 1 : 0

	/* Controls if the agent is *allowed & able* to engage using *anything*
	// Can be used to force 'hold fire' or simulate the hands being occupied
	// during special actions / while using items.
	*/
	states[STATE_CANFIRE] = 1

	return states


/mob/goai/combatant/GetActionsList()
	/* TODO: add Time as a resource! */
	var/list/new_actionslist = list(
		// Cost, Req-ts, Effects
		//"Idle" = new /datum/Triple (10, list(), list()),
		//"Take Cover" = new /datum/Triple (10, list(STATE_DOWNTIME = 1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1)),
		"Cover Leapfrog" = new /datum/Triple (10, list(STATE_DOWNTIME = 1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1)),
		"Directional Cover" = new /datum/Triple (4, list(STATE_DOWNTIME = -1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1, NEED_OBEDIENCE = NEED_SATISFIED)),
		//"Directional Cover Leapfrog" = new /datum/Triple (4, list(STATE_DOWNTIME = -1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1, NEED_OBEDIENCE = NEED_SATISFIED)),
		//"Cover Fire" = new /datum/Triple (5, list(STATE_INCOVER = 1), list(NEED_COVER = NEED_MINIMUM, STATE_INCOVER = 0, NEED_ENEMIES = NEED_SATISFIED)),
		//"Shoot" = new /datum/Triple (10, list(STATE_CANFIRE = 1), list(NEED_COVER = NEED_SATISFIED, STATE_INCOVER = 1, NEED_OBEDIENCE = NEED_SATISFIED)),
	)
	return new_actionslist


/mob/goai/combatant/Equip()
	. = ..()
	GimmeGun()
	return


/mob/goai/combatant/proc/GetActionLookup()
	var/list/action_lookup = list()
	action_lookup["Idle"] = /mob/goai/combatant/proc/HandleIdling
	action_lookup["Take Cover"] = /mob/goai/combatant/proc/HandleTakeCover
	action_lookup["Cover Leapfrog"] = /mob/goai/combatant/proc/HandleCoverLeapfrog
	action_lookup["Directional Cover"] = /mob/goai/combatant/proc/HandleDirectionalCover
	action_lookup["Directional Cover Leapfrog"] = /mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog
	action_lookup["Cover Fire"] = /mob/goai/combatant/proc/HandleIdling
	action_lookup["Shoot"] = /mob/goai/combatant/proc/HandleShoot
	return action_lookup


/mob/goai/combatant/CreateBrain(var/list/custom_actionslist = NONE)
	var/list/new_actionslist = (custom_actionslist ? custom_actionslist : actionslist)
	var/datum/brain/concrete/combat/new_brain = new /datum/brain/concrete/combat(new_actionslist)
	new_brain.states = states
	return new_brain



/mob/goai/combatant/Hit(var/angle)
	. = ..(angle)
	var/impact_angle = IMPACT_ANGLE(angle)
	/* NOTE: impact_angle is in degrees from *positive X axis* towards Y, i.e.:
	//
	// impact_angle = +0   => hit from straight East
	// impact_angle = +180 => hit from straight West
	// impact_angle = -180 => hit from straight West
	// impact_angle = -90  => hit from straight North
	// impact_angle = +90  => hit from straight South
	// impact_angle = +45  => hit from North-East
	// impact_angle = -45  => hit from South-East
	//
	// Everything else - extrapolate from the above.
	*/
	world.log << "Impact angle [impact_angle]"
	brain.SetMemory("ShotAt", impact_angle, 600)



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


/mob/goai/combatant/verb/CancelOrders()
	set src in view()

	SetState(STATE_DOWNTIME, TRUE)
	usr << "Set [src] downtime-state to [TRUE]"

	usr << (waypoint ? "[src] tracking [waypoint]" : "[src] no longer tracking waypoints")

	return waypoint


/mob/goai/combatant/verb/GiveFollowOrder(mob/M in world)
	set src in view()
	if(!M)
		return

	SetState(STATE_DOWNTIME, FALSE)
	usr << "Set [src] downtime-state to [FALSE]"

	waypoint = M
	usr << (waypoint ? "[src] now tracking [waypoint]" : "[src] not tracking waypoints")

	return waypoint


/mob/goai/combatant/verb/GiveMoveOrder(posX as num, posY as num)
	set src in view()

	var/trueX = posX % world.maxx
	var/trueY = posY % world.maxy
	var/trueZ = src.z

	var/turf/position = locate(trueX, trueY, trueZ)
	if(!position)
		usr << "Target position does not exist!"
		return

	SetState(STATE_DOWNTIME, FALSE)
	usr << "Set [src] downtime-state to [FALSE]"

	waypoint = position
	usr << (waypoint ? "[src] now tracking [waypoint] @ ([trueX], [trueY], [trueZ])" : "[src] not tracking waypoints")

	return waypoint


/mob/goai/combatant/proc/FindPathTo(var/trg, var/min_dist = 0, var/avoid = NONE)
	var/list/path = AStar(get_turf(loc), trg, /turf/proc/CardinalTurfs, /turf/proc/Distance, 0, pathing_dist_cutoff, min_target_dist = min_dist, exclude = avoid)
	return path


/mob/goai/combatant/proc/BuildPathTrackerTo(var/trg, var/min_dist = 0, var/avoid = NONE, var/inh_frustration = 0)
	var/datum/ActivePathTracker/pathtracker = null
	var/list/path = FindPathTo(trg,  min_dist, avoid)

	if(path)
		pathtracker = new /datum/ActivePathTracker(trg, path, min_dist, inh_frustration)

	return pathtracker


/mob/goai/combatant/proc/StartNavigateTo(var/trg, var/min_dist = 0, var/avoid = NONE, var/inh_frustration = 0)
	is_repathing = 1

	var/datum/ActivePathTracker/pathtracker = BuildPathTrackerTo(trg, min_dist, inh_frustration)

	if(pathtracker)
		active_path = pathtracker

	if(istype(trg, /turf))
		var/turf/trg_turf = trg
		trg_turf.DrawVectorbeam()

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
	//var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)
	var/turf/best_local_pos = tracker.BBGet("bestpos", null)

	if(isnull(best_local_pos) && active_path && (!(active_path.IsDone())) && active_path.target && active_path.frustration < 2)
		best_local_pos = active_path.target

	//world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")

	if(isnull(best_local_pos))
		var/list/processed = list()
		var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Triple/proc/FirstTwoCompare)
		var/list/curr_view = view(src)

		for(var/turf/wall/loc_wall in curr_view)

			if(!(loc_wall.is_corner || loc_wall.is_pillar))
				continue

			var/list/adjacents = loc_wall.CardinalTurfs(TRUE)

			if(!adjacents)
				continue

			for(var/turf/cand in adjacents)
				if(cand in processed)
					continue

				if(!(cand in curr_view))
					continue

				if(!(cand.Enter(src)))
					continue

				var/cand_dist = ManhattanDistance(cand, src)

				var/open_lines = cand.GetOpenness()
				var/score = -open_lines

				var/datum/Triple/cover_triple = new(score, -cand_dist, cand)
				cover_queue.Enqueue(cover_triple)
				processed.Add(cand)

		var/datum/Triple/best_cand_triple = cover_queue.Dequeue()

		best_local_pos = best_cand_triple.right
		tracker.BBSet("bestpos", best_local_pos)
		world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")


	if(best_local_pos && (!active_path || active_path.target != best_local_pos))
		world.log << "Navigating to [best_local_pos]"
		StartNavigateTo(best_local_pos)

	if(best_local_pos && src.loc == best_local_pos)
		tracker.SetTriggered()

	var/is_triggered = tracker.IsTriggered()

	if(is_triggered)
		if(tracker.TriggeredMoreThan(10))
			tracker.SetDone()

	else if(active_path && tracker.IsOlderThan(150))
		tracker.SetFailed()

	else if(tracker.IsOlderThan(100))
		tracker.SetFailed()


	return


/mob/goai/combatant/proc/HandleCoverLeapfrog(var/datum/ActionTracker/tracker)
	//var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)
	var/turf/best_local_pos = tracker.BBGet("bestpos", null)

	if(isnull(best_local_pos) && active_path && (!(active_path.IsDone())) && active_path.target && active_path.frustration < 2)
		best_local_pos = active_path.target

	if(isnull(best_local_pos))
		var/list/processed = list()
		var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Triple/proc/FirstTwoCompare)
		var/list/curr_view = oview(src)


		for(var/turf/wall/loc_wall in curr_view)
			if(!(loc_wall.is_corner || loc_wall.is_pillar))
				continue

			var/list/adjacents = loc_wall.CardinalTurfs(TRUE)

			if(!adjacents)
				continue

			for(var/turf/cand in adjacents)
				if(cand in processed)
					continue

				if(!(cand in curr_view))
					continue

				if(!(cand.Enter(src)))
					continue

				var/cand_dist = ManhattanDistance(cand, src)
				if(cand_dist < 3)
					// we want substantial moves only
					continue

				var/open_lines = cand.GetOpenness()
				var/score = -abs(open_lines-pick(
					/*
					This is a bit un-obvious:

					What we're doing here is biasing the pathing towards
					cover positions *around* the picked value.

					For example, if we roll a 3, the ideal cover position
					would be one with Openness score of 3.

					However, this is not a hard requirement; if we don't
					have a 3, we'll accept a 2 or a 4 (equally, preferentially)
					and if we don't have *those* - a 1 or a 5, etc.

					This makes it harder for the AI to wind up giving up due to
					no valid positions; sub-optimal is still good enough in that case.

					The randomness is here to make the leapfrogging more dynamic;
					if we just rank by best cover, we'll just wind bouncing between
					the same positions, and this action is supposed to be more like
					a 'smart' tacticool wandering behaviour.
					 */
					120; 3,
					50; 4,
					50; 5,
					40; 6,
					5; 7
				))

				var/datum/Triple/cover_triple = new(score, -cand_dist, cand)
				cover_queue.Enqueue(cover_triple)
				processed.Add(cand)

		var/datum/Triple/best_cand_triple = cover_queue.Dequeue()

		best_local_pos = best_cand_triple.right
		tracker.BBSet("bestpos", best_local_pos)
		world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")


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


/mob/goai/combatant/proc/HandleDirectionalCover(var/datum/ActionTracker/tracker)
	//var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)
	var/turf/best_local_pos = tracker.BBGet("bestpos", null)

	if(isnull(best_local_pos) && active_path && (!(active_path.IsDone())) && active_path.target && active_path.frustration < 2)
		best_local_pos = active_path.target

	//world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")

	if(isnull(best_local_pos))
		var/list/processed = list()
		var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Quadruple/proc/TriCompare)
		var/list/curr_view = oview(src)

		for(var/turf/wall/loc_wall in curr_view)
			if(!(loc_wall.is_corner || loc_wall.is_pillar))
				if(prob(90))
					continue

			var/list/adjacents = loc_wall.CardinalTurfs(TRUE)

			if(!adjacents)
				continue

			for(var/turf/cand in adjacents)
				if(cand in processed)
					continue

				if(!(cand in curr_view))
					continue

				if(!(cand.Enter(src)))
					continue

				var/cand_dist = ManhattanDistance(cand, src)

				var/targ_dist = (waypoint ? ManhattanDistance(cand, waypoint) : 0)
				var/total_dist = (cand_dist + targ_dist)

				var/open_lines = cand.GetOpenness()
				var/score = -abs(open_lines-pick(
					/*
					This is a bit un-obvious:

					What we're doing here is biasing the pathing towards
					cover positions *around* the picked value.

					For example, if we roll a 3, the ideal cover position
					would be one with Openness score of 3.

					However, this is not a hard requirement; if we don't
					have a 3, we'll accept a 2 or a 4 (equally, preferentially)
					and if we don't have *those* - a 1 or a 5, etc.

					This makes it harder for the AI to wind up giving up due to
					no valid positions; sub-optimal is still good enough in that case.

					The randomness is here to make the leapfrogging more dynamic;
					if we just rank by best cover, we'll just wind bouncing between
					the same positions, and this action is supposed to be more like
					a 'smart' tacticool wandering behaviour.
					 */
					120; 3,
					50; 4,
					5; 7
				))

				var/datum/Quadruple/cover_quad = new(-targ_dist, score, -total_dist, cand)
				cover_queue.Enqueue(cover_quad)
				processed.Add(cand)

		var/datum/Quadruple/best_cand_quad = cover_queue.Dequeue()

		best_local_pos = best_cand_quad.fourth
		tracker.BBSet("bestpos", best_local_pos)
		world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")


	if(best_local_pos && (!active_path || active_path.target != best_local_pos))
		world.log << "Navigating to [best_local_pos]"
		StartNavigateTo(best_local_pos)

	if(best_local_pos)
		var/dist_to_pos = ManhattanDistance(src.loc, best_local_pos)
		if(dist_to_pos <= 1)
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


/mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog(var/datum/ActionTracker/tracker)
	//var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)
	var/turf/best_local_pos = tracker.BBGet("bestpos", null)

	if(isnull(best_local_pos) && active_path && (!(active_path.IsDone())) && active_path.target && active_path.frustration < 2)
		best_local_pos = active_path.target

	//world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")

	if(isnull(best_local_pos))
		var/list/processed = list()
		var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Quadruple/proc/TriCompare)
		var/list/curr_view = oview(src)

		for(var/turf/wall/loc_wall in curr_view)
			if(!(loc_wall.is_corner || loc_wall.is_pillar))
				if(prob(90))
					continue

			var/list/adjacents = loc_wall.CardinalTurfs(TRUE)

			if(!adjacents)
				continue

			for(var/turf/cand in adjacents)
				if(cand in processed)
					continue

				if(!(cand in curr_view))
					continue

				if(!(cand.Enter(src)))
					continue

				var/cand_dist = ManhattanDistance(cand, src)
				if(cand_dist < 3)
					// we want substantial moves only
					continue

				var/targ_dist = (waypoint ? ManhattanDistance(cand, waypoint) : 0)
				var/total_dist = (cand_dist + targ_dist)

				var/open_lines = cand.GetOpenness()
				var/score = -abs(open_lines-pick(
					/*
					This is a bit un-obvious:

					What we're doing here is biasing the pathing towards
					cover positions *around* the picked value.

					For example, if we roll a 3, the ideal cover position
					would be one with Openness score of 3.

					However, this is not a hard requirement; if we don't
					have a 3, we'll accept a 2 or a 4 (equally, preferentially)
					and if we don't have *those* - a 1 or a 5, etc.

					This makes it harder for the AI to wind up giving up due to
					no valid positions; sub-optimal is still good enough in that case.

					The randomness is here to make the leapfrogging more dynamic;
					if we just rank by best cover, we'll just wind bouncing between
					the same positions, and this action is supposed to be more like
					a 'smart' tacticool wandering behaviour.
					 */
					120; 3,
					50; 4,
					5; 7
				))

				var/datum/Quadruple/cover_quad = new(-targ_dist, score, -total_dist, cand)
				cover_queue.Enqueue(cover_quad)
				processed.Add(cand)

		var/datum/Quadruple/best_cand_quad = cover_queue.Dequeue()

		best_local_pos = best_cand_quad.fourth
		tracker.BBSet("bestpos", best_local_pos)
		world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")


	if(best_local_pos && (!active_path || active_path.target != best_local_pos))
		world.log << "Navigating to [best_local_pos]"
		StartNavigateTo(best_local_pos)

	if(best_local_pos)
		var/dist_to_pos = ManhattanDistance(src.loc, best_local_pos)
		if(dist_to_pos <= 1)
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


/mob/goai/combatant/proc/HandleShoot(var/datum/ActionTracker/tracker)
	if (tracker.IsStopped())
		return

	if(tracker.IsOlderThan(50))
		tracker.SetFailed()
		return

	states[STATE_CANFIRE] = TRUE
	tracker.SetDone()

	return


/mob/goai/combatant/proc/GetTarget(var/list/searchspace = NONE, var/maxtries = 5)
	var/list/true_searchspace = (isnull(searchspace) ? view() : searchspace)

	var/PriorityQueue/target_queue = new /PriorityQueue(/datum/Tuple/proc/FirstCompare)

	for(var/mob/goai/combatant/enemy in true_searchspace)
		var/enemy_dist = ManhattanDistance(src.loc, enemy)

		if (enemy_dist <= 0)
			continue

		var/datum/Tuple/enemy_tup = new(-enemy_dist, enemy)
		target_queue.Enqueue(enemy_tup)

	var/tries = 0
	var/atom/target = null

	while (isnull(target) && target_queue.L.len && tries < maxtries)
		var/datum/Tuple/best_target_tup = target_queue.Dequeue()
		target = best_target_tup.right
		tries++

	return target


/mob/goai/combatant/proc/Shoot(var/obj/gun/cached_gun = NONE, var/atom/cached_target = NONE)
	. = FALSE

	var/obj/gun/my_gun = (isnull(cached_gun) ? (locate(/obj/gun) in src.contents) : cached_gun)

	if(isnull(my_gun))
		world.log << "Gun not found for [src] to shoot D;"
		return FALSE

	var/atom/target = (isnull(cached_target) ? GetTarget() : cached_target)

	if(!isnull(target))
		my_gun.shoot(target, src)
		. = TRUE

	return .


/mob/goai/combatant/proc/HandleShootOld(var/datum/ActionTracker/tracker)
	if (tracker.IsStopped())
		return

	if(tracker.IsOlderThan(50))
		tracker.SetFailed()
		return

	var/obj/gun/my_gun = locate(/obj/gun) in src.contents

	if(isnull(my_gun))
		world.log << "Gun not found for [src] to shoot D;"
		return

	var/atom/target = GetTarget()
	var/successful = Shoot(my_gun, target)

	if(successful)
		tracker.SetDone()

	return

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

	// Combat system; decoupled from generic planning/actions to make it run
	// *in parallel* to other behaviours - e.g. run-and-gun or fire from cover
	spawn(0)
		while(life)
			FightTick()
			sleep(AI_TICK_DELAY)


/mob/goai/combatant/proc/MovementSystem()
	if(!(active_path) || active_path.IsDone() || is_moving)
		return

	var/success = FALSE
	var/atom/next_step = ((active_path.path && active_path.path.len) ? active_path.path[1] : null)
	if(next_step == src.loc)
		lpop(active_path.path)
		next_step = ((active_path.path && active_path.path.len) ? lpop(active_path.path) : null)

	var/atom/followup_step = ((active_path.path && active_path.path.len >= 2) ? active_path.path[2] : null)

	if(next_step)
		step_towards(src, next_step, 0)

		success = ((src.x == next_step.x) && (src.y == next_step.y))

		if(success)
			active_path.frustration = 0

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


	else
		// This happens prematurely in some cases, dunno why ATM
		world.log << "Setting path to Done"
		active_path.SetDone()

	if(success)
		lpop(active_path.path)

	return


/mob/goai/combatant/proc/LifeTick()
	if(brain)
		brain.LifeTick()

		if(brain.running_action_tracker)
			var/tracked_action = brain.running_action_tracker.tracked_action
			if(tracked_action)
				HandleAction(tracked_action, brain.running_action_tracker)

	return


/mob/goai/combatant/proc/FightTick()
	var/can_fire = ((STATE_CANFIRE in states) ? states[STATE_CANFIRE] : FALSE)
	if(!can_fire)
		return

	var/atom/target = GetTarget()
	Shoot(NONE, target)

	return


/mob/goai/combatant/Move()
	. = ..()


/mob/goai/combatant/proc/randMove()
	is_moving = 1
	var/moving_to = 0 // otherwise it always picks 4
	moving_to = pick(SOUTH, NORTH, WEST, EAST)
	dir = moving_to //How about we turn them the direction they are moving, yay.
	Move(get_step(src, moving_to))
	is_moving = 0


/mob/goai/combatant/proc/Idle()
	if(prob(50))
		randMove()
