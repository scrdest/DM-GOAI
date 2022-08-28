
/datum/goai_action
	var/list/preconditions
	var/list/effects

	/* Priority */
	var/cost = 10 // standard

	/* Name, for debugging */
	var/name = "Action"

	/* If < 1, action not available for execution.
	// Each execution depletes the charges.
	// For one-off, dynamically inserted Actions mostly.
	*/
	var/charges = PLUS_INF

	/* If TRUE, finishes 'instantly' from the AI PoV, so we
	// run it in the same AI tick and go to the next Action
	// (or finish the current plan and create a new one).
	//
	// Any number of Instant actions can run before a non-Instant
	// action; they all follow the same rules on preconds/effects
	// as non-Instants.
	//
	// This can be a good tool to set up dependencies for another
	// Action without wasting ticks or baking them in in the dependant.
	// For example,  we can factor out pathfinding to an Instant Action
	// that sets up a non-Instant, MoveTo action.
	*/
	var/instant = FALSE


/datum/goai_action/New(var/list/new_preconds, var/list/new_effects, var/new_cost = null, var/new_name = null, var/new_charges = null, var/is_instant = null)
	name = (isnull(new_name) ? name : new_name)
	cost = (isnull(new_cost) ? cost : new_cost)
	preconditions = (new_preconds || list())
	effects = (new_effects || list())
	charges = (isnull(new_charges) ? charges : new_charges)
	instant = (isnull(is_instant) ? instant : is_instant)


/datum/goai_action/proc/ReduceCharges(var/amt=1)
	world.log << "Reducing charges for [src] by [amt], curr [charges]"
	charges -= amt
	return charges