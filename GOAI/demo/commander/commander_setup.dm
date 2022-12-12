/datum/goai_commander/proc/InitActionLookup()
	/* Largely redundant; initializes handlers, but
	// InitActions should generally use AddAction
	// with a handler arg to register them.
	// Mostly a relic of past design iterations.
	*/
	var/list/new_actionlookup = list()
	return new_actionlookup


/datum/goai_commander/proc/InitActionsList()
	var/list/new_actionslist = list()
	return new_actionslist


/datum/goai_commander/proc/InitSenses()
	senses = list()
	return senses


/datum/goai_commander/proc/InitNeeds()
	needs = list()
	return needs


/datum/goai_commander/proc/InitStates()
	states = list()
	return states


/datum/goai_commander/proc/Equip()
	return TRUE