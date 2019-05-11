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
		src << "[target.name] - [target.life]"

/mob/goai/agent
	var/datum/need
	var/tiredness = 100
	var/hunger = 100

/mob/goai/New()
	..()
	Life()

/mob/goai/proc/Life()
	return 1

/mob/goai/agent/Life()
	var/list/status = src.mobstatuslist
	if(!status)
		status = list()
		src.mobstatuslist = status

	while(src.life)
		if(src.tiredness < 50 && !("Tired" in src.mobstatuslist))
			world << "[src.name] *yawn*"
			status.Add("Tired")
		if(src.hunger < 50 && !("Hungry" in src.mobstatuslist))
			world << "[src.name] *rumble*"
			status.Add("Hungry")
		TirednessDecay()
		HungerDecay()

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

