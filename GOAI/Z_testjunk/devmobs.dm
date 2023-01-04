/mob/aitester
	icon = 'icons/uristmob/simpleanimals.dmi'
	icon_state = "ANTAG"

	var/faction
	var/real_name

	var/dict/attachments

	var/spawn_commander = TRUE
	var/ensure_unique_name = FALSE


/mob/aitester/proc/ChooseFaction()
	var/list/factions = list("ANTAG", "Skrell", "NTIS")
	var/myfaction = pick(factions)
	return myfaction


/mob/aitester/proc/SpriteForFaction(var/faction)
	if(isnull(faction))
		return

	switch(faction)
		if("ANTAG") return "ANTAG"
		if("Skrell") return "skrellorist"
		if("NTIS") return "agent"


/mob/aitester/New()
	. = ..()

	if(isnull(src.faction))
		src.faction = src.ChooseFaction()
		var/new_sprite = src.SpriteForFaction(src.faction)

		if(new_sprite)
			src.icon_state = new_sprite

	if(isnull(src.real_name))
		src.real_name = "AiTester"

	if(ensure_unique_name)
		src.real_name = "[src.real_name] #[rand(100, 999)]-[rand(100, 999)]"

	src.name = src.real_name

	var/datum/goai/mob_commander/combat_commander/new_commander = new()
	AttachCombatCommanderTo(src, new_commander)

	return
