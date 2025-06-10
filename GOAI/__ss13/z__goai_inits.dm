
# ifdef GOAI_LIBRARY_FEATURES
// Initialization stuff to backfill for proper SS13 controllers

/proc/GoaiInitializer()
	//set waitfor = FALSE

	if(!GLOB)
		GLOB = new()

	sleep(0)
	return


/world/New()
	. = ..()
	GoaiInitializer()
	return

#endif
