
/mob/goai/combatant/proc/ChoosePanicRunLandmark(var/atom/primary_threat = null, var/list/threats = null, min_safe_dist = null)
	// Pathfinding/search
	var/list/_threats = (threats || list())
	var/_min_safe_dist = (isnull(min_safe_dist) ? 0 : min_safe_dist)

	var/turf/best_local_pos = null
	var/list/processed = list()
	var/PriorityQueue/cover_queue = new /PriorityQueue(/datum/Quadruple/proc/TriCompare)

	var/list/curr_view = brain?.perceptions?.Get(SENSE_SIGHT) || list()

	var/turf/last_loc = brain?.GetMemoryValue("Location-1", null)
	if(last_loc)
		curr_view.Add(last_loc)

	var/turf/prev_to_last_loc = brain?.GetMemoryValue("Location-2", null)
	if(prev_to_last_loc)
		curr_view.Add(prev_to_last_loc)

	var/turf/safespace_loc = brain?.GetMemoryValue(MEM_SAFESPACE, null)
	if(safespace_loc)
		curr_view.Add(safespace_loc)

	var/turf/unreachable = brain?.GetMemoryValue("UnreachableTile", null)

	for(var/turf/cand in curr_view)
		// NOTE: This is DIFFERENT to cover moves! We're not doing a double-loop here!
		if(unreachable && cand == unreachable)
			continue

		if(!(cand?.Enter(src, src.loc)))
			continue

		if(cand in processed)
			continue

		if(!(cand in curr_view))
			continue

		var/penalty = 0
		var/threat_dist = 0
		var/heat = 0

		for(var/dict/threat_ghost in _threats)
			threat_dist = GetThreatDistance(cand, threat_ghost)

			if(threat_ghost && threat_dist < _min_safe_dist)
				heat++

		if(heat == 1)
			penalty += MAGICNUM_DISCOURAGE_SOFT

		if(heat >= 2)
			continue

		//var/datum/Tuple/curr_pos_tup = cand.CurrentPositionAsTuple()

		/*if (curr_pos_tup ~= shot_at_where)
			world.log << "[src]: Curr pos tup [curr_pos_tup] ([curr_pos_tup?.left], [curr_pos_tup?.right]) equals shot_at_where"
			continue*/

		var/cand_dist = ManhattanDistance(cand, src)
		//var/targ_dist = (waypoint ? ManhattanDistance(cand, waypoint) : 0)
		var/targ_dist = 0 // ignore waypoint, just leg it!
		var/total_dist = (cand_dist + targ_dist)

		/*if(threat_dist < min_safe_dist)
			continue*/

		penalty += -threat_dist  // the further from a threat, the better

		var/datum/Quadruple/cover_quad = new(threat_dist, -penalty, -total_dist, cand)
		cover_queue.Enqueue(cover_quad)
		processed.Add(cand)

	var/datum/Quadruple/best_cand_quad = cover_queue.Dequeue()

	if(best_cand_quad)
		best_local_pos = best_cand_quad?.fourth
		SpotObstacles(src, best_local_pos, FALSE)

		// Obstacles:
		var/atom/obstruction = brain.GetMemoryValue(MEM_OBSTRUCTION)
		var/handled = FALSE
		var/list/goto_preconds = list(
			STATE_PANIC = TRUE,
		)

		var/obj/cover/door/D = obstruction

		if(D && istype(D) && !(D.open))
			var/obs_need_key = NEED_OBSTACLE_OPEN(obstruction)
			SetState(obs_need_key, NEED_MINIMUM)
			SetState("DoorClosed", (D.open ? NEED_MINIMUM : NEED_MAXIMUM))

			AddAction(
				"Open [obstruction]",
				list(
					"DoorClosed" = NEED_MAXIMUM,
				),
				list(
					obs_need_key = NEED_MAXIMUM,
					"DoorClosed" = NEED_MINIMUM,
					"DoorOpen" = TRUE,
				),
				/mob/goai/combatant/proc/HandleOpenDoor,
				5,
				1
			)
			//goto_preconds[obs_need_key] = NEED_THRESHOLD
			goto_preconds[obs_need_key] = NEED_MINIMUM
			goto_preconds["DoorOpen"] = TRUE
			handled = TRUE

		var/obj/cover/autodoor/AD = obstruction

		if(AD && istype(AD) && !(AD.open))
			var/obs_need_key = NEED_OBSTACLE_OPEN(obstruction)
			SetState(obs_need_key, NEED_MINIMUM)
			SetState("DoorClosed", NEED_MAXIMUM)

			AddAction(
				"Open [obstruction]",
				list(
					"DoorClosed" = NEED_MAXIMUM,
				),
				list(
					obs_need_key = NEED_MAXIMUM,
					"DoorClosed" = NEED_MINIMUM,
					"DoorOpen" = TRUE,
				),
				/mob/goai/combatant/proc/HandleOpenAutodoor,
				5,
				1
			)
			//goto_preconds[obs_need_key] = NEED_THRESHOLD
			goto_preconds[obs_need_key] = NEED_MINIMUM
			goto_preconds["DoorOpen"] = TRUE
			handled = TRUE

		if(handled)
			AddAction(
				"PanicRun Towards [best_local_pos]",
				goto_preconds,
				list(
					NEED_COVER = NEED_SATISFIED,
					NEED_OBEDIENCE = NEED_SATISFIED,
					STATE_INCOVER = 1,
					STATE_DISORIENTED = 1,
				),
				/mob/goai/combatant/proc/HandlePanickedRun,
				1,
				//1, /* It would MAKE SENSE to limit charges on this (so a new PathPlan readds a new charge)
				//      except for the fact that for some reason IT DOESN'T WORK ARGH (yet, probably - TODO) */
				PLUS_INF
			)

		else
			brain?.SetMemory("UnreachableTile", best_local_pos)
			best_local_pos = null

	return best_local_pos


