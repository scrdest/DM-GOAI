
/datum/aim
	var/atom/target

/datum/aim/New(var/atom/aim_target)
	target = aim_target


/mob/goai/combatant/proc/FightTick()
	var/can_fire = ((STATE_CANFIRE in states) ? states[STATE_CANFIRE] : FALSE)
	
	if(!can_fire)
		return

	var/atom/target = GetTarget()

	var/datum/memory/aim_mem = brain?.GetMemory(KEY_ACTION_AIM, null, FALSE)
	var/datum/aim/target_aim = aim_mem?.val

	var/aim_time = GetAimTime(target)

	if(isnull(target_aim) || target_aim.target != target)
		if(brain)
			target_aim = new(target)
			aim_mem = brain?.SetMemory(KEY_ACTION_AIM, target_aim, aim_time*5)
			// we started aiming, no point in moving forwards
			// I guess unless/until I add melee...
			return

	spawn(aim_time)
		if(target in view(src))
			Shoot(NONE, target)

	return


/mob/goai/combatant/proc/GetAimTime(var/atom/target)
	if(isnull(target))
		return
	
	var/targ_distance = EuclidDistance(src, target)
	var/aim_time = rand(clamp(targ_distance*5, 1, 200)) + rand()*10
	return aim_time


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


/mob/goai/combatant/proc/Shoot(var/obj/gun/cached_gun = NONE, var/atom/cached_target = NONE, var/datum/aim/cached_aim = NONE)
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


/mob/goai/combatant/proc/GetActiveThreat() // -> /dict
	var/datum/memory/threat_mem = brain?.GetMemory(MEM_THREAT, null, FALSE)
	//world.log << "[src] threat memory: [threat_mem]"

	var/dict/threat_ghost = threat_mem?.val
	return threat_ghost


/mob/goai/combatant/proc/GetThreatDistance(var/atom/relative_to = null, var/dict/curr_threat = null) // -> num
	var/atom/rel_source = isnull(relative_to) ? src : relative_to
	var/dict/threat_ghost = isnull(curr_threat) ? GetActiveThreat() : curr_threat
	var/threat_dist = 0

	if(isnull(threat_ghost))
		return threat_dist

	var/threat_pos_x = 0
	var/threat_pos_y = 0

	//world.log << "[src] threat ghost: [threat_ghost]"

	if(!isnull(threat_ghost))
		threat_pos_x = threat_ghost.Get(KEY_GHOST_X, null)
		threat_pos_y = threat_ghost.Get(KEY_GHOST_Y, null)
		//world.log << "[src] believes there's a threat at ([threat_pos_x], [threat_pos_y])"

		if(! (isnull(threat_pos_x) || isnull(threat_pos_y)) )
			threat_dist = ManhattanDistanceNumeric(rel_source.x, rel_source.y, threat_pos_x, threat_pos_y)

	return threat_dist


/mob/goai/combatant/proc/GetThreatAngle(var/atom/relative_to = null, var/dict/curr_threat = null)
	var/atom/rel_source = isnull(relative_to) ? src : relative_to
	var/dict/threat_ghost = isnull(curr_threat) ? GetActiveThreat() : curr_threat
	var/threat_angle = null

	if(isnull(threat_ghost))
		return threat_angle

	var/threat_pos_x = 0
	var/threat_pos_y = 0

	//world.log << "[src] threat ghost: [threat_ghost]"

	if(!isnull(threat_ghost))
		threat_pos_x = threat_ghost.Get(KEY_GHOST_X, null)
		threat_pos_y = threat_ghost.Get(KEY_GHOST_Y, null)
		//world.log << "[src] believes there's a threat at ([threat_pos_x], [threat_pos_y])"

		if(! (isnull(threat_pos_x) || isnull(threat_pos_y)) )
			var/dx = (threat_pos_x - rel_source.x)
			var/dy = (threat_pos_y - rel_source.y)
			threat_angle = arctan(dx, dy)

	return threat_angle


/mob/goai/combatant/Hit(var/angle, var/atom/shotby = null)
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
	//world.log << "Impact angle [impact_angle]"

	var/list/shot_memory_data = list(
		KEY_GHOST_X = src.x,
		KEY_GHOST_Y = src.y,
		KEY_GHOST_Z = src.z,
		KEY_GHOST_POS_TUPLE = src.CurrentPositionAsTuple(),
		KEY_GHOST_ANGLE = impact_angle,
	)
	var/dict/shot_memory_ghost = new(shot_memory_data)

	brain.SetMemory(MEM_SHOTAT, shot_memory_ghost, COMBATAI_AI_TICK_DELAY*10)

	/* disabled for testing Senses */
	/*
	if (!isnull(shotby))
		var/list/threat_memory_data = list(
			KEY_GHOST_X = shotby.x,
			KEY_GHOST_Y = shotby.y,
			KEY_GHOST_Z = shotby.z,
			KEY_GHOST_POS_TUPLE = shotby.CurrentPositionAsTuple(),
		)
		var/dict/threat_memory_ghost = new(threat_memory_data)
		brain.SetMemory(MEM_THREAT, threat_memory_ghost, COMBATAI_AI_TICK_DELAY*50)
	*/
