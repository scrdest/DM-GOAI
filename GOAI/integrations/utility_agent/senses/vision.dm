
/sense/combatant_commander_eyes
	// Only run if units are simulated properly and not abstracted
	min_lod = GOAI_LOD_UNIT_LOW

	// max length of stored enemies
	var/max_enemies = DEFAULT_MAX_ENEMIES

	// max distance to count friendlies
	var/enemy_dist_cutoff = 12

	// do raycasts from the enemies to us and sets a flag if enabled (nonzero)
	// negative values are treated as infinity, positive as limit of enemies checked
	var/check_threatened_max = DEFAULT_MAX_ENEMIES

	// max length of stored friends
	var/max_friends = DEFAULT_MAX_ENEMIES

	// max distance to count friendlies
	var/friend_dist_cutoff = 6

	// filter out dead mobs
	var/ignore_dead = TRUE

	var/sense_side_delay_mult = 1


/sense/combatant_commander_eyes/proc/UpdatePerceptions(var/datum/utility_ai/mob_commander/owner)
	var/datum/brain/owner_brain = owner.brain

	if(isnull(owner_brain))
		// No point processing this if there's no memories to set
		return

	var/atom/pawn = owner.GetPawn()

	if(!istype(pawn))
		// We grab the view range from the owned mob, so we need it here
		return

	var/list/_raw_visual_range = view(pawn)
	var/list/visual_range = list()

	for(var/atom/viewthing in _raw_visual_range)
		if(!(CHECK_ALL_FLAGS(viewthing.goai_processing_visibility, GOAI_VISTYPE_STANDARD)))
			//GOAI_LOG_DEBUG("Skipping [viewthing] from sight - goai_processing_visibility is [viewthing.goai_processing_visibility] vs [GOAI_VISTYPE_STANDARD] required.")
			continue

		visual_range.Add(viewthing)

	if(visual_range)
		owner_brain.perceptions[SENSE_SIGHT_CURR] = visual_range

	/*
	// Disabled because it takes a lot of memory for not a lot of obvious benefit
	var/list/old_visual_range = owner_brain?.perceptions?[SENSE_SIGHT_CURR]
	if(old_visual_range)
		owner_brain?.perceptions[SENSE_SIGHT_PREV] = old_visual_range

	owner_brain?.perceptions[SENSE_SIGHT_CURR] = (visual_range || list()) | (old_visual_range || list())
	*/

	return


