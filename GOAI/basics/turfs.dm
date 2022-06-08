/turf/ground
	icon = 'icons/turf/snow.dmi'
	icon_state = "snow"


/turf/ground/New()
	. = ..()
	name += " ([x], [y])"


/turf/wall
	density = 1
	opacity = 1
	icon = 'icons/urist/turf/walls.dmi'
	icon_state = "stone0"

	var/is_pillar = FALSE
	var/is_corner = FALSE


/turf/wall/New()
	. = ..()
	name += " ([x], [y])"

	var/list/adjacents = src.CardinalTurfs(FALSE)
	var/dense_conn = 0
	var/dense_neighbors = 0

	for(var/turf/neigh in adjacents)
		if(neigh.IsBlocked())
			dense_conn |= get_dir(neigh, src)
			dense_neighbors++

	switch(dense_neighbors)
		if(0)
			is_pillar = TRUE

		if(1)
			is_corner = TRUE

		if(2)
			var/list/dir_pairs = list(0, NORTH|SOUTH, EAST|WEST)
			// if NORTH|SOUTH or WEST|EAST, it's a line; otherwise, corner
			if(!(dense_conn in dir_pairs))
				is_corner = TRUE
				name += " <corner>"

	name += " <dense: [dense_conn], [is_corner]>"
	icon_state = "stone[dense_conn]"



/proc/trange(rad = 0, turf/centre = null) //alternative to range (ONLY processes turfs and thus less intensive)
	if(!centre)
		return

	var/turf/x1y1 = locate(((centre.x-rad)<1 ? 1 : centre.x-rad),((centre.y-rad)<1 ? 1 : centre.y-rad),centre.z)
	var/turf/x2y2 = locate(((centre.x+rad)>world.maxx ? world.maxx : centre.x+rad),((centre.y+rad)>world.maxy ? world.maxy : centre.y+rad),centre.z)
	return block(x1y1,x2y2)


/turf/proc/IsBlocked()
	if(density)
		return TRUE

	//if(!LinkBlocked(src, t) && !TurfBlockedNonWindow(t))
	//	adjacents += t // Fancy SS13 logic

	return FALSE


/turf/proc/AdjacentTurfs(var/check_blockage = TRUE)
	var/list/adjacents = list()

	for(var/turf/t in (trange(1,src) - src))
		if(check_blockage)
			if(!(t.IsBlocked()))
				adjacents += t
		else
			adjacents += t

	return adjacents


/turf/proc/CardinalTurfs(var/check_blockage = TRUE)
	var/list/adjacents = list()

	for(var/ad in AdjacentTurfs(check_blockage))
		var/turf/T = ad
		if(T.x == src.x || T.y == src.y)
			adjacents += T

	return adjacents


/turf/proc/Distance(turf/t)
	if(get_dist(src,t) == 1)
		var/cost = (src.x - t.x) * (src.x - t.x) + (src.y - t.y) * (src.y - t.y)
		cost *= (pathweight+t.pathweight)/2
		return cost
	else
		return get_dist(src,t)


/turf/proc/GetOpenness(var/range = 1)
	var/open_lines = 0

	for(var/turf/adj_open in oview(range, src))
		if(!adj_open.density)
			open_lines++

	return open_lines
