
CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_get_need_perc)
	var/datum/brain/requesting_brain = _cihelper_get_requester_brain(requester, "consideration_input_get_need_perc")

	if(!istype(requesting_brain))
		DEBUGLOG_MEMORY_FETCH("consideration_input_get_need_perc Brain is null ([requesting_brain || "null"]) @ L[__LINE__] in [__FILE__]")
		return FALSE

	var/input_key = CONSIDERATION_INPUTKEY_DEFAULT

	if(!isnull(consideration_args))
		input_key = consideration_args[CONSIDERATION_INPUTKEY_KEY] || input_key

	if(isnull(input_key))
		DEBUGLOG_MEMORY_FETCH("consideration_input_get_need_perc Input Key is null ([input_key || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/default = null

	if(!isnull(consideration_args))
		default = consideration_args["default"]

	if(isnull(default))
		default = NEED_MAXIMUM

	var/value = requesting_brain.GetNeedAmountCurrent(input_key, null)
	if(isnull(value))
		return default

	// normalise to 0-1
	// technically we should do x/(MAX-MIN), but we can assume MIN is always 0
	// and MAX is just scaling the increments
	var/result = (value / NEED_MAXIMUM)

	return result


CONSIDERATION_CALL_SIGNATURE(/proc/consideration_input_get_lowest_need_perc)
	var/datum/brain/requesting_brain = _cihelper_get_requester_brain(requester, "consideration_input_get_lowest_need_perc")

	if(!istype(requesting_brain))
		DEBUGLOG_MEMORY_FETCH("consideration_input_get_need_perc Brain is null ([requesting_brain || "null"]) @ L[__LINE__] in [__FILE__]")
		return FALSE

	var/input_key = CONSIDERATION_INPUTKEY_DEFAULT

	if(!isnull(consideration_args))
		input_key = consideration_args[CONSIDERATION_INPUTKEY_KEY] || input_key

	if(isnull(input_key))
		DEBUGLOG_MEMORY_FETCH("consideration_input_get_need_perc Input Key is null ([input_key || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/default = null

	if(!isnull(consideration_args))
		default = consideration_args["default"]

	if(isnull(default))
		default = NEED_MAXIMUM

	var/list/needs_by_weight = requesting_brain.GetNeedWeights() || list()

	var/lowest_need = null
	var/lowest_value = null

	for(var/need_key in needs_by_weight)
		var/need_weight = needs_by_weight[need_key]

		if(!need_weight)
			// ignore unimportant needs
			continue

		var/need_value = requesting_brain.GetNeedAmountCurrent(input_key, null)

		if(isnull(need_value))
			continue

		if(isnull(lowest_value) || (need_value < lowest_value))
			lowest_value = need_value
			lowest_need = need_key

	if(isnull(lowest_need))
		return default

	// normalise to 0-1
	// technically we should do x/(MAX-MIN), but we can assume MIN is always 0
	// and MAX is just scaling the increments
	var/result = (lowest_value / NEED_MAXIMUM)

	return result
