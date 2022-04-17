var/global/list/mob_actions = list(
	"Eat" = new /datum/Triple (10, list("HasFood" = 1), list("Hunger" = 40, "HasFood" = -1)),
	"Shop" = new /datum/Triple (10, list("Money" = 10), list("HasFood" = 1, "Money" = -10)),
	"Party" = new /datum/Triple (10, list("Money" = 11), list("Rested" = 15, "Money" = -11, "Fun" = 40)),
	"Sleep" = new /datum/Triple (10, list("Hunger" = 30), list("Rested" = 50)),
	//"DishWash" = new /datum/Triple (10, list("HasDirtyDishes" = 1), list("HasDirtyDishes" = -1, "HasCleanDishes" = 1)),
	"Work" = new /datum/Triple (10, list("Rested" = 1), list("Money" = 10)),
	"Idle" = new /datum/Triple (10, list(), list("Rested" = 5))
)

/mob/goai
	var/life = 1
	icon = 'icons/mob/human_races/r_human.dmi'
	icon_state = "preview"
	var/list/needs
	var/list/inventory
	var/list/actionslist
	var/list/mobstatuslist
	var/datum/PlanHolder/active_plan
	var/datum/actionholder/active_action


/mob/verb/InspectGoaiLife()
	var/list/targetlist = typesof(/mob/goai in world)
	for(var/i=1,i<=targetlist.len,i++)
		var/mob/goai/target = targetlist[i]
		usr << "[target.name] - [target.life]"


/mob/goai/agent
	var/tiredness = 100
	var/hunger = 100


/mob/goai/New()
	..()
	Life()


/mob/goai/proc/Life()
	return 1


/mob/goai/agent/proc/DoPlan()

	return 1


/mob/goai/agent/Life()
	var/list/status = src.mobstatuslist
	if(!status)
		status = list()
		src.mobstatuslist = status

	while(src.life)

		if(src.tiredness < 50 && prob(10))
			world << "[src.name] *yawn*"

		if(src.hunger < 50 && prob(10))
			world << "[src.name] *rumble*"

		TirednessDecay()
		HungerDecay()

		src.needs["Sleep"] = src.tiredness
		src.needs["Hunger"] = src.hunger

		if(active_action) //ready to go
			DoAction(active_action)

		else if(active_plan)
			if(active_plan.queue.len) //step done, move on to the next
				active_action = pop(active_plan.queue)

		else if(needs && needs.len) //no plan & need to make one
			var/need = pick(needs)


		else //satisfied, can be lazy
			Idle()

		sleep(10)


/mob/goai/agent/Move()
	..()
	src.tiredness--


/mob/goai/agent/proc/Idle() //make this an action later!
	if(prob(10))
		var/moving_to = 0 // otherwise it always picks 4, fuck if I know.   Did I mention fuck BYOND
		moving_to = pick(SOUTH, NORTH, WEST, EAST)
		dir = moving_to			//How about we turn them the direction they are moving, yay.
		Move(get_step(src,moving_to))


/mob/goai/agent/proc/TirednessDecay()
	if(src.tiredness >= 0)
		src.tiredness -= 1
	else
		src.tiredness = 0


/mob/goai/agent/proc/HungerDecay()
	if(src.hunger >= 0)
		src.hunger -= 1
	else
		src.hunger = 0


/mob/goai/agent/proc/GetHunger()
	var/howhungry = src.hunger
	return howhungry


/mob/goai/agent/proc/GetTiredness()
	var/howtired = src.tiredness
	return howtired


/mob/goai/agent/verb/DoAction(Act as obj in actionslist)
	if(istype(Act,/datum/actionholder))
		var/datum/actionholder/WhatDo = Act
		WhatDo.Action()
		return 1
	else
		return 0


/mob/goai/agent/proc/Has(What as obj)
	if(What in src.inventory)
		return 1
	else
		return 0


/mob/goai/agent/proc/HasType(What as obj)
	if(typesof(What) in src.inventory)
		return 1
	else
		return 0

