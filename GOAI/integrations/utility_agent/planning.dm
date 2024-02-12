
# define GOAPPLAN_ACTIONSET_PATH "integrations/smartobject_definitions/goapplan.json"


/datum/utility_ai
	var/list/ai_worldstate = null


/datum/utility_ai/proc/QueryWorldState(var/list/trg_queries = null)
	if(isnull(src.ai_worldstate))
		src.ai_worldstate = list()
		src.ai_worldstate["global"] = list()

	var/list/worldstate = src.ai_worldstate.Copy()

	if(trg_queries?.len)
		for(var/datum/trg_key in trg_queries)
			var/list/qry = trg_queries[trg_key]

			if(isnull(qry))
				continue

			if(isnull(worldstate[trg_key]))
				worldstate[trg_key] = list()

			for(var/query_key in qry)
				var/result = trg_key.GetWorldstateValue(query_key)
				worldstate[trg_key][query_key] = result

	return worldstate


/datum/utility_ai/mob_commander/QueryWorldState(var/list/trg_queries = null)
	var/list/worldstate = ..(trg_queries)

	var/atom/pawn = src.GetPawn()

	if(!isnull(pawn))
		if(isnull(worldstate["pawn"]))
			worldstate["pawn"] = list()

		// Needs to be hella improved
		var/obj/item/up_test_welder/welder = locate() in pawn; worldstate["pawn"]["HasWelder"] = (!isnull(welder))
		var/obj/item/up_test_multitool/multitool = locate() in pawn; worldstate["pawn"]["HasMultitool"] = (!isnull(multitool))
		var/obj/item/up_test_screwdriver/screwdriver = locate() in pawn; worldstate["pawn"]["HasScrewdriver"] = (!isnull(screwdriver))

	return worldstate


/datum/order_smartobject
	/*
	// A fairly lightweight generic "here's something to solve for with planning" marker.
	// By giving one to an agent, you're effectively requesting the AI to solve for a certain
	// state for a given target.
	//
	// Things like Doors having Actions to plan for opening them are effectively a special case
	// of this pattern where we've offloaded the equivalent logic to an actual physical object.
	//
	// Orders just let us make things a bit more generic and allow users to specify arbitrary
	// goals on arbitrary targets.
	*/

	// optional-ish, identifier for debugging:
	var/name

	// An assoc of worldstate values we require our plan to result in
	// e.g. {"IsOpen": 1} to request a plan to open a door (using Python dict notation as shorthand)
	var/list/goal_state = null

	// Who do we want to apply those worldstate values to (e.g. WHICH door to open)
	var/datum/target

	// Utility Considerations required to *plan*
	// (i.e. separate from the Considerations of plan Actions themselves!)
	var/list/planning_considerations = null


/datum/order_smartobject/New(var/list/new_goal_state, var/datum/new_target, var/list/new_planning_considerations, var/name = null)
	. = ..()
	src.goal_state = new_goal_state
	src.target = new_target
	src.planning_considerations = new_planning_considerations
	src.name = DEFAULT_IF_NULL(name, src.name)
	return


/datum/order_smartobject/GetUtilityActions(var/requester, var/list/args = null) // (Any, assoc) -> [ActionSet]
	var/list/actions = list()

	var/action_key = src.name

	var/list/considerations = (isnull(src.planning_considerations) ? list() : src.planning_considerations)
	considerations.Add(/proc/consideration_input_always) // devjunk, remove me!

	var/list/ctxprocs = list(/proc/ctxfetcher_read_origin_var)
	var/list/context_args = list()
	var/list/hard_args = list()

	var/list/primary_context = list()

	primary_context["variable"] = "target" // i.e. src.target
	primary_context["output_context_key"] = "target" // the arg used by the handler

	// nested sublists =_=
	context_args.len++
	context_args[1] = primary_context

	hard_args["goal_state"] = src.goal_state

	var/desc = "plan for order: [json_encode(src.goal_state)]"

	var/datum/utility_action_template/new_action_template = new(
		considerations, //considerations
		/datum/utility_ai/mob_commander/proc/PlanForGoal, //handler
		HANDLERTYPE_SRCMETHOD, //handler_type
		ctxprocs, //ctxprocs
		context_args, //context_args
		3, //priority
		2, //charges
		FALSE, //instant
		hard_args, //hard_args
		action_key, //action_key
		desc, //act_description
		TRUE, // instant
		// GOAP stuff
		null, //preconds,
		null //effects
	)

	var/used_name = (src.name || desc)

	new_action_template.name = used_name
	new_action_template.origin = src
	actions.Add(new_action_template)

	var/datum/action_set/myset = new(used_name, actions)

	ASSERT(!isnull(myset))

	var/list/my_action_sets = list()
	myset.origin = src
	my_action_sets.Add(myset)

	return my_action_sets



/datum/plan_smartobject
	/* Represents a Plan of Actions. Grants SO Actions corresponding to what's in the plan. */

	// optional-ish, identifier for debugging:
	var/name

	// the actual plan
	var/list/plan

	// an assoc of metadata; things like the target etc.
	var/list/bound_context

	// number of failed steps; if this is too high, invalidate the plan
	var/frustration = 0


/datum/plan_smartobject/New(var/list/new_plan, var/list/new_bound_context, var/new_name = null)
	if(!isnull(new_name))
		src.name = new_name

	src.plan = new_plan
	src.bound_context = new_bound_context

	if(!isnull(src.name))
		// Potentially, cache by destination later.
		src.smartobject_cache_key = src.name


