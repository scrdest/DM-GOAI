# ifdef GOAI_LIBRARY_FEATURES
/*
	These are simple defaults for your project.
 */

world
	fps = 30		// 25 frames per second
	icon_size = 32	// 32x32 icon size by default

	view = 20		// show up to 6 tiles outward from center (13x13 view)
	//view = 8		// show up to 6 tiles outward from center (13x13 view)


// Make objects move 8 pixels per tick when walking

mob
	//step_size = 16
	icon = 'icons/mob/mob.dmi'
	icon_state = "ghost1"


/mob/proc/AddFilters()
	set waitfor = FALSE

	sleep(-1)

	//src.filters += filter(type="drop_shadow", x=0, y=-8, size=5, offset=2)

/*
	src.filters += filter(type="motion_blur", x=0, y=0)
	animate(src.filters[src.filters.len], x=2, y=0, time=5, loop=-1, easing=BOUNCE_EASING, flags=ANIMATION_PARALLEL)
	animate(x=1, y=0, time=5, easing=BOUNCE_EASING)
	animate(x=4, y=0, time=10, easing=BOUNCE_EASING)
	animate(x=0, y=0, time=10, easing=SINE_EASING)
*/

/*	src.filters += filter(type="wave", x=0, y=0, offset=0, size=2)
	animate(src.filters[src.filters.len], x=0, y=1, offset=0, time=200, loop=-1, flags=ANIMATION_PARALLEL)
	animate(x=0, y=0, offset=0, time=10)
*/


mob/New()
	..()
	//src.AddFilters()


obj
	var/pathweight = 1
	//step_size = 32

/turf
	var/pathweight = 1

# endif
