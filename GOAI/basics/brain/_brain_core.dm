/* This is the minimal Brain datum interface.
//
// Think of this as a template for writing an actual Brain class.
// If you're looking for an implementation, look for `/datum/brain/concrete`
// in: ./concrete_brains/_concrete.dm
*/


/datum/brain
	var/name = "brain"
	var/life = 1

	/* Optional 'parent' brain ref.
	//
	// Can be used to simulate literal hiveminds, but also
	// various lower-granularity planners, e.g. squads or
	// organisations or a mob's 'strategic' planner that
	// informs the 'tactical'/'operational' planners' goals.
	//
	// IMPORTANT: this hierarchy should form a (Directed) Acyclic Graph!
	*/
	var/datum/brain/hivemind

	/* Dict containing sensory data indexed by sense key. */
	var/dict/perceptions

	/* Bookkeeping for update times */
	var/list/last_need_update_times
	var/last_pawn_update_time
	var/last_action_update_time

	/* Dynamically attached junk */
	var/dict/attachments




/datum/brain/proc/Life()
	/* Something like the commented-out block below *SHOULD* be here as it's a base class
	// but since this runs an infinite ticker loop, I didn't want to waste CPU cycles running
	// procs that just do a 'return' forever. May get restored later at some point if having
	// a solid ABC outweighs the risks.

	while(life)
		LifeTick()
		sleep(AI_TICK_DELAY)
	*/
	return


/datum/brain/proc/LifeTick()
	return


/datum/brain/proc/CleanDelete()
	src.life = FALSE
	qdel(src)
	return TRUE


/datum/brain/proc/GetAiController()
	FetchAiControllerForObjIntoVar(src, var/datum/commander)
	return commander
