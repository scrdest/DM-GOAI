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

	// populates the economy_brain with an actual brain; will log if it's not
	CIHELPER_GET_REQUESTER_BRAIN_INLINED(requester, var/datum/brain/economy_brain)

	var/from_ctx = consideration_args["from_context"]
	if(isnull(from_ctx))
		from_ctx = TRUE

	var/input_key = "input"

	if(!isnull(consideration_args))
		input_key = consideration_args["input_key"] || input_key

	if(isnull(input_key))
		DEBUGLOG_MEMORY_FETCH("consideration_trade_desirability Input Key is null ([input_key || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/commodity = null
	DEBUGLOG_MEMORY_ERRTRY(commodity = (from_ctx ? context[input_key] : consideration_args[input_key]))
	DEBUGLOG_MEMORY_ERRCATCH(var/exception/e, DEBUGLOG_UTILITY_INPUT_FETCHERS("ERROR: [e] on [e.file]:[e.line]. <input_key='[input_key]'>"))

	if(isnull(commodity))
		DEBUGLOG_MEMORY_FETCH("consideration_trade_desirability commodity is null ([input_key || "null"]) @ L[__LINE__] in [__FILE__]")
		return null

	var/cash_value = consideration_args["cash_value"] || 0
	var/raw_volume = consideration_args["trade_volume"] || 0

	// Supply-side reverses the preferences in the formula. Default to demand-side.
	var/is_sell = raw_volume < 0

	if(isnull(is_sell))
		is_sell = FALSE

	var/commodity_preference = economy_brain.GetCommodityDesirability(commodity, raw_volume)
	var/money_preference = economy_brain.GetMoneyDesirability(cash_value)

	var/desirability = 0  // default

	// the general shape of formula is: (2 * Acquired) / (1 + Acquired + Traded)
	// the additive smoothing in the denominator ensures we're always normalized
	// the multiplier in the numerator ensures desirability maxes out at Acquired=1 + Traded=0
	//     (because it's definitely a deal we NEED to make)
	// if Acq/Tra are both 1, we are considering an 'emergency' trade with Desirability at 66% (modulo other Considerations)

	var/numerator = is_sell ? (2 * money_preference) : (2 * commodity_preference)
	var/denominator = (1 + commodity_preference + money_preference)

	desirability = numerator / denominator
	return desirability
