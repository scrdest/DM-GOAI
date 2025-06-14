# ifdef GOAI_LIBRARY_FEATURES
/mob/living/simple_animal/aitester
	icon = 'icons/uristmob/simpleanimals.dmi'
	icon_state = "ANTAG"

	var/spawn_commander = TRUE
	var/equip = TRUE
	var/ensure_unique_name = FALSE

	var/commander_id = null


/mob/living/simple_animal/aitester/squadtester
	// To identify squaddies more easily
	//ensure_unique_name = TRUE

	// To get a ref to the custom-created commander in the spawner proc
	spawn_commander = FALSE


/mob/living/simple_animal/aitester/proc/ChooseFaction()
	var/list/factions = list("ANTAG", "Skrell", "NTIS", "Terran")
	var/myfaction = pick(factions)
	return myfaction


/mob/living/simple_animal/proc/SpriteForFaction(var/faction)
	if(isnull(faction))
		return

	switch(faction)
		if("ANTAG") return "ANTAG"
		if("Skrell") return "skrellorist"
		if("NTIS") return "agent"
		if("Terran") return "terran_marine"


/mob/living/simple_animal/aitester/proc/Equip()
	set waitfor = FALSE

	while(!GLOB)
		sleep(1)

	var/obj/item/gun/mygun = new(src)

	GLOB.mob_equipped_event.raise_event(src, mygun, null)
	GLOB.item_equipped_event.raise_event(mygun, src, null)

	to_chat(src, "You've received a [mygun]")
	return src


/mob/living/simple_animal/aitester/proc/SpawnCommander()
	var/datum/utility_ai/mob_commander/new_commander = new()
	#ifdef UTILITY_SMARTOBJECT_SENSES
	// Spec for Dev senses!
	new_commander.sense_filepaths = DEFAULT_UTILITY_AI_SENSES
	#endif
	AttachUtilityCommanderTo(src, new_commander)
	src.commander_id = new_commander.registry_index
	return src


/mob/living/simple_animal/aitester/New()
	. = ..()

	//src.directional_blocker = new(null, null, TRUE, TRUE)
	src.cover_data = new(TRUE, TRUE)

	if(isnull(src.faction))
		src.faction = src.ChooseFaction()
		var/new_sprite = src.SpriteForFaction(src.faction)

		if(new_sprite)
			src.icon_state = new_sprite

	if(equip)
		src.Equip()

	if(isnull(src.real_name))
		src.real_name = "AiTester"

	if(ensure_unique_name)
		src.real_name = "[src.real_name] #[rand(100, 999)]-[rand(100, 999)]"

	src.name = src.real_name

	if(src.spawn_commander)
		src.SpawnCommander()

	return


// Spawns with a pure Utility AI instead
/mob/living/simple_animal/aitester/utility

#endif