/proc/ActionSetFromGoapPlan(var/list/plan, var/list/bound_context, var/name, var/requester = null) // [Action] -> ActionSet
	// Plan assumed to be a simple array-style list of action KEYS
	// (meaning: just strings, no further metadata; we need to do a JOIN)

	if(isnull(global.global_plan_actions_repo))
		InitializeGlobalPlanActionsRepo()

	var/list/planned_actions = list()
	var/list/plan_context = (isnull(bound_context) ? list() : bound_context)

	// wip targetting stuff
	var/action_target = plan_context["action_target"]

	// Running tracker of preconds/effects.
	// To ensure proper sequencing, the preconds of each Action must be the 'base' Preconds AND all predecessors' Effects
	//var/list/preconds_blackboard = list()

	for(var/action_key in plan)
		var/list/action_data = global.global_plan_actions_repo[action_key]
		ASSERT(!isnull(action_data))

		var/has_movement = action_data[JSON_KEY_PLANACTION_HASMOVEMENT]
		var/target_key = action_data[JSON_KEY_PLANACTION_TARGET_KEY]

		var/list/common_consideration_args = list(
			"target_key" = target_key,
			"from_context" = TRUE
		)

		var/datum/consideration/effects_consideration = new(
			input_val_proc = /proc/consideration_actiontemplate_effects_not_all_met,
			curve_proc = /proc/curve_linear,
			loMark = 0,
			hiMark = 1,
			noiseScale = 0,
			name = "EffectsNotMet",
			active = TRUE,
			consideration_args = common_consideration_args
		)

		var/datum/consideration/preconds_consideration = new(
			input_val_proc = /proc/consideration_actiontemplate_preconditions_met,
			curve_proc = /proc/curve_linear,
			loMark = 0,
			hiMark = 1,
			noiseScale = 0,
			name = "PrecondsAllMet",
			active = TRUE,
			consideration_args = common_consideration_args
		)

		var/list/considerations = list(effects_consideration, preconds_consideration)
		var/raw_handler_proc = action_data[JSON_KEY_PLANACTION_RAW_HANDLERPROC]
		var/handler_proc = action_data[JSON_KEY_PLANACTION_HANDLERPROC]

		var/list/hard_args = list()

		var/list/context_args = list()

		// targetting, very wip:
		context_args["action_target"] = action_target
		context_args["contextarg_variable"] = "action_target"

		var/loc_key = action_data[JSON_KEY_PLANACTION_HANDLER_LOCARG]
		context_args["output_context_key"] = loc_key

		if(has_movement)
			// Sneakily substitute the raw function with a decorated one
			hard_args["ai_proc"] = handler_proc
			hard_args["location_key"] = loc_key

			// Introspect function path to check whether it's a method or not
			// We need this because of how the call() syntax works
			var/is_func = (findtextEx(raw_handler_proc, "/proc/") == 1)
			hard_args["is_func"] = is_func

			context_args["output_context_key"] = "location" // always this for the hardcoded decorator

			handler_proc = /datum/utility_ai/mob_commander/proc/MoveToAndExecuteWrapper

			// TODO this could be more sophisticated, e.g. a pair of distance considerations (Too Near/Too Far)
			var/datum/consideration/distance_consideration = new(
				input_val_proc = /proc/consideration_input_manhattan_distance_to_requester,
				curve_proc = /proc/curve_linear_leaky,
				loMark = 1,
				hiMark = 20,
				noiseScale = 0,
				name = "TargetNearby",
				active = TRUE,
				consideration_args = list(
					"input_key" = target_key,
					"from_context" = 1
				)
			)
			considerations.Add(distance_consideration)

		var/raw_override_ctxproc = action_data[JSON_KEY_PLANACTION_CTXFETCHER_OVERRIDE]
		var/override_ctxproc = (isnull(raw_override_ctxproc) ? null : STR_TO_PROC(raw_override_ctxproc))
		var/contextfetcher = (isnull(override_ctxproc) ? /proc/ctxfetcher_read_another_contextarg : override_ctxproc)

		var/list/ctxprocs = list(
			// by default, the context is the target of the plan
			contextfetcher
		)

		var/list/extra_ctx_args = action_data[JSON_KEY_PLANACTION_CTXARGS]

		for(var/extra_ctx_section in extra_ctx_args)
			for(var/arg_key in extra_ctx_section)
				var/arg_val = extra_ctx_section[arg_key]
				context_args[arg_key] = arg_val

		var/list/all_context_args = list()

		all_context_args.len++
		all_context_args[all_context_args.len] = context_args

		var/priority = 9 // TODO: get actual value from Elsewhere (TM)
		var/charges = null
		var/instant = FALSE
		var/act_description = action_data[JSON_KEY_PLANACTION_DESCRIPTION]

		var/list/preconds = action_data[JSON_KEY_PLANACTION_PRECONDITIONS]

		var/list/effects = action_data[JSON_KEY_PLANACTION_EFFECTS]

		if(isnull(effects))
			effects = list()

		var/datum/utility_action_template/new_action_template = new(
			considerations,
			handler_proc,
			HANDLERTYPE_SRCMETHOD,
			ctxprocs,
			all_context_args,
			priority,
			charges,
			instant,
			hard_args,
			action_key,
			act_description,
			TRUE,
			// GOAP stuff
			preconds,
			effects
		)

		// Package it up!
		planned_actions.Add(new_action_template)

	var/datum/action_set/plan_actionset = new(
		name = name,
		included_actions = planned_actions,
		origin = isnull(requester) ? plan : requester
		// TODO: could use a freshness proc w/ the plan as args
	)
	return plan_actionset


/datum/plan_smartobject/GetUtilityActions(var/requester, var/list/args = null) // (Any, assoc) -> [ActionSet]
	var/datum/action_set/myset = ActionSetFromGoapPlan(src.plan, src.bound_context, "TestPlan", src)
	ASSERT(!isnull(myset))

	var/list/my_action_sets = list()

	myset.origin = src
	my_action_sets.Add(myset)

	return my_action_sets
