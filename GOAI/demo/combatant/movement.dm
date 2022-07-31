/* Movement system (in the ECS sense) and movement helpers. */

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


/mob/goai/combatant/proc/CancelNavigate()
	active_path = null
	is_repathing = 0
	return TRUE


/mob/goai/combatant/proc/MovementSystem()
	if(!(active_path) || active_path.IsDone() || is_moving)
		return

	var/success = FALSE
	var/atom/next_step = ((active_path.path && active_path.path.len) ? active_path.path[1] : null)

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
			world.log << "[src]: FRUSTRATION, repath avoiding [next_step] @ ([frustr_x], [frustr_y])!"
			StartNavigateTo(active_path.target, active_path.min_dist, next_step, active_path.frustration)


	else
		world.log << "[src]: Setting path to Done"
		active_path.SetDone()

	if(success)
		lpop(active_path.path)

	return



/mob/goai/combatant/Move()
	. = ..()


/mob/goai/combatant/proc/randMove()
	is_moving = 1
	var/moving_to = 0 // otherwise it always picks 4
	moving_to = pick(SOUTH, NORTH, WEST, EAST)
	dir = moving_to //How about we turn them the direction they are moving, yay.
	step(src, dir)
	is_moving = 0