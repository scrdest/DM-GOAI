/datum/brain
	/* Needs.
	//
	// Key-value map where the keys are strings representing the Need ID
	// and the values represent the level of satisfaction of each Need.
	//
	// Needs can be initialized based on a JSON-serialized data file which
	// specifies the levels of all initial Needs.
	*/
	var/list/needs = null
	var/initial_needs_fp = null


/datum/brain/proc/InitNeeds()
	var/list/needfile_data = null
	var/list/file_needs = null

	if(src.initial_needs_fp)
		needfile_data = READ_JSON_FILE(src.initial_needs_fp)

	if(needfile_data)
		// Keep the need values in a separate key - might need to chuck in other data
		// like the need weights or randomness factors or whatever, so we need to keep
		// the top-level namespace tidy.
		file_needs = needfile_data["needs"]

	src.needs = DEFAULT_IF_NULL(file_needs, list())
	return needs


/datum/brain/proc/GetNeed(var/key, var/default = null)
	if(isnull(src.needs))
		return default

	var/found = (key in src.needs)
	var/result = (found ? src.needs[key] : default)
	return result


/datum/brain/proc/SetNeed(var/key, var/val)
	if(isnull(needs))
		src.needs = new()

	src.needs[key] = val
	return TRUE