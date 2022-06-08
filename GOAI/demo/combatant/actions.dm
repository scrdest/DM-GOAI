



/mob/goai/combatant/proc/HandleIdling(var/datum/ActionTracker/tracker)
	active_path = null
	Idle()

	if(tracker.IsOlderThan(20))
		tracker.SetDone()

	return


/mob/goai/combatant/proc/HandleTakeCover(var/datum/ActionTracker/tracker)
	//var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)
	var/turf/best_local_pos = tracker.BBGet("bestpos", null)

	if(isnull(best_local_pos) && active_path && (!(active_path.IsDone())) && active_path.target && active_path.frustration < 2)
		best_local_pos = active_path.target

	//world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")

	if(isnull(best_local_pos))
		var/list/processed = list()
		var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Triple/proc/FirstTwoCompare)
		var/list/curr_view = view(src)

		for(var/turf/wall/loc_wall in curr_view)

			if(!(loc_wall.is_corner || loc_wall.is_pillar))
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

				var/cand_dist = ManhattanDistance(cand, src)

				var/open_lines = cand.GetOpenness()
				var/score = -open_lines

				var/datum/Triple/cover_triple = new(score, -cand_dist, cand)
				cover_queue.Enqueue(cover_triple)
				processed.Add(cand)

		var/datum/Triple/best_cand_triple = cover_queue.Dequeue()

		best_local_pos = best_cand_triple.right
		tracker.BBSet("bestpos", best_local_pos)
		world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")


	if(best_local_pos && (!active_path || active_path.target != best_local_pos))
		world.log << "Navigating to [best_local_pos]"
		StartNavigateTo(best_local_pos)

	if(best_local_pos && src.loc == best_local_pos)
		tracker.SetTriggered()

	var/is_triggered = tracker.IsTriggered()

	if(is_triggered)
		if(tracker.TriggeredMoreThan(10))
			tracker.SetDone()

	else if(active_path && tracker.IsOlderThan(150))
		tracker.SetFailed()

	else if(tracker.IsOlderThan(100))
		tracker.SetFailed()


	return


/mob/goai/combatant/proc/HandleCoverLeapfrog(var/datum/ActionTracker/tracker)
	//var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)
	var/turf/best_local_pos = tracker.BBGet("bestpos", null)

	if(isnull(best_local_pos) && active_path && (!(active_path.IsDone())) && active_path.target && active_path.frustration < 2)
		best_local_pos = active_path.target

	if(isnull(best_local_pos))
		var/list/processed = list()
		var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Triple/proc/FirstTwoCompare)
		var/list/curr_view = oview(src)


		for(var/turf/wall/loc_wall in curr_view)
			if(!(loc_wall.is_corner || loc_wall.is_pillar))
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

				var/cand_dist = ManhattanDistance(cand, src)
				if(cand_dist < 3)
					// we want substantial moves only
					continue

				var/open_lines = cand.GetOpenness()
				var/score = -abs(open_lines-pick(
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
					50; 5,
					40; 6,
					5; 7
				))

				var/datum/Triple/cover_triple = new(score, -cand_dist, cand)
				cover_queue.Enqueue(cover_triple)
				processed.Add(cand)

		var/datum/Triple/best_cand_triple = cover_queue.Dequeue()

		best_local_pos = best_cand_triple.right
		tracker.BBSet("bestpos", best_local_pos)
		world.log << (isnull(best_local_pos) ? "Best local pos: null" : "Best local pos [best_local_pos]")


	if(best_local_pos && (!active_path || active_path.target != best_local_pos))
		world.log << "Navigating to [best_local_pos]"
		StartNavigateTo(best_local_pos)

	if(best_local_pos && src.loc == best_local_pos)
		tracker.SetTriggered()

	var/is_triggered = tracker.IsTriggered()

	if(is_triggered)
		if(tracker.TriggeredMoreThan(10))
			tracker.SetDone()

	else if(active_path && tracker.IsOlderThan(100))
		tracker.SetFailed()

	else if(tracker.IsOlderThan(50))
		tracker.SetFailed()

	return


/mob/goai/combatant/proc/HandleDirectionalCover(var/datum/ActionTracker/tracker)
	//var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)
	var/turf/best_local_pos = tracker.BBGet("bestpos", null)

	if(isnull(best_local_pos) && active_path && (!(active_path.IsDone())) && active_path.target && active_path.frustration < 2)
		best_local_pos = active_path.target

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

				var/cand_dist = ManhattanDistance(cand, src)

				var/targ_dist = (waypoint ? ManhattanDistance(cand, waypoint) : 0)
				var/total_dist = (cand_dist + targ_dist)

				var/open_lines = cand.GetOpenness()
				var/score = -abs(open_lines-pick(
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

				var/datum/Quadruple/cover_quad = new(-targ_dist, score, -total_dist, cand)
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
		if(dist_to_pos <= 1)
			tracker.SetTriggered()

	var/is_triggered = tracker.IsTriggered()

	if(is_triggered)
		if(tracker.TriggeredMoreThan(10))
			tracker.SetDone()

	else if(active_path && tracker.IsOlderThan(100))
		tracker.SetFailed()

	else if(tracker.IsOlderThan(50))
		tracker.SetFailed()

	return


/mob/goai/combatant/proc/HandleDirectionalCoverLeapfrog(var/datum/ActionTracker/tracker)
	//var/turf/startpos = tracker.BBSetDefault("startpos", src.loc)
	var/turf/best_local_pos = tracker.BBGet("bestpos", null)

	if(isnull(best_local_pos) && active_path && (!(active_path.IsDone())) && active_path.target && active_path.frustration < 2)
		best_local_pos = active_path.target

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

				var/cand_dist = ManhattanDistance(cand, src)
				if(cand_dist < 3)
					// we want substantial moves only
					continue

				var/targ_dist = (waypoint ? ManhattanDistance(cand, waypoint) : 0)
				var/total_dist = (cand_dist + targ_dist)

				var/open_lines = cand.GetOpenness()
				var/score = -abs(open_lines-pick(
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

				var/datum/Quadruple/cover_quad = new(-targ_dist, score, -total_dist, cand)
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
		if(dist_to_pos <= 1)
			tracker.SetTriggered()

	var/is_triggered = tracker.IsTriggered()

	if(is_triggered)
		if(tracker.TriggeredMoreThan(10))
			tracker.SetDone()

	else if(active_path && tracker.IsOlderThan(100))
		tracker.SetFailed()

	else if(tracker.IsOlderThan(50))
		tracker.SetFailed()

	return


/mob/goai/combatant/proc/HandleShoot(var/datum/ActionTracker/tracker)
	if (tracker.IsStopped())
		return

	if(tracker.IsOlderThan(50))
		tracker.SetFailed()
		return

	states[STATE_CANFIRE] = TRUE
	tracker.SetDone()

	return


/mob/goai/combatant/proc/HandleShootOld(var/datum/ActionTracker/tracker)
	if (tracker.IsStopped())
		return

	if(tracker.IsOlderThan(50))
		tracker.SetFailed()
		return

	var/obj/gun/my_gun = locate(/obj/gun) in src.contents

	if(isnull(my_gun))
		world.log << "Gun not found for [src] to shoot D;"
		return

	var/atom/target = GetTarget()
	var/successful = Shoot(my_gun, target)

	if(successful)
		tracker.SetDone()

	return