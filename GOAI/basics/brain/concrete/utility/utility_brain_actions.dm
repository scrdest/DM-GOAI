
/datum/brain/utility/proc/Idle()
	return
/*
// This module contains the API for dealing with available Actions.
//
// For messy, historical reasons, the core AI logic had once been implemented in the Brain class rather than the AI class
// (namely: the AI object came later by factoring out the AI from the mob class).
//
// This is that LEGACY implementation - the AI proper calls into the Brain's API.
//
// This is (or at least should be) unincluded at the moment.
// Not much will happen if you untick this and/or the other Brain-based decision API components,
// but this is deprecated, possibly under-maintained and probably just... unnecessary.
*/

/datum/brain/utility/proc/GetActionSetFromFile(var/filename)
	if(isnull(src.file_actionsets))
		src.file_actionsets = list()

	var/datum/action_set/file_actionset = src.file_actionsets[filename]

	var/local_cache_miss = FALSE
	var/global_cache_miss = FALSE

	if(isnull(file_actionset))
		local_cache_miss = TRUE

		if(isnull(GOAI_LIBBED_GLOB_ATTR(actionset_file_cache)))
			GOAI_LIBBED_GLOB_ATTR(actionset_file_cache) = list()

		file_actionset = GOAI_LIBBED_GLOB_ATTR(actionset_file_cache)[filename]

		if(isnull(file_actionset))
			global_cache_miss = TRUE

	if(global_cache_miss)
		file_actionset = ActionSetFromJsonFile(filename)
		GOAI_LIBBED_GLOB_ATTR(actionset_file_cache)[filename] = file_actionset

		if(local_cache_miss)
			src.file_actionsets[filename] = file_actionset

	return file_actionset


/datum/brain/utility/GetAvailableActions()
	var/list/actionsets = list()

	var/list/smartobjects = src.GetMemoryValue("SmartObjects", null)
	var/list/smart_paths = src.GetMemoryValue("AbstractSmartPaths", null)
	var/list/smart_plans = src.GetMemoryValue("SmartPlans", null)
	var/list/smart_orders = src.GetMemoryValue("SmartOrders", null)

	if(isnull(smartobjects))
		smartobjects = list()

	if(!isnull(smart_paths))
		for(var/path_key in smart_paths)
			var/datum/path_smartobject/path_so = smart_paths[path_key]
			if(istype(path_so))
				smartobjects.Add(path_so)

	if(!isnull(smart_plans))
		for(var/datum/plan_smartobject/plan_so in smart_plans)
			smartobjects.Add(plan_so)

	if(!isnull(smart_orders))
		for(var/datum/order_smartobject/order_so in smart_orders)
			smartobjects.Add(order_so)

	var/datum/utility_ai/requester = src.GetRequester()
	ASSERT(istype(requester))

	// Innate actions; note that these should be used fairly sparingly
	// (to avoid checking for actions we could never take anyway).
	// Mostly useful for abstract AIs that have no natural pawns some of the time.
	smartobjects.Add(requester)

	// currently implicit since we always can see ourselves
	// should prolly do a 'if X not in list already', but BYOOOOND

	// The Pawn is a SmartObject too!
	var/datum/pawn = requester.GetPawn()
	if(!isnull(pawn))
		smartobjects.Add(pawn)

	if(!isnull(smartobjects))

		for(var/datum/SO in smartobjects)
			var/list/SO_actionsets = src.GetActionSetsFromSmartObject(SO, requester)

			if(!isnull(SO_actionsets))
				actionsets.Add(SO_actionsets)

	/*
	if(src.smart_objects)
		if(isnull(src.smartobject_last_fetched))
			src.smartobject_last_fetched = list()

		for(var/datum/smart_object/SO in src.smart_objects)
	*/

	return actionsets


/datum/brain/utility/DoAction(Act as anything in src.GetAvailableActions())
	RUN_ACTION_DEBUG_LOG("INFO: Running DoAction: [Act] | <@[src]> | L[__LINE__] in [__FILE__]")

	var/datum/utility_action/utility_act = Act

	var/datum/ActionTracker/new_actiontracker = src.running_action_tracker

	if(isnull(new_actiontracker))
		new_actiontracker = new /datum/ActionTracker(utility_act)
	else
		// Object pooling
		var/should_run = new_actiontracker.IsStopped()  // if already running, no need to spin up a thread
		new_actiontracker.Initialize(utility_act, run=should_run)

	if(!new_actiontracker)
		RUN_ACTION_DEBUG_LOG("ERROR: Failed to create a tracker for [utility_act]! | <@[src]> | L[__LINE__] in [__FILE__]")
		return null

	running_action_tracker = new_actiontracker

	// Update the tracked Action stack for Considerations
	src.SetMemory(MEM_ACTION_MINUS_TWO, src.GetMemoryValue(MEM_ACTION_MINUS_ONE), RETAIN_LAST_ACTIONS_TTL)
	src.SetMemory(MEM_ACTION_MINUS_ONE, utility_act.name, RETAIN_LAST_ACTIONS_TTL)
	src.SetMemory("LastActionEffects", utility_act.name, RETAIN_LAST_ACTIONS_TTL)

	return new_actiontracker


/datum/brain/utility/proc/OnInvalidAction(var/action_key) // str -> bool
	/* If the Action is invalid, what do we do?
	//
	// Returns a bool, indicating whether to try planning again in the same tick.
	*/

	// By default, abandon ship.
	RUN_ACTION_DEBUG_LOG("INVALID ACTION: [action_key]  | <@[src]> | [__FILE__] -> L[__LINE__]")
	src.AbortPlan()
	return TRUE

