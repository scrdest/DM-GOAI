/mob/goai/combatant/proc/HandleTakeCover(var/datum/ActionTracker/tracker)
	var/tracker_frustration = tracker.BBSetDefault("frustration", 0)
	var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)
	var/turf/best_local_pos = tracker?.BBGet("bestpos", null)

	var/atom/threat = GetActiveThreat()
	world.log << "Threat for [src]: [threat || "NONE"]"

	var/datum/memory/shot_at_mem = brain?.GetMemory(MEM_SHOTAT, null, FALSE)
	var/dict/shot_at_memdata = shot_at_mem?.val

	var/datum/Tuple/shot_at_where = shot_at_memdata?.Get(KEY_GHOST_POS_TUPLE, null)
	//world.log << "Shot at where for [src]: [shot_at_where] ([shot_at_where?.left], [shot_at_where?.right])"

	if(isnull(best_local_pos) && active_path && (!(active_path.IsDone())) && active_path.target && active_path.frustration < 2)
		best_local_pos = active_path.target

	var/atom/next_step = ((active_path && active_path.path && active_path.path.len) ? active_path.path[1] : null)

	var/next_step_threat_distance = (next_step ? GetThreatDistance(next_step, threat, PLUS_INF) : PLUS_INF)
	var/curr_threat_distance = GetThreatDistance(src, threat, PLUS_INF)
	var/bestpos_threat_distance = GetThreatDistance(best_local_pos, threat, PLUS_INF)

	var/bestpos_is_unsafe = (bestpos_threat_distance < 2)
	var/currpos_is_unsafe = (
		(tracker_frustration < 3) && (curr_threat_distance <= 3) && (next_step_threat_distance < curr_threat_distance)
	)

	if(bestpos_is_unsafe || currpos_is_unsafe)
		tracker.BBSet("frustration", tracker_frustration+1)

		CancelNavigate()
		best_local_pos = null
		tracker.BBSet("bestpos", null)

	if(isnull(best_local_pos))
		var/list/processed = list()
		var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Triple/proc/FirstTwoCompare)
		var/list/curr_view = view(src)
		curr_view.Add(startpos)

		for(var/turf/wall/loc_wall in curr_view)
			var/list/adjacents = loc_wall.CardinalTurfs(TRUE)

			if(!adjacents)
				continue

			for(var/turf/cand in adjacents)
				if(cand in processed)
					continue

				if(!(cand in curr_view))
					continue

				if(!(cand.Enter(src)))
					continue

				var/penalty = 0

				var/threat_dist = PLUS_INF

				if(threat)
					threat_dist = GetThreatDistance(cand, threat)
					var/threat_angle = GetThreatAngle(cand, threat)
					var/threat_dir = angle2dir(threat_angle)

					var/atom/maybe_cover = get_step(cand, threat_dir)
					if(maybe_cover && !(maybe_cover.density))  // is cover check
						continue

				var/datum/Tuple/curr_pos_tup = cand.CurrentPositionAsTuple()
				world.log << "[src]: Curr pos tup is [curr_pos_tup] ([curr_pos_tup?.left], [curr_pos_tup?.right])"

				if (curr_pos_tup ~= shot_at_where)
					world.log << "[src]: Curr pos tup [curr_pos_tup] ([curr_pos_tup?.left], [curr_pos_tup?.right]) equals shot_at_where"
					continue


				var/cand_dist = ManhattanDistance(cand, src)
				var/open_lines = cand.GetOpenness()

				penalty += open_lines  // the less exposed, the better
				//penalty += -threat_dist  // the further from a threat, the better

				if(threat_dist < 2)
					continue

				var/datum/Triple/cover_triple = new(-penalty, -cand_dist, cand)
				cover_queue.Enqueue(cover_triple)
				processed.Add(cand)

		var/datum/Triple/best_cand_triple = cover_queue.Dequeue()

		if(best_cand_triple)
			best_local_pos = best_cand_triple?.right
			tracker.BBSet("bestpos", best_local_pos)

		world.log << (isnull(best_local_pos) ? "[src]: Best local pos: null" : "[src]: Best local pos [best_local_pos]")


	if(best_local_pos && (!active_path || active_path.target != best_local_pos))
		world.log << "[src]: Navigating to [best_local_pos]"
		StartNavigateTo(best_local_pos)

	if(best_local_pos)
		var/dist_to_pos = ManhattanDistance(src.loc, best_local_pos)
		if(dist_to_pos < 1)
			tracker.SetTriggered()

	var/is_triggered = tracker.IsTriggered()

	if(is_triggered)
		if(tracker.TriggeredMoreThan(COMBATAI_AI_TICK_DELAY))
			tracker.SetDone()

	else if(active_path && tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * 20))
		tracker.SetFailed()

	else if(tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * 10))
		tracker.SetFailed()


	return