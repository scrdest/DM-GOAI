/datum/goai_commander/InitSenses()
	/* Parent stuff */
	. = ..()

	/* Initialize sense objects: */

	/* Register each Sense: */

	return


/datum/goai_commander/proc/SensesSystem()
	/* We're rolling ECS-style */
	for(var/sense/sensor in senses)
		sensor.ProcessTick(src)
	return
