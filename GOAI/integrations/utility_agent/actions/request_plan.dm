
/datum/utility_ai/mob_commander/proc/PlanAroundObstacle(var/datum/ActionTracker/tracker, var/atom/obstacle, var/atom/position, var/planning_budget = null)
	// Requests a GOAP Plan to handle a contextual obstacle
	// Fails if no Plan was found
	// Otherwise, creates a Utility-friendly SmartObject to deal with execution

	if(isnull(tracker))
		RUN_ACTION_DEBUG_LOG("Tracker position is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(tracker.IsStopped())
		return

	if(isnull(obstacle))
		RUN_ACTION_DEBUG_LOG("Obstacle is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		tracker.SetFailed()
		return

	if(isnull(src.brain))
		RUN_ACTION_DEBUG_LOG("Requester brain is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		tracker.SetFailed()
		return

	var/list/start_state = obstacle.worldstate

	var/list/goal_state = list(
		// Should be generalized I guess
		"IsOpen" = TRUE
	)

	var/myref = ref(src)
	var/datum/GOAP/planner = GetGoapResource(myref)
	var/list/plan_items = null

	if(!isnull(planner))
		var/list/actions = GoapActionSetFromJsonFile(GOAPPLAN_METADATA_PATH) // this is doing way too much I/O, but dev gonna dev
		var/_planning_budget = isnull(planning_budget) ? 20 : planning_budget
		planner.graph = actions

		to_world_log("PLANNING! START: [json_encode(start_state)] GOAL: [json_encode(goal_state)], ACTIONS: [json_encode(actions)]")
		plan_items = planner.Plan(start_state, goal_state, cutoff_iter=_planning_budget)
		to_world_log("PLANNING END - PLAN: [json_encode(plan_items)]")

		FreeGoapResource(planner, myref)

	if(isnull(plan_items))
		tracker.SetFailed()
		return

	var/list/bound_context = list()
	bound_context["action_target"] = obstacle
	var/datum/plan_smartobject/returned_plan = new(plan_items, bound_context)

	var/_plan_ttl = 600
	var/list/stored_plans = src.brain.GetMemoryValue("SmartPlans")
	if(isnull(stored_plans))
		stored_plans = list()

	to_world_log("->-StoredPlans: [json_encode(stored_plans)]")
	if(stored_plans.len < MAX_STORED_PLANS)
		// Pad out the length lazily if not full
		// Might be better to preallocate MAX_STORED_PLANS' worth of space later.
		stored_plans.len++; stored_plans[stored_plans.len] = returned_plan

	else
		var/eject_idx = 0

		for(var/stored_plan in stored_plans)
			// find empty slots in the buffer, if any
			eject_idx++

			if(isnull(stored_plan))
				// if there's a hole, fill that slot
				break

		if(eject_idx >= MAX_STORED_PLANS)
			// if we went through all, eject at random
			eject_idx = rand(1, MAX_STORED_PLANS)

		stored_plans[eject_idx] = returned_plan

	src.brain.SetMemory("SmartPlans", stored_plans, _plan_ttl)
	src.brain.SetMemory("CurrentObstaclePlanContext", obstacle, _plan_ttl)
	tracker.SetDone()
	return
