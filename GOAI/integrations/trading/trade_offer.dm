/datum/trade_offer
	// A one-off *offer* to exchange resources/services between two parties at fixed prices.
	// This is approximately a generalized commodity option/forward contract
	// (which exactly depends on whether it can be discarded once bound or not).
	// DO NOT confuse this with a trade_contract. A Contract is a 'bound' Offer.

	// Whether the offer is standing, independent of the expiry time.
	// Primarily meant for invalidating already bound offers.
	var/is_open = TRUE

	// So that we can put these into a hugh jass array and assign the index from the array here for tracking.
	var/id = null

	// Who is offering
	var/creator = null

	// Who is receiving the offer - optional, null means open to all
	var/receiver = null

	// String key of what we're trading
	var/commodity_key

	// Positive amount A implies receiver buying A units from creator
	// Negative amount A implies receiver selling A units to creator
	var/commodity_amount = 0

	// Positive price P implies receiver transferring P credits to creator
	// Negative price P implies receiver will receive P credits from creator
	var/cash_value = 0

	// The keys in both assocs should match. Null values shall be assumed to be zero.

	// Note that prices and amounts' signs are independent.
	// +A & +P is a regular buy
	// -A & -P is a regular sell
	// +A & -P is a disposal contract to receiver (take our trash and we'll pay you)
	// -A & +P is a disposal contract to creator (we'll take your trash, for a price)

	// When does the offer go away. Can be null for always valid.
	var/expiry_time = null

	// If bound as a contract, when will that contract expire.
	// This is distinct from the *offer* expiring - this represents by when the services shall be rendered.
	// Can be null for always valid.
	var/deadline = null


/datum/trade_offer/proc/Create(var/source, var/commodity_key, var/commodity_amt, var/cash_amt, var/expires_at = null, var/target = null)
	// Should possibly clean the ID/array here, but don't have a Big Ole Array for these yet.
	src.is_open = TRUE
	src.creator = source
	src.commodity_key = commodity_key
	src.commodity_amount = commodity_amt
	src.cash_value = cash_amt
	src.receiver = target

	if(!isnull(expires_at))
		src.expiry_time = expires_at

	return


/datum/trade_offer/New(var/source, var/commodity_key, var/commodity_amt, var/cash_amt, var/expires_at = null, var/target = null)
	// We'll shunt the init to a custom proc so we can object-pool and reuse these.
	..()
	src.Create(source, commodity_key, commodity_amt, cash_amt, expires_at, target)
	return


/datum/trade_contract
	/*
	// This is very nearly a copypasta of trade_offer. This is entirely on purpose.
	// A contract is a 'materialized' offer, so the parameters will be heavily aligned.
	// ...and if they ain't, we can add and remove values from this at will!
	*/

	// Whether the offer is standing, independent of the expiry time.
	// Primarily meant for invalidating fulfilled contracts.
	var/is_open = TRUE

	// A bitflag tracking the current state of the trade.
	// Use GOAI_CONTRACT_IS_COMPLETED(src.lifecycle_state) to check if the deal can be considered fulfilled.
	var/lifecycle_state = GOAI_CONTRACT_LIFECYCLE_INITIAL

	// So that we can put these into a hugh jass array and assign the index from the array here for tracking.
	var/id = null

	// Who is offering
	var/creator = null

	// Who is receiving the offer
	var/receiver = null

	// String key of what we're trading
	var/commodity_key

	// Positive amount A implies receiver buying A units from creator
	// Negative amount A implies receiver selling A units to creator
	var/commodity_amount = 0

	// Positive price P implies receiver transferring P credits to creator
	// Negative price P implies receiver will receive P credits from creator
	var/cash_value = 0

	// The keys in both assocs should match. Null values shall be assumed to be zero.

	// Note that prices and amounts' signs are independent.
	// +A & +P is a regular buy
	// -A & -P is a regular sell
	// +A & -P is a disposal contract to holder (take our trash and we'll pay you)
	// -A & +P is a disposal contract to creator (we'll take your trash, for a price)

	// Deadline for fulfillment. Can be null for no limit for options.
	var/deadline = null


