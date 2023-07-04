
/mob/verb/CommanderGiveFollowOrder(datum/utility_ai/mob_commander/combat_commander/M in GOAI_LIBBED_GLOB_ATTR(global_goai_registry), mob/Trg in world)
	set category = "Commander Orders"

	if(!M)
		return

	if(!(M?.brain))
		return

	var/datum/memory/created_mem = M.brain.SetMemory("ai_target", Trg, PLUS_INF)
	var/atom/waypoint = created_mem?.val

	to_chat(usr, (waypoint ? "[M] now tracking [waypoint]" : "[M] not tracking waypoints"))
	return waypoint


/mob/verb/CommanderGiveMoveOrder(datum/utility_ai/mob_commander/combat_commander/M in GOAI_LIBBED_GLOB_ATTR(global_goai_registry), posX as num, posY as num)
	set category = "Commander Orders"

	if(!(M?.brain))
		return

	var/trueX = posX % world.maxx
	var/trueY = posY % world.maxy
	var/trueZ = src.z

	var/turf/position = locate(trueX, trueY, trueZ)
	if(!position)
		to_chat(usr, "Target position does not exist!")
		return

	var/datum/memory/created_mem = M.brain.SetMemory("ai_target", position, PLUS_INF)
	var/atom/waypoint = created_mem?.val

	to_chat(usr, (waypoint ? "[M] now tracking [waypoint] @ ([trueX], [trueY], [trueZ])" : "[M] not tracking waypoints"))

	return waypoint


/mob/verb/CommanderCancelOrders(datum/utility_ai/mob_commander/combat_commander/M in GOAI_LIBBED_GLOB_ATTR(global_goai_registry))
	set category = "Commander Orders"

	if(!(M?.brain))
		return

	M.brain.DropMemory("ai_target")

	//to_chat(usr, (waypoint ? "[M] tracking [waypoint]" : "[M] no longer tracking waypoints"))

	return TRUE
