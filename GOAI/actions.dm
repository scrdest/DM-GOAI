#define HASFOOD 2

/datum/actionholder/eat
	name = "Eat"
	cost = 2
	preconds = list(HASFOOD)
	var/satietypotential = 0

/datum/actionholder/eat/CheckPreconditions()
	if(istype(src,/datum/actionholder))
		var/datum/actionholder/caller = src
		if("HasFood" in caller.owner.mobstatuslist)
			return 1
		else
			return 0
	else
		return -1 //error return


/datum/actionholder/eat/Action(Food as obj)
	var/datum/actionholder/caller = src
	if(!caller)
		return -1

	if(istype(Food, /obj/food))
		var/obj/food/foodstuff = Food
		src.owner.hunger += foodstuff.satiety
		del(foodstuff)
		return

	else
		src.owner << "That's not food!"
	return -1 //error return