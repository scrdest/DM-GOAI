
/sense/combatant_eyes


/sense/combatant_eyes/proc/UpdatePerceptions(var/mob/goai/combatant/owner)
	var/datum/brain/owner_brain = owner.brain
	if(isnull(owner_brain))
		// No point processing this if there's no memories to set
		return

	var/list/visual_range = view(owner)
	owner_brain?.perceptions[SENSE_SIGHT] = visual_range


/sense/combatant_eyes/proc/SpotThreats(var/mob/goai/combatant/owner)
	if(isnull(owner))
		return

	var/datum/brain/owner_brain = owner.brain
	if(isnull(owner_brain))
		// No point processing this if there's no memories to set
		return

	var/list/true_searchspace = owner_brain?.perceptions?.Get(SENSE_SIGHT)
	if(!(true_searchspace))
		return

	var/PriorityQueue/target_queue = new /PriorityQueue(/datum/Tuple/proc/FirstCompare)

	// TODO: Refactor to accept objects/structures as threats (turrets, grenades...).
	for(var/mob/goai/combatant/enemy in true_searchspace)
		var/enemy_dist = ManhattanDistance(owner, enemy)

		if (enemy_dist <= 0)
			continue

		var/datum/Tuple/enemy_tup = new(-enemy_dist, enemy)
		target_queue.Enqueue(enemy_tup)

	var/tries = 0
	var/maxtries = 3
	var/atom/target = null

	while (isnull(target) && target_queue.L.len && tries < maxtries)
		var/datum/Tuple/best_target_tup = target_queue.Dequeue()
		target = best_target_tup.right
		tries++

	if(istype(target))
		var/list/threat_memory_data = list(
			KEY_GHOST_X = target.x,
			KEY_GHOST_Y = target.y,
			KEY_GHOST_Z = target.z,
			KEY_GHOST_POS_TUPLE = target.CurrentPositionAsTuple(),
		)
		var/dict/threat_memory_ghost = new(threat_memory_data)
		owner_brain.SetMemory(MEM_THREAT, threat_memory_ghost, COMBATAI_AI_TICK_DELAY*20)

		// forecast-raycast goes here once I find it

	/* Secondary threat handling.
	// Sadly, using a list of threats was not performant, so
	// we're just allowing two 'slots' for threats.
	// Because of how a PQ works, secondary threat is guaranteed
	// to be of no greater priority than the primary threat.
	*/
	var/secondary_tries = 0
	var/secondary_maxtries = 3
	var/atom/secondary_threat = null

	while (isnull(secondary_threat) && target_queue.L.len && secondary_tries < secondary_maxtries)
		var/datum/Tuple/best_sec_target_tup = target_queue.Dequeue()
		target = best_sec_target_tup.right
		secondary_tries++

	if(istype(secondary_threat))
		var/list/secondary_threat_memory_data = list(
			KEY_GHOST_X = secondary_threat.x,
			KEY_GHOST_Y = secondary_threat.y,
			KEY_GHOST_Z = secondary_threat.z,
			KEY_GHOST_POS_TUPLE = secondary_threat.CurrentPositionAsTuple(),
		)
		var/dict/secondary_threat_memory_ghost = new(secondary_threat_memory_data)
		owner_brain.SetMemory(MEM_THREAT_SECONDARY, secondary_threat_memory_ghost, COMBATAI_AI_TICK_DELAY*20)

	return TRUE


/sense/combatant_eyes/proc/SpotWaypoint(var/mob/goai/combatant/owner)
	if(isnull(owner))
		return

	var/datum/brain/owner_brain = owner?.brain
	if(isnull(owner_brain))
		// No point processing this if there's no memories to use
		return

	var/datum/memory/waypoint_mem = owner.brain.GetMemory(MEM_WAYPOINT_IDENTITY, null, FALSE, TRUE)

	if(isnull(waypoint_mem))
		return

	var/atom/waypoint = waypoint_mem?.val
	if(isnull(waypoint))
		return

	if(owner_brain.GetMemory(MEM_WAYPOINT_LKP, FALSE, FALSE))
		return

	var/list/true_searchspace = owner_brain?.perceptions?.Get(SENSE_SIGHT)
	if(!(true_searchspace))
		return

	if(waypoint in true_searchspace)
		var/list/waypoint_memory_data = list(
			KEY_GHOST_X = waypoint.x,
			KEY_GHOST_Y = waypoint.y,
			KEY_GHOST_Z = waypoint.z,
			KEY_GHOST_POS_TUPLE = waypoint.CurrentPositionAsTuple(),
		)
		var/dict/waypoint_memory_ghost = new(waypoint_memory_data)
		owner_brain.SetMemory(MEM_WAYPOINT_LKP, waypoint_memory_ghost, COMBATAI_AI_TICK_DELAY*20)

	return TRUE


