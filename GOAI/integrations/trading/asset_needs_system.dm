/*
// This is a System (in the ECS sense) that updates AI Needs based on the Assets they have.
// This only applies to Assets that DO correspond to Needs - everything else can be handled custom-like.
//
// This System relies on two registries: CommodityDB and AssetsDB.
// Removal of either will make this unusable.
*/

// tracks the running subsystem, by ticker ID hash, to prevent duplication
var/global/assetneeds_subsystem_running = null

// Format-string to use to construct a unique hash for the Production/Consumption subsystem
// Currently uses a random number AND a world.time to ensure collisions are extremely unlikely
#define ASSETNEEDS_SYSTEM_TICKER_ID_HASH(MaxRand) "[rand(1, MaxRand)]-[world.time]"

// Inline version; generally preferable unless you REALLY need a proc
#define INITIALIZE_ASSETNEEDS_SYSTEM_INLINE(Tickrate) if(TRUE) {\
	StartAssetNeedsSystem(Tickrate); \
};

// Variant - does the same, but only if it's not already initialized
#define INITIALIZE_ASSETNEEDS_SYSTEM_INLINE_IF_NEEDED(Tickrate) if(isnull(GOAI_LIBBED_GLOB_ATTR(assetneeds_subsystem_running))) {\
	INITIALIZE_ASSETNEEDS_SYSTEM_INLINE(Tickrate); \
};

#define INITIALIZE_ASSETNEEDS_SYSTEM_INLINE_IF_NEEDED_AT_DEFAULT_RATE INITIALIZE_ASSETNEEDS_SYSTEM_INLINE_IF_NEEDED(null)


/proc/StartAssetNeedsSystem(var/tickrate = null, var/my_id = null)
	/* Starts a backgrounded Production/Consumption system.
	//
	// This is something like the old-style SS13 Chemistry (simpler than 2020s-chem),
	// except for living economy - modeling how capital transforms goods.
	*/
	set waitfor = FALSE

	// Our ID; should be a unique string
	var/ticker_id = my_id || ASSETNEEDS_SYSTEM_TICKER_ID_HASH(1000)
	var/tick_rate = max(1, DEFAULT_IF_NULL(tickrate, DEFAULT_ASSETNEEDS_SYSTEM_TICKRATE))
	GOAI_LIBBED_GLOB_ATTR(assetneeds_subsystem_running) = ticker_id
	to_world_log("= ASSET-NEEDS SYSTEM: Initialized an asset-needs subsystem with tickrate [tick_rate] =")

	// Waitfor is false, so we use this sleep to detach the 'thread'
	sleep(0)

	// This is a ticker; it will continue to run while the global holds its ID
	// If we start a new instance, it will take over the value in the global
	// thereby terminating any old instances.
	while(ticker_id == GOAI_LIBBED_GLOB_ATTR(assetneeds_subsystem_running))
		to_world_log("= ASSET-NEEDS SYSTEM: STARTED TICK! =")

		if(!istype(GOAI_LIBBED_GLOB_ATTR(global_faction_registry)))
			GOAI_LIBBED_GLOB_ATTR(global_faction_registry) = list()

		for(var/datum/brain/aibrain in GOAI_LIBBED_GLOB_ATTR(global_aibrain_registry))
			// can yield between factions, assuming they have separate resource pools
			sleep(0)

			var/datum/faction_data/faction = null

			var/datum/utility_ai/ai_controller = null
			FetchAiControllerForObjIntoVar(aibrain, ai_controller)

			if(istype(ai_controller))
				var/datum/faction_data/maybe_pawn = ai_controller.GetPawn()
				if(istype(maybe_pawn))
					faction = maybe_pawn

			// TODO add a mechanism for player-controlled things to provide a valid ID too

			if(!istype(faction))
				to_world_log("= ASSET-NEEDS SYSTEM: SKIPPING for ref [NULL_TO_TEXT(faction)] - wrong type! =")
				continue

			var/faction_id = GET_GLOBAL_ID_LAZY(faction)
			var/list/assets = GET_ASSETS_TRACKER(faction_id)

			if(isnull(GOAI_LIBBED_GLOB_ATTR(commodity_db)))
				InitCommodityDb()

			var/list/new_need_values = list()

			for(var/commodity_key in GOAI_LIBBED_GLOB_ATTR(commodity_db))
				// We need to go CommodityDB first, so that we can set needs to 0 if we ain't got anything.
				// If we went assets-first, all the missing ones would be frozen in the last updated state.
				// In theory we could EXPLICITLY give factions zero of Thing, but that is really inelegant.
				// The commodity list shouldn't be THAT long anyway (he said, ready to regret it later...).
				var/list/associated_needs = GOAI_LIBBED_GLOB_ATTR(commodity_db)[commodity_key]

				if(!associated_needs)
					continue

				var/owned_amt = 0

				if(commodity_key in assets)
					owned_amt = DEFAULT_IF_NULL(assets[commodity_key], 0)

				owned_amt = max(0, owned_amt) // no negativity here pls

				for(var/need_key in associated_needs)
					var/need_wgt = associated_needs[need_key]

					if(DEFAULT_IF_NULL(need_wgt, 0) <= 0)
						continue

					var/curr_need = DEFAULT_IF_NULL(new_need_values[need_key], 0)
					var/commodity_effect = need_wgt * owned_amt
					var/new_need_val = curr_need + commodity_effect

					new_need_values[need_key] = new_need_val

			// all need deltas calculated, now apply...
			to_world_log("= ASSET-NEEDS SYSTEM: Updated for [NULL_TO_TEXT(faction)]... =")
			aibrain.SetNeedBatched(new_need_values)

		// Wait for the next iteration
		sleep(tick_rate)

	return
