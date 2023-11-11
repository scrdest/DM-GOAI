/datum/event/backrooms_deepmaint
	announceWhen = 10
	endWhen = 1000
	var/entrypoints = 100
	var/list/spawned_teleporters


/datum/event/gravity/setup()
	endWhen = rand(600, 6000)

/datum/event/backrooms_deepmaint/proc/create_outbound_teleporters()
	set waitfor = FALSE

	sleep(-1) // detach immediately and background
	var/list/predicates = list(/proc/is_station_turf, /proc/not_turf_contains_dense_objects)

	if(isnull(src.spawned_teleporters))
		src.spawned_teleporters = list()

	var/tries = src.entrypoints + 3 // small padding; keep the addition here, even if with zero, to ensure a clone...

	// ...because I'm pretty sure the `--x` op here is inplace
	while(tries --> 0)
		if(src.spawned_teleporters.len >= src.entrypoints)
			break

		var/area/location = pick_area(list(/proc/is_not_space_area, /proc/is_station_area, /proc/is_maint_area))

		if(isnull(location))
			continue

		var/turf/T = pick_area_turf(location, predicates)

		if(isnull(T))
			continue

		var/obj/wfc_step_trigger/deepmaint_entrance/deepmaint_teleporter = new(T)
		src.spawned_teleporters.Add(deepmaint_teleporter)

		if(!(tries % 5))
			// Try to do blocks of 5 between each sleep
			sleep(0)

	if(!(src.spawned_teleporters?.len))
		log_debug("Failed to spawn any teleporters for the Deepmaint event. Aborting.")
		kill(TRUE)

	return


/datum/event/backrooms_deepmaint/start()
	src.create_outbound_teleporters()
	return


/datum/event/backrooms_deepmaint/end()
	for (var/obj/wfc_step_trigger/deepmaint_entrance/deepmaint_teleporter in src.spawned_teleporters)
		qdel(deepmaint_teleporter)

	command_announcement.Announce("All subspace distortions have ceased. All personnel and/or assets not present onboard should be considered lost.")


/datum/event/deepmaint/announce()
	command_announcement.Announce("Extreme subspace anomalies detected. Ensure all persons and assets are accounted for.", "[location_name()] Spooky Sensor Network", zlevels = affecting_z)

