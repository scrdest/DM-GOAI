/*
// Diplomancy - make a target faction friendlier to us. Somehow.
*/

/datum/utility_ai/proc/ImproveRelations(var/datum/ActionTracker/tracker, var/datum/utility_ai/buddyfriendo)
	if(isnull(tracker))
		RUN_ACTION_DEBUG_LOG("Tracker position is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(isnull(buddyfriendo))
		RUN_ACTION_DEBUG_LOG("buddyfriendo is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		return

	if(tracker.IsStopped())
		return

	if(isnull(buddyfriendo.brain))
		RUN_ACTION_DEBUG_LOG("Target brain is null | <@[src]> | [__FILE__] -> L[__LINE__]")
		tracker.SetFailed()
		return

	if(isnull(src.brain.relations))
		src.brain.relations = new()

	if(isnull(buddyfriendo.brain.relations))
		buddyfriendo.brain.relations = new()

	if(prob(75))
		var/their_tag = src.name
		var/their_amount = (rand(2, 10) / 2)

		var/our_tag = buddyfriendo.name
		var/our_amount = their_amount + (rand(-2, 2) / 4)

		buddyfriendo.brain.relations.Increase(their_tag, their_amount)
		src.brain.relations.Increase(our_tag, our_amount)
	tracker.SetDone()
	return
