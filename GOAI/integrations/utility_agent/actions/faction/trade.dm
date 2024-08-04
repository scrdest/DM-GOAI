/*
// Most if not all factions will trade resources with allies, neutrals, or even less-hated enemies.
*/

// Magic expression for randomizing how much Need we want to get from a deal
// Macro'd just to avoid maintaining the same expression in multiple places.
#define RANDOMIZED_NEED_DELTA (rand(4, 12) * (NEED_MAXIMUM / 40))

// Magic expression for randomizing how much we want to *profit* from a deal
// Macro'd just to avoid maintaining the same expression in multiple places.
#define RANDOMIZED_PROFITABILITY_FACTOR (rand(NEED_MAXIMUM / 100, NEED_MAXIMUM / 20) / NEED_MAXIMUM)


/datum/utility_ai/proc/AcceptTradeOffer(var/datum/ActionTracker/tracker, var/input)
	if(isnull(tracker))
		return

	var/datum/trade_offer/offer = input

	if(!istype(offer))
		to_world_log("AcceptTradeOffer ([src]): Invalid offer type for offer object [NULL_TO_TEXT(offer)]!")
		tracker.SetFailed()
		return

	var/ai_pawn = src.GetPawn()  // usually a faction, though COULD be a mob too

	if(isnull(ai_pawn))
		to_world_log("AcceptTradeOffer ([src]): Does not have a pawn ([NULL_TO_TEXT(ai_pawn)]).")
		tracker.SetFailed()
		return

	var/datum/trade_contract/contract = offer.ToContract(ai_pawn)
	GOAI_BRAIN_ADD_CONTRACT(src.brain, contract)

	# warn TODO, debug log
	to_world_log("ACCEPTED a deal for [offer.commodity_key] * [offer.commodity_amount]u @ [offer.cash_value]$")

	tracker.SetDone()
	return


/datum/utility_ai/proc/CreateSellOfferForNeed(var/datum/ActionTracker/tracker, var/input)
	if(isnull(tracker))
		return

	var/need_key = input
	if(!need_key)
		return

	var/datum/brain/ai_brain = src.brain

	if(!istype(ai_brain))
		to_world_log("CreateSellOfferForNeed: object [ai_brain] is not a brain!")
		tracker.SetFailed()
		return

	// How high our 'sacrificed' need is rn
	var/curr_need = ai_brain.GetNeed(need_key, null)

	if(isnull(curr_need))
		to_world_log("CreateSellOfferForNeed: need_key [need_key] value is null!")
		tracker.SetFailed()
		return

	// How much money we got
	//var/curr_wealth = ai_brain.GetNeed(NEED_WEALTH, 0)

	// How much of our Need-satisfaction we're willing to sacrifice
	var/need_delta_total = -min(curr_need - 10, RANDOMIZED_NEED_DELTA)

	if(need_delta_total > 0)
		// Would put us in danger (or some code went rogue), abort!
		tracker.SetFailed()
		return

	var/commodity = src.GetBestSaleCommodityForNeed(need_key)

	if(isnull(commodity))
		to_world_log("ERROR: CreateSellOfferForNeed: [src.name] Commodity for [need_key] is null ([commodity])")
		return

	var/trade_amount = src.GetCommodityAmountForNeedDelta(commodity, need_delta_total)  // should usually return a negative value!

	// How much Utility we lose from the trade if we didn't get paid
	var/tradeoff_utility_loss = src.GetCommodityDesirability(commodity, trade_amount, 0)

	// How much profit we want to take on top of a Utility-fair trade
	var/profitability_factor = RANDOMIZED_PROFITABILITY_FACTOR

	// Just totalling the factors for auditability
	var/total_pricing_utility = tradeoff_utility_loss - profitability_factor

	// How much we want for this deal
	var/asking_price = src.GetMoneyForNeedUtility(total_pricing_utility)

	// How long do we want to keep this open
	// Generally, this should be lower if we are desperate (because we are offering deals that are quite bad for us).
	// This is const'd right now, but might have some randomness or w/e, plus we can audit it better in a variable.
	var/expiry_time = EXPIRY_TIME_SLOW

	// NOTE: The source on the contract will be the Pawn, so Faction datum for faction AIs or a mob for mob AIs.
	//       This separates concerns - other AIs only care about how much they like the mob/faction and don't have
	//         to know whether they are dealing with an NPC, a PC, or a completely abstract entity.
	var/source_entity = src.pawn

	var/datum/trade_offer/sell_offer = new(source_entity, commodity, trade_amount, asking_price, world.time + expiry_time)
	REGISTER_OFFER_TO_MARKETPLACE(sell_offer)
	GOAI_BRAIN_ADD_OFFER(ai_brain, sell_offer.id)

	tracker.SetDone()

	#warn Debug logs
	to_world_log("CreateSellOfferForNeed: [src.name] created new Sell offer for [commodity] @ [trade_amount]u | [asking_price]$")
	return sell_offer


