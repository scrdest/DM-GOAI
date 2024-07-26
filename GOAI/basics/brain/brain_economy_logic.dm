/*
// This module extends the AI Brain class with methods for reasoning about economic values of goods and money.
*/

#define BRAIN_MODULE_INCLUDED_ECONOMY 1

// mostly placeholders because this is an ABC:

/datum/brain/proc/GetMoneyDesirability(var/amount, var/curr_wealth = null)
	return 0


/datum/brain/proc/GetCommodityDesirability(var/commodity, var/amount, var/cash_value, var/list/curr_need_level_overrides = null)
	return null


/datum/brain/proc/GetMoneyForNeedUtility(var/utility, var/curr_wealth = null)
	/* This is effectively an inverse of GetMoneyDesirability(Amt). */
	return


/datum/brain/proc/GetCommodityAmountForNeedDelta(var/commodity, var/need_key, var/delta)
	/* Given a Commodity and a Need delta, how many whole units of Commodity do we need
	// to give us at least that much change in the Need?
	//
	// As any Commodity's Need satisfaction per unit may be higher than our delta,
	// and we want integer-valued amounts, this is not a simple division.
	*/
	return

/*
// Picking the preferred trade good when WE are making offers.
//
// This does not affect our willingness to accept buy or sell offers from others,
// that just depends on normal AI logic evaluating the offer.
//
// The methods for preferred Buy and Sell goods are split to make it easier
// to customize their logic separately.
//
// For example, you might want to hardcode the bought item for a need,
// but pick a sold item from items that we have available at the moment.
*/

/datum/brain/proc/GetBestPurchaseCommodityForNeed(var/need_key)
	/* Given a Need, what is the thing we'd prefer to buy to satisfy it? */

	// The implementation can be very dumb, e.g. hardcoded item or a random
	// choice from a list of hardcoded items, or very fancy - up to implementer.

	return


/datum/brain/proc/GetBestSaleCommodityForNeed(var/need_key)
	/* Given a Need, what is the thing we'd prefer to sell to satisfy it? */

	// The implementation can be very dumb, e.g. hardcoded item or a random
	// choice from a list of hardcoded items, or very fancy - up to implementer.

	return

