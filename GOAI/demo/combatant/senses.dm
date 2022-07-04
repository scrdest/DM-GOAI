
.
/sense/combatant_eyes

/sense/combatant_eyes/proc/SpotThreats(var/mob/goai/combatant/owner)
	if(isnull(owner))
		return

	var/datum/brain/owner_brain = owner.brain
	if(isnull(owner_brain))
		// No point processing this if there's no memories to set
		return

	var/list/true_searchspace = view(owner)

	var/PriorityQueue/target_queue = new /PriorityQueue(/datum/Tuple/proc/FirstCompare)

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
		owner_brain.SetMemory(MEM_THREAT, threat_memory_ghost, COMBATAI_AI_TICK_DELAY*50)

		// forecast-raycast goes here once I find it

	return TRUE


/sense/combatant_eyes/ProcessTick(var/owner)
	..(owner)

	if(processing)
		return

	processing = TRUE
	SpotThreats(owner)

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
