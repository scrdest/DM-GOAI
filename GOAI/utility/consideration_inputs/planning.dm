# define PLANNING_CONSIDERATIONS_LOG(x) to_world(x); to_world_log(x)
//# define PLANNING_CONSIDERATIONS_LOG(x)

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
		PLANNING_CONSIDERATIONS_LOG("- AT [action_template.name] preconds check for [precond_key]!!!")
		var/precond_val = preconds[precond_key]

		var/worldval = null

		if(precond_val > 0)
			// Intuitively normal case; state value is a minimum satisfactory value
			if(!(precond_key in world_state))
				// missing interpreted as false
				PLANNING_CONSIDERATIONS_LOG("--- AT [action_template.name] failed preconds check for [precond_key] - V0")
				return FALSE

			worldval = world_state[precond_key]
			PLANNING_CONSIDERATIONS_LOG("-- AT [action_template.name] preconds worldval for [precond_key] is: [worldval || "null"] @ thresh [precond_val]")

			if(worldval < precond_val)
				// not satisfied
				PLANNING_CONSIDERATIONS_LOG("--- AT [action_template.name] failed preconds check for [precond_key] - V1")
				return FALSE

			PLANNING_CONSIDERATIONS_LOG("--- AT [action_template.name] preconds check for [precond_key] - PASS [worldval || "null"] @ thresh [precond_val]")

		if(precond_val <= 0)
			// We use -val as a logical inverse of the normal check as done for the abs(val)
			// In other words:
			// val = +2 -> must be 2 or more
			// val = -2 -> must be 2 or less (2 == abs(-2))
			// val=0 is interpreted as 'boolean predicate is FALSE'.

			if(!(precond_key in world_state))
				PLANNING_CONSIDERATIONS_LOG("--- AT [action_template.name] preconds check for [precond_key] - PASS, special case, missing key passthru...")
				continue

			worldval = world_state[precond_key]
			PLANNING_CONSIDERATIONS_LOG("-- AT [action_template.name] preconds worldval for [precond_key] is: [worldval || "null"] @ thresh [precond_val]")

			if(worldval >= -precond_val)
				PLANNING_CONSIDERATIONS_LOG("--- AT [action_template.name] failed preconds check for [precond_key] - V2")
				return FALSE

			PLANNING_CONSIDERATIONS_LOG("--- AT [action_template.name] preconds check for [precond_key] - PASS [worldval || "null"] @ thresh [precond_val]")

	PLANNING_CONSIDERATIONS_LOG("AT [action_template.name] passed all preconds checks...")
	return TRUE


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_actiontemplate_effects_not_all_met)
	// Retrieves Effects from the candidate ActionTemplate object.
	// If any is not satisfied, return True.
	var/datum/utility_action_template/candidate = action_template

	if(isnull(candidate))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_actiontemplate_effects_not_all_met Candidate is not an ActionTemplate! @ L[__LINE__] in [__FILE__]")
		return null

	if(isnull(requester))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_actiontemplate_effects_not_all_met - Requester must be provided for this Consideration! @ L[__LINE__] in [__FILE__]")
		return null

	var/datum/utility_ai/ai = requester

	if(isnull(ai))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_actiontemplate_effects_not_all_met - Requester must be a Utility controller for this Consideration! @ L[__LINE__] in [__FILE__]")
		return null

	var/list/effects = candidate.effects

	if(isnull(effects) || !effects.len)
		// No effects - no point running
		return FALSE

	var/list/world_state = ai.QueryWorldState()

	for(var/effect_key in effects)
		PLANNING_CONSIDERATIONS_LOG("- AT [action_template.name] effects check for [effect_key]!!!")
		var/effect_val = effects[effect_key]

		if(!(effect_key in world_state))
			return TRUE

		var/worldval = null

		if(effect_val > 0)
			// Intuitively normal case; state value is a minimum satisfactory value
			if(!(effect_key in world_state))
				// missing interpreted as false
				return TRUE

			worldval = world_state[effect_key]
			PLANNING_CONSIDERATIONS_LOG("-- AT [action_template.name] effects worldval for [effect_key] is: [worldval || "null"] @ thresh [effect_val]")

			if(worldval < effect_val)
				// not satisfied
				PLANNING_CONSIDERATIONS_LOG("--- AT [action_template.name] missed effect check for [effect_key] - V1")
				return TRUE

			PLANNING_CONSIDERATIONS_LOG("--- AT [action_template.name] effect check for [effect_key] - ALREADY DONE [worldval || "null"] @ thresh [effect_val]")

		if(effect_val <= 0)
			// We use -val as a logical inverse of the normal check as done for the abs(val)
			// In other words:
			// val = +2 -> must be 2 or more
			// val = -2 -> must be 2 or less (2 == abs(-2))
			// val=0 is interpreted as 'boolean predicate is FALSE'.

			if(!(effect_key in world_state))
				if(effect_val == 0)
					PLANNING_CONSIDERATIONS_LOG("--- AT [action_template.name] effects check for [effect_key] - PASS, special case, missing key passthru...")
					continue

				PLANNING_CONSIDERATIONS_LOG("--- AT [action_template.name] missed effect check for [effect_key] - V3")
				return TRUE

			worldval = world_state[effect_key]
			PLANNING_CONSIDERATIONS_LOG("-- AT [action_template.name] effects worldval for [effect_key] is: [worldval || "null"] @ thresh [effect_val]")

			if(worldval != -effect_val)
				PLANNING_CONSIDERATIONS_LOG("--- AT [action_template.name] missed effect check for [effect_key] - V2")
				return TRUE

			PLANNING_CONSIDERATIONS_LOG("--- AT [action_template.name] effect check for [effect_key] - ALREADY DONE [worldval || "null"] @ thresh [effect_val]")

	PLANNING_CONSIDERATIONS_LOG("AT [action_template.name] missed all effect checks...")
	return FALSE

