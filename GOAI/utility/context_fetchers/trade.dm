
CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_get_market_trade_offers)
	// Returns a context for each of the (valid) trade offers posted.

	/*
	if(isnull(context_args))
		UTILITYBRAIN_DEBUG_LOG("ERROR: context_args for ctxfetcher_get_market_trade_offers is null @ L[__LINE__] in [__FILE__]!")
		return
	*/

	var/list/contexts = list()

	if(!(GOAI_LIBBED_GLOB_ATTR(global_marketplace)))
		return contexts

	CONTEXT_GET_OUTPUT_KEY(var/context_key)
	var/now = world.time

	var/requester_pawn = null

	var/datum/utility_ai/requester_ai = requester

	if(istype(requester_ai))
		requester_pawn = requester_ai.GetPawn()

	for(var/offer_key in GOAI_LIBBED_GLOB_ATTR(global_marketplace))
		var/datum/trade_offer/offer = (GOAI_LIBBED_GLOB_ATTR(global_marketplace))[offer_key]

		#warn debug logging
		if(!istype(offer))
			// Exclude null/junk offers
			to_world_log("ctxfetcher_get_market_trade_offers: Rejecting [offer_key] - junk")
			continue

		if(!(isnull(offer.expiry_time) || (offer.expiry_time > now)))
			// Exclude expired offers
			to_world_log("ctxfetcher_get_market_trade_offers: Rejecting [offer_key] - expired")
			continue

		if(!(isnull(offer.receiver) || (offer.receiver == requester_pawn)))
			// Exclude offers that are specifically directed at someone else.
			to_world_log("ctxfetcher_get_market_trade_offers: Rejecting [offer_key] - directed at someone else")
			continue

		if(!isnull(requester_pawn) && (offer.creator == requester_pawn))
			// Exclude our own offers; this should be handled by another CF.
			to_world_log("ctxfetcher_get_market_trade_offers: Rejecting [offer_key] - we created this")
			continue

		var/list/ctx = list()
		ctx[context_key] = offer
		contexts[++(contexts.len)] = ctx

	return contexts
