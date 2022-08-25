
/mob/goai/combatant/proc/SpotObstacles(var/mob/goai/combatant/owner, var/atom/target = null, default_to_waypoint=TRUE)
	if(!owner)
		// No mob - no point.
		return

	var/datum/brain/owner_brain = owner?.brain
	if(isnull(owner_brain))
		// No point processing this if there's no memories to use
		// Might not be a precondition later.
		return

	var/atom/goal = target

	if(isnull(goal) && default_to_waypoint)
		var/atom/waypoint = owner.brain.GetMemoryValue(MEM_WAYPOINT_IDENTITY, null, FALSE, TRUE)
		goal = waypoint

	if(isnull(goal))
		// Nothing to spot.
		return

	var/list/path = null
	var/turf/target_turf = get_turf(goal)

	if(isnull(target_turf))
		target_turf = get_turf(goal.loc)

	var/turf/startpos = get_turf(owner)
	var/init_dist = 30
	// NOTE: somehow, this once runtimed with the distance seemingly being -1, wtf?
	//       the max() was added as a measure to ensure sane input
	var/sqrt_dist = (max(0, get_dist(startpos, target)) ** 0.5) * 0.5

	if(init_dist < 40)
		world.log << "[owner] entering ASTARS STAGE"
		path = AStar(owner, target_turf, /turf/proc/CardinalTurfs, /turf/proc/Distance, null, init_dist, min_target_dist = sqrt_dist, exclude = null)
		world.log << "[owner] found ASTAR 1 path from [startpos] to [target_turf]: [path] ([path?.len])"

		if(path && path.len)
			world.log << "[owner] entering HAPPYPATH"
			return

		// No unobstructed path to target!
		// Let's try to get a direct path and check for obstacles.
		path = AStar(owner, target_turf, /turf/proc/CardinalTurfsNoblocks, /turf/proc/Distance, null, init_dist, min_target_dist = sqrt_dist, exclude = null)
		world.log << "[src] found ASTAR 2 path from [startpos] to [target_turf]: [path] ([path?.len])"

		if(!path)
			return

		var/path_pos = 0

		world.log << "[owner] entering OBSTACLE HUNT STAGE"
		for(var/turf/pathitem in path)
			path_pos++
			//world.log << "[owner]: [pathitem]"

			if(isnull(pathitem))
				continue

			if(path_pos <= 1)
				continue

			var/turf/previous = path[path_pos-1]

			if(isnull(previous))
				continue

			var/last_link_blocked = LinkBlocked(previous, pathitem)

			if(last_link_blocked)
				world.log << "[owner]: LINK BETWEEN [previous] & [pathitem] OBSTRUCTED"
				// find the obstacle
				var/atom/obstruction = null

				if(!obstruction)
					for(var/atom/potential_obstruction_curr in pathitem.contents)
						var/datum/directional_blocker/blocker = potential_obstruction_curr?.directional_blocker
						if(!blocker)
							continue

						var/dirDelta = get_dir(previous, potential_obstruction_curr)
						var/blocks = blocker.Blocks(dirDelta)

						if(blocks)
							obstruction = potential_obstruction_curr
							break

				if(!obstruction && path_pos > 2) // check earlier steps
					for(var/atom/potential_obstruction_prev in previous.contents)
						var/datum/directional_blocker/blocker = potential_obstruction_prev?.directional_blocker
						if(!blocker)
							continue

						var/dirDeltaPrev = get_dir(path[path_pos-2], potential_obstruction_prev)
						var/blocksPrev = blocker.Blocks(dirDeltaPrev)

						if(blocksPrev)
							obstruction = potential_obstruction_prev
							break

				world.log << "[owner]: LINK OBSTRUCTION => [obstruction] @ [obstruction?.loc]"
				owner.brain.SetMemory(MEM_OBSTRUCTION, obstruction, MEM_TIME_LONGTERM)
				break

	return


