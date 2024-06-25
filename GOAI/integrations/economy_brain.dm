/*
// This module extends the AI Brain class with methods for reasoning about economic values of goods and money.
*/

/*
// UTILITY DELTA INTEGRATION
// This is a bit of tricky math. We want the AI to favour satisfying its needs,
// with priority to boosting low needs to survival levels over maximizing the high ones.
//
// The formulas were derived by specifying a function of how the Utility drops off with supply and
// calculating the indefinite integral of the raw function (and defining it as the _COMMODITY_DELTA_UTILITY_INTEGRATION_POINT... macro)
//
// To calculate how much Utility we gain from going low-to-high, we calculate the definite integral between the start and end amounts.
// Practically speaking this is a simple difference between the value of the INTEGRATION_POINT macros at start and end.
//
// The quadratic formula below is well-behaved, but not necessarily the only viable function. It's cheap though!
*/
#define _COMMODITY_DELTA_UTILITY_INTEGRATION_POINT_QUADRATIC(CD) ((3 * (CD) - (CD ** 2)) / 2)
#define INTEGRATE_COMMODITY_DELTA_UTILITY_QUADRATIC(Pre, Post) ((_COMMODITY_DELTA_UTILITY_INTEGRATION_POINT_QUADRATIC(Post) - _COMMODITY_DELTA_UTILITY_INTEGRATION_POINT_QUADRATIC(Pre)))


// placeholders because this is an ABC:


/datum/brain/proc/GetMoneyDesirability(var/amount)
	return 0


/datum/brain/proc/GetNeeds() // () -> assoc[str, float]
	// returns an assoc of keys of all Needs this AI cares about to their weights
	var/list/needs = list()
	return needs


/datum/brain/proc/GetNeedAmountCurrent(var/need)
	return 0


/datum/brain/proc/GetNeedDesirability(var/need, var/amount)
	return 0


/datum/brain/proc/GetCommodityDesirability(var/commodity, var/amount)
	return null


/datum/brain/proc/GetNeedDeltaUtility(var/need, var/amt_pre, var/amt_post)
	return null


/*
// Utility-brained implementations
*/

/datum/brain/utility/GetNeedAmountCurrent(var/need)
	return (src.needs[need] || 0)


/datum/brain/utility/GetNeeds()
	#warn Get this from data in GetNeeds
	var/list/myneeds = null //src.needs

	if(isnull(myneeds))
		#warn Do better defaults
		myneeds = list(
			"food" = 3,
			"bling" = 0.5
		)

	return myneeds


/datum/brain/utility/GetNeedDesirability(var/need, var/amount)
	var/desirability = (amount / 100)
	desirability = clamp(desirability, 0, 1)
	return desirability


/datum/brain/utility/GetNeedDeltaUtility(var/need, var/amt_pre, var/amt_post)
	/*
	// Calculates how much we value increasing the amount of Commodity from x1 to x2.
	//
	// For example, if we're at 50% Food and a Burger item increases our Food by 10%,
	//  what is our (subjective) value of the burger in utils?
	//
	// This value generally depends both on the quality of the item AND our current Need levels.
	//
	// If we're already 100% full, the Burger is worthless to us as a food item.
	// If we are at 0%, we will take anything we can get, but we still value the
	//  Burger at 10% as higher than a Candy at 1% all the rest being equal.
	//
	// As an API contract, if amt_pre >= amt_post, Utility should always be <= 0.
	*/

	// How happy we are with how much we've had
	var/pre_desirability = src.GetNeedDesirability(need, amt_pre)

	// How happy we are to be at the new amount
	var/post_desirability = src.GetNeedDesirability(need, amt_post)

	// How happy we are with the CHANGE.
	//
	// This is NOT NECESSARILY a simple difference,
	//  because the underlying function *is generally not linear*.
	//
	// In turn, this is because we care more about dealing with critically low needs;
	//  we'd rather stave off starvation by 5% than raise our comfort from 90% to 95%
	//
	// Instead, we calculate a simple definite integral with pre/post amounts as limits.
	//
	// All this is mentioned primarily for the benefit of maintainers playing with the curves.
	// If the math scares you, don't worry - the actual formula used will likely be very simple.
	var/result = INTEGRATE_COMMODITY_DELTA_UTILITY_QUADRATIC(pre_desirability, post_desirability)
	#warn debug logs
	to_world_log("Need [need] [amt_pre]->[amt_post]: desirability [result]")
	result = clamp(result, 0, 1)

	return result


