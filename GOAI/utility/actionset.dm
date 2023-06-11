/* ==  ACTION SETS  == */

/datum/action_set
	/* Represents a logical grouping of ActionTemplates.
	// This is handy because we can slot in whole bundles of possible Actions that are
	//   provided by some source (e.g. a Combat state providing the Combat suite of ActionTemplates).
	// This also means we can manage them together, e.g. disable the whole Combat bundle when not in a
	//   Combat state and reenable it when aggressive, rather than having to spent an eternity del()ing
	//   and new()ing Actions.
	*/
	var/active = TRUE
	var/list/actions = null


/datum/action_set/New(var/list/included_actions, var/active = null)
	SET_IF_NOT_NULL(included_actions, src.actions)
	SET_IF_NOT_NULL(active, src.active)

	ASSERT(src.actions)