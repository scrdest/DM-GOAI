/datum/brain
	/* Cleanup stuff */
	var/registry_index // our index in the Big Brain List

	// If positive, number of ticks before we deregister & delete ourselves.
	var/cleanup_detached_threshold = DEFAULT_ORPHAN_CLEANUP_THRESHOLD

	// Tracker for the cleanup
	var/_ticks_since_detached = 0


/* Stubs. Should implement properly in the subclasses! */
/datum/brain/proc/ShouldCleanup()
	return FALSE


/datum/brain/proc/CheckForCleanup()
	return FALSE

