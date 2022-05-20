/datum/ActivePathTracker
	var/list/path
	var/target
	var/min_dist = 0
	var/frustration = 0
	var/done = 0

	var/creation_time


/datum/ActivePathTracker/New(var/new_trg, var/new_path, var/new_min_dist=0, var/inh_frustration = 0)
	path = new_path
	target = new_trg
	min_dist = new_min_dist
	frustration = inh_frustration

	creation_time = world.time


/datum/ActivePathTracker/proc/SetDone()
	done = 1


/datum/ActivePathTracker/proc/IsDone()
	return done



/proc/LinRegress(var/atom/From, var/atom/To)
	/* Finds the slope coefficient A in the line equation:

	   (1) --  y = Ax + B  --

	   This can then be used to plug in X or Y values to
	   find positions of arbitrary points on the line between
	   two atoms.

	   We only care about lines passing through the From atom
	   as the origin point here, so we can assume B is effectively 0.

	   This is only for a pair of 2D position vectors (i.e. x/y coords
	   of two atoms).

	   The 3D case and cases for multiple points are left as an exercise
	   to the kind of people for whom inverting matrices sounds like their
	   idea of a good time. If you're one of them, you almost certainly
	   already know where to find the literature describing this operation.
	*/

	/* (2) --  y = Ax + 0  -- from (1) assuming B = 0
	//
	// Therefore:
	// (3) --  A = y/x  --
	*/

	var/deltaX = To.x - From.x
	var/deltaY = To.y - From.y

	if (deltaX == 0)
		if (deltaY == 0)
			return 0

		else if (deltaY > 0)
			return PLUS_INF

		else
			return -PLUS_INF

	var/slope = deltaY / deltaX
	return slope


/proc/GetEuclidStepOffset(var/atom/From, var/atom/To, var/dist = 1)
	/* Produces coords for a single (unrasterized) step along the line from From to To.

	Kind of like get_step_towards(), but works w/o the hard tile limits
	imposed by the native functions.

	From basic Euclidean distance definition/triangle magicks:
	(1) Di^2 = X^2 + Y^2

	Thanks to our lovely BYOND coordinate system, we can assume that to
	draw a line between two points P1 & P2, we can use the line equation:
	(2) dY = A * dX

	where 'd' stands for 'delta' (i.e. dY = P2.y - P1.y & dX = P2.x - P1.x)
	for some coefficient A, which we can trivially find w/ some simple division.

	To find the positions for offset Di, by combining the two, we get:
	(3) Di^2 = X^2 + (AX)^2
	(4) Di^2 = X^2 + A^2 * X^2  -- extract shared X^2
	(5) Di^2 = (1 + A^2) * X^2  -- divide by (1 + A^2)
	(6) X^2 = Di^2 / (1 + A^2)  -- sqrt both sides

	(7) X = ((Di^2 / (1 + A^2))^(0.5))
	(8) Y = A * X = A * ((Di^2 / (1 + A^2))^(0.5))

	*/

	var/slope = LinRegress(From, To)

	if (slope == 0)
		var/datum/Tuple/zero_result = new(dist, 0)
		return zero_result

	if (abs(slope) == PLUS_INF)
		var/datum/Tuple/inf_result = new(0, dist)
		return inf_result

	var/sq_dist = (dist ** 2)
	var/sq_slope = (slope ** 2)
	var/x_offset = (sq_dist / (1 + sq_slope))
	var/y_offset = slope * x_offset

	var/datum/Tuple/result = new(x_offset, y_offset)

	return result


/proc/GetEuclidStepPos(var/atom/From, var/atom/To, var/dist = 1)
	/* Same as GetEuclidStepOffset, except produces an absolute
	position and not a relative offset.

	Can be used to walk over a raycast between two points.
	*/
	var/datum/Tuple/offsets = GetEuclidStepOffset(From, To, dist)

	if(isnull(offsets))
		return

	var/x_off = offsets.left
	var/y_off = offsets.right

	if(isnull(x_off) || isnull(y_off))
		return

	var/x_pos = From.x + x_off
	var/y_pos = From.y + y_off

	var/datum/Tuple/result = new(x_pos, y_pos)

	return result