/sense/combatant_eyes/ProcessTick(var/owner)
	..(owner)

	if(processing)
		return

	processing = TRUE

	UpdatePerceptions(owner)
	SpotThreats(owner)
	SpotWaypoint(owner)

	spawn(COMBATAI_AI_TICK_DELAY * 3)
		// Sense-side delay to avoid spamming view() scans too much
		processing = FALSE
	return


/sense/combatant_obstruction_handler
	/* Spots obstacles that can be overcome with an Action,
	// such as doors (Open/Break), tables (Climb), etc.
	// and updates the Owner with actions to handle that action.
	*/


/sense/combatant_obstruction_handler/proc/SpotObstacles(var/mob/goai/combatant/owner)
	if(!owner)
		// No mob - no point.
		return

	var/datum/brain/owner_brain = owner?.brain
	if(isnull(owner_brain))
		// No point processing this if there's no memories to use
		// Might not be a precondition later.
		return

	var/datum/memory/waypoint_mem = owner.brain.GetMemory(MEM_WAYPOINT_IDENTITY, null, FALSE, TRUE)

	if(isnull(waypoint_mem))
		// Nothing to spot.
		return

	var/atom/waypoint = waypoint_mem?.val
	if(isnull(waypoint))
		// Nothing to spot.
		return

	var/list/path = null
	var/turf/target = get_turf(waypoint)

	if(isnull(target))
		target = get_turf(waypoint.loc)

	var/turf/startpos = get_turf(owner)
	var/init_dist = 30
	var/sqrt_dist = get_dist(startpos, target) ** 0.5

	if(init_dist < 40)
		world.log << "[owner] entering ASTARS STAGE"
		path = AStar(owner, target, /turf/proc/CardinalTurfs, /turf/proc/Distance, null, init_dist, min_target_dist = sqrt_dist, exclude = null)
		world.log << "[owner] found ASTAR 1 path from [startpos] to [target]: [path] ([path?.len])"

		if(path)
			world.log << "[owner] entering HAPPYPATH"

		else if(!(path && path.len))
			// No unobstructed path to target!
			// Let's try to get a direct path and check for obstacles.
			path = AStar(owner, target, /turf/proc/CardinalTurfsNoblocks, /turf/proc/Distance, null, init_dist, min_target_dist = sqrt_dist, exclude = null)
			world.log << "[src] found ASTAR 2 path from [startpos] to [target]: [path] ([path?.len])"

			if(path)
				var/path_pos = 0

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
						var/obj/cover/door/D = obstruction

						if(D && istype(D))
							owner.brain.SetMemory(MEM_OBSTRUCTION, obstruction, 1000)
							var/obs_need_key = "Passable @ [D]"
							owner.needs[obs_need_key] = NEED_MINIMUM
							owner.AddAction("Open [D]", list(), list(obs_need_key = NEED_MAXIMUM, NEED_COVER = NEED_SATISFIED, NEED_OBEDIENCE = NEED_SATISFIED), /mob/goai/combatant/proc/HandleOpenDoor, 5, 1)
							break
						// Update Actions, somehow - fetch actions from obstruction?

						var/obj/cover/autodoor/AD = obstruction

						if(AD && istype(AD))
							owner.brain.SetMemory(MEM_OBSTRUCTION, obstruction, 1000)
							var/obs_need_key = "Passable @ [D]"
							owner.needs[obs_need_key] = NEED_MINIMUM
							owner.AddAction("Open [D]", list(), list(obs_need_key = NEED_MAXIMUM, NEED_COVER = NEED_SATISFIED, NEED_OBEDIENCE = NEED_SATISFIED), /mob/goai/combatant/proc/HandleOpenAutodoor, 5, 1)
							break

						break
	return


/sense/combatant_obstruction_handler/ProcessTick(var/owner)
	..(owner)

	if(processing)
		return

	processing = TRUE

	SpotObstacles(owner)

	spawn(COMBATAI_AI_TICK_DELAY * 20)
		// Sense-side delay to avoid spamming view() scans too much
		processing = FALSE
	return


/mob/goai/combatant/InitSenses()
	. = ..()
	var/sense/combatant_eyes/eyes = new()
	var/sense/combatant_obstruction_handler/obstacle_handler = new()
	senses.Add(eyes)
	senses.Add(obstacle_handler)
	return


/mob/goai/combatant/proc/SensesSystem()
	/* We're rolling ECS-style */
	for(var/sense/sensor in senses)
		sensor.ProcessTick(src)
	return
