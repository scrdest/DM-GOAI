#define HASFOOD 2

/datum/actionholder/eat
	name = "Eat"
	cost = 2
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

/datum/actionholder/eat/GetPreconditions()
	var/O = HASFOOD
	return O

/datum/actionholder/eat/GetEffects()
	//if(istype(Food, /obj/food))
		//var/obj/food/foodstuff = Food

/datum/actionholder/eat/Action(Food as obj)
	if(istype(src,/datum/actionholder))
		var/datum/actionholder/caller = src
		if(istype(Food, /obj/food))
			var/obj/food/foodstuff = Food
			caller.owner.hunger += foodstuff.satiety
			del(foodstuff)
		else
			src.owner << "That's not food!"
	else
		return -1 //error return