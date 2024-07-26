/*
// Helpers for testing economic.dm code
// Should generall not be included for live code.
*/

#warn Dev module included!


var/global/datum/faction_data/trade_debug_faction = null


/mob/verb/TestTrade(testfilepath as file|null)
	var/data_fp = testfilepath || GOAI_DATA_PATH("trade_test_cases.json")
	var/list/testdata
	READ_JSON_FILE_CACHED(data_fp, testdata)

	if(!testdata)
		to_chat(usr, "test data from [data_fp] is invalid!")
		return

	var/raw_faction_ai = pick(GOAI_LIBBED_GLOB_ATTR(global_faction_ai_registry))
	var/datum/utility_ai/faction_ai = raw_faction_ai

	if(!istype(faction_ai))
		to_chat(usr, "[raw_faction_ai] is not an AI somehow")
		return

	var/datum/brain/utility/faction_brain = faction_ai.brain

	if(!istype(faction_brain))
		to_chat(usr, "[raw_faction_ai] brain [faction_brain] is not a Utility brain, somehow")
		return

	var/list/new_needs = testdata["_new_needs"] || list()

	for(var/new_need_key in new_needs)
		var/new_need_val = new_needs[new_need_key]

		to_chat(usr, "[raw_faction_ai] needs changing: [new_need_key] -> [new_need_val]")
		to_world_log("[raw_faction_ai] needs changing: [new_need_key] -> [new_need_val]")

		faction_brain.needs[new_need_key] = new_need_val

	if(isnull(global.trade_debug_faction))
		var/datum/faction_data/economy_gods = new("Economy Gods")
		global.trade_debug_faction = economy_gods

	for(var/test_key in testdata)
		if(test_key == "_new_needs")
			continue

		var/list/test_case = testdata[test_key]

		if(!istype(test_case))
			continue

		var/commodity_key = test_case["commodity_key"]
		var/trade_volume = test_case["trade_volume"] || 1
		var/cash_value = test_case["cash_value"] || 1000

		var/datum/trade_offer/test_offer = new(global.trade_debug_faction, commodity_key, trade_volume, cash_value)
		REGISTER_OFFER_TO_MARKETPLACE(test_offer)

		to_chat(usr, "Created a new trade offer ([DEFAULT_IF_NULL(test_offer.id, "null")]): {commodity_key: [test_offer.commodity_key], commodity_amount: [test_offer.commodity_amount]u, cash_value: [test_offer.cash_value] }")

	return
