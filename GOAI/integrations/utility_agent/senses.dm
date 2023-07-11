
/datum/utility_ai/proc/SensesSystem()
	/* We're rolling ECS-style */
	for(var/sense/sensor in senses)
		if(sensor?.enabled)
			sensor?.ProcessTick(src)
	return


/datum/utility_ai/proc/InitSenses()
	if(isnull(src.senses))
		src.senses = list()

	return src.senses


/datum/utility_ai/mob_commander/combat_commander/InitSenses()
	/* Parent stuff */
	. = ..()

	if(isnull(src.senses))
		src.senses = list()

	if(isnull(src.senses_index))
		src.senses_index = list()

	// Basic init done; actual senses go below:
	// NOTE: ORDER MATTERS!!!
	//       Senses are processed in the order of insertion!
	//
	//       If two Senses have a dependency relationship and you put the dependent
	//       before the dependee, there will be a 1-tick lag in the dependent Sense!
	//       Now, this *might* be desirable for some things, but keep it in mind.


	var/sense/combatant_commander_eyes/eyes = new()

	/* Register each Sense: */
	src.senses.Add(eyes)

	/* Register lookup by key for quick access (optional) */
	src.senses_index[SENSE_SIGHT] = eyes

	// The logic below is similar, but we need to loop over filepaths.

	if(src.sense_filepaths)
		// Initialize SmartObject senses from files

		var/list/filepaths = splittext(src.sense_filepaths, ";")
		ASSERT(!isnull(filepaths))

		for(var/fp in filepaths)
			if(!fexists(fp))
				continue

			var/sense/utility_sense_fetcher/new_fetcher = UtilitySenseFetcherFromJsonFile(fp)

			if(isnull(new_fetcher))
				continue

			ASSERT(!isnull(new_fetcher.sense_idx_key))

			src.senses.Add(new_fetcher)
			src.senses_index[new_fetcher.sense_idx_key] = new_fetcher

	return src.senses
