/*
// This module extends the AI Brain class with methods for reasoning about economic values of goods and money.
*/

// placeholders because this is an ABC:

/datum/brain/proc/GetCommodityDesirability(var/commodity, var/amount)
	return 0

/datum/brain/proc/GetMoneyDesirability(var/amount)
	return 0


/datum/brain/utility/GetCommodityDesirability(var/commodity, var/amount)
	// mostly pro-forma in case this ever does anything important in the ABC
	. = ..(amount)

	// TODO figure out the logic here
	return 0


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
