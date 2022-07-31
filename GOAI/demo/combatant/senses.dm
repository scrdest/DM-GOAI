
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

	if(isnull(owner.waypoint))
		return

	var/datum/brain/owner_brain = owner?.brain
	if(isnull(owner_brain))
		// No point processing this if there's no memories to set
		return

	if(owner_brain.GetMemory(MEM_WAYPOINT_LKP, FALSE, FALSE))
		return

	var/list/true_searchspace = owner_brain?.perceptions?.Get(SENSE_SIGHT)
	if(!(true_searchspace))
		return

	if(owner.waypoint in true_searchspace)
		var/list/waypoint_memory_data = list(
			KEY_GHOST_X = owner.waypoint.x,
			KEY_GHOST_Y = owner.waypoint.y,
			KEY_GHOST_Z = owner.waypoint.z,
			KEY_GHOST_POS_TUPLE = owner.waypoint.CurrentPositionAsTuple(),
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


/mob/goai/combatant/InitSenses()
	. = ..()
	var/sense/combatant_eyes/eyes = new()
	senses.Add(eyes)
	return


/mob/goai/combatant/proc/SensesSystem()
	/* We're rolling ECS-style */
	for(var/sense/sensor in senses)
		sensor.ProcessTick(src)
	return
