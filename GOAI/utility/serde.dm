/*
// Constructors for assorted Utility AI classes from serialization formats (JSON, mainly)
// We can use these to make the AI design data-driven, with the code just providing the plumbing.
*/

//# define DEBUG_SERDE_LOADS 1


// Unfortunately DM is suffering, so these have to be 'plain' procs and not classmethods.

# define READ_JSON_FILE(FP) (fexists(FP) && json_decode(file2text(FP)))
# define WRITE_JSON_FILE(Data, FP) ((!isnull(Data)) && text2file(json_encode(Data), FP))

/* ====  JSON schemas  ==== */

// Generic:
# define JSON_KEY_VERSION "version"

// Consideration schema:
# define JSON_KEY_CONSIDERATION_INPPROC "input_proc"
# define JSON_KEY_CONSIDERATION_CURVEPROC "curve_proc"
# define JSON_KEY_CONSIDERATION_LOMARK "lo_mark"
# define JSON_KEY_CONSIDERATION_HIMARK "hi_mark"
# define JSON_KEY_CONSIDERATION_NOISESCALE "noise_scale"
# define JSON_KEY_CONSIDERATION_NAME "name"
# define JSON_KEY_CONSIDERATION_DESC "description"
# define JSON_KEY_CONSIDERATION_ACTIVE "active"
# define JSON_KEY_CONSIDERATION_ARGS "input_args"

// ActionTemplate schema:
# define JSON_KEY_CONSIDERATIONS "considerations"
# define JSON_KEY_ACT_CTXPROC "context_proc"
# define JSON_KEY_ACT_CTXARGS "context_args"
# define JSON_KEY_ACT_HANDLER "handler"
# define JSON_KEY_ACT_PRIORITY "priority"
# define JSON_KEY_ACT_CHARGES "charges"
# define JSON_KEY_ACT_ISINSTANT "instant"
# define JSON_KEY_ACT_NAME "name"
# define JSON_KEY_ACT_DESCRIPTION "description"
# define JSON_KEY_ACT_ACTIVE "active"

// ActionSet schema:
# define JSON_KEY_ACTSET_ACTIVE "active"
# define JSON_KEY_ACTSET_ACTIONS "actions"

/* ============================================= */


/proc/UtilityConsiderationFromData(var/list/json_data) // list -> ActionTemplate
	ASSERT(json_data)

	var/raw_inp_proc = json_data[JSON_KEY_CONSIDERATION_INPPROC]
	var/raw_curve_proc = json_data[JSON_KEY_CONSIDERATION_CURVEPROC]
	var/bookmark_low = json_data[JSON_KEY_CONSIDERATION_LOMARK]
	var/bookmark_high = json_data[JSON_KEY_CONSIDERATION_HIMARK]
	var/noise_scale = json_data[JSON_KEY_CONSIDERATION_NOISESCALE]
	var/name = json_data[JSON_KEY_CONSIDERATION_NAME]
	var/description = json_data[JSON_KEY_CONSIDERATION_DESC]
	var/active = json_data[JSON_KEY_CONSIDERATION_ACTIVE]
	var/list/consideration_args = json_data[JSON_KEY_CONSIDERATION_ARGS]

	// Yeah, I know, for data-driven stuff you just gotta bite your tongue and take it
	var/inp_proc = STR_TO_PROC(raw_inp_proc)
	var/curve_proc = STR_TO_PROC(raw_curve_proc)

	var/datum/consideration/new_consideration = new(
		input_val_proc=inp_proc,
		curve_proc=curve_proc,
		loMark=bookmark_low,
		hiMark=bookmark_high,
		noiseScale=noise_scale,
		id=null,
		name=name,
		description=description,
		active=active,
		consideration_args=consideration_args
	)

	return new_consideration


