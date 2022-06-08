/datum/memory
	var/val

	var/created_time = 0
	var/updated_time = 0
	var/ttl = PLUS_INF


/datum/memory/New(var/new_val, var/new_ttl = null)
	val = new_val
	ttl = (isnull(new_ttl) ? ttl : new_ttl)

	var/right_now = world.time
	created_time = right_now
	updated_time = right_now


/datum/memory/proc/GetAge()
	/* Retrieves the age of the memory in ds since creation-time */
	var/right_now = world.time
	var/deltaT = right_now - created_time
	return deltaT


/datum/memory/proc/GetFreshness()
	/* Like GetAge(), except considers Last Update-time, not Creation-time. */
	var/right_now = world.time
	var/deltaT = right_now - updated_time
	return deltaT


/datum/memory/proc/Update(var/new_val)
	var/right_now = world.time
	val = new_val
	updated_time = right_now
	return src
