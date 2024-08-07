/*
// Alternative trading procs with mocked out steps to test the logic
*/

#warn DEBUG MODULE INCLUDED!


/datum/utility_ai/proc/DebugFulfilContractInstant(var/datum/ActionTracker/tracker, var/input)
	/*
	// Debug variant of fulfillment logic.
	// Will instantly set the contract to its resolved state.
	*/
	if(isnull(tracker))
		return

	if(tracker.IsStopped())
		return

	var/datum/trade_contract/contract = input

	if(!istype(contract))
		to_world_log("FulfilContract ([src]): Invalid offer type for contract object [NULL_TO_TEXT(contract)]!")
		tracker.SetFailed()
		return

	var/ai_pawn = src.GetPawn()  // usually a faction, though COULD be a mob too

	if(isnull(ai_pawn))
		to_world_log("FulfilContract ([src]): Does not have a pawn ([NULL_TO_TEXT(ai_pawn)]).")
		tracker.SetFailed()
		return

	/*
	var/creator_is_seller = contract.commodity_amount > 0
	var/creator_is_payer = contract.cash_value < 0

	var/datum/goods_sender = (creator_is_seller ? contract.receiver : contract.creator)
	var/datum/money_sender = (creator_is_payer ? contract.creator : contract.receiver)

	contract.EscrowPut(goods_sender, contract.commodity_key, abs(contract.commodity_amount))
	contract.EscrowPut(money_sender, contract.commodity_key, abs(contract.cash_value))

	contract.Signoff(contract.creator)
	contract.Signoff(contract.receiver)
	*/

	// We'll directly set everything up for success here
	contract.escrow[contract.commodity_key] = abs(contract.commodity_amount)
	contract.escrow[NEED_WEALTH] = abs(contract.cash_value)
	contract.lifecycle_state = GOAI_CONTRACT_LIFECYCLE_FULFILLED

	var/completed = contract.Complete()

	# warn TODO, debug logs for contract fulfillment
	if(completed)
		tracker.SetDone()
		to_world_log("FULFILLED a contract for [contract.commodity_key] * [contract.commodity_amount]u @ [contract.cash_value]$")
	else
		tracker.SetFailed()
		to_world_log("FAILED a contract for [contract.commodity_key] * [contract.commodity_amount]u @ [contract.cash_value]$")

	return


