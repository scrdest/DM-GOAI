/*
// Most if not all factions will trade resources with allies, neutrals, or even less-hated enemies.
*/

///datum/utility_ai/proc/CreateTradeOffer(var/datum/ActionTracker/tracker, var/datum/utility_ai/target)

/datum/utility_ai/proc/AcceptTradeOffer(var/datum/ActionTracker/tracker, var/commodity, var/trade_volume, var/cash_value)
	if(isnull(tracker))
		return

	# warn TODO, debug log
	to_world_log("ACCEPTED a deal for [commodity] * [trade_volume]u @ [cash_value]$")
	tracker.SetDone()
	return
