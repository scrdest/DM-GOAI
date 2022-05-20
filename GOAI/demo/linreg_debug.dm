/*
This is actually redundant:

/turf/verb/TestLinRegFrom()
	set src in view()

	usr << "SRC: [src], USR: [usr]"
	var/result = LinRegress(src, usr)
	usr << "LinReg result from [src]: [result]"
	return result
*/

/turf/verb/TestLinRegTo()
	set src in view()

	usr << "SRC: [src], USR: [usr]"
	var/result = LinRegress(usr, src)
	usr << "LinReg result to [src]: [result]"
	return result
