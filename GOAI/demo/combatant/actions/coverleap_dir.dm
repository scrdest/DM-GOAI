/mob/goai/combatant/proc/ChooseCoverleapLandmark(var/atom/startpos, var/atom/primary_threat = null, var/turf/prev_loc_memdata = null, var/list/threats = null, min_safe_dist = null)
	// Pathfinding/search
	var/atom/_startpos = (startpos || src.loc)
	var/list/_threats = (threats || list())
	var/_min_safe_dist = (isnull(min_safe_dist) ? 0 : min_safe_dist)

	var/turf/best_local_pos = null
	//var/list/processed = list(_startpos)
	var/list/processed = list()
	var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Quadruple/proc/TriCompare)

	var/list/curr_view = brain?.perceptions?.Get(SENSE_SIGHT)
	curr_view.Add(_startpos)

	var/turf/safespace_loc = brain?.GetMemoryValue(MEM_SAFESPACE, null)
	if(safespace_loc)
		curr_view.Add(safespace_loc)

	var/effective_waypoint_x = null
	var/effective_waypoint_y = null

	var/atom/waypoint_ident = brain?.GetMemoryValue(MEM_WAYPOINT_IDENTITY, null, FALSE, TRUE)

	if(waypoint_ident)
		// This only applies to the case where the brain has a Waypoint stored, i.e. when we're
		//   deliberately moving towards a specific location as opposed to patrolling randomly.
		// This lets us reuse one handler for both random and directed cover leapfrogs.
		var/list/waypoint_memdata = brain?.GetMemoryValue(MEM_WAYPOINT_LKP, null, FALSE, TRUE)
		var/mem_waypoint_x = waypoint_memdata?[KEY_GHOST_X]
		var/mem_waypoint_y = waypoint_memdata?[KEY_GHOST_Y]
		world.log << "[src] waypoint positions: ([mem_waypoint_x], [mem_waypoint_y]) from [waypoint_memdata]"

		if(!isnull(mem_waypoint_x) && !isnull(mem_waypoint_y))
			world.log << "[src] found waypoint position in memory!"
			effective_waypoint_x = mem_waypoint_x
			effective_waypoint_y = mem_waypoint_y

		else
			var/datum/Tuple/waypoint_position = waypoint_ident.CurrentPositionAsTuple()

			effective_waypoint_x = waypoint_position.left + rand(-WAYPOINT_FUZZ_X, WAYPOINT_FUZZ_X)
			effective_waypoint_y = waypoint_position.right + rand(-WAYPOINT_FUZZ_Y, WAYPOINT_FUZZ_Y)

	var/turf/unreachable = brain?.GetMemoryValue("UnreachableTile", null)

	for(var/atom/candidate_cover in curr_view)
		if(unreachable && candidate_cover == unreachable)
			continue

		var/has_cover = candidate_cover?.HasCover(get_dir(candidate_cover, primary_threat), FALSE)
		// IsCover here is Transitive=FALSE b/c has_cover will have checked transitives already)
		var/is_cover = candidate_cover?.IsCover(FALSE, get_dir(candidate_cover, primary_threat), FALSE)

		if(!(has_cover || is_cover))
			continue

		var/turf/cover_loc = (istype(candidate_cover, /turf) ? candidate_cover : candidate_cover?.loc)
		var/list/adjacents = (has_cover ? list(candidate_cover) : (cover_loc?.CardinalTurfs(TRUE) || list()))
		/*var/list/adjacents = cover_loc?.CardinalTurfs(TRUE) || list()

		if(has_cover)
			adjacents.Add(candidate_cover)*/

		if(!adjacents)
			continue

		for(var/turf/cand in adjacents)
			if(!(cand?.Enter(src, src.loc)))
				continue

			if(cand in processed)
				continue

			if(!(cand in curr_view) && (cand != prev_loc_memdata))
				continue

			var/penalty = 0

			if(cand == candidate_cover || cand == candidate_cover.loc)
				penalty -= 50

			if(prev_loc_memdata && prev_loc_memdata == cand)
				//world.log << "Prev loc [prev_loc_memdata] matched candidate [cand]"
				penalty += MAGICNUM_DISCOURAGE_SOFT

			var/threat_dist = PLUS_INF
			var/invalid_tile = FALSE

			for(var/dict/threat_ghost in _threats)
				threat_dist = GetThreatDistance(cand, threat_ghost)
				var/threat_angle = GetThreatAngle(cand, threat_ghost)
				var/threat_dir = angle2dir(threat_angle)

				var/tile_is_cover = (cand.IsCover(TRUE, threat_dir, FALSE) && cand.Enter(src, src.loc))

				var/atom/maybe_cover = get_step(cand, threat_dir)

				if(maybe_cover && !(tile_is_cover ^ maybe_cover.IsCover(TRUE, threat_dir, FALSE)))
					invalid_tile = TRUE
					break

				if(threat_ghost && threat_dist < _min_safe_dist)
					invalid_tile = TRUE
					break

			if(invalid_tile)
				continue

			var/cand_dist = ManhattanDistance(cand, src)
			if(cand_dist < 3)
				// we want substantial moves only
				penalty += MAGICNUM_DISCOURAGE_SOFT
				//continue

			/*if (cand.CurrentPositionAsTuple() ~= shot_at_where)
				penalty += MAGICNUM_DISCOURAGE_SOFT*/
				//continue

			//var/open_lines = cand.GetOpenness()

			var/targ_dist = 0

			if(!isnull(effective_waypoint_x) && !isnull(effective_waypoint_y))
				targ_dist = ManhattanDistanceNumeric(cand.x, cand.y, effective_waypoint_x, effective_waypoint_y)

			penalty += -targ_dist  // the closer to target, the better
			//penalty += -threat_dist  // the further from a threat, the better
			/*penalty += abs(open_lines-pick(
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
			))*/

			// Reminder to self: higher values are higher priority
			// Smaller penalty => also higher priority
			var/datum/Quadruple/cover_quad = new(-targ_dist, -penalty, -cand_dist, cand)
			cover_queue.Enqueue(cover_quad)
			processed.Add(cand)

	var/datum/Quadruple/best_cand_quad = cover_queue.Dequeue()

	best_local_pos = istype(best_cand_quad) ? best_cand_quad?.fourth : null
	/* We could do this here^ but I'm not sure if it's the right move yet
	// So I'm doing it as a separate line to make it easy to comment in/out.
	*/
	//best_local_pos = isnull(best_local_pos) ? src.loc : best_local_pos

	return best_local_pos


