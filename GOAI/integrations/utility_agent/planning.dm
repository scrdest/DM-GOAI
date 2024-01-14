
# define GOAPPLAN_ACTIONSET_PATH "integrations/smartobject_definitions/goapplan.json"


/datum/utility_ai
	var/list/ai_worldstate = null


/datum/utility_ai/proc/QueryWorldState(var/list/trg_queries = null)
	if(isnull(src.ai_worldstate))
		src.ai_worldstate = list()
		// Debug initial worldstate stuff
		src.ai_worldstate["global"] = list()
		src.ai_worldstate["global"]["DoorDebugAllowUnwelding"] = 1
		src.ai_worldstate["global"]["DoorDebugAllowUnscrewing"] = 1
		src.ai_worldstate["global"]["DoorDebugAllowScrewing"] = 1
		src.ai_worldstate["global"]["DoorDebugAllowHacking"] = 1
		src.ai_worldstate["global"]["DoorDebugAllowGetWelder"] = 1
		src.ai_worldstate["global"]["DoorDebugUnscrewed"] = prob(75)
		src.ai_worldstate["global"]["DoorDebugWelded"] = prob(75)
		src.ai_worldstate["global"]["DoorDebugBolted"] = prob(75)

	var/list/worldstate = src.ai_worldstate.Copy()

	if(trg_queries?.len)
		for(var/atom/trg_key in trg_queries)
			var/list/qry = trg_queries[trg_key]

			if(isnull(qry))
				continue

			if(isnull(worldstate[trg_key]))
				worldstate[trg_key] = list()

			for(var/query_key in qry)
				var/result = trg_key.GetWorldstate(query_key)
				worldstate[trg_key][query_key] = result

	return worldstate


/datum/utility_ai/mob_commander/QueryWorldState(var/list/trg_queries = null)
	var/list/worldstate = ..(trg_queries)

	var/atom/pawn = src.GetPawn()

	if(!isnull(pawn))
		if(isnull(worldstate["pawn"]))
			worldstate["pawn"] = list()

		var/obj/item/up_test_welder/welder = locate() in pawn; worldstate["pawn"]["HasWelder"] = (!isnull(welder))
		var/obj/item/up_test_multitool/multitool = locate() in pawn; worldstate["pawn"]["HasMultitool"] = (!isnull(multitool))
		var/obj/item/up_test_screwdriver/screwdriver = locate() in pawn; worldstate["pawn"]["HasScrewdriver"] = (!isnull(screwdriver))

		/*
		var/obj/item/up_test_welder/globwelder = locate()
		var/obj/item/up_test_welder/tagwelder = locate("test_welder")
		to_world("Welder - in pawn: [welder], global [globwelder], by tag [tagwelder]")
		*/

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
