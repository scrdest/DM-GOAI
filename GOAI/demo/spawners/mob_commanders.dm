/proc/spawn_commanded_combatant(var/atom/loc, var/name = null, var/mob_icon = null, var/mob_icon_state = null)
	var/true_name = name

	var/mob/goai/combatant/M = new(active = FALSE)
	M.pLobotomizeGoai(stop_life = FALSE) // probably should refactor to not make a brain in the first place!
	M.loc = loc

	var/datum/goai/mob_commander/new_commander = new()

	new_commander.owned_mob = M
	world.log << "Owned mob of [new_commander.name] is [new_commander.owned_mob]"

	true_name = true_name || "AI of [M.name]"
	if(true_name)
		new_commander.name = true_name

	world.log << "Spawned [new_commander.name]/[M]"


/obj/spawner/oneshot/commanded_mob
	var/commander_name = null
	var/mob_icon = null
	var/mob_icon_state = null

	icon = 'icons/uristmob/simpleanimals.dmi'
	icon_state = "ANTAG"

	script = /proc/spawn_commanded_combatant


/obj/spawner/oneshot/commanded_mob/CallScript()
	var/true_mob_icon = src.mob_icon || src.icon
	var/true_mob_icon_state = src.mob_icon_state || src.icon_state

	var/script_args = list(
		loc = src.loc,
		name = src.commander_name,
		mob_icon = true_mob_icon,
		mob_icon_state = true_mob_icon_state
	)

	sleep(-1)
	call(script)(arglist(script_args))
