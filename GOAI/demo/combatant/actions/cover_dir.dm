
/mob/goai/combatant/proc/HandleDirectionalCover(var/datum/ActionTracker/tracker)
	//var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)
	var/turf/best_local_pos = tracker?.BBGet("bestpos", null)

	var/atom/threat = GetActiveThreat()

	var/datum/memory/shot_at_mem = brain?.GetMemory(MEM_SHOTAT, null, FALSE)
	var/dict/shot_at_memdata = shot_at_mem?.val
	//var/shot_at_angle = shot_at_memdata?.Get(KEY_GHOST_ANGLE, null) || rand(0, 360)

	var/datum/Tuple/shot_at_where = shot_at_memdata?.Get(KEY_GHOST_POS_TUPLE, null)

	//var/preferred_dir = angle2dir(shot_at_angle)

	//world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")

	if(isnull(best_local_pos))
		var/list/processed = list()
		var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Quadruple/proc/TriCompare)
		var/list/curr_view = oview(src)

		for(var/turf/wall/loc_wall in curr_view)
			if(!(loc_wall.is_corner || loc_wall.is_pillar))
				if(prob(90))
					continue

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

				var/threat_angle = GetThreatAngle(cand, threat)
				var/threat_dir = angle2dir(threat_angle)

				var/cand_dir_offset = get_dir(cand, loc_wall)

				if((cand_dir_offset & threat_dir) == 0)
					continue

				if (cand.CurrentPositionAsTuple() ~= shot_at_where)
					penalty += MAGICNUM_DISCOURAGE_SOFT

				var/cand_dist = ManhattanDistance(cand, src)

				var/threat_dist = GetThreatDistance(cand, threat)

				var/targ_dist = (waypoint ? ManhattanDistance(cand, waypoint) : 0)
				var/total_dist = (cand_dist + targ_dist)

				var/open_lines = cand.GetOpenness()

				if(threat_dist < 2)
					penalty += MAGICNUM_DISCOURAGE_SOFT

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

				var/datum/Quadruple/cover_quad = new(-targ_dist, -penalty, -total_dist, cand)
				cover_queue.Enqueue(cover_quad)
				processed.Add(cand)

		var/datum/Quadruple/best_cand_quad = cover_queue.Dequeue()

		best_local_pos = best_cand_quad.fourth
		tracker.BBSet("bestpos", best_local_pos)
		world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")


	if(best_local_pos && (!active_path || active_path.target != best_local_pos))
		world.log << "Navigating to [best_local_pos]"
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
