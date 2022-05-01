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


/turf/wall/New()
	. = ..()
	name += " ([x], [y])"


/proc/trange(rad = 0, turf/centre = null) //alternative to range (ONLY processes turfs and thus less intensive)
	if(!centre)
		return

	var/turf/x1y1 = locate(((centre.x-rad)<1 ? 1 : centre.x-rad),((centre.y-rad)<1 ? 1 : centre.y-rad),centre.z)
	var/turf/x2y2 = locate(((centre.x+rad)>world.maxx ? world.maxx : centre.x+rad),((centre.y+rad)>world.maxy ? world.maxy : centre.y+rad),centre.z)
	return block(x1y1,x2y2)


/turf/proc/AdjacentTurfs(var/check_blockage = TRUE)
	var/list/adjacents = list()

	for(var/turf/t in (trange(1,src) - src))
		if(check_blockage)
			if(!t.density)
				//if(!LinkBlocked(src, t) && !TurfBlockedNonWindow(t))
				//	adjacents += t // Fancy SS13 logic; replaced w/ dedented below
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


/turf/proc/GetOpenness()
	var/open_lines = 0

	for(var/turf/adj_open in oview(1, src))
		if(!adj_open.density)
			open_lines++

	return open_lines
