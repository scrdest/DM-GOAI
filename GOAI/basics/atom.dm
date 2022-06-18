/atom/proc/Hit(var/hit_angle, var/atom/shotby = null)
	/* hit angle - clockwise from positive Y axis if positive,
	counterclockwise if negative.

	Can use the IMPACT_ANGLE(x) macro to calculate.

	shotby - a reference to who shot us (atom - to incl. turret objects etc.)
	*/

	return


/atom/proc/CurrentPositionAsTuple()
	var/datum/Tuple/pos_tuple = new(src.x, src.y)
	return pos_tuple


/atom/proc/CurrentPositionAsTriple()
	var/datum/Triple/pos_triple = new(src.x, src.y, src.z)
	return pos_triple
