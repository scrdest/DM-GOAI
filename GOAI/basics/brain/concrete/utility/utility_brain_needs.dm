/datum/brain/utility/GetNeed(var/key, var/default = null)
	// This part is copypasta'd from the parent; we could dedupe it,
	// but it saves us a proc-call in the early exit cases.

	if(isnull(src.needs))
		return default

	var/found = (key in src.needs)

	if(!found)
		return default

	// This is the new bit
	if(key == NEED_WEALTH)
		var/datum/utility_ai/commander = src.GetAiController()

		if(!istype(commander))
			return default

		return commander.GetWealthNeedFromAssets()

	var/result = ..(key, default)
	return result


/datum/brain/utility/SetNeed(var/key, var/val)
	if(isnull(key))
		return

	// Clamp needs to range
	var/fixed_value = isnull(val) ? null : clamp(val, NEED_MINIMUM, NEED_MAXIMUM)

	// Parent logic handles the rest
	. = ..(key, fixed_value)

	// Extra bookkeeping on top
	#ifdef BRAIN_MODULE_INCLUDED_METRICS

	if(isnull(src.last_need_update_times))
		src.last_need_update_times = list()

	src.last_need_update_times[key] = world.time

	#endif
	MOTIVES_DEBUG_LOG("Curr [key] = [needs[key]] | <@[src]>")

	return .