/sense/combatant_commander_eyes/proc/AssessThreats(var/datum/utility_ai/mob_commander/owner)
	if(isnull(owner))
		return

	var/datum/brain/owner_brain = owner.brain
	if(isnull(owner_brain))
		// No point processing this if there's no memories to set
		return

	var/list/true_searchspace = owner_brain?.perceptions?.Get(SENSE_SIGHT_CURR)
	if(!(true_searchspace))
		return

	var/atom/pawn = owner?.GetPawn()

	if(!istype(pawn))
		return

	var/my_loc = pawn.loc

	if(isnull(my_loc))
		return

	var/PriorityQueue/target_queue = new DEFAULT_PRIORITY_QUEUE_IMPL(/datum/Tuple/proc/FirstCompare)

	var/list/occupied_turfs = list()

	var/list/friends = list()
	var/list/friend_positions = list()

	var/list/enemies = list()
	var/list/enemy_positions = list()

	// TODO: Refactor to accept objects/structures as threats (turrets, grenades...).
	for(var/mob/enemy in true_searchspace)
		if(!(istype(enemy, /mob/living/carbon) || istype(enemy, /mob/living/simple_animal) || istype(enemy, /mob/living/bot)))
			continue

		var/mob/living/L = enemy
		if(ignore_dead && istype(L) && L.stat == DEAD)
			continue

		var/turf/enemyTurf = get_turf(enemy)
		if(!isnull(enemyTurf) && !(enemyTurf in occupied_turfs))
			occupied_turfs.Add(enemyTurf)

		var/enemy_dist = ManhattanDistance(my_loc, enemy)

		if (enemy_dist <= 0 || enemy_dist > src.enemy_dist_cutoff)
			continue

		if(owner.IsFriend(enemy))
			if(length(friends) < src.max_friends && enemy_dist < friend_dist_cutoff)
				friends.Add(enemy)
				var/turf/friend_pos = get_turf(enemy)
				if(!isnull(friend_pos))
					friend_positions.Add(friend_pos)

			continue

		var/datum/Tuple/enemy_tup = new(enemy_dist, enemy)
		target_queue.Enqueue(enemy_tup)

	owner_brain.SetMemory(MEM_OCCUPIED_TURFS, occupied_turfs, owner.ai_tick_delay * MEM_AITICK_MULT_SHORTTERM)

	var/tries = 0
	var/maxtries = 3
	var/atom/target = null

	while (isnull(target) && target_queue.L.len && tries < maxtries)
		var/datum/Tuple/best_target_tup = target_queue.Dequeue()
		target = best_target_tup.right
		tries++

		if(istype(target) && length(enemies) < src.max_enemies)
			enemies.Add(target)
			var/turf/trgTurf = get_turf(target)
			if(istype(trgTurf))
				enemy_positions.Add(trgTurf)

	if(istype(target))
		var/turf/threat_pos = get_turf(target)
		if(istype(threat_pos))
			owner_brain.SetMemory(MEM_THREAT, threat_pos, owner.ai_tick_delay * MEM_AITICK_MULT_SHORTTERM)

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

		if(istype(target) && length(enemies) < src.max_enemies)
			enemies.Add(target)
			var/turf/trgTurf = get_turf(target)
			if(istype(trgTurf))
				enemy_positions.Add(trgTurf)

	if(istype(secondary_threat))
		var/turf/secondary_threat_pos = get_turf(target)
		if(istype(secondary_threat_pos))
			owner_brain.SetMemory(MEM_THREAT_SECONDARY, secondary_threat_pos, owner.ai_tick_delay * MEM_AITICK_MULT_SHORTTERM)

	while(length(target_queue.L) && length(enemies) < src.max_enemies)
		var/datum/Tuple/next_enemy_tuple = target_queue.Dequeue()
		var/atom/nme = next_enemy_tuple.right
		if(istype(nme))
			enemies.Add(nme)
			var/turf/nmeT = get_turf(nme)
			if(istype(nmeT))
				enemy_positions.Add(nmeT)

	// Just the currently visible mobs
	// Short-term - otherwise AI will be clairvoyant
	owner_brain.SetMemory(MEM_FRIENDS, friends, owner.ai_tick_delay * MEM_AITICK_MULT_SHORTTERM)
	owner_brain.SetMemory(MEM_ENEMIES, enemies, owner.ai_tick_delay * MEM_AITICK_MULT_SHORTTERM)

	if(length(friend_positions))
		owner_brain.SetMemory(MEM_FRIENDS_POSITIONS, friend_positions, owner.ai_tick_delay * MEM_AITICK_MULT_SHORTTERM)

	if(length(enemy_positions))
		// Copy the previous latest
		var/list/current_stored_enemy_positions = owner_brain.GetMemoryValue(MEM_ENEMIES_POSITIONS_LATEST) || list()

		// Update with new
		owner_brain.SetMemory(MEM_ENEMIES_POSITIONS_LATEST, enemy_positions.Copy(), owner.ai_tick_delay * MEM_AITICK_MULT_SHORTTERM)

		// shift previous tick's positions to another slot
		if(length(current_stored_enemy_positions))
			owner_brain.SetMemory(MEM_ENEMIES_POSITIONS_RETAINED, current_stored_enemy_positions, owner.ai_tick_delay * MEM_AITICK_MULT_MIDTERM)

			// merge in previous for a separate memory of both ticks
			enemy_positions.Add(current_stored_enemy_positions)

		// Store the two lists merged
		owner_brain.SetMemory(MEM_ENEMIES_POSITIONS, enemy_positions, owner.ai_tick_delay * MEM_AITICK_MULT_MIDTERM)

	var/threats_checked = 0

	if(src.check_threatened_max)
		var/list/ignorelist = enemies.Copy()

		for(var/atom/raytrace_enemy in enemies)
			if(src.check_threatened_max > 0 && threats_checked++ >= src.check_threatened_max)
				break

			var/atom/whosehit = AtomDensityRaytrace(raytrace_enemy, pawn, ignorelist, RAYTYPE_PROJECTILE, FALSE)
			if(isnull(whosehit))
				continue

			if(whosehit == pawn)
				owner_brain.SetMemory(MEM_POS_THREATENED, TRUE, owner.ai_tick_delay * MEM_AITICK_MULT_SHORTTERM)
				break


	return TRUE


/sense/combatant_commander_eyes/proc/SpotWaypoint(var/datum/utility_ai/mob_commander/owner)
	if(isnull(owner))
		return

	var/datum/brain/owner_brain = owner?.brain
	if(isnull(owner_brain))
		// No point processing this if there's no memories to use
		return

	var/atom/waypoint = owner.brain.GetMemoryValue(MEM_WAYPOINT_IDENTITY, null, FALSE, TRUE)

	if(isnull(waypoint))
		return

	if(owner_brain.GetMemory(MEM_WAYPOINT_LKP, FALSE, FALSE))
		return

	var/list/true_searchspace = owner_brain?.perceptions?.Get(SENSE_SIGHT_CURR)
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
		owner_brain.SetMemory(MEM_WAYPOINT_LKP, waypoint_memory_ghost, owner.ai_tick_delay*20)

	return TRUE


/sense/combatant_commander_eyes/ProcessTick(var/owner)
	..(owner)

	if(processing)
		return

	processing = TRUE

	UpdatePerceptions(owner)
	AssessThreats(owner)
	//SpotWaypoint(owner)

	spawn(src.GetOwnerAiTickrate(owner) * src.sense_side_delay_mult)
		// Sense-side delay to avoid spamming view() scans too much
		processing = FALSE
	return
