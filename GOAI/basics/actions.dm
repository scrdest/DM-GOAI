
/datum/goai_action
	var/list/preconditions
	var/list/effects
	var/cost = 10 // standard
	var/name = "Action"
	var/charges = PLUS_INF


/datum/goai_action/New(var/list/new_preconds, var/list/new_effects, var/new_cost = null, var/new_name = null, var/new_charges = null)
	name = (isnull(new_name) ? name : new_name)
	cost = (isnull(new_cost) ? cost : new_cost)
	preconditions = (new_preconds || list())
	effects = (new_effects || list())
	charges = (isnull(new_charges) ? charges : new_charges)


/datum/goai_action/proc/ReduceCharges(var/amt=1)
	world.log << "Reducing charges for [src] by [amt], curr [charges]"
	charges -= amt
	return charges
