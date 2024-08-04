/*
// A lot of power and flexibility of GOAI APIs lies in using a sprinkle of the ECS architecture,
// where instead of storing values in a class itself, we store them in a global table of some kind
// and attach only a small ID in the class proper to serve as a key for looking up that table.
//
// This module extends BYOND's native classes with a single shared attribute that serves as that ID
// as well as a unified API for setting that.
//
// This allows all global tables to reuse this ID as their key.
*/

/datum
	var/global_id = null


/datum/proc/InitializeGlobalId(var/list/args = null)
	/* Subclass hook in case the ID has to be dynamically generated */
	var/default_id = ref(src)
	src.global_id = default_id
	return default_id
