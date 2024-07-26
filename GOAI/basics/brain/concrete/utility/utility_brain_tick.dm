/*
// This module houses the core loop of the Utility brain.
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

/datum/brain/utility/proc/OnBeginLifeTick()
	return


// Bears explaining: for mostly emergent design reasons, the Utility Brain does not own its own processing.
// Instead, the AI controlling the Brain 'pulses' this core loop at its own leisure and harvests results.

// Potential TODO: move this logic to AI, use the Brain just for storage

/datum/brain/utility/LifeTick()
	var/run_count = 0
	var/target_run_count = 1
	var/do_plan = FALSE

	OnBeginLifeTick() // hook

	while(run_count++ < target_run_count)
		/* STATE: Running */
		if(running_action_tracker?.process) // processing action
			RUN_ACTION_DEBUG_LOG("ACTIVE ACTION: [running_action_tracker.tracked_action] @ [running_action_tracker.IsRunning()] | <@[src]>")

			if(running_action_tracker.replan)
				do_plan = TRUE
				target_run_count++
				src.AbortPlan(FALSE)

			else if(running_action_tracker.is_done)
				src.NextPlanStep()
				target_run_count++

			else if(running_action_tracker.is_failed)
				src.AbortPlan(FALSE)


		/* STATE: Ready */
		else if(selected_action) // ready to go
			RUN_ACTION_DEBUG_LOG("SELECTED ACTION: [selected_action]([selected_action?:arguments && json_encode(selected_action:arguments)]) | <@[src]>")

			running_action_tracker = src.DoAction(selected_action)
			target_run_count++

			selected_action = null


		/* STATE: Pending next stage */
		else if(active_plan && active_plan.len)
			//step done, move on to the next
			RUN_ACTION_DEBUG_LOG("ACTIVE PLAN: [active_plan] ([active_plan.len]) | <@[src]>")
			DEBUG_LOG_LIST_ASSOC(active_plan, RUN_ACTION_DEBUG_LOG)

			while(active_plan.len && isnull(selected_action))
				// Unlike GOAP as of writing, active_plan is a STACK.
				// (it's faster this way and GOAP should use a stack too but honk)
				selected_action = pop(active_plan)

				var/datum/utility_action/action = selected_action
				UTILITYBRAIN_DEBUG_LOG("Selected action: [action?.name || "NONE"]([action?.arguments && json_encode(action?.arguments)]) | <@[src]>")

				// do instants in one tick
				if(action?.instant)
					RUN_ACTION_DEBUG_LOG("Instant ACTION: [action?.name || "NONE"]([action?.arguments && json_encode(action?.arguments)]) | <@[src]>")
					DoInstantAction(selected_action)
					selected_action = null

				else
					RUN_ACTION_DEBUG_LOG("Regular ACTION: [action?.name || "NONE"]([action?.arguments && json_encode(action?.arguments)]) | <@[src]>")


		else //no plan & need to make one
			do_plan = TRUE


		/* STATE: Planning */
		if(do_plan)
			var/prev_plan = src.active_plan

			var/should_retry = HandlePlanningState()

			if(should_retry)
				target_run_count++

			if(isnull(prev_plan) && src.active_plan)
				// If we created a new plan, execute straight away
				target_run_count++

	return

/*
/datum/brain/utility/Life()
	while(life)
		CheckForCleanup()
		LifeTick()
		sleep(AI_TICK_DELAY)
	return
*/