/mob/goai/combatant/proc/HandleChoosePanicRunLandmark(var/datum/ActionTracker/tracker)
	world.log << "Running HandleChoosePanicRunLandmark"

	var/turf/best_local_pos = null
	best_local_pos = best_local_pos || tracker?.BBGet("bestpos", null)

	if(best_local_pos)
		return

	var/list/threats = new()
	var/min_safe_dist = brain.GetPersonalityTrait(KEY_PERS_MINSAFEDIST, 2)

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
	best_local_pos = ChooseDirectionalCoverLandmark(primary_threat, threats, min_safe_dist)

	if(best_local_pos)
		tracker.BBSet("bestpos", best_local_pos)
		tracker.SetDone()

		if(brain)
			brain.SetMemory("PanicRunBestpos", best_local_pos)

	else if(active_path && tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * 5))
		tracker.SetFailed()

	return


/mob/goai/combatant/proc/HandlePanickedRun(var/datum/ActionTracker/tracker)
	var/tracker_frustration = tracker.BBSetDefault("frustration", 0)

	var/turf/best_local_pos = null
	best_local_pos = best_local_pos || tracker?.BBGet("bestpos", null)
	if(brain && isnull(best_local_pos))
		best_local_pos = brain.GetMemoryValue("PanicRunBestpos", best_local_pos)

	var/min_safe_dist = brain.GetPersonalityTrait(KEY_PERS_MINSAFEDIST, 2) * 2
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
			world.log << "[src]: Dropping PanicRun bestpos - unsafe!"

			CancelNavigate()
			best_local_pos = null
			tracker.BBSet("bestpos", null)
			brain?.DropMemory("DirectionalCoverBestpos")
			break


	if(isnull(best_local_pos))
		best_local_pos = ChoosePanicRunLandmark(primary_threat, threats, min_safe_dist)
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
	var/datum/brain/concrete/needybrain = brain

	if(is_triggered)
		if(tracker.TriggeredMoreThan(COMBATAI_AI_TICK_DELAY))
			tracker.SetDone()

			if(needybrain)
				needybrain.ChangeMotive(NEED_COMPOSURE, NEED_SAFELEVEL)


	else if(active_path && tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * 20))
		brain?.SetMemory("UnreachableTile", active_path.target, MEM_TIME_LONGTERM)
		if(prob(10))
			step_away(src, primary_threat || secondary_threat || src)
		tracker.SetFailed()


	else if(tracker.IsOlderThan(COMBATAI_MOVE_TICK_DELAY * 10))
		if(prob(10))
			step_away(src, primary_threat || secondary_threat || src)

		tracker.SetFailed()

	return
