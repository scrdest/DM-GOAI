
/mob/goai/combatant/proc/FightTick()
	var/can_fire = ((STATE_CANFIRE in states) ? states[STATE_CANFIRE] : FALSE)
	if(!can_fire)
		return

	var/atom/target = GetTarget()
	Shoot(NONE, target)

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
