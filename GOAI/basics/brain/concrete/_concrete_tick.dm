

/datum/brain/concrete/Life()
	while(life)
		CheckForCleanup()
		LifeTick()
		sleep(AI_TICK_DELAY)
	return


/datum/brain/concrete/proc/OnBeginLifeTick()
	return


// NOTE: this is ACTUALLY specifically a GOAP tick
// No real reason, legacy of the code evolution

/datum/brain/concrete/LifeTick()
	var/run_count = 0
	var/target_run_count = 1
	var/do_plan = FALSE

	OnBeginLifeTick() // hook

	while(run_count++ < target_run_count)
		/* STATE: Running */
		if(running_action_tracker) // processing action
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
			RUN_ACTION_DEBUG_LOG("SELECTED ACTION: [selected_action] | <@[src]>")

			var/is_valid = src.IsActionValid(selected_action)

			RUN_ACTION_DEBUG_LOG("SELECTED ACTION [selected_action] VALID: [is_valid ? "TRUE" : "FALSE"]")

			if(is_valid)
				running_action_tracker = src.DoAction(selected_action)

			else
				var/should_rerun = src.OnInvalidAction(selected_action)
				if(should_rerun)
					target_run_count++

			selected_action = null


		/* STATE: Pending next stage */
		else if(active_plan && active_plan.len)
			//step done, move on to the next
			RUN_ACTION_DEBUG_LOG("ACTIVE PLAN: [active_plan] ([active_plan.len]) | <@[src]>")
			DEBUG_LOG_LIST_ARRAY(active_plan, RUN_ACTION_DEBUG_LOG)

			while(active_plan.len && isnull(selected_action))
				// do instants in one tick
				selected_action = lpop(active_plan)

				if(!(selected_action in actionslist))
					continue

				var/datum/goai_action/goai_act = src.actionslist[selected_action]

				if(!goai_act)
					continue

				if(goai_act.instant)
					RUN_ACTION_DEBUG_LOG("Instant ACTION: [selected_action] | <@[src]>")
					DoInstantAction(selected_action)
					selected_action = null

				else
					RUN_ACTION_DEBUG_LOG("Regular ACTION: [selected_action] | <@[src]>")


		else //no plan & need to make one
			do_plan = TRUE


		/* STATE: Planning */
		if(do_plan)
			var/should_retry = HandlePlanningState()
			if(should_retry)
				target_run_count++

	return