/mob/goai/combatant/proc/HandleDirectionalChooseCoverleapLandmark(var/datum/ActionTracker/tracker)
	world.log << "Running HandleDirectionalChooseCoverleapLandmark"

	var/turf/best_local_pos = tracker?.BBGet("bestpos", null)
	if(best_local_pos)
		return

	var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)
	var/list/threats = new()
	var/min_safe_dist = brain.GetPersonalityTrait(KEY_PERS_MINSAFEDIST, 2)
	var/turf/prev_loc_memdata = brain?.GetMemoryValue(MEM_PREVLOC, null, FALSE)

	// Main threat:
	var/dict/primary_threat_ghost = GetActiveThreat()
	var/datum/Tuple/primary_threat_pos_tuple = GetThreatPosTuple(primary_threat_ghost)
	var/atom/primary_threat = null
	if(!(isnull(primary_threat_pos_tuple?.left) || isnull(primary_threat_pos_tuple?.right)))
		primary_threat = locate(primary_threat_pos_tuple.left, primary_threat_pos_tuple.right, src.z)

	if(primary_threat_ghost)
		threats[primary_threat_ghost] = primary_threat

	// Secondary threat:
	var/dict/secondary_threat_ghost = GetActiveSecondaryThreat()
	var/datum/Tuple/secondary_threat_pos_tuple = GetThreatPosTuple(secondary_threat_ghost)
	var/atom/secondary_threat = null
	if(!(isnull(secondary_threat_pos_tuple?.left) || isnull(secondary_threat_pos_tuple?.right)))
		secondary_threat = locate(secondary_threat_pos_tuple.left, secondary_threat_pos_tuple.right, src.z)

	if(secondary_threat_ghost)
		threats[secondary_threat_ghost] = secondary_threat

	// Run pathfind
	best_local_pos = ChooseCoverleapLandmark(startpos, primary_threat, prev_loc_memdata, threats, min_safe_dist)

	if(best_local_pos)
		tracker.BBSet("bestpos", best_local_pos)
		tracker.SetDone()

		if(brain)
			brain.SetMemory("DirectionalCoverleapBestpos", best_local_pos)

	else if(active_path && tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * 5))
		tracker.SetFailed()

	return


/mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog(var/datum/ActionTracker/tracker)
	var/tracker_frustration = tracker.BBSetDefault("frustration", 0)
	var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)

	var/turf/best_local_pos = null
	best_local_pos = best_local_pos || tracker?.BBGet("bestpos", null)
	if(brain && isnull(best_local_pos))
		best_local_pos = brain.GetMemoryValue("DirectionalCoverleapBestpos", best_local_pos)

	var/min_safe_dist = brain.GetPersonalityTrait(KEY_PERS_MINSAFEDIST, 2)
	var/frustration_repath_maxthresh = brain.GetPersonalityTrait(KEY_PERS_FRUSTRATION_THRESH, 3)

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

	// Previous position
	var/turf/prev_loc_memdata = brain?.GetMemoryValue(MEM_PREVLOC, null, FALSE)

	// Shot-at logic (avoid known currently unsafe positions):
	/*
	var/datum/memory/shot_at_mem = brain?.GetMemory(MEM_SHOTAT, null, FALSE)
	var/dict/shot_at_memdata = shot_at_mem?.val
	var/datum/Tuple/shot_at_where = shot_at_memdata?.Get(KEY_GHOST_POS_TUPLE, null)
	*/

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
		var/bestpos_is_unsafe = (bestpos_threat_distance < min_safe_dist && !(bestpos_threat_neighbor?.IsCover(TRUE, get_dir(bestpos_threat_neighbor, curr_threat), FALSE)))
		var/currpos_is_unsafe = (
			(tracker_frustration < frustration_repath_maxthresh) && (curr_threat_distance <= min_safe_dist) && (next_step_threat_distance < curr_threat_distance)
		)

		if(bestpos_is_unsafe || currpos_is_unsafe)
			tracker.BBSet("frustration", tracker_frustration+1)

			CancelNavigate()
			best_local_pos = null
			tracker.BBSet("bestpos", null)
			brain?.DropMemory("DirectionalCoverleapBestpos")
			break

	// Pathfinding/search
	if(isnull(best_local_pos))
		best_local_pos = ChooseCoverleapLandmark(startpos, primary_threat, prev_loc_memdata, threats, min_safe_dist)
		tracker?.BBSet("bestpos", best_local_pos)
		world.log << (isnull(best_local_pos) ? "[src]: Best local pos: null" : "[src]: Best local pos [best_local_pos]")


	if(best_local_pos && (!active_path || active_path.target != best_local_pos))
		//world.log << "Navigating to [best_local_pos]"
		StartNavigateTo(best_local_pos)

	if(best_local_pos)
		var/dist_to_pos = ManhattanDistance(src.loc, best_local_pos)
		if(dist_to_pos < 1)
			tracker.SetTriggered()
	else
		tracker.SetFailed()

	var/datum/brain/concrete/needybrain = brain

	if(tracker.IsTriggered() && !tracker.is_done)
		if(tracker.TriggeredMoreThan(1))
			tracker.SetDone()
			brain?.SetMemory(MEM_PREVLOC, startpos, MEM_TIME_LONGTERM)

	else if(active_path && tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * 20))
		if(needybrain)
			needybrain.AddMotive(NEED_COMPOSURE, -MAGICNUM_COMPOSURE_LOSS_FAILMOVE)

		randMove()
		brain?.SetMemory("UnreachableTile", active_path.target, MEM_TIME_LONGTERM)
		tracker.SetFailed()

	else if(tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * 10))
		if(needybrain)
			needybrain.AddMotive(NEED_COMPOSURE, -MAGICNUM_COMPOSURE_LOSS_FAILMOVE)

		randMove()
		tracker.SetFailed()

	SetState(STATE_DISORIENTED, TRUE)
	SetState(STATE_ORIENTED, FALSE)
	return
