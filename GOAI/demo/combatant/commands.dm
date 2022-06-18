/* Methods for manipulating the NPC AI by external agents
   (read - some player, probably, but potentially also
   'hivemind'/'AI director'-style NPC agents).
 */

/mob/goai/combatant/verb/InspectGoaiLife()
	set src in view(1)
	usr << "X=======================X"
	usr << "|"
	usr << "| [name] - ALIVE: [life]"
	usr << "|"

	var/path_list = (active_path ? active_path.path : "<No path for null>")
	var/list/brain_plan = null
	var/plan_len = "<No len for null>"
	var/brain_is_planning = null

	if(brain)
		brain_plan = brain.active_plan
		plan_len = (brain_plan ? brain_plan.len : plan_len)
		brain_is_planning = brain.is_planning

		for (var/need_key in brain.needs)
			usr << "| [need_key]: [brain.needs[need_key]]"
	else
		usr << "| (brainless)"

	usr << "|"
	usr << "| ACTIVE PATH: [active_path] ([path_list])"
	usr << "| ACTIVE PLAN: [brain_plan] ([plan_len])"
	usr << "|"
	usr << "| PLANNING: [brain_is_planning]"
	usr << "| REPATHING: [is_repathing]"
	usr << "|"
	usr << "X=======================X"


/mob/goai/combatant/verb/CancelOrders()
	set src in view()

	SetState(STATE_DOWNTIME, TRUE)
	usr << "Set [src] downtime-state to [TRUE]"

	usr << (waypoint ? "[src] tracking [waypoint]" : "[src] no longer tracking waypoints")

	return waypoint


/mob/goai/combatant/verb/GiveFollowOrder(mob/M in world)
	set src in view()
	if(!M)
		return

	SetState(STATE_DOWNTIME, FALSE)
	usr << "Set [src] downtime-state to [FALSE]"

	waypoint = M
	usr << (waypoint ? "[src] now tracking [waypoint]" : "[src] not tracking waypoints")

	return waypoint


/mob/goai/combatant/verb/GiveMoveOrder(posX as num, posY as num)
	set src in view()

	var/trueX = posX % world.maxx
	var/trueY = posY % world.maxy
	var/trueZ = src.z

	var/turf/position = locate(trueX, trueY, trueZ)
	if(!position)
		usr << "Target position does not exist!"
		return

	SetState(STATE_DOWNTIME, FALSE)
	usr << "Set [src] downtime-state to [FALSE]"

	waypoint = position
	usr << (waypoint ? "[src] now tracking [waypoint] @ ([trueX], [trueY], [trueZ])" : "[src] not tracking waypoints")

	return waypoint


/mob/goai/combatant/verb/Disarm()
	set src in view()

	var/curr_firing_state = ((STATE_CANFIRE in states) ? states[STATE_CANFIRE] : FALSE)
	states[STATE_CANFIRE] = !curr_firing_state

	usr << "[src] CAN_FIRE set to [states[STATE_CANFIRE]]"

	return