/proc/UtilityConsiderationArrayFromData(var/list/json_data) // list -> ActionTemplate
	ASSERT(json_data)

	var/list/considerations = list()
	var/idx = 0

	for(var/list/consideration_json_data in json_data)
		idx++
		var/datum/consideration/new_consideration = UtilityConsiderationFromData(consideration_json_data)

		if(isnull(new_consideration))
			//log
			UTILITYBRAIN_DEBUG_LOG("Failed to load Consideration at idx [idx]")
			continue

		# ifdef DEBUG_SERDE_LOADS
		UTILITYBRAIN_DEBUG_LOG("   ")
		UTILITYBRAIN_DEBUG_LOG("Loaded new Consideration: ")
		for(var/varkey in new_consideration.vars)
			UTILITYBRAIN_DEBUG_LOG("o [varkey] => [new_consideration.vars[varkey]]")
		# endif

		considerations.Add(new_consideration)

	return considerations


/proc/ActionTemplateFromData(var/list/json_data) // list -> ActionTemplate
	ASSERT(json_data)

	var/list/considerations_data = json_data[JSON_KEY_CONSIDERATIONS]

	var/raw_ctxproc = json_data[JSON_KEY_ACT_CTXPROC]
	var/context_proc = STR_TO_PROC(raw_ctxproc)

	var/context_args = json_data[JSON_KEY_ACT_CTXARGS]

	var/raw_handler = json_data[JSON_KEY_ACT_HANDLER]
	var/handler = STR_TO_PROC(raw_handler)

	var/priority = json_data[JSON_KEY_ACT_PRIORITY]
	var/charges = json_data[JSON_KEY_ACT_CHARGES]
	var/instant = json_data[JSON_KEY_ACT_ISINSTANT]
	var/act_name = json_data[JSON_KEY_ACT_NAME]
	var/act_description = json_data[JSON_KEY_ACT_DESCRIPTION]
	var/active = json_data[JSON_KEY_ACT_ACTIVE]

	var/list/considerations = UtilityConsiderationArrayFromData(considerations_data)

	var/datum/utility_action_template/new_action_template = new(
		considerations,
		handler,
		context_proc,
		context_args,
		priority,
		charges,
		instant,
		act_name,
		act_description,
		active
	)

	# ifdef DEBUG_SERDE_LOADS
	if(new_action_template)
		UTILITYBRAIN_DEBUG_LOG("Loaded new ActionTemplate: ")
		for(var/varkey in new_action_template.vars)
			UTILITYBRAIN_DEBUG_LOG("o [varkey] => [new_action_template.vars[varkey]]")
	# endif

	return new_action_template


/proc/ActionTemplateFromJsonFile(var/json_filepath) // str -> ActionTemplate
	ASSERT(json_filepath)

	var/list/json_data = READ_JSON_FILE(json_filepath)
	ASSERT(json_data)

	var/datum/utility_action_template/new_template = ActionTemplateFromData(json_data)
	return new_template



/proc/ActionSetFromData(var/list/json_data) // list -> ActionTemplate
	ASSERT(json_data)

	var/active = json_data[JSON_KEY_ACTSET_ACTIVE]
	var/list/action_data = json_data[JSON_KEY_ACTSET_ACTIONS]

	var/list/actions = list()

	for(var/action_definition in action_data)
		if(isnull(action_definition))
			continue

		var/datum/utility_action_template/new_action_template = ActionTemplateFromData(action_definition)
		if(isnull(new_action_template))
			continue

		# ifdef DEBUG_SERDE_LOADS
		UTILITYBRAIN_DEBUG_LOG("Loaded ActionSet item [new_action_template]")
		for(var/nav in new_action_template.vars)
			UTILITYBRAIN_DEBUG_LOG("[nav] => [new_action_template.vars[nav]]")
		# endif

		actions.Add(new_action_template)

	var/datum/action_set/new_actionset = new(actions, active)
	return new_actionset


/proc/ActionSetFromJsonFile(var/json_filepath) // str -> ActionTemplate
	ASSERT(json_filepath)

	var/list/json_data = READ_JSON_FILE(json_filepath)
	ASSERT(json_data)

	var/datum/action_set/new_actionset = ActionSetFromData(json_data)
	return new_actionset
