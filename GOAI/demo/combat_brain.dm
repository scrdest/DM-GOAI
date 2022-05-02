/datum/GOAP/demoGoap/combatGoap


/datum/GOAP/demoGoap/combatGoap/update_op(var/old_val, var/new_val)
	var/result = new_val
	return result


/datum/brain/concrete/combat


/datum/brain/concrete/combat/InitNeeds()
	needs = ..()
	needs[NEED_COVER] = NEED_MINIMUM
	//needs[NEED_ENEMIES] = 2
	return needs


/datum/brain/concrete/combat/InitStates()
	states = ..()
	states[STATE_DOWNTIME] = TRUE
	return states


/datum/brain/concrete/combat/New(var/list/actions)
	..(actions)

	var/datum/GOAP/demoGoap/new_planner = new /datum/GOAP/demoGoap/combatGoap/(actionslist)
	planner = new_planner
