/mob/goai/combatant/proc/HandlePanickedRun(var/datum/ActionTracker/tracker)
	var/tracker_frustration = tracker.BBSetDefault("frustration", 0)
	var/turf/best_local_pos = tracker?.BBGet("bestpos", null)

	var/min_safe_dist = brain.GetPersonalityTrait(KEY_PERS_MINSAFEDIST, 2) ** 2
	var/frustration_repath_maxthresh = brain.GetPersonalityTrait(KEY_PERS_FRUSTRATION_THRESH, null) || world.log << "Missed KEY_PERS_FRUSTRATION_THRESH" || 3

	var/list/threats = new()

	// Main threat:
	var/dict/primary_threat_ghost = GetActiveThreat()
	var/datum/Tuple/primary_threat_pos_tuple = GetThreatPosTuple(primary_threat_ghost)
	var/atom/primary_threat = null
	if(!(isnull(primary_threat_pos_tuple?.left) || isnull(primary_threat_pos_tuple?.right)))
		primary_threat = locate(primary_threat_pos_tuple.left, primary_threat_pos_tuple.right, src.z)

	if(primary_threat_ghost)
		threats[primary_threat_ghost] = primary_threat

	//world.log << "[src]: Threat for [src]: [threat || "NONE"]"

	// Secondary threat:
	var/dict/secondary_threat_ghost = GetActiveSecondaryThreat()
	var/datum/Tuple/secondary_threat_pos_tuple = GetThreatPosTuple(secondary_threat_ghost)
	var/atom/secondary_threat = null
	if(!(isnull(secondary_threat_pos_tuple?.left) || isnull(secondary_threat_pos_tuple?.right)))
		secondary_threat = locate(secondary_threat_pos_tuple.left, secondary_threat_pos_tuple.right, src.z)

	if(secondary_threat_ghost)
		threats[secondary_threat_ghost] = secondary_threat

	// Shot-at logic (avoid known currently unsafe positions):
	var/datum/memory/shot_at_mem = brain?.GetMemory(MEM_SHOTAT, null, FALSE)
	var/dict/shot_at_memdata = shot_at_mem?.val
	var/datum/Tuple/shot_at_where = shot_at_memdata?.Get(KEY_GHOST_POS_TUPLE, null)

	// Reuse cached solution if it's good enough
	if(isnull(best_local_pos) && active_path && (!(active_path.IsDone())) && active_path.target && active_path.frustration < 2)
		best_local_pos = active_path.target

	// Required for the following logic: next location on the path
	var/atom/next_step = ((active_path && active_path.path && active_path.path.len) ? active_path.path[1] : null)

	// Bookkeeping around threats
	for(var/dict/threat_ghost in threats)
		if(isnull(threat_ghost))
			continue

		var/atom/curr_threat = threats[threat_ghost]
		var/next_step_threat_distance = (next_step ? GetThreatDistance(next_step, threat_ghost, PLUS_INF) : PLUS_INF)
		var/curr_threat_distance = GetThreatDistance(src, threat_ghost, PLUS_INF)
		var/bestpos_threat_distance = GetThreatDistance(best_local_pos, threat_ghost, PLUS_INF)

		var/atom/bestpos_threat_neighbor = (curr_threat ? get_step_towards(best_local_pos, curr_threat) : null)

		// Reevaluating plans as new threats pop up
		var/bestpos_is_unsafe = (bestpos_threat_distance < min_safe_dist && !(bestpos_threat_neighbor?.IsCover()))
		var/currpos_is_unsafe = (
			(tracker_frustration < frustration_repath_maxthresh) && (curr_threat_distance <= min_safe_dist) && (next_step_threat_distance < curr_threat_distance)
		)

		if(bestpos_is_unsafe || currpos_is_unsafe)
			tracker.BBSet("frustration", tracker_frustration+1)

			CancelNavigate()
			best_local_pos = null
			tracker.BBSet("bestpos", null)
			break

	if(isnull(best_local_pos))
		var/list/processed = list(src.loc)
		var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Quadruple/proc/TriCompare)
		var/list/curr_view = brain?.perceptions?.Get(SENSE_SIGHT)

		for(var/turf/cand in curr_view)
			if(!(cand.Enter(src)))
				continue

			if(cand in processed)
				continue

			var/penalty = 0

			var/threat_dist = 0
			var/invalid_tile = FALSE

			for(var/dict/threat_ghost in threats)
				threat_dist = GetThreatDistance(cand, threat_ghost)
				var/threat_angle = GetThreatAngle(cand, threat_ghost)
				var/threat_dir = angle2dir(threat_angle)

				var/atom/maybe_cover = get_step(cand, threat_dir)

				if(maybe_cover && !(maybe_cover.density))  // is cover check
					penalty += 50

				if(threat_ghost && threat_dist < min_safe_dist)
					invalid_tile = TRUE
					break

				/* Bit of a hack: for now, let's only consider primary threat
				// for Panicking - this should mean that a Panic state is just
				// trying to bail from the primary ASAP, even if it's a little
				// bit irrational.
				*/
				break

			if(invalid_tile)
				continue

			var/datum/Tuple/curr_pos_tup = cand.CurrentPositionAsTuple()

			if (curr_pos_tup ~= shot_at_where)
				world.log << "[src]: Curr pos tup [curr_pos_tup] ([curr_pos_tup?.left], [curr_pos_tup?.right]) equals shot_at_where"
				continue

			var/cand_dist = ManhattanDistance(cand, src)
			//var/targ_dist = (waypoint ? ManhattanDistance(cand, waypoint) : 0)
			var/targ_dist = 0 // ignore waypoint, just leg it!
			var/total_dist = (cand_dist + targ_dist)

			/*if(threat_dist < min_safe_dist)
				continue*/

			penalty += -threat_dist  // the further from a threat, the better

			var/datum/Quadruple/cover_quad = new(-penalty, threat_dist, -total_dist, cand)
			cover_queue.Enqueue(cover_quad)
			processed.Add(cand)

		var/datum/Quadruple/best_cand_quad = cover_queue.Dequeue()

		if(best_cand_quad)
			best_local_pos = best_cand_quad?.fourth
			tracker.BBSet("bestpos", best_local_pos)

		world.log << (isnull(best_local_pos) ? "[src]: Best local pos: null" : "[src]: Best local pos [best_local_pos]")


	if(best_local_pos && (!active_path || active_path.target != best_local_pos))
		world.log << "[src]: Navigating to [best_local_pos]"
		StartNavigateTo(best_local_pos, 0, primary_threat?.loc)

	if(best_local_pos)
		var/dist_to_pos = ManhattanDistance(src.loc, best_local_pos)
		if(dist_to_pos < 1)
			tracker.SetTriggered()

	var/is_triggered = tracker.IsTriggered()

	if(is_triggered)
		if(tracker.TriggeredMoreThan(COMBATAI_AI_TICK_DELAY))
			tracker.SetDone()

			var/datum/brain/concrete/needybrain = brain
			if(needybrain)
				needybrain.ChangeMotive(NEED_COMPOSURE, NEED_SAFELEVEL)

			SetState(STATE_PANIC, -1)

	else if(active_path && tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * 20))
		tracker.SetFailed()

	else if(tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * 10))
		tracker.SetFailed()

	return
