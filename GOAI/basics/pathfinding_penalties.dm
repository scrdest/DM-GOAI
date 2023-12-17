/atom
	// extra cost for pathfinding if this is present
	var/pathing_obstacle_penalty = 0


/obj/cover
	pathing_obstacle_penalty = 800


/obj/cover/door
	pathing_obstacle_penalty = 20


/obj/cover/autodoor
	pathing_obstacle_penalty = 20

