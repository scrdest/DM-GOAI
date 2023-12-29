// This is a System, i.e. a proc called by an endless loop spawned by the Commander class on init.

/datum/utility_ai/mob_commander/proc/LegacyMovementSystem()
	var/atom/movable/pawn = src.GetPawn()

	if(!(src?.active_path) || src.active_path.IsDone() || src.is_moving || isnull(pawn))
		return

	if(!(pawn.MayMove()))
		return

	var/success = FALSE
	var/atom/next_step = ((src.active_path.path && src.active_path.path.len) ? src.active_path.path[1] : null)

	if(next_step)
		var/curr_pos = get_turf(pawn)

		if(get_dist(pawn, next_step) > 1)
			// If we somehow wind up away from the core path, move back towards it first
			WalkPawnTowards(next_step, FALSE, TRUE)
			src.brain?.SetMemory("LastTile", curr_pos)
			return

		var/step_result = MovePawn(next_step)

		success = (
			step_result || (
				(pawn.x == next_step.x) && (pawn.y == next_step.y)
			)
		)

		if(success)
			src.brain?.SetMemory("LastTile", curr_pos)
		else
			to_world_log("MOVEMENT SYSTEM: Failed a step from ([pawn.x], [pawn.y]) to ([next_step.x], [next_step.y])")

	else
		src.active_path.SetDone()

	if(success)
		lpop(src.active_path.path)

	return


// Less of a port of GOAP movement; more steering-behavior-ish