/datum/utility_ai/proc/CreateBuyOfferForNeed(var/datum/ActionTracker/tracker, var/input)
	if(isnull(tracker))
		return

	var/need_key = input
	if(!need_key)
		return

	var/datum/brain/ai_brain = src.brain

	if(!istype(ai_brain))
		to_world_log("CreateBuyOfferForNeed: object [ai_brain] is not a brain!")
		tracker.SetFailed()
		return

	// How high our 'acquired' need is rn
	var/curr_need = ai_brain.GetNeed(need_key, null)

	if(isnull(curr_need))
		to_world_log("CreateBuyOfferForNeed: need_key [need_key] value is null!")
		tracker.SetFailed()
		return

	// How much of our Need-satisfaction we're trying to get
	var/need_delta_total = min(NEED_MAXIMUM - curr_need, RANDOMIZED_NEED_DELTA)

	if(need_delta_total < 0)
		// Would put us in danger (or some code went rogue), abort!
		tracker.SetFailed()
		return

	// This is a bit tricky.
	// We split our buys into a pair of equal-volume offers, 'Fast' and 'Slow'
	//
	// The Fast buy offer is a worse deal for us money-wise, but satisfies our urgent needs.
	// The Slow buy offer is a better deal, but less enticing to sellers.
	//
	// As such, the Fast buy has a short time-to-live - we don't want to float
	//   offers made in desperation if we are no longer desperate, and we expect
	//   the offer to either clear quickly or get withdrawn by us quickly.
	//
	// Conversely the Slow buy has a long TTL, because it's a trade we can stand by.
	//   Either we find someone distressed willing to take it immediately and get a good deal,
	//   or we can wait until someone does is happy with out terms later.
	//
	// This way, we ensure both our urgent needs are attended to, but also get good
	//   'stretch goal' deals out there to take advantage of distressed sellers.
	var/half_need_delta = need_delta_total / 2

	// How much money we got
	var/curr_wealth = max(0, ai_brain.GetNeed(NEED_WEALTH, 0))

	// How much profit we want to take on top of a Utility-fair trade
	var/profitability_factor = RANDOMIZED_PROFITABILITY_FACTOR

	// How much we offer for this deal
	var/bid_price_fast = min(curr_wealth, src.GetMoneyForNeedUtility(half_need_delta - profitability_factor, curr_wealth))

	if(bid_price_fast >= PLUS_INF)
		// Invalid deal
		tracker.SetFailed()
		return

	var/remaining_cash = curr_wealth

	if(bid_price_fast > curr_wealth)
		// clamp to money we actually HAVE
		bid_price_fast = curr_wealth

	remaining_cash = (curr_wealth - bid_price_fast)

	var/bid_price_slow = null

	if(remaining_cash > 0)
		bid_price_slow = min(remaining_cash, src.GetMoneyForNeedUtility(half_need_delta - profitability_factor, remaining_cash))

	// Find the best Thing we can buy to satisfy this need
	var/commodity = src.GetBestPurchaseCommodityForNeed(need_key)

	if(isnull(commodity))
		to_world_log("ERROR: CreateBuyOfferForNeed: [src.name] Commodity for [need_key] is null ([commodity])")
		return

	var/source_entity = src.pawn

	if(!isnull(bid_price_fast))
		// Find HOW MUCH of said Thing we ideally want to buy
		var/fast_trade_amount = src.GetCommodityAmountForNeedDelta(half_need_delta, curr_need)  // should usually return a positive value!
		var/expiry_time_fast = EXPIRY_TIME_FAST
		var/datum/trade_offer/buy_offer_fast = new(source_entity, commodity, fast_trade_amount, bid_price_fast, world.time + expiry_time_fast)
		REGISTER_OFFER_TO_MARKETPLACE(buy_offer_fast)
		GOAI_BRAIN_ADD_OFFER(ai_brain, buy_offer_fast.id)

	if(!isnull(bid_price_slow))
		// all the same steps, except assume the fast trade has been 'applied' and extend the timeout
		var/slow_trade_amount = src.GetCommodityAmountForNeedDelta(half_need_delta, curr_need + half_need_delta)  // should usually return a positive value!
		var/expiry_time_slow = EXPIRY_TIME_SLOW
		var/datum/trade_offer/buy_offer_slow = new(source_entity, commodity, slow_trade_amount, bid_price_slow, world.time + expiry_time_slow)
		REGISTER_OFFER_TO_MARKETPLACE(buy_offer_slow)
		GOAI_BRAIN_ADD_OFFER(ai_brain, buy_offer_slow.id)

	tracker.SetDone()

	#warn Debug logs
	to_world_log("CreateBuyOfferForNeed: [src.name] created new Buy [isnull(bid_price_slow) ? "offer" : "offers"] for [commodity]")
	return


/datum/utility_ai/proc/FulfilContract(var/datum/ActionTracker/tracker, var/input)
	/* ATTEMPTS to fulfil the terms of a Contract on our part.
	// If we are buying, send the cash; if we are selling, send the goods.
	// Depending on the deal type, pawn type, and any AI LOD logic, this might success instantly,
	// create abstract tracker data, or trigger low-level movement etc. to physically move objects.
	*/
	if(isnull(tracker))
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

	#warn Finish this - apply the effects, dispatch the execution to the pawn, track

	# warn TODO, debug log
	to_world_log("FULFILLED a contract for [contract.commodity_key] * [contract.commodity_amount]u @ [contract.cash_value]$")

	tracker.SetDone()
	return