/datum/brain/utility/GetCommodityDesirability(var/commodity, var/amount)
	// Desirability of a Commodity is an aggregate of the integrated
	//   Desirability of all Needs that we care about.
	// Practically speaking, what this means is:
	//   - we grab all Needs we care about
	//   - we check the deltas from the commodity
	//   - we calculate the Utility of (curr + delta) for each Need by integrating
	//   - we do a weighted average of this value as our true Utility/Desirability

	if(!amount)
		// broken or fairly pointless call, no value in trading nothing
		return 0

	/* STEP 1: Figure out what Needs we even care about */
	var/list/needs = src.GetNeeds() // assoc[str, float]
	if(!needs)
		return 0 // vendor trash

	// How much this Commodity will shift the Needs we care about
	var/list/needs_commodity_deltas = list()

	var/list/need_values = GetCommodityNeedAllValuesAbstract(commodity)
	if(!need_values)
		return 0 // vendor trash

	/* STEP 2: Get deltas of all relevant Needs */
	for(var/need_key in needs)
		var/need_weight = needs[need_key]

		if(!need_weight)
			// skip zeros for speed
			// and nulls for validity
			continue

		var/raw_commodity_need_amt = need_values[need_key] || 0

		if(!raw_commodity_need_amt)
			// no point adding zeros to things
			continue

		// scale by trade volume
		var/commodity_need_amt = raw_commodity_need_amt * amount

		var/curr_stored_need = needs_commodity_deltas[need_key]
		if(isnull(curr_stored_need))
			// We only store deltas here, it's more efficient than fetching
			// the current values twice (for this and later for integration)
			curr_stored_need = 0

		needs_commodity_deltas[need_key] = curr_stored_need + commodity_need_amt

	/* STEP 3: Calculate the Utility of each applied delta */
	var/total = 0
	var/denom = 0

	for(var/posthoc_need_key in needs_commodity_deltas)
		// aggregate results
		var/need_weight = needs[posthoc_need_key]

		if(!need_weight)
			// skip zeros for speed
			// and nulls for validity
			continue

		// starting point:
		var/curr_need_amt = src.GetNeedAmountCurrent(posthoc_need_key)

		// deltas:
		var/raw_post_need_amt = needs_commodity_deltas[posthoc_need_key]

		// actually apply the deltas to the current amount:
		var/true_post_need_amt = curr_need_amt + raw_post_need_amt

		if(true_post_need_amt < 0)
			// If any deal would take us below zero on any need, it's trash.
			return null

		// integration:
		var/desirability = src.GetNeedDeltaUtility(posthoc_need_key, curr_need_amt, true_post_need_amt)

		// weight sum is the denominator in a weighted average later
		denom += need_weight

		// future numerator; we need to scale the values by weights or things would get silly
		total += (desirability * need_weight)

		#warn debug logs
		to_world_log("Need [posthoc_need_key] [curr_need_amt]->[true_post_need_amt]: desirability [desirability] | total [total] / denominator [denom]")

	/* STEP 4: weighted average to get final value */
	if(!denom)
		// no division by zero!
		return null

	var/commodity_desirability = total / denom

	/* STEP 5: PROFIT!!! */
	#warn debug logs
	to_world_log("needs [json_encode(needs_commodity_deltas)] | numerator [total] / denominator [denom] == [commodity_desirability]")
	return commodity_desirability


/datum/brain/utility/GetMoneyDesirability(var/amount)
	// mostly pro-forma in case this ever does anything important in the ABC
	. = ..(amount)

	var/personality_factor = src.personality?["money_preference"]

	if(isnull(personality_factor))
		// default; TODO constify this
		personality_factor = 0.5

	personality_factor = clamp(personality_factor, 0, 1)

	// TODO: This should be more sophisticated and track how much reserves we have vs. how much we want.
	//       For now, this is a simple placeholder.
	var/money_preference = personality_factor

	return money_preference
