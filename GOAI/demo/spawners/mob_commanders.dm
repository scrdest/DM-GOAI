/proc/spawn_commanded_combatant(var/atom/loc, var/name = null, var/mob_icon = null, var/mob_icon_state = null)
	var/true_name = name

	var/mob/goai/combatant/M = new(active = FALSE)
	M.pLobotomizeGoai(stop_life = FALSE) // probably should refactor to not make a brain in the first place!
	M.loc = loc

	var/datum/goai/mob_commander/new_commander = new()

	new_commander.pawn = M
	world.log << "Pawn of [new_commander.name] is [new_commander.pawn]"

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
	if(!active)
		return

	var/true_mob_icon = src.mob_icon || src.icon
	var/true_mob_icon_state = src.mob_icon_state || src.icon_state

	var/script_args = list(
		loc = src.loc,
		name = src.commander_name,
		mob_icon = true_mob_icon,
		mob_icon_state = true_mob_icon_state
	)

	call(script)(arglist(script_args))



/proc/spawn_commanded_object(var/atom/loc, var/name = null)
	var/true_name = name

	var/obj/gun/M = new(loc)

	var/datum/goai/mob_commander/new_commander = new()

	new_commander.pawn = M
	world.log << "Pawn of [new_commander.name] is [new_commander.pawn]"

	true_name = "AI of [M.name]"

	world.log << "Spawned [new_commander.name]/[M]"

	return



/obj/spawner/oneshot/commanded_object
	var/commander_name = null

	icon = 'icons/obj/gun.dmi'
	icon_state = "laser"

	script = /proc/spawn_commanded_object


/obj/spawner/oneshot/commanded_object/CallScript()
	if(!active)
		return

	var/script_args = list(
		loc = src.loc,
		name = src.commander_name
	)

	call(script)(arglist(script_args))