/datum/trade_contract/proc/Create(var/source, var/receiver, var/commodity_key, var/commodity_amt, var/cash_amt, var/contract_deadline = null)
	src.is_open = TRUE
	src.creator = source
	src.commodity_key = commodity_key
	src.commodity_amount = commodity_amt
	src.cash_value = cash_amt

	if(!isnull(contract_deadline))
		src.deadline = contract_deadline

	return


/datum/trade_contract/New(var/source, var/receiver, var/commodity_key, var/commodity_amt, var/cash_amt, var/contract_deadline = null)
	// We'll shunt the init to a custom proc so we can object-pool and reuse these.
	src.Create(source, receiver, commodity_key, commodity_amt, cash_amt, contract_deadline)
	return


/*
// $$$  Offer => Contract  $$$
*/
/datum/trade_offer/proc/ToContract(var/claimed_by = null) // () -> trade_contract datum
	/*
	// Binds the offer to a contract. This represents both sides accepting the deal.
	*/

	// Do not reuse the offer object until it's properly reinited as a new offer.
	src.is_open = FALSE

	// If claimed_by is set, use it. Otherwise use receiver.
	// GENERALLY non-receivers shouldn't see the offer to claim it.
	// A possible exception is something like a Faction AI claiming on behalf of its Faction etc.
	var/target = (isnull(claimed_by) ? src.receiver : claimed_by)

	// Currently just alloc a new object; may object-pool in the future.
	var/datum/trade_contract/as_contract = new(src.creator, target, src.commodity_key, src.commodity_amount, src.cash_value, src.deadline)

	return as_contract


/*
// $$$  Contract => Fulfilment (or not)  $$$
*/


/datum/trade_contract/proc/Signoff(var/signoff_party)
	/*
	// Represents a party in the trade signing off on its fulfilment.
	// The user must pass an entity as the argument that should match either the creator or the receiver of the offer.
	// This functions like providing that side's "signature" and allows switching the appropriate flag.
	// The contracts require the signoff from both sides to be considered successfully closed.
	*/

	if(isnull(signoff_party))
		to_world_log("TradeContract [src] received a call to Signoff() with a null signoff_party. This is not critical, but generally should not happen.")
		return src

	if((signoff_party == src.creator) && (src.lifecycle_state & GOAI_CONTRACT_LIFECYCLE_AWAITING_SIGNOFF_CREATOR))
		src.lifecycle_state ^= GOAI_CONTRACT_LIFECYCLE_AWAITING_SIGNOFF_CREATOR
		return src

	if((signoff_party == src.receiver) && (src.lifecycle_state & GOAI_CONTRACT_LIFECYCLE_AWAITING_SIGNOFF_CONTRACTOR))
		src.lifecycle_state ^= GOAI_CONTRACT_LIFECYCLE_AWAITING_SIGNOFF_CONTRACTOR
		return src

	return null


/datum/trade_contract/proc/Complete()
	/*
	// Job's done.
	*/

	// Verify signoff, refuse to complete if there's anything unsettled left.
	if(!GOAI_CONTRACT_IS_COMPLETED(src.lifecycle_state))
		return FALSE

	// Mark the contract as closed.
	src.is_open = FALSE

	return TRUE


/datum/trade_contract/proc/Expire()
	/*
	// Failed-to-deliver, fission mailed.
	*/

	// If somehow we forgot to mark the contract as completed
	// but it is in a success state as of expiry, just complete it now.
	if(GOAI_CONTRACT_IS_COMPLETED(src.lifecycle_state))
		return src.Complete()

	//
	if(GOAI_CONTRACT_IS_PROGRESSED(src.lifecycle_state))
		return

	// Mark the contract as closed.
	src.is_open = FALSE

	return TRUE

