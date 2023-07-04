

/datum/utility_ai/mob_commander/proc/DraftMoveToChunky(var/datum/ActionTracker/tracker, var/atom/position)
	/*
	// Movement-planning Action; persist a rough Astar path to avoid getting stuck and use it in other Actions.
	*/
	if(isnull(tracker))
		RUN_ACTION_DEBUG_LOG("Tracker position is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(tracker.IsStopped())
		return

	if(isnull(position))
		RUN_ACTION_DEBUG_LOG("Target position is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		tracker.SetFailed()
		return

	if(isnull(src.brain))
		RUN_ACTION_DEBUG_LOG("Requester brain is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		tracker.SetFailed()
		return

	var/atom/pawn = src.GetPawn()

	if(isnull(pawn))
		RUN_ACTION_DEBUG_LOG("Pawn is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	var/list/chunkypath = tracker.BBGet("path")

	if(isnull(chunkypath))
		chunkypath = ChunkyAStar(pawn, position)
		tracker.BBSet("path", chunkypath)
		src.brain.SetMemory(MEM_PATH_TO_POS("aitarget"), chunkypath, 100)

	var/memory = src.brain.GetMemoryValue(MEM_PATH_TO_POS("aitarget"))
	world.log << "Memory is [memory] | [__FILE__] -> L[__LINE__]"
	var/succeeded = !isnull(memory)

	if(succeeded)
		tracker.SetDone()
		return

	tracker.SetFailed()
	return



/datum/utility_ai/mob_commander/proc/DraftMoveToPrecise(var/datum/ActionTracker/tracker, var/atom/position)
	/*
	// Movement-planning Action; persist a rough Astar path to avoid getting stuck and use it in other Actions.
	*/
	if(isnull(tracker))
		RUN_ACTION_DEBUG_LOG("Tracker is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(tracker.IsStopped())
		return

	if(isnull(position))
		RUN_ACTION_DEBUG_LOG("Target position is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		tracker.SetFailed()
		return

	if(isnull(src.brain))
		RUN_ACTION_DEBUG_LOG("Requester brain is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		tracker.SetFailed()
		return

	var/atom/pawn = src.GetPawn()

	if(isnull(pawn))
		RUN_ACTION_DEBUG_LOG("Pawn is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	var/list/path = tracker.BBGet("path")

	if(isnull(path))
		path = GoaiAStar(
			start = get_turf(pawn.loc),
			end = get_turf(position),
			adjacent = /proc/fCardinalTurfsNoblocks,
			dist = DEFAULT_GOAI_DISTANCE_PROC,
			max_nodes = 0,
			max_node_depth = 60,
			min_target_dist = 1,
			min_node_dist = null,
			adj_args = null,
			exclude = null
		)
		world.log << "Path to [position] is [path] | [__FILE__] -> L[__LINE__]"
		tracker.BBSet("path", path)
		src.brain.SetMemory(MEM_PATH_TO_POS("aitarget"), path, 200)

	var/memory = src.brain.GetMemoryValue(MEM_PATH_TO_POS("aitarget"))
	world.log << "Memory is [memory] | [__FILE__] -> L[__LINE__]"
	var/succeeded = !isnull(memory)

	if(succeeded)
		tracker.SetDone()
		return

	tracker.SetFailed()
	return
