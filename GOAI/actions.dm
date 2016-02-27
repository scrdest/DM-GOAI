#define HASFOOD 2

/obj/actionholder/eat
	name = "Eat"
	cost = 2
	var/satietypotential = 0

/obj/actionholder/eat/CheckPreconditions()
	if(istype(src,/obj/actionholder))
		var/obj/actionholder/caller = src
		if("HasFood" in caller.owner.mobstatuslist)
			return 1
		else
			return 0
	else
		return -1 //error return

/obj/actionholder/eat/GetPreconditions()
	var/O = HASFOOD
	return O

/obj/actionholder/eat/GetEffects()
	//if(istype(Food, /obj/food))
		//var/obj/food/foodstuff = Food

/obj/actionholder/eat/Action(Food as obj)
	if(istype(src,/obj/actionholder))
		var/obj/actionholder/caller = src
		if(istype(Food, /obj/food))
			var/obj/food/foodstuff = Food
			caller.owner.hunger += foodstuff.satiety
			del(foodstuff)
		else
			src.owner << "That's not food!"
	else
		return -1 //error return