/mob/goai/combatant/proc/HandleWaypoint(var/datum/ActionTracker/tracker)
	// Locate waypoint
	// Capture any obstacles
	// Add Action Goto<Goal> with clearing obstacles as a precond

	if(!src || !(src?.brain))
		tracker?.SetFailed()
		return

	var/atom/waypoint = brain.GetMemoryValue(MEM_WAYPOINT_IDENTITY, null, FALSE, TRUE)
	if(isnull(waypoint))
		tracker?.SetFailed() // b/c we shouldn't have triggered this in the first place if it's null
		return

	// Astar checking for obstacles
	src.SpotObstacles(src, waypoint, FALSE)

	var/list/goto_preconds = list(
		STATE_HASWAYPOINT = TRUE,
		STATE_CALM = TRUE,
		STATE_ORIENTED = TRUE,
	)

	var/atom/obstruction = brain.GetMemoryValue(MEM_OBSTRUCTION)

	var/obj/cover/door/D = obstruction

	if(D && istype(D) && !(D.open))
		var/obs_need_key = NEED_OBSTACLE_OPEN(obstruction)
		SetState(obs_need_key, NEED_MINIMUM)
		SetState("DoorClosed", (D.open ? NEED_MINIMUM : NEED_MAXIMUM))

		AddAction(
			"Open [obstruction]",
			list(
				"DoorClosed" = NEED_MAXIMUM,
				STATE_CALM = 1,
				STATE_ORIENTED = TRUE,
			),
			list(
				obs_need_key = NEED_MAXIMUM,
				"DoorClosed" = NEED_MINIMUM,
				"DoorOpen" = TRUE,
			),
			/mob/goai/combatant/proc/HandleOpenDoor,
			5,
			1
		)
		//goto_preconds[obs_need_key] = NEED_THRESHOLD
		goto_preconds[obs_need_key] = NEED_MINIMUM
		goto_preconds["DoorOpen"] = TRUE

	var/obj/cover/autodoor/AD = obstruction

	if(AD && istype(AD) && !(AD.open))
		var/obs_need_key = NEED_OBSTACLE_OPEN(obstruction)
		SetState(obs_need_key, NEED_MINIMUM)
		SetState("DoorClosed", NEED_MAXIMUM)

		AddAction(
			"Open [obstruction]",
			list(
				"DoorClosed" = NEED_MAXIMUM,
				STATE_CALM = 1,
				STATE_ORIENTED = TRUE,
			),
			list(
				obs_need_key = NEED_MAXIMUM,
				"DoorClosed" = NEED_MINIMUM,
				"DoorOpen" = TRUE,
			),
			/mob/goai/combatant/proc/HandleOpenAutodoor,
			5,
			1
		)
		//goto_preconds[obs_need_key] = NEED_THRESHOLD
		goto_preconds[obs_need_key] = NEED_MINIMUM
		goto_preconds["DoorOpen"] = TRUE

	// Add need to get near Waypoint

	/* Add any 'target-flavoured' actions, e.g.
		CoverleapDirTo<Waypoint>(
			prereqs=(normal_prereqs + obstacles),
			effects=(normal + need to be at target fulfilled)
		)
	*/

	AddAction(
		"MoveTowards [waypoint]",
		goto_preconds,
		list(
			NEED_COVER = NEED_SATISFIED,
			NEED_OBEDIENCE = NEED_SATISFIED,
			STATE_INCOVER = 1,
			STATE_DISORIENTED = 1,
		),
		/mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog,
		1,
		//1, /* It would MAKE SENSE to limit charges on this (so a new PathPlan readds a new charge)
		//      except for the fact that for some reason IT DOESN'T WORK ARGH (yet, probably - TODO) */
		PLUS_INF
	)

	SetState(STATE_DISORIENTED, FALSE)
	SetState(STATE_ORIENTED, TRUE)

	tracker.SetDone()
	return
