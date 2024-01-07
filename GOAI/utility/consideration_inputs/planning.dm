
CONSIDERATION_CALL_SIGNATURE(/proc/consideration_actiontemplate_preconditions_met)
	// Retrieves Preconditions from the candidate ActionTemplate object.
	// If any is not satisfied, return False.
	var/datum/utility_action_template/candidate = action_template

	if(isnull(candidate))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_actiontemplate_preconditions_met Candidate is not an ActionTemplate! @ L[__LINE__] in [__FILE__]")
		return null

	if(isnull(requester))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_actiontemplate_preconditions_met - Requester must be provided for this Consideration! @ L[__LINE__] in [__FILE__]")
		return null

	var/datum/utility_ai/ai = requester

	if(isnull(ai))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_actiontemplate_preconditions_met - Requester must be a Utility controller for this Consideration! @ L[__LINE__] in [__FILE__]")
		return null


	var/list/preconds = candidate.preconditions

	if(isnull(preconds) || !preconds.len)
		// No preconds - automatically satisfied
		return TRUE

	var/list/world_state = ai.QueryWorldState()

	for(var/precond_key in preconds)
		var/precond_val = preconds[precond_key]

		if(!(precond_key in world_state))
			return FALSE

		var/worldval = world_state[precond_key]

		if(worldval < precond_val)
			// not satisfied
			return FALSE

	return TRUE


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_actiontemplate_effects_not_all_met)
	// Retrieves Effects from the candidate ActionTemplate object.
	// If any is not satisfied, return True.
	var/datum/utility_action_template/candidate = action_template

	if(isnull(candidate))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_actiontemplate_preconditions_met Candidate is not an ActionTemplate! @ L[__LINE__] in [__FILE__]")
		return null

	if(isnull(requester))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_actiontemplate_preconditions_met - Requester must be provided for this Consideration! @ L[__LINE__] in [__FILE__]")
		return null

	var/datum/utility_ai/ai = requester

	if(isnull(ai))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_actiontemplate_preconditions_met - Requester must be a Utility controller for this Consideration! @ L[__LINE__] in [__FILE__]")
		return null

	var/list/effects = candidate.effects

	if(isnull(effects) || !effects.len)
		// No effects - no point running
		return FALSE

	var/list/world_state = ai.QueryWorldState()

	for(var/effect_key in effects)
		var/effect_val = effects[effect_key]

		if(!(effect_key in world_state))
			return TRUE

		var/worldval = world_state[effect_key]

		if(worldval < effect_val)
			// not satisfied
			// we could tally all of them up at return the count, but for now - this is cheaper
			return TRUE

	return FALSE

