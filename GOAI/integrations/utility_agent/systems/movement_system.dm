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

	if(!(src?.active_path) || src.active_path.IsDone() || src.is_moving || isnull(pawn))
		RUN_ACTION_DEBUG_LOG("MovementSystem idle; active_path [active_path] - done: [src.active_path?.IsDone()] | [__FILE__] -> L[__LINE__]")
		return

	if(!(pawn.MayMove()))
		return

	if(isnull(src.active_path.path) || (src.active_path.path.len < src.active_path.curr_offset))
		return

	var/atom/next_step = src.active_path.path[src.active_path.curr_offset]
	var/atom/destination = src.active_path.path[src.active_path.path.len]
	//bestcand.pDrawVectorbeam(pawn, bestcand, "n_beam")

	var/success = FALSE

	var/turf/curr_pos = get_turf(pawn)
	var/turf/prev_draw_pos = null

	for(var/turf/drawpos in src.active_path.path)
		// debug path drawing
		if(!isnull(prev_draw_pos))
			drawpos.pDrawVectorbeam(prev_draw_pos, drawpos, "y_beam")

		prev_draw_pos = drawpos

	if(isnull(curr_pos))
		return

	// Score potential steps for steering purposes
	var/list/cardinals = curr_pos.CardinalTurfs()

	if(isnull(cardinals))
		return

	var/bestscore = null
	var/turf/bestcand = null

	for(var/turf/cardturf in cardinals)
		// score should be a float between 0 and 1, ultimately
		// it's effectively a less-flexible, mini-Utility-AI
		if(cardturf.density)
			continue

		var/dirscore = PLUS_INF

		var/next_score = MANHATTAN_DISTANCE(cardturf, next_step)
		var/dest_score = MANHATTAN_DISTANCE(cardturf, destination)

		dirscore = min(next_score, dest_score * 3)
		dirscore += rand() * 0.1
		dirscore += src.active_path.frustration * (0.5 + rand())

		//RUN_ACTION_DEBUG_LOG("Score for [cardturf] is [dirscore], best: [bestscore] for [bestcand] | <@[src]> | [__FILE__] -> L[__LINE__]")

		if(isnull(bestscore) || dirscore < bestscore)
			bestscore = dirscore
			bestcand = cardturf

	if(isnull(bestcand))
		return

	//RUN_ACTION_DEBUG_LOG("MovePawn target is [bestcand] w/ score: [bestscore] | <@[src]> | [__FILE__] -> L[__LINE__]")
	//bestcand.pDrawVectorbeam(pawn, bestcand, "n_beam")
	var/og_xpos = pawn.x
	var/og_ypos = pawn.y

	var/step_result = MovePawn(bestcand)
	RUN_ACTION_DEBUG_LOG("MovePawn step_result is [step_result] | <@[src]> | [__FILE__] -> L[__LINE__]")

	success = (
		step_result || (
			(pawn.x == next_step.x) && (pawn.y == next_step.y)
		) || (
			(pawn.x == destination.x) && (pawn.y == destination.y)
		)
	)

	if(success)
		to_world_log("MOVEMENT SYSTEM: Completed a step from ([og_xpos], [og_ypos]) to ([next_step.x], [next_step.y])")
		src.brain?.SetMemory("LastTile", curr_pos)
		src.active_path.curr_offset++

		if(src.active_path.curr_offset > src.active_path.path.len)
			src.active_path.SetDone()
			//src.active_path.path.Cut()
	else
		to_world_log("MOVEMENT SYSTEM: !FAILED! a step from ([og_xpos], [og_ypos]) to ([next_step.x], [next_step.y])")
		src.active_path.frustration++
		var/datum/path_smartobject/stored_path_so = src.brain?.GetMemoryValue("AbstractSmartPaths")
		if(istype(stored_path_so))
			stored_path_so.frustration++

		if(src.active_path.frustration > 5)
			src.brain?.SetMemory(MEM_PATH_ACTIVE, null, 1)

	return

