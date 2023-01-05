/mob/living/simple_animal/aitester
	icon = 'icons/uristmob/simpleanimals.dmi'
	icon_state = "ANTAG"

	var/real_name

	var/dict/attachments

	var/spawn_commander = TRUE
	var/equip = TRUE
	var/ensure_unique_name = FALSE


/mob/living/simple_animal/aitester/proc/ChooseFaction()
	var/list/factions = list("ANTAG", "Skrell", "NTIS")
	var/myfaction = pick(factions)
	return myfaction


/mob/living/simple_animal/proc/SpriteForFaction(var/faction)
	if(isnull(faction))
		return

	switch(faction)
		if("ANTAG") return "ANTAG"
		if("Skrell") return "skrellorist"
		if("NTIS") return "agent"


/mob/living/simple_animal/aitester/proc/Equip()
	var/obj/item/weapon/gun/mygun = new(src)
	to_chat(src, "You've received a [mygun]")
	return src


/mob/living/simple_animal/aitester/New()
	. = ..()

	//src.directional_blocker = new(null, TRUE, TRUE)
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
		var/datum/goai/mob_commander/combat_commander/new_commander = new()
		AttachCombatCommanderTo(src, new_commander)

	return
