#define HASFOOD 2

/datum/actionholder
	var/name = "Do stuff"
	var/cost = 9999
	var/list/effects
	var/list/preconds
	var/mob/goai/agent/owner

/datum/actionholder/proc/Action()
	return 1

/datum/actionholder/proc/CheckPreconditions()
	return list()

/datum/actionholder/proc/GetPreconditions()
	return src.preconds ? src.preconds.Copy() : null

/datum/actionholder/proc/GetEffects(var/list/old_state)
	var/list/new_state = src.effects
	new_state = new_state ? new_state.Copy() : list()
	if(old_state)
		for(var/key in old_state)
			var/oldval = old_state[key]
			var/newval = src.effects[key]
			new_state[key] = isnull(newval) ? oldval : newval
	return new_state

/datum/actionholder/proc/IsDone()
	return 1

/datum/PlanHolder
	var/list/queue = list()
	var/cost = null

/datum/PlanHolder/New(var/plancost, var/list/actions)
	..()
	src.cost = plancost
	if(actions)
		for(var/datum/actionholder/A in actions)
			src.queue.Add(A)

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