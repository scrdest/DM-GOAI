/*
// Smart Objects implementation.
//
// Gives all datums (and therefore all DM objects) the ability to return Utility ActionSets.
// This allows any game entity to be queried for Things Wot You Can Do Onnit by the AI.
//
// In turn, this means we don't have to write a handler for Everything The Agent Might Do.
// We can just let objects have various affordances for various requesters (e.g. OpenDoor
// is only available to agents whose Pawn has hands or equivalent).
//
// The API shall return an ActionSet, with a firm tacit encouragement to specify the TTL details
// as well (or we'll wind up storing a ton of unnecessary inactive Actions)
*/


// Assoc list that will store
//var/list/global/smartobject_cache = null


/datum
	// To speed up queries, we'll cache the ActionSets for Smart Objects
	// If an object instance has custom actions, set its cache key to something
	// that will distinguish it from the generic instances of this object.
	var/smartobject_cache_key = null  // implementation-defined on null


/datum/proc/GetUtilityActions(var/requester, var/list/args = null) // (Any, assoc) -> [ActionSet]
	return


/datum/brain/utility
	var/list/smart_objects = null
	var/list/smartobject_last_fetched = null


/datum/brain/utility/proc/GetActionSetFromSmartObject(var/datum/smartobj, var/list/args = null)
	if(isnull(smartobj))
		return null

	var/cache_key = (smartobj.smartobject_cache_key || smartobj.type)

	if(isnull(src.smart_objects))
		src.smart_objects = list()

	var/datum/action_set/so_actions = src.smart_objects[cache_key]

	if(so_actions)
		so_actions.Refresh()
		return so_actions

	so_actions = smartobj.GetUtilityActions(src, args)
	src.smart_objects[cache_key] = so_actions

	return so_actions
