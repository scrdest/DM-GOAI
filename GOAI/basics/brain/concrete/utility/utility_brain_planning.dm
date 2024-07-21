
/datum/brain/utility/proc/ScoreActions(var/list/actionsets)
	var/PriorityQueue/utility_ranking = new /PriorityQueue(/datum/Triple/proc/FirstTwoCompare)
	var/requester = src.GetRequester()

	# ifdef UTILITYBRAIN_LOG_ACTIONCOUNT
	var/template_count = 0
	# endif

	for(var/datum/action_set/actionset in actionsets)
		if(!(actionset?.active))
			continue

		var/list/actions = actionset?.actions
		if(!actions)
			continue

		for(var/datum/utility_action_template/action_template in actions)
			# ifdef UTILITYBRAIN_LOG_ACTIONCOUNT
			template_count++
			# endif

			var/list/contexts = action_template.GetCandidateContexts(requester)

			if(contexts)
				# ifdef UTILITYBRAIN_LOG_CONTEXTS
				UTILITYBRAIN_DEBUG_LOG("Found contexts ([contexts.len]) | <@[src]>")
				# endif

				# ifdef UTILITYBRAIN_LOG_CONTEXTS
				var/ctxidx = 0
				# endif

				for(var/ctx in contexts)
					# ifdef UTILITYBRAIN_LOG_CONTEXTS
					// Yes, this is a triple-nested for-loop, and that's fine since we're looping
					// over different categories. In particular, the first two loops are effectively
					// one loop with a top-level optimization (skip all disabled actions in a set).
					//
					// That said, the amount of evaluated Contexts should be kept tightly constrained.
					// Only fetch contexts that are likely to be a) relevant & b) executed.
					UTILITYBRAIN_DEBUG_LOG("ScoreAction context: [ctx]")
					var/subctx_idx = 0
					for(var/subctx in ctx)
						subctx_idx++
						try
							UTILITYBRAIN_DEBUG_LOG("ScoreAction subcontext: [subctx] [ctx[subctx]] @ [subctx_idx]")
						catch(var/exception/e)
							UTILITYBRAIN_DEBUG_LOG("[e]")
							UTILITYBRAIN_DEBUG_LOG("ScoreAction subcontext: [subctx] @ [subctx_idx]")
						DEBUG_LOG_LIST_ASSOC(subctx, to_world_log)
					# endif

					var/utility = action_template.ScoreAction(action_template, ctx, requester)
					if(utility > 0.01)
						// tiebreaker noise
						utility -= (0.01 * rand())

					# ifdef UTILITYBRAIN_LOG_UTILITIES
					UTILITYBRAIN_DEBUG_LOG("Utility for [action_template?.name]([json_encode(ctx)]): [utility] (priority: [action_template?.priority_class]) | <@[src]>")
					UTILITYBRAIN_DEBUG_LOG("=========================")
					UTILITYBRAIN_DEBUG_LOG(" ")
					# endif

					if(utility <= 0)
						// To prevent impossible actions from being considered!
						continue

					var/datum/Triple/scored_action = new(utility, action_template, ctx)
					utility_ranking.Enqueue(scored_action)

			else
				// Some actions could have a 'null' context (i.e. they don't care about the world-state)
				// We should support this to avoid alloc-ing empty lists for efficiency, at the cost of smol code duplication
				var/utility = action_template.ScoreAction(action_template, null, requester) // null/default context

				if(utility <= 0)
					// To prevent impossible actions from being considered!

					# ifdef UTILITYBRAIN_LOG_UTILITIES
					UTILITYBRAIN_DEBUG_LOG("REJECTED [action_template?.name] due to zero Utility score [utility]")
					# endif

					continue

				var/datum/Triple/scored_action = new(utility, action_template, null) // ...and here, as a triple!
				utility_ranking.Enqueue(scored_action)


	# ifdef UTILITYBRAIN_LOG_ACTIONCOUNT
	UTILITYBRAIN_DEBUG_LOG(" ")
	UTILITYBRAIN_DEBUG_LOG("INFO: Processed [template_count] ActionTemplates")
	UTILITYBRAIN_DEBUG_LOG(" ")
	#endif

	return utility_ranking


/datum/brain/utility/proc/HandlePlanningState()
	/* Main selection logic.
	// Runs through all available actions,
	// scores them by utility,
	// selects a high-utility action.
	*/

	set waitfor = FALSE

	// selection left intentionally vague; will probably do deterministic as PoC and weighted sampling later

	if(!is_planning)
		is_planning = TRUE
		sleep(0)

		var/list/actionsets = GetAvailableActions()

		var/PriorityQueue/utility_ranking = src.ScoreActions(actionsets)
		var/datum/Triple/best_act_tup = null

		while(utility_ranking.L)
			var/best_act_res = utility_ranking.Dequeue()

			best_act_tup = best_act_res
			if(!isnull(best_act_tup))
				break

		if(!best_act_tup)
			RUN_ACTION_DEBUG_LOG("ERROR: Best action tuple is null! [best_act_tup], Actionset count: [length(actionsets)] | <@[src]> | [__FILE__] -> L[__LINE__]")
			return

		var/datum/utility_action_template/best_action_template = best_act_tup.middle
		var/list/best_action_ctx = best_act_tup.right
		var/datum/utility_action/best_action = best_action_template.ToAction(best_action_ctx)

		src.SetMemory("SelectedActionTemplate", best_action_template)

		if(best_action)
			PUT_EMPTY_LIST_IN(src.active_plan)
			src.active_plan.Add(best_action)

		else
			RUN_ACTION_DEBUG_LOG("ERROR: Best action is null! | <@[src]> | [__FILE__] -> L[__LINE__]")

	else //satisfied, can be lazy
		Idle()

	is_planning = FALSE
	return


/datum/brain/utility/proc/NextPlanStep()
	if(src.running_action_tracker)
		src.running_action_tracker.process = FALSE
	return TRUE


/datum/brain/utility/AbortPlan(var/mark_failed = TRUE)
	if(mark_failed)
		// Mark the plan as failed
		src.last_plan_successful = FALSE
		src.running_action_tracker?.SetFailed()

	// Cancel current tracker, if any is running
	if(src.running_action_tracker)
		src.running_action_tracker.process = FALSE

	// Cancel all instant and regular Actions
	PUT_EMPTY_LIST_IN(src.pending_instant_actions)
	src.active_plan = null
	src.selected_action = null

	return TRUE
