# define PLANNER_CACHE_SIZE 5

var/global/list/planner_cache = null
var/global/list/planner_owners = null


/proc/GetGoapResource(var/requester_ref)
	if(isnull(global.planner_cache))
		// Lazy-init of cache lists
		var/new_cache_list[PLANNER_CACHE_SIZE]
		var/new_owner_list[PLANNER_CACHE_SIZE]
		global.planner_cache = new_cache_list
		global.planner_owners = new_owner_list

	var/datum/GOAP/demoGoap/planner = null
	var/free_idx = null
	var/curr_idx = 1

	for(var/owner_ref in global.planner_owners)
		// find the first currently unowned item
		if(isnull(owner_ref))
			free_idx = curr_idx
			break

		curr_idx++

	if(free_idx)
		global.planner_owners[free_idx] = requester_ref  // take ownership

		// fetch the planner from the other list...
		planner = global.planner_cache[free_idx]
		if(isnull(planner))
			// ...or create if uninitialized
			planner = new(null)

		// this should already match, but let's set it to be safe
		planner.cache_id = free_idx

	return planner


/proc/FreeGoapResource(var/datum/GOAP/freed_goap, var/owner_ref)
	ASSERT(!isnull(freed_goap))
	ASSERT(!isnull(global.planner_cache))

	var/cache_id = freed_goap.cache_id

	ASSERT(cache_id <= global.planner_cache.len)
	ASSERT(cache_id <= global.planner_owners.len)
	ASSERT(owner_ref == global.planner_owners[cache_id])

	global.planner_owners[cache_id] = null // remove ownership
	global.planner_cache[cache_id] = freed_goap // again, to be safe
	return
