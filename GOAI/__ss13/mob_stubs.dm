# ifdef GOAI_LIBRARY_FEATURES

# define CONSCIOUS 0
# define UNCONSCIOUS 1
# define DEAD 2

# define I_HURT "harm"
# define I_HELP "help"

/mob
	var/real_name
	var/faction

/mob/Bump(atom/Obstacle)
	var/turf/obsloc = get_turf(Obstacle)
	if(obsloc.IsBlocked(TRUE, TRUE))
		return

	var/mob/obsmob = Obstacle

	if(istype(obsmob))
		if(!(src in obsmob.group))
			obsmob.group.Add(src)

	. = ..(Obstacle)
	return

/mob/living
	var/stat = CONSCIOUS

	var/health_current = 100
	var/health_max = 100

/mob/living/carbon

/mob/living/carbon/human
	var/a_intent

/mob/living/simple_animal

/mob/living/simple_animal/hostile

/mob/living/bot

# endif
