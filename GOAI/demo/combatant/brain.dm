/* In this module:
===================

 - Brain definition
 - Operator override for need updates
 - Initial needs
 - Initial states

*/

/datum/GOAP/demoGoap/combatGoap


/datum/GOAP/demoGoap/combatGoap/update_op(var/old_val, var/new_val)
	var/result = new_val
	return result


/datum/brain/concrete/combat



/mob/goai/combatant/InitNeeds()
	needs = ..()
	/* COVER need encourages the AI to seek cover positions, duh
	// since we don't actually *set* that need to be satisfied (as of rn)
	// they will continuously try to get to cover.
	*/
	needs[NEED_COVER] = NEED_MINIMUM
	/* COMPOSURE serves a similar role as Morale in TW and other strategy games;
	// if it gets depleted, the NPC makes a run for their lives or whatever else
	// they think will save their bacon.
	//
	// Not called Morale because that's a less fine-grained concept - we'll model
	// it as a product of different states and needs, including COMPOSURE itself.
	*/
	needs[NEED_COMPOSURE] = NEED_SAFELEVEL
	//needs[NEED_ENEMIES] = 2
	return needs

/*
/datum/brain/concrete/combat/InitNeeds()
	needs = ..()
	needs[NEED_COVER] = NEED_MINIMUM
	//needs[NEED_ENEMIES] = 2
	return needs


/datum/brain/concrete/combat/InitStates()
	states = ..()
	states[STATE_DOWNTIME] = TRUE
	return states
*/

/datum/brain/concrete/combat/New(var/list/actions, var/list/init_memories = null, var/init_action = null, var/datum/brain/with_hivemind = null, var/dict/init_personality = null, var/newname = null)
	..(actions, init_memories, init_action, with_hivemind, init_personality, newname)

	var/datum/GOAP/demoGoap/new_planner = new /datum/GOAP/demoGoap/combatGoap/(actionslist)
	planner = new_planner
