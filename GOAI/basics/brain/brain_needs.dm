#define BRAIN_MODULE_INCLUDED_NEEDS 1

#warn Restore null default for production
// #define DEFAULT_NEEDS_FP null
#define DEFAULT_NEEDS_FP GOAI_PERSONALITY_PATH("trade_faction.json")

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

	/* In addition to raw amounts, we store Need *weights*. Higher is higher priority.
	//
	// This helps the AI prioritize vital needs like Hunger over comfort needs like Fun.
	// A need with *NO* weight, OR a null weight, OR a weight of *zero* is effectively ignored.
	//
	// As such, the keys for Needs and WeightPerNeed lists should GENERALLY be equal.
	// However, you might want to use zero-weight Needs for some sneaky purpose, so it's not necessarily useless.
	*/
	var/list/need_weights = null

	// Data file to load all the above from.
	var/initial_needs_fp = null


/datum/brain/proc/InitNeeds()
	var/list/needfile_data = null
	var/list/file_needs = null
	var/list/file_need_weights = null

	if(src.initial_needs_fp)
		needfile_data = READ_JSON_FILE(src.initial_needs_fp)

	if(needfile_data)
		// Keep the need values in a separate key - might need to chuck in other data
		// like the need weights or randomness factors or whatever, so we need to keep
		// the top-level namespace tidy.
		file_needs = needfile_data["needs"]
		file_need_weights = needfile_data["need_weights"]

	src.needs = DEFAULT_IF_NULL(file_needs, list())
	src.need_weights = DEFAULT_IF_NULL(file_need_weights, list())
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


/datum/brain/proc/AddNeed(var/key, var/val)
	if(isnull(needs))
		src.needs = new()

	var/curr_val = src.needs[key]
	if(isnull(curr_val))
		return

	var/new_val = curr_val + val
	src.SetNeed(new_val)
	return new_val

/*
// NOTE: the declarations below are largely just interface declarations, not real implementations.
*/

/datum/brain/proc/GetNeedWeights() // () -> assoc[str, float]
	// returns an assoc of keys of all Needs this AI cares about to their weights
	return src.need_weights


/datum/brain/proc/GetNeedAmountCurrent(var/need, var/default = 0)
	// How much Need we've got.
	// This is NOT a simple lookup, because there might be some scaling etc. in here.
	return default


/datum/brain/proc/GetNeedDesirability(var/need, var/amount)
	// How happy we are with the amount of Need we've got, 0 to 1 float.
	// This is NOT a simple lookup, because there might be some scaling or nonlinearities.
	return 0


/datum/brain/proc/GetNeedDeltaUtility(var/need, var/amt_pre, var/amt_post)
	// How happy we would be with a change in the Need level from Pre to Post.
	return null
