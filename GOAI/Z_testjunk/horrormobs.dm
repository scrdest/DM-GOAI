/mob/living/simple_animal/horror
	icon = 'icons/horrortest.dmi'
	icon_state = "amigara_red"


/mob/living/simple_animal/horror/proc/PickHorrorIcon()
	var/list/choices = list(
		"shadowman",
		"imp_green",
		"birdfencer",
		"hoodthulhu",
		"shambler",
		"oozer",
		"amigara_red",
		"tentaclearm",
	)

	var/result = pick(choices)
	return result


/mob/living/simple_animal/horror/New()
	. = ..()

	src.icon_state = src.PickHorrorIcon()
