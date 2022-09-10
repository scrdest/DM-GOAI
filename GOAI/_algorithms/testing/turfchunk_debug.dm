/mob/verb/TestTperimeter(var/radius = 1 as num, var/exclude_centre=FALSE as null|anything in list(TRUE, FALSE))

	var/list/result_turfs = tperimeter(
		radius = radius,
		centreX = usr.x,
		centreY = usr.y,
		centreZ = usr.z,
		dirs = ALL_CARDINAL_DIRS,
		exclude_centre_tile = exclude_centre
	)

	var/result_no = 0

	for(var/turf/T in result_turfs)
		result_no++
		usr << "TestTperimeter result [result_no]: [T]"

	usr << " "
	return
