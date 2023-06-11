/* ==  ACTION EXECUTION  == */

/datum/utility_action
	/* This class represents an action *execution*.
	// A true Action is ActionTemplate + Context.
	// For example, Attack(<X>) is a Template where X is a context variable.
	// Attack(BadDude) is an Action where we bound BadDude as the value of X in the Attack(<X>) Template.
	*/
	var/id // this will/may be assigned at runtime, as a position index in an array
	var/name = "UtilityAction"
	var/instant = FALSE
	var/charges = PLUS_INF
	var/list/arguments


/datum/utility_action/New(var/name, var/handler, var/charges, var/instant = FALSE, var/list/action_args = null)
	SET_IF_NOT_NULL(name, src.name)
	SET_IF_NOT_NULL(charges, src.charges)
	SET_IF_NOT_NULL(instant, src.instant)
	SET_IF_NOT_NULL(action_args, src.arguments)
