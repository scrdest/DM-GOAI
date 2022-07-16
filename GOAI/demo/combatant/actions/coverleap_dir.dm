
/mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog(var/datum/ActionTracker/tracker)
	var/tracker_frustration = tracker.BBSetDefault("frustration", 0)
	var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)
	var/turf/best_local_pos = tracker?.BBGet("bestpos", null)

	var/min_safe_dist = brain.GetPersonalityTrait(KEY_PERS_MINSAFEDIST, 2)
	var/frustration_repath_maxthresh = brain.GetPersonalityTrait(KEY_PERS_FRUSTRATION_THRESH, 3)

	// var/list/all_threats = GetActiveThreats()
	// should do a proper for/in loop here!
	var/atom/threat =  GetActiveThreat()
	world.log << "[src]: Threat for [src]: [threat || "NONE"]"

	var/datum/memory/prev_loc_mem = brain?.GetMemory(MEM_PREVLOC, null, FALSE)
	var/turf/prev_loc_memdata = prev_loc_mem?.val

	var/datum/memory/shot_at_mem = brain?.GetMemory(MEM_SHOTAT, null, FALSE)
	var/dict/shot_at_memdata = shot_at_mem?.val

	var/datum/Tuple/shot_at_where = shot_at_memdata?.Get(KEY_GHOST_POS_TUPLE, null)

	if(isnull(best_local_pos) && active_path && (!(active_path.IsDone())) && active_path.target && active_path.frustration < 2)
		best_local_pos = active_path.target

	var/atom/next_step = ((active_path && active_path.path && active_path.path.len) ? active_path.path[1] : null)

/*
	var/next_step_threat_distance = (next_step ? Min(GetThreatDistances(next_step, null, PLUS_INF), TRUE, null) : PLUS_INF)
	var/curr_threat_distance = Min(GetThreatDistances(src, null, PLUS_INF), TRUE, null)
	var/bestpos_threat_distance = Min(GetThreatDistances(best_local_pos, null, PLUS_INF), TRUE, null)
*/

	var/next_step_threat_distance = (next_step ? GetThreatDistance(next_step, threat, PLUS_INF) : PLUS_INF)
	var/curr_threat_distance = GetThreatDistance(src, threat, PLUS_INF)
	var/bestpos_threat_distance = GetThreatDistance(best_local_pos, threat, PLUS_INF)

	var/atom/bestpos_threat_neighbor = (threat ? get_step_towards(best_local_pos, threat) : null)

	var/bestpos_is_unsafe = (bestpos_threat_distance < min_safe_dist && !(bestpos_threat_neighbor?.IsCover()))
	var/currpos_is_unsafe = (
		(tracker_frustration < frustration_repath_maxthresh) && (curr_threat_distance <= min_safe_dist) && (next_step_threat_distance < curr_threat_distance)
	)

	if(bestpos_is_unsafe || currpos_is_unsafe)
		tracker.BBSet("frustration", tracker_frustration+1)

		CancelNavigate()
		best_local_pos = null
		tracker.BBSet("bestpos", null)

	if(isnull(best_local_pos))
		var/list/processed = list()
		var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Quadruple/proc/TriCompare)
		var/list/curr_view = oview(src)
		curr_view.Add(startpos)

		for(var/turf/wall/loc_wall in curr_view)
			var/list/adjacents = loc_wall.CardinalTurfs(TRUE)

			if(!adjacents)
				continue

			for(var/turf/cand in adjacents)
				if(cand in processed)
					continue

				if(!(cand in curr_view) && (cand != startpos))
					continue

				if(!(cand.Enter(src)))
					continue

				if(prev_loc_memdata && prev_loc_memdata == cand)
					//world.log << "Prev loc [prev_loc_memdata] matched candidate [cand]"
					continue

				var/penalty = 0

				var/threat_dist = PLUS_INF

				if(threat)
					//threat_dist = Min(GetThreatDistances(cand, null), TRUE, null)
					//var/threat_angle = First(GetThreatAngles(cand, null), TRUE, null)
					threat_dist = GetThreatDistance(cand, threat)
					var/threat_angle = GetThreatAngle(cand, threat)
					var/threat_dir = angle2dir(threat_angle)

					var/atom/maybe_cover = get_step(cand, threat_dir)
					if(maybe_cover && !(maybe_cover.density))  // is cover check
						continue

				var/cand_dist = ManhattanDistance(cand, src)
				if(cand_dist < 3)
					// we want substantial moves only
					penalty += MAGICNUM_DISCOURAGE_SOFT
					//continue

				if (cand.CurrentPositionAsTuple() ~= shot_at_where)
					penalty += MAGICNUM_DISCOURAGE_SOFT
					//continue

				if(threat && threat_dist < min_safe_dist)
					continue

				var/open_lines = cand.GetOpenness()

				var/targ_dist = 0
				if(waypoint)
					var/datum/memory/waypoint_mem = brain?.GetMemory(MEM_WAYPOINT_LKP, null, FALSE)
					var/list/waypoint_memdata = waypoint_mem?.val
					var/mem_waypoint_x = waypoint_memdata?[KEY_GHOST_X]
					var/mem_waypoint_y = waypoint_memdata?[KEY_GHOST_Y]
					world.log << "[src] waypoint positions: ([mem_waypoint_x], [mem_waypoint_y]) from [waypoint_memdata] from mem [waypoint_mem]"

					if(!isnull(mem_waypoint_x) && !isnull(mem_waypoint_y))
						world.log << "[src] found waypoint position in memory!"
						targ_dist = ManhattanDistanceNumeric(cand.x, cand.y, mem_waypoint_x, mem_waypoint_y)

					else
						var/datum/Tuple/waypoint_position = waypoint.CurrentPositionAsTuple()

						var/effective_waypoint_x = waypoint_position.left + rand(-WAYPOINT_FUZZ_X, WAYPOINT_FUZZ_X)
						var/effective_waypoint_y = waypoint_position.right + rand(-WAYPOINT_FUZZ_Y, WAYPOINT_FUZZ_Y)

						targ_dist = ManhattanDistanceNumeric(cand.x, cand.y, effective_waypoint_x, effective_waypoint_y)

				//penalty += -threat_dist  // the further from a threat, the better
				penalty += abs(open_lines-pick(
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
				))

				var/datum/Quadruple/cover_quad = new(-targ_dist, -cand_dist, -penalty, cand)
				cover_queue.Enqueue(cover_quad)
				processed.Add(cand)

		var/datum/Quadruple/best_cand_quad = cover_queue.Dequeue()

		best_local_pos = istype(best_cand_quad) ? best_cand_quad?.fourth : null
		/* We could do this here^ but I'm not sure if it's the right move yet
		// So I'm doing it as a separate line to make it easy to comment in/out.
		*/
		//best_local_pos = isnull(best_local_pos) ? src.loc : best_local_pos

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

	if(tracker.IsTriggered() && !tracker.is_done)
		if(tracker.TriggeredMoreThan(1))
			tracker.SetDone()
			brain?.SetMemory(MEM_PREVLOC, startpos, MEM_TIME_LONGTERM)

	else if(active_path && tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * 20))
		tracker.SetFailed()

	else if(tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * 10))
		tracker.SetFailed()

	return
