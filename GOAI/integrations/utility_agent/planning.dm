
# define GOAPPLAN_ACTIONSET_PATH "integrations/smartobject_definitions/goapplan.json"


var/list/global_worldstate = null


/datum/utility_ai/proc/QueryWorldState()
	if(isnull(global.global_worldstate))
		global.global_worldstate = list()
		// Debug worldstate
		global.global_worldstate["DoorDebugAllowUnwelding"] = 1
		global.global_worldstate["DoorDebugAllowUnscrewing"] = 1
		global.global_worldstate["DoorDebugAllowScrewing"] = 1
		global.global_worldstate["DoorDebugAllowHacking"] = 1
		global.global_worldstate["DoorDebugAllowGetWelder"] = 1
		global.global_worldstate["DoorDebugUnscrewed"] = 1


	var/list/worldstate = list()

	// dev trick, this global shouldn't exist in final version
	worldstate = global.global_worldstate.Copy()

	// Debug worldstate
	//worldstate["DoorDebugAllowOpening"] = prob(25)

	return worldstate


/datum/plan_smartobject
	// optional-ish, identifier for debugging:
	var/name

	// the actual plan
	var/list/plan

	// number of failed steps; if this is too high, invalidate the plan
	var/frustration = 0


/datum/plan_smartobject/New(var/list/new_plan, var/new_name = null)
	if(!isnull(new_name))
		src.name = new_name

	src.plan = new_plan

	if(!isnull(src.name))
		// Potentially, cache by destination later.
		src.smartobject_cache_key = src.name


/datum/plan_smartobject/GetUtilityActions(var/requester, var/list/args = null) // (Any, assoc) -> [ActionSet]
	// Replace this with proper generation of Actions from the GOAP Plan!

	// For exploratory development, just hardcoding a plan for now
	ASSERT(fexists(GOAPPLAN_ACTIONSET_PATH))
	var/datum/action_set/myset = ActionSetFromJsonFile(GOAPPLAN_ACTIONSET_PATH)
	ASSERT(!isnull(myset))

	var/list/my_action_sets = list()

	myset.origin = src
	my_action_sets.Add(myset)

	return my_action_sets
