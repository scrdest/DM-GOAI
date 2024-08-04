/*
// This module provides procs for resolving a Contract success state
// in an abstract fashion (i.e. we ignore the actual physical items and
// just update the abstract resources they correspond to).
*/

/proc/trade_apply_instant_abstract_success(var/datum/trade_contract/contract)
	/* Simple callback meant as a default, resolves the trade instantly */
	set waitfor = FALSE

	to_world_log("INFO: RUNNING trade_apply_instant_abstract_success() @ [__LINE__] in [__FILE__]")
	ASSETS_TABLE_LAZY_INIT(TRUE)
	sleep(0)

	if(!istype(contract))
		to_world_log("ERROR: trade_apply_instant_success() received an invalid input type [contract] ([NULL_TO_TEXT(contract?.type)]) @ [__LINE__] in [__FILE__]")
		return

	if(!contract.escrow)
		// Nothing to do here, return early.
		// The Complete() proc should ensure this doesn't get here
		// if the Contract has any unfulfilled terms, so should be rare.
		return

	/* Currently both parties MUST be at least datums to support maintaining global IDs into the assets table */
	// Cast and validate this for the Contract creator...
	var/datum/my_creator = contract.creator

	if(!istype(my_creator))
		to_world_log("ERROR: trade_apply_instant_abstract_success contract creator ([NULL_TO_TEXT(my_creator)]) is not a datum @ L[__LINE__] in [__FILE__]")
		return

	if(isnull(my_creator.global_id))
		to_world_log("WARNING: trade_apply_instant_abstract_success contract creator ([NULL_TO_TEXT(my_creator)]) has no global ID - attempting to initialize @ L[__LINE__] in [__FILE__]")
		my_creator.InitializeGlobalId()

	if(isnull(my_creator.global_id))
		to_world_log("ERROR: trade_apply_instant_abstract_success contract creator ([NULL_TO_TEXT(my_creator)]) has no global ID @ L[__LINE__] in [__FILE__]")
		return

	var/creator_has_account = HAS_REGISTERED_ASSETS(my_creator.global_id)
	if(!creator_has_account)
		CREATE_ASSETS_TRACKER(my_creator.global_id)

	// ...and now the same for the Contract receiver
	var/datum/my_receiver = contract.receiver

	if(!istype(my_receiver))
		to_world_log("ERROR: trade_apply_instant_abstract_success contract receiver ([NULL_TO_TEXT(my_receiver)]) is not a datum @ L[__LINE__] in [__FILE__]")
		return

	if(isnull(my_receiver.global_id))
		to_world_log("WARNING: trade_apply_instant_abstract_success contract receiver ([NULL_TO_TEXT(my_receiver)]) has no global ID - attempting to initialize @ L[__LINE__] in [__FILE__]")
		my_receiver.InitializeGlobalId()

	if(isnull(my_receiver.global_id))
		to_world_log("ERROR: trade_apply_instant_abstract_success contract receiver ([NULL_TO_TEXT(my_receiver)]) has no global ID @ L[__LINE__] in [__FILE__]")
		return

	var/receiver_has_account = HAS_REGISTERED_ASSETS(my_receiver.global_id)
	if(!receiver_has_account)
		CREATE_ASSETS_TRACKER(my_receiver.global_id)

	// Allocate the assets table if it's uninitialized
	ASSETS_TABLE_LAZY_INIT(TRUE)

	// Figuring out what kind of good goes to whom
	var/creator_is_seller = contract.commodity_amount > 0
	var/creator_is_payer = contract.cash_value < 0

	var/datum/goods_receiver = (creator_is_seller ? my_creator : my_receiver)
	var/datum/money_receiver = (creator_is_payer ? my_creator : my_receiver)

	// Iterate through the assoc; route goods to buyer, money to seller
	for(var/escrow_key in contract.escrow)
		// Iteration through an assoc gives us a key, grab the value by a lookup
		// (effectively doing a Python dict.items()-style iterator)
		var/escrow_val = contract.escrow[escrow_key]

		if(!escrow_val)
			// not worth the hassle if the value is zero, and null means something went wrong
			continue

		//var/datum/curr_sender = null
		var/datum/curr_recipient = null

		if(escrow_key == NEED_WEALTH)
			//curr_sender = money_sender
			curr_recipient = money_receiver

		else
			//curr_sender = goods_sender
			curr_recipient = goods_receiver

		if(isnull(curr_recipient))
			to_world_log("ERROR: trade_apply_instant_abstract_success current receiver ([NULL_TO_TEXT(curr_recipient)]) is null @ L[__LINE__] in [__FILE__]")
			continue

		var/list/receiver_assets = GET_ASSETS_TRACKER(curr_recipient.global_id)

		if(!istype(receiver_assets))
			// If null/corrupted, overwrite with a clean list
			receiver_assets = list()

		var/transferred_amt = abs(escrow_val)
		var/new_receiver_asset_amt = (receiver_assets[escrow_key] || 0) + transferred_amt
		receiver_assets[escrow_key] = new_receiver_asset_amt
		UPDATE_ASSETS_TRACKER(curr_recipient.global_id, receiver_assets)

		// The only logic needed here is just us handling each Receiver.
		// The Sender should just put things into escrow and decrement their account themselves in the process
		// during the contract's earlier lifecycle.

		// Drop the value from the key to avoid duplication
		// We could null it, but this way we should be able to spot errors more easily
		// If there's anything nonzero left, we hadn't cleaned this up properly.
		contract.escrow[escrow_key] = escrow_val - transferred_amt

	// All done!
	contract.is_open = FALSE
	to_world_log("INFO: FINISHED trade_apply_instant_abstract_success() @ L[__LINE__] in [__FILE__]")
	return
