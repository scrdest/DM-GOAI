/obj/spawner
	/* Object that runs a script at runtime
	//
	// Base class; you *probably* want to use one of the children.
	*/
	icon = 'icons/obj/objects.dmi'
	icon_state = "anom"
	alpha = 50

	var/script = null // proc(loc) => Any


/obj/spawner/proc/Setup()
	return


/obj/spawner/proc/CallScript()
	call(script)(src.loc)


/obj/spawner/New()
	Setup()
	CallScript()


/obj/spawner/oneshot
	// Runs a script and deletes itself


/obj/spawner/oneshot/New()
	..()
	del(src)