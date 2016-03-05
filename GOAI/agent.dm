/mob/goai
	var/life = 1
	icon = 'icons/mob/human_races/r_human.dmi'
	icon_state = "preview"
	var/list/needs
	var/list/inventory
	var/list/actionslist
	var/list/mobstatuslist

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

	while(src.life)
		if(src.tiredness < 50 && !("Tired" in src.mobstatuslist))
			world << "[src.name] *yawn*"
			src.mobstatuslist.Add("Tired")
		if(src.hunger < 50 && !("Hungry" in src.mobstatuslist))
			world << "[src.name] *rumble*"
			src.mobstatuslist.Add("Hungry")
		TirednessDecay()
		HungerDecay()
		Idle()
		PlanActions()
		sleep(10)

/mob/goai/agent/Move()
	..()
	src.tiredness--

/mob/goai/agent/proc/Idle()
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

/mob/goai/agent/proc/GainAction(var/obj/actionholder/target)
	if(istype(target, /obj/actionholder))
		var/obj/actionholder/trg = New(target)
		trg.owner = src
		trg.loc = src.loc
		src.actionslist += trg

/mob/goai/agent/verb/DoAction(Act as obj in actionslist)
	if(istype(Act,/obj/actionholder))
		var/obj/actionholder/WhatDo = Act
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

/obj/actionholder
	name = "Do stuff"
	var/cost = 9999
	var/mob/goai/agent/owner

/obj/actionholder/proc/Action()
	return 1

/obj/actionholder/proc/CheckPreconditions()
	return 1

/obj/actionholder/proc/GetPreconditions()
	return

/obj/actionholder/proc/GetEffects()
	return 1

/obj/actionholder/proc/IsDone()
	return 1

//BEGIN GOAP CORE: Build a tree of actions, take valids and A* through lowest cost path to action accomplishing the goal

/datum/PlanHolder
	var/list/plan = list()

/datum/PlanHolder/New()
	..()
	var/obj/actionholder/A
	for(A in args)
		plan.Add(A)

/proc/PlanActions(var/Goal as num, var/mob/goai/actor, var/obj/actionholder/callingaction)

	if(!istype(actor))
		return

	var/list/mobactions = actor.actionslist //a copy of the mob's list - so we can remove actions from the tally
	var/obj/actionholder/allactions
	var/list/plans = list() //holds data containing strings of actions for evaluation
	var/list/goodactions = list()


	//first, let's see if any of our actions can do what we want
	if(!(mobactions.len))
		return

	for(allactions in mobactions) //cycle through all actions the mob has

		var/plan
		var/obj/actionholder/A = allactions
		var/Effect = A.GetEffects() //look at its effects //TODO: Make this a list

		if(Effect == Goal) //prune branches for aimless actions

			//now, let's see if we can actually do it
			var/Requirement = A.GetPreconditions() //TODO: Make this a list

			if(Requirement == Goal) //prevents infinite loops
				continue

			if((Requirement in actor.mobstatuslist)||(!(Requirement)))
				goodactions.Add(A) //Yay, we can! //Finalize this branch as valid for further consideration!

			else //we can't do it just now, but we might be able to do stuff to make it possible...
				var/subbranchplan = (PlanActions(Requirement, actor, A)) //Build subbranches same way
				if(!subbranchplan) //No valid solution found, kill this branch
					continue
				else //Found a solution a level below
					for(var/datum/PlanHolder/PH in subbranchplan)
						for(var/obj/actionholder/AH in PH.plan)
							goodactions.Add(AH) //nope, will mix solutions

			if(istype(callingaction))
				goodactions.Add(callingaction) //only used by subbranches - automatically add the parent to each valid child

			plan = new /datum/PlanHolder(arglist(goodactions))
			plans.Add(plan)

		else
			continue //doing that won't accomplish the goal, keep going
	return plans


	//now, we have all our workable solutions tallied up
	//time to check which one suits our purposes best

