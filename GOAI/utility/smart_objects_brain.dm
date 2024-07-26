/*
// Smart Objects integration with Brain as the main user.
//
// This is the LEGACY version of the API before this logic moved to AIs proper.
//
// This is (or at least should be) unincluded at the moment.
// Not much will happen if you untick this and/or the other Brain-based decision API components,
// but this is deprecated, possibly under-maintained and probably just... unnecessary.
*/


/datum/brain/utility
	var/list/smart_objects = null
	var/list/smartobject_last_fetched = null


/datum/brain/utility/proc/GetActionSetsFromSmartObject(var/datum/smartobj, var/requester, var/list/args = null)
	if(isnull(smartobj))
		return null

	if(isnull(src.smart_objects))
		src.smart_objects = list()

	SMARTOBJECT_CACHE_LAZY_INIT(0)

	var/cache_key = (smartobj.smartobject_cache_key || "[smartobj.type]")

	var/list/so_actions = null

	so_actions = smartobj.no_smartobject_caching ? null : GOAI_LIBBED_GLOB_ATTR(smartobject_cache)[cache_key]

	if(!isnull(so_actions))
		//for(var/so_actionset in so_actions)
		//	so_actions.Refresh()

		src.smart_objects[cache_key] = so_actions
		return so_actions

	so_actions = smartobj.no_smartobject_caching ? null : src.smart_objects[cache_key]

	if(so_actions)
		//so_actions.Refresh()
		return so_actions

	if(!(smartobj.HasUtilityActions(requester, args)))
		GOAI_LOG_DEVEL("[smartobj] failed HasUtilityActions check")

	var/datum/action_set/subactions = smartobj.GetUtilityActions(requester, args)

	so_actions = subactions
	// old version, not sure why it was like this but it was misbehaving
	//so_actions = list(); so_actions[subactions.name] = subactions

	if(!smartobj.no_smartobject_caching)
		GOAI_LIBBED_GLOB_ATTR(smartobject_cache)[cache_key] = so_actions
		src.smart_objects[cache_key] = so_actions

	return so_actions
