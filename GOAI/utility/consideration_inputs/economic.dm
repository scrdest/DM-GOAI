/*
// Considerations around trades and contracts.
//
// Note that this is not exhaustive; these are just logic that would be hard to express using a combination of 'pure' considerations.
//
// For example, Net Commodity Desirability is a *difference* between the Raw Commodity Desirability and the Raw Cash Desirability.
//
// On the other side, the raw desire for buying healing items can be expressed just by health CIs, which would not live here.
*/

CONSIDERATION_CALL_SIGNATURE(/proc/consideration_trade_desirability)
	// Returns a normalized (0 <-> 1 float) score representing how much we want to buy/sell a commodity IN ABSTRACT.
	// In other words, how much we would want to buy a product if we could get a fair price or better, guaranteed.
	//
	// This is determined by an interaction of two factors:
	// 1) how much we value having the goods (Commodity Preference Factor, CPF)
	// 2) how much we value having cash on hand (Money Preference Factor, MPF)
	//
	// For BUYING:
	// If we really need the goods (high CPF) and don't mind spending cash (low MPF), the desirability is high.
	// If we don't need them (low CPF), then it doesn't matter how much we want cash (any MPF), we won't buy.
	// If we both really need the goods AND need to be stingy (both high), the utility will be lower, but still reasonable;
	//    however, it will never be our top choice AND they will drop off much more sharply as CPF drops.
	//
	// For SELLING, these roles are simply reversed (MPF on sell-side acts like CPF on buy-side and likewise substitute CPF for MPF above for the seller)
	// So, we only sell when MPF is high and prefer to sell commodities we don't really need.

	var/datum/utility_action_template/candidate = action_template

	if(!istype(candidate))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_trade_desirability Candidate is not an ActionTemplate! @ L[__LINE__] in [__FILE__]")
		return null

	if(isnull(requester))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_trade_desirability - Requester must be provided for this Consideration! @ L[__LINE__] in [__FILE__]")
		return null

	var/datum/utility_ai/ai = requester

	if(!istype(ai))
		DEBUGLOG_UTILITY_INPUT_FETCHERS("consideration_trade_desirability - Requester must be an AI for this Consideration (found: [ai.type])! @ L[__LINE__] in [__FILE__]")
		return null

	var/datum/brain/economy_brain
	// populates the economy_brain with an actual brain; will log if it's not
	CIHELPER_GET_REQUESTER_BRAIN_INLINED(requester, economy_brain)

	var/from_ctx = consideration_args?["from_context"]
	if(isnull(from_ctx))
		from_ctx = TRUE

	var/datasource = from_ctx ? context : consideration_args

	var/commodity = datasource["commodity"]
	var/cash_value = datasource["cash_value"] || 0
	var/raw_volume = datasource["trade_volume"] || 0
	#warn remove debug prints
	to_world_log("RQ [requester] consideration_trade_desirability received trade_data: [cash_value]$ for [commodity] @ [raw_volume]")

	// Supply-side reverses the preferences in the formula. Default to demand-side.
	var/is_sell = raw_volume < 0

	if(isnull(is_sell))
		is_sell = FALSE

	var/commodity_preference = economy_brain.GetCommodityDesirability(commodity, raw_volume)

	if(isnull(commodity_preference))
		// Either a need went negative, or the proc straight up crashed somewhere.
		// In both cases, do not pass go, do not collect 200 trades.
		return 0

	# warn money_preference logic does not account for amounts right now
	var/money_preference = economy_brain.GetMoneyDesirability(cash_value) || 0

	// the general shape of formula is: (2 * Acquired) / (1 + Acquired + Traded)
	// the additive smoothing in the denominator ensures we're always normalized
	// the multiplier in the numerator ensures desirability maxes out at Acquired=1 + Traded=0
	//     (because it's definitely a deal we NEED to make)
	// if Acq/Tra are both 1, we are considering an 'emergency' trade with Desirability at 66% (modulo other Considerations)

	var/numerator = is_sell ? (2 * money_preference) : (2 * commodity_preference)
	var/denominator = (1 + commodity_preference + money_preference)

	var/desirability = numerator / denominator

	#warn debug logs
	to_world_log("money_preference [money_preference] | commodity_preference [commodity_preference] | numerator [numerator] / denominator [denominator] == [desirability]")
	return desirability

#warn TODO TEST THE CONSIDERATION

/mob/verb/TestTradeFoodBuy()
	var/raw_faction_ai = pick(GOAI_LIBBED_GLOB_ATTR(global_faction_ai_registry))
	var/datum/utility_ai/faction_ai = raw_faction_ai

	if(!istype(faction_ai))
		to_chat(usr, "[raw_faction_ai] is not an AI somehow")
		return

	var/datum/brain/faction_brain = faction_ai.brain

	var/trade_data = list("commodity" = "/obj/food", "trade_volume" = 1, "cash_value" = 1000)

	faction_brain.SetMemory("testTrade", trade_data)

	to_chat(usr, "[raw_faction_ai] got a new trade offer: [json_encode(trade_data)]")
	return


/mob/verb/TestTradeFoodSell()
	var/raw_faction_ai = pick(GOAI_LIBBED_GLOB_ATTR(global_faction_ai_registry))
	var/datum/utility_ai/faction_ai = raw_faction_ai

	if(!istype(faction_ai))
		to_chat(usr, "[raw_faction_ai] is not an AI somehow")
		return

	var/datum/brain/faction_brain = faction_ai.brain

	var/trade_data = list("commodity" = "/obj/food", "trade_volume" = -1, "cash_value" = 1000)

	faction_brain.SetMemory("testTrade", trade_data)

	to_chat(usr, "[raw_faction_ai] got a new trade offer: [json_encode(trade_data)]")
	return
