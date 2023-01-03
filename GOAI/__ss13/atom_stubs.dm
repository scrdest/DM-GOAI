/atom/movable/proc/DoMove(var/dir, var/mover, var/external = FALSE)
	. = step(src, dir)
	return .


/atom/movable/proc/MayMove()
	. = TRUE
	return .


/atom/movable/proc/MayEnterTurf(var/turf/T)
	. = T?.Enter(src, get_turf(src))
	return .
