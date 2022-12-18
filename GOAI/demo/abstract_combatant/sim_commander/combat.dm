
/datum/goai/sim_commander/proc/GetActiveThreatDict() // -> /dict
	var/dict/threat_ghost = brain?.GetMemoryValue(MEM_THREAT, null, FALSE)
	return threat_ghost


/datum/goai/sim_commander/proc/GetActiveSecondaryThreatDict() // -> /dict
	var/dict/threat_ghost = brain?.GetMemoryValue(MEM_THREAT, null, FALSE)
	return threat_ghost


/datum/goai/sim_commander/proc/GetThreatPosTuple(var/dict/curr_threat = null) // -> num
	var/dict/threat_ghost = isnull(curr_threat) ? GetActiveThreatDict() : curr_threat

	var/threat_pos_x = 0
	var/threat_pos_y = 0

	if(!isnull(threat_ghost))
		threat_pos_x = threat_ghost.Get(KEY_GHOST_X, null)
		threat_pos_y = threat_ghost.Get(KEY_GHOST_Y, null)

		var/datum/Tuple/ghost_pos_tuple = new(threat_pos_x, threat_pos_y)

		return ghost_pos_tuple

	return


/datum/goai/sim_commander/proc/GetThreatDistance(var/atom/relative_to = null, var/dict/curr_threat = null, var/default = 0) // -> num
	var/datum/Tuple/ghost_pos_tuple = GetThreatPosTuple(curr_threat)

	if(isnull(ghost_pos_tuple))
		return default

	var/atom/rel_source = isnull(relative_to) ? src.pawn : relative_to
	var/threat_dist = default

	var/threat_pos_x = ghost_pos_tuple?.left
	var/threat_pos_y = ghost_pos_tuple?.right

	if(! (isnull(threat_pos_x) || isnull(threat_pos_y)) )
		threat_dist = ManhattanDistanceNumeric(rel_source.x, rel_source.y, threat_pos_x, threat_pos_y)

	return threat_dist


/datum/goai/sim_commander/proc/GetThreatChunk(var/dict/curr_threat) // -> turfchunk
	var/datum/Tuple/ghost_pos_tuple = GetThreatPosTuple(curr_threat)

	if(isnull(ghost_pos_tuple))
		return

	var/threat_pos_x = ghost_pos_tuple?.left
	var/threat_pos_y = ghost_pos_tuple?.right

	var/datum/chunk/threat_chunk = null

	if(! (isnull(threat_pos_x) || isnull(threat_pos_y)) )
		var/datum/chunkserver/chunkserver = GetOrSetChunkserver()
		threat_chunk = chunkserver.ChunkForTile(threat_pos_x, threat_pos_y, src.pawn.z)

	return threat_chunk


/datum/goai/sim_commander/proc/GetThreatAngle(var/atom/relative_to = null, var/dict/curr_threat = null, var/default = null)
	var/datum/Tuple/ghost_pos_tuple = GetThreatPosTuple(curr_threat)

	if(isnull(ghost_pos_tuple))
		return default

	var/atom/rel_source = isnull(relative_to) ? src.pawn : relative_to
	var/threat_angle = default

	var/threat_pos_x = ghost_pos_tuple?.left
	var/threat_pos_y = ghost_pos_tuple?.right

	if(! (isnull(threat_pos_x) || isnull(threat_pos_y)) )
		var/dx = (threat_pos_x - rel_source.x)
		var/dy = (threat_pos_y - rel_source.y)
		threat_angle = arctan(dx, dy)

	return threat_angle


/datum/goai/sim_commander/proc/Hit(var/angle, var/atom/shotby = null)
	. = ..(angle)

	var/impact_angle = IMPACT_ANGLE(angle)
	/* NOTE: impact_angle is in degrees from *positive X axis* towards Y, i.e.:
	//
	// impact_angle = +0   => hit from straight East
	// impact_angle = +180 => hit from straight West
	// impact_angle = -180 => hit from straight West
	// impact_angle = -90  => hit from straight North
	// impact_angle = +90  => hit from straight South
	// impact_angle = +45  => hit from North-East
	// impact_angle = -45  => hit from South-East
	//
	// Everything else - extrapolate from the above.
	*/
	//world.log << "Impact angle [impact_angle]"

	if(brain)
		var/list/shot_memory_data = list(
			KEY_GHOST_X = src.pawn.x,
			KEY_GHOST_Y = src.pawn.y,
			KEY_GHOST_Z = src.pawn.z,
			KEY_GHOST_POS_TUPLE = src.pawn.CurrentPositionAsTuple(),
			KEY_GHOST_ANGLE = impact_angle,
		)
		var/dict/shot_memory_ghost = new(shot_memory_data)

		brain.SetMemory(MEM_SHOTAT, shot_memory_ghost, src.ai_tick_delay*10)

		var/datum/brain/concrete/needybrain = brain
		if(needybrain)
			needybrain.AddMotive(NEED_COMPOSURE, -MAGICNUM_COMPOSURE_LOSS_ONHIT)

