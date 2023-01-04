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

	var/list/adjacents = src.CardinalTurfs(FALSE, FALSE, FALSE)
	var/dense_conn = 0
	var/dense_neighbors = 0

	for(var/turf/neigh in adjacents)
		if(neigh.IsBlocked(FALSE))
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


/turf/proc/ObjectBlocked()
	// simplified version of the SS13 logic
	// TODO: add directional logic for flipped tables etc.

	for(var/obj/object in src.contents)
		if(!object.density)
			continue

		if(object.density)
			//to_world_log("[src] hit dense object [object] @ [object.loc]")
			return TRUE

	//to_world_log("[src] is not blocked")
	return FALSE


/proc/LinkBlocked(var/turf/A, var/turf/B)
	if(A == null || B == null) return TRUE
	var/adir = get_dir(A,B)
	var/rdir = get_dir(B,A)

	if((adir & (NORTH|SOUTH)) && (adir & (EAST|WEST)))	//	diagonal
		var/iStep = get_step(A,adir&(NORTH|SOUTH))
		if(!LinkBlocked(A,iStep) && !LinkBlocked(iStep,B)) return FALSE

		var/pStep = get_step(A,adir&(EAST|WEST))
		if(!LinkBlocked(A,pStep) && !LinkBlocked(pStep,B)) return FALSE
		return TRUE

	if(GoaiDirBlocked(A,adir))
		//to_world_log("A -> B blocked; A=[A], B=[B]")
		return TRUE

	if(GoaiDirBlocked(B,rdir))
		//to_world_log("B -> A blocked; A=[A], B=[B]")
		return TRUE

	return FALSE



/turf/proc/GoaiObjectBlocked()
	// simplified version of the SS13 logic
	// TODO: add directional logic for flipped tables etc.

	for(var/obj/object in src.contents)
		if(!object.density)
			continue

		if(object.density)
			return TRUE

	return FALSE


/proc/GoaiDirBlocked(var/atom/trg, var/dir)

	for(var/atom/D in trg)
		var/datum/directional_blocker/dirblocker = D.directional_blocker

		if(isnull(dirblocker))
			continue

		if(dirblocker.Blocks(dir))
			return TRUE

	return FALSE


/turf/proc/IsBlocked(var/check_objects = FALSE)
	if(density)
		return TRUE

	if(check_objects && src.GoaiObjectBlocked())
		return TRUE

	return FALSE


/turf/proc/AdjacentTurfs(var/check_blockage = TRUE, var/check_links = TRUE, var/check_objects = TRUE)
	var/list/adjacents = list()
	var/turf/src_turf = get_turf(src)

	for(var/turf/t in (trange(1,src) - src))
		if(check_blockage)
			if(!(t.IsBlocked(check_objects)))
				if(!(check_links && LinkBlocked(src_turf, t)))
					adjacents += t
		else
			adjacents += t

	return adjacents


// NOTE: the f-prefix stands for 'functional' (i.e. not bound method)
/proc/fAdjacentTurfs(var/turf/start, var/check_blockage = TRUE, var/check_links = TRUE, var/check_objects = TRUE)
	if(!start)
		return

	var/list/adjacents = list()
	var/turf/start_turf = get_turf(start)

	for(var/turf/t in (trange(1, start) - start))
		if(check_blockage)
			if(!(t.IsBlocked(check_objects)))
				if(!(check_links && LinkBlocked(start_turf, t)))
					adjacents += t
		else
			adjacents += t

	return adjacents


/turf/proc/CardinalTurfs(var/check_blockage = TRUE, var/check_links = TRUE, var/check_objects = TRUE)
	var/list/adjacents = list()

	for(var/ad in AdjacentTurfs(check_blockage, check_links, check_objects))
		var/turf/T = ad
		if(T.x == src.x || T.y == src.y)
			adjacents += T

	return adjacents


/proc/fCardinalTurfs(var/turf/start, var/check_blockage = TRUE, var/check_links = TRUE, var/check_objects = TRUE)
	if(!start)
		return

	var/list/adjacents = list()

	for(var/ad in fAdjacentTurfs(start, check_blockage, check_links, check_objects))
		var/turf/T = ad
		if(T.x == start.x || T.y == start.y)
			adjacents += T

	return adjacents


/turf/proc/CardinalTurfsNoblocks()
	var/result = CardinalTurfs(TRUE, FALSE, FALSE)
	//to_world_log("CardinalTurfsNoblocks([src]) => [result] ([result?.len])")
	return result


/proc/fCardinalTurfsNoblocks(var/turf/start)
	if(!start)
		return

	var/result = fCardinalTurfs(start, TRUE, FALSE, FALSE)
	//to_world_log("CardinalTurfsNoblocks([src]) => [result] ([result?.len])")

	return result


/turf/proc/Distance(var/T)
	var/turf/t = T
	if(t && get_dist(src,t) == 1)
		var/cost = (src.x - t.x) * (src.x - t.x) + (src.y - t.y) * (src.y - t.y)
		cost *= (pathweight+t.pathweight)/2
		return cost
	else
		return get_dist(src, T)


/proc/fDistance(var/turf/start, var/T)
	if(!start)
		return

	var/turf/t = T
	if(t && get_dist(start, t) == 1)
		var/cost = (start.x - t.x) * (start.x - t.x) + (start.y - t.y) * (start.y - t.y)
		cost *= (start.pathweight + t.pathweight)/2
		return cost

	else
		return get_dist(start, T)


/turf/proc/ObstaclePenaltyDistance(var/T)
	var/turf/t = get_turf(T)
	var/base_dist = fDistance(src, t)
	var/block_penalty = 0

	if(t && LinkBlocked(src, t))
		block_penalty = 10

	var/total_dist = base_dist + block_penalty
	return total_dist


/proc/fObstaclePenaltyDistance(var/S, var/T)
	if(!S || !T)
		return

	var/turf/s = get_turf(S)
	var/turf/t = get_turf(T)

	if(!s || !t)
		return

	var/base_dist = fDistance(s, t)
	var/block_penalty = 0

	if(t && LinkBlocked(s, t))
		block_penalty = 10

	var/total_dist = base_dist + block_penalty
	return total_dist


/turf/proc/GetOpenness(var/range = 1)
	var/open_lines = 0

	for(var/turf/adj_open in oview(range, src))
		if(!adj_open.density)
			open_lines++

	return open_lines



/turf/IsCover(var/transitive = FALSE, var/for_dir = null, var/default_for_null_dir = FALSE)
	. = ..(transitive, for_dir, default_for_null_dir)

	if(.)
		return . // there's a dot here. BYOOOOOND!

	// Transitive means turfs *with* cover innit *are* cover too
	if(transitive && src.HasCover(FALSE, for_dir, default_for_null_dir))
		return TRUE

	return FALSE


/world
	turf = /turf/ground
