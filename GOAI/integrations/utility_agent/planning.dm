
# define GOAPPLAN_ACTIONSET_PATH "integrations/smartobject_definitions/goapplan.json"


/datum/utility_ai
	var/list/ai_worldstate = null


/datum/utility_ai/proc/QueryWorldState()
	if(isnull(src.ai_worldstate))
		src.ai_worldstate = list()
		// Debug initial worldstate stuff
		src.ai_worldstate["DoorDebugAllowUnwelding"] = 1
		src.ai_worldstate["DoorDebugAllowUnscrewing"] = 1
		src.ai_worldstate["DoorDebugAllowScrewing"] = 1
		src.ai_worldstate["DoorDebugAllowHacking"] = 1
		src.ai_worldstate["DoorDebugAllowGetWelder"] = 1
		src.ai_worldstate["DoorDebugUnscrewed"] = prob(75)
		src.ai_worldstate["DoorDebugWelded"] = prob(75)
		src.ai_worldstate["DoorDebugBolted"] = prob(75)

	var/list/worldstate = src.ai_worldstate.Copy()

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