/datum/utility_ai/mob_commander/proc/MovementSystem()
	var/atom/movable/pawn = src.GetPawn()

	if(src.is_moving)
		RUN_ACTION_DEBUG_LOG("MovementSystem cannot run; already moving | [__FILE__] -> L[__LINE__]")
		return

	if(src.is_moving || isnull(pawn))
		RUN_ACTION_DEBUG_LOG("MovementSystem idle; pawn is null for [src] | [__FILE__] -> L[__LINE__]")
		return

	if(!(pawn.MayMove()))
		RUN_ACTION_DEBUG_LOG("MovementSystem idle; pawn [pawn] cannot move. | [__FILE__] -> L[__LINE__]")
		return

	var/turf/curr_loc = get_turf(pawn)
	if(isnull(curr_loc))
		RUN_ACTION_DEBUG_LOG("MovementSystem idle; curr_loc is null! | [__FILE__] -> L[__LINE__]")
		return

	var/list/curr_path = src.brain.GetMemoryValue(MEM_PATH_ACTIVE)
	//var/trg = src?.brain?.GetMemoryValue("PendingMovementTarget")
	var/trg = (isnull(curr_path) || !(curr_path?.len)) ? null : curr_path[curr_path.len]

	var/turf/trgturf = get_turf(trg)

	var/safe_trg = trg || src.brain.GetMemoryValue("last_pathing_target") || src.brain.GetMemoryValue("PendingMovementTarget")
	var/turf/safe_trgturf = !isnull(safe_trg) ? get_turf(safe_trg) : null
	//RUN_ACTION_DEBUG_LOG("LPT is [src.brain.GetMemoryValue("last_pathing_target", by_age=TRUE) || "null"] | [__FILE__] -> L[__LINE__]")
	//RUN_ACTION_DEBUG_LOG("PMT is [src.brain.GetMemoryValue("PendingMovementTarget", by_age=TRUE) || "null"] | [__FILE__] -> L[__LINE__]")

	if(isnull(safe_trgturf))
		RUN_ACTION_DEBUG_LOG("MovementSystem idle; safe_trgturf is null! | [__FILE__] -> L[__LINE__]")
		return

	var/localdist = MANHATTAN_DISTANCE(trgturf, curr_loc)
	if(!localdist)
		RUN_ACTION_DEBUG_LOG("MovementSystem idle; already at target! | [__FILE__] -> L[__LINE__]")
		return

	var/success = FALSE
	var/turf/bestcand = null

	if(!isnull(src.active_path) && (src.active_path.path.len >= src.active_path.curr_offset) && !src.active_path.IsDone())
		// Path-following mode:
		to_world("-> MOVEMENT SYSTEM: IN PATH-FOLLOWING MODE <-")

		var/atom/next_step = src.active_path.path[src.active_path.curr_offset]
		var/atom/destination = src.active_path.path[src.active_path.path.len]

		var/turf/prev_draw_pos = null

		for(var/turf/drawpos in src.active_path.path)
			// debug path drawing
			if(!isnull(prev_draw_pos))
				drawpos.pDrawVectorbeam(prev_draw_pos, drawpos, "y_beam")

			prev_draw_pos = drawpos

		if(isnull(curr_loc))
			return

		// Score potential steps for steering purposes
		var/list/cardinals = curr_loc.CardinalTurfs()

		if(isnull(cardinals))
			return

		var/bestscore = null

		for(var/turf/cardturf in cardinals)
			// score should be a float between 0 and 1, ultimately
			// it's effectively a less-flexible, mini-Utility-AI
			if(cardturf.density)
				continue

			var/dirscore = PLUS_INF

			var/next_score = MANHATTAN_DISTANCE(cardturf, next_step)
			var/dest_score = MANHATTAN_DISTANCE(cardturf, destination)

			dirscore = min(next_score, dest_score * 20)
			dirscore += rand() * 0.1
			dirscore += src.active_path.frustration * (0.5 + rand())

			//RUN_ACTION_DEBUG_LOG("Score for [cardturf] is [dirscore], best: [bestscore] for [bestcand] | <@[src]> | [__FILE__] -> L[__LINE__]")

			if(isnull(bestscore) || dirscore < bestscore)
				bestscore = dirscore
				bestcand = cardturf

	if(isnull(bestcand) && curr_path && prob(100))
		// Path-guided steering:
		to_world("-> MOVEMENT SYSTEM: IN STEERING MODE <-")
		var/turf/path_pos = null
		var/path_idx = 1
		var/path_len = curr_path.len

		while(path_idx < path_len)
			// this could be optimized to search only the part of the path close to curr_loc
			// (check distance to both ends and search that half only)
			var/turf/pathstep = curr_path[path_idx++]

			var/cand_dist = MANHATTAN_DISTANCE(curr_loc, pathstep)

			if(!cand_dist)
				// found it
				path_pos = pathstep
				break

		if(isnull(path_pos))
			return

		bestcand = curr_path[path_idx]

	if(isnull(bestcand) && prob(20))
		// Goal-guided steering, lowest quality fallback
		to_world("-> MOVEMENT SYSTEM: IN NUDGING MODE <-")
		var/list/cardinals = curr_loc.CardinalTurfs()

		if(isnull(cardinals))
			return

		var/bestscore = null

		for(var/turf/cardturf in cardinals)
			// score should be a float between 0 and 1, ultimately
			// it's effectively a less-flexible, mini-Utility-AI
			if(cardturf.density)
				continue

			var/dirscore = PLUS_INF

			var/next_score = MANHATTAN_DISTANCE(cardturf, curr_loc)
			var/dest_score = MANHATTAN_DISTANCE(cardturf, safe_trgturf)

			//dirscore = next_score + dest_score
			dirscore = next_score + rand(0, dest_score * 2) * 0.1
			//dirscore += rand() * 0.25

			//RUN_ACTION_DEBUG_LOG("Score for [cardturf] is [dirscore], best: [bestscore] for [bestcand] | <@[src]> | [__FILE__] -> L[__LINE__]")

			if(isnull(bestscore) || dirscore < bestscore)
				bestscore = dirscore
				bestcand = cardturf

	// Wrap-up: actually move
	if(isnull(bestcand))
		return

	var/og_xpos = pawn.x
	var/og_ypos = pawn.y

	//bestcand.pDrawVectorbeam(pawn, bestcand, "n_beam")
	var/step_result = MovePawn(bestcand)
	RUN_ACTION_DEBUG_LOG("MovePawn step_result is [step_result] | <@[src]> | [__FILE__] -> L[__LINE__]")

	success = (
		step_result || (
			(pawn.x == bestcand.x) && (pawn.y == bestcand.y)
		) || (
			(pawn.x == bestcand.x) && (pawn.y == bestcand.y)
		)
	)

	if(success)
		to_world_log("MOVEMENT SYSTEM: Completed a step from ([og_xpos], [og_ypos]) to ([bestcand.x], [bestcand.y])")
		src.brain?.SetMemory("LastTile", curr_loc)

		if(src.active_path)
			src.active_path.curr_offset++

			if(src.active_path.curr_offset > src.active_path.path.len)
				src.active_path.SetDone()
				//src.active_path.path.Cut()
	else
		to_world_log("MOVEMENT SYSTEM: !FAILED! a step from ([og_xpos], [og_ypos]) to ([bestcand.x], [bestcand.y])")

		if(src.active_path)
			src.active_path.frustration++

			if(src.active_path.frustration > 5)
				src.brain?.SetMemory(MEM_PATH_ACTIVE, null, 1)

		var/datum/path_smartobject/stored_path_so = src.brain?.GetMemoryValue("AbstractSmartPaths")

		if(istype(stored_path_so))
			stored_path_so.frustration++

	return
