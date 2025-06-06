
/datum/utility_ai/mob_commander/proc/FlipTable(
	var/datum/ActionTracker/tracker,
	var/turf/location,
	# ifdef GOAI_LIBRARY_FEATURES
	var/obj/cover/table/target
	#endif
	# ifdef GOAI_SS13_SUPPORT
	var/obj/structure/table/target
	#endif
)
	/*
	// (╯ರ ~ ರ）╯︵ ┻━┻
	*/
	if(isnull(tracker))
		RUN_ACTION_DEBUG_LOG("Tracker position is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(tracker.IsStopped())
		return

	if(isnull(target))
		RUN_ACTION_DEBUG_LOG("Target is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		tracker.SetFailed()
		return

	var/atom/pawn = src.GetPawn()

	if(isnull(pawn))
		RUN_ACTION_DEBUG_LOG("Pawn is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	src.allow_wandering = FALSE
	var/dist = MANHATTAN_DISTANCE(pawn, target)

	# ifdef GOAI_LIBRARY_FEATURES
	var/succeeded = (dist == 1 && target.pFlip(get_dir(pawn, target)))
	#endif

	# ifdef GOAI_SS13_SUPPORT
	var/succeeded = (dist == 1 && target.flip(get_dir(pawn, target)))
	#endif


	if(succeeded)
		tracker.SetDone()
	else
		var/bb_failures = tracker.BBSetDefault("failed_steps", 0)
		tracker.BBSet("failed_steps", ++bb_failures)

		if(bb_failures > 1)
			tracker.SetFailed()

	return


/datum/utility_ai/mob_commander/proc/UnflipTable(
	var/datum/ActionTracker/tracker,
	var/turf/location,
	# ifdef GOAI_LIBRARY_FEATURES
	var/obj/cover/table/target
	#endif
	# ifdef GOAI_SS13_SUPPORT
	var/obj/structure/table/target
	#endif
)
	/*
	// ┬──┬ ノ( ゜-゜ノ)
	*/
	if(isnull(tracker))
		RUN_ACTION_DEBUG_LOG("Tracker position is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(tracker.IsStopped())
		return

	if(isnull(target))
		RUN_ACTION_DEBUG_LOG("Target is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		tracker.SetFailed()
		return

	var/atom/pawn = src.GetPawn()

	if(isnull(pawn))
		RUN_ACTION_DEBUG_LOG("Pawn is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	src.allow_wandering = FALSE
	var/dist = MANHATTAN_DISTANCE(pawn, target)
	src.brain?.SetMemory("DontWanderToTurf", location, 200)

	# ifdef GOAI_LIBRARY_FEATURES
	var/succeeded = (dist == 1 && target.pUnflip())
	#endif

	# ifdef GOAI_SS13_SUPPORT
	var/succeeded = (dist == 1 && target.unflip())
	#endif

	if(succeeded)
		tracker.SetDone()
	else
		var/bb_failures = tracker.BBSetDefault("failed_steps", 0)
		tracker.BBSet("failed_steps", ++bb_failures)

		if(bb_failures > 1)
			tracker.SetFailed()

	return



/datum/utility_ai/mob_commander/proc/ClimbTable(var/datum/ActionTracker/tracker, var/turf/location, var/obj/cover/table/target)
	/*
	//
	*/
	if(isnull(tracker))
		RUN_ACTION_DEBUG_LOG("Tracker position is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(tracker.IsStopped())
		return

	if(isnull(location))
		RUN_ACTION_DEBUG_LOG("location is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		tracker.SetFailed()
		return

	var/atom/movable/pawn = src.GetPawn()

	if(isnull(pawn))
		RUN_ACTION_DEBUG_LOG("Pawn is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	var/turf/pawnturf = get_turf(pawn)

	if(isnull(pawnturf))
		RUN_ACTION_DEBUG_LOG("Pawnturf is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	src.brain?.SetMemory("DontWanderToTurf", location, 200)
	src.allow_wandering = FALSE

	var/succeeded = TRUE

	if(MANHATTAN_DISTANCE(pawnturf, location) == 1)
		pawn.managed_movement = TRUE
		pawn.loc = location
	else
		pawn.managed_movement = FALSE

	if(pawn.x == location.x && pawn.y == location.y && pawn.z == location.z)
		tracker.SetDone()

	if(tracker.IsStopped())
		pawn.managed_movement = FALSE
		return

	if(succeeded)
		tracker.SetDone()
		pawn.managed_movement = FALSE
	else
		var/bb_failures = tracker.BBSetDefault("failed_steps", 0)
		tracker.BBSet("failed_steps", ++bb_failures)

		if(bb_failures > 1)
			tracker.SetFailed()
			pawn.managed_movement = FALSE

	return



/datum/utility_ai/mob_commander/proc/StepAway(var/datum/ActionTracker/tracker, var/turf/location, var/obj/cover/table/target, var/order_halt_time = 0)
	/*
	//
	*/
	if(isnull(tracker))
		RUN_ACTION_DEBUG_LOG("Tracker position is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(tracker.IsStopped())
		return

	if(isnull(location))
		RUN_ACTION_DEBUG_LOG("location is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		tracker.SetFailed()
		return

	var/atom/movable/pawn = src.GetPawn()

	if(isnull(pawn))
		RUN_ACTION_DEBUG_LOG("Pawn is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	src.brain?.SetMemory("DontWanderToTurf", location, 200)
	src.allow_wandering = FALSE
	var/succeeded = TRUE

	var/dir_to_obstacle = target.dir

	var/list/candidates = fCardinalTurfs(pawn.loc)

	var/turf/bestcand = null
	var/bestscore = null

	RUN_ACTION_DEBUG_LOG("Selecting StepAway candidate... | [__FILE__] -> L[__LINE__]")

	for(var/turf/candturf in candidates)
		// randomly choose a neighbor to step to
		var/neigh_dir = get_dir(pawn, candturf)

		if(neigh_dir == dir_to_obstacle)
			continue

		var/candscore = rand()
		if(isnull(bestscore) || candscore < bestscore)
			bestcand = candturf
			bestscore = candscore

	RUN_ACTION_DEBUG_LOG("Selected StepAway candidate: [bestcand || "null"] | [__FILE__] -> L[__LINE__]")

	if(isnull(bestcand))
		succeeded = FALSE

	src.StartNavigateTo(bestcand)
	ADD_GOAI_TEMP_GIZMO_SAFEINIT(bestcand, "greyO")

	if(!(pawn.x == location.x && pawn.y == location.y && pawn.z == location.z))
		tracker.SetDone()
		if(order_halt_time) { src.brain.SetMemory("HaltManeouverActive", TRUE, order_halt_time) }

	if(tracker.IsStopped())
		return

	if(!succeeded)
		var/bb_failures = tracker.BBSetDefault("failed_steps", 0)
		tracker.BBSet("failed_steps", ++bb_failures)

		if(bb_failures > 1)
			tracker.SetFailed()

	return
