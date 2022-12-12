/turf/proc/CombatantAdjacents(var/mob/goai/combatant/owner)
	var/turf/s = get_turf(src)
	if(!s)
		return

	var/list/base_adjs = s.CardinalTurfsNoblocks()
	var/list/out_adjs = list()

	var/cut_link = owner?.brain?.GetMemoryValue("BadStartTile", null)

	for(var/adj in base_adjs)
		if(cut_link && src == cut_link)
			world.log << "[src] is a cut link!"
			continue

		out_adjs.Add(adj)

	return out_adjs


/proc/fCombatantAdjacents(var/S, var/mob/goai/combatant/owner)
	if(!S)
		return

	var/turf/s = get_turf(S)
	if(!s)
		return

	var/list/base_adjs = s.CardinalTurfsNoblocks()
	var/list/out_adjs = list()

	var/cut_link = owner?.brain?.GetMemoryValue("BadStartTile", null)

	for(var/adj in base_adjs)
		if(cut_link && src == cut_link)
			world.log << "[S] is a cut link!"
			continue

		out_adjs.Add(adj)

	return out_adjs


/proc/mCombatantAdjacents(var/mob/goai/combatant/owner)
	if(!owner)
		return

	var/turf/s = get_turf(owner)
	if(!s)
		return

	var/list/out_adjs = call(s, /turf/proc/CombatantAdjacents)(owner)

	return out_adjs