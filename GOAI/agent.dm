/mob/goai
	var/life = 1
	icon = 'icons/mob/human_races/r_human.dmi'
	icon_state = "preview"
	var/list/needs
	var/list/inventory
	var/list/actionslist
	var/list/mobstatuslist
	var/datum/PlanHolder/active_plan
	var/obj/actionholder/active_action

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
		if(active_action) //ready to go
			DoAction(active_action)
		else if(active_plan)
			if(active_plan.queque.len) //step done, move on to the next
				active_action = pop(active_plan.queque)
		else if(needs.len) //no plan & need to make one
			var/need = pick(needs)
			Mastermind(need, src)
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

//BEGIN GOAP CORE: Build a tree of actions depth-first, take valids and A* through lowest cost path to action accomplishing the goal

/datum/PlanHolder
	var/list/queque = list()

/datum/PlanHolder/New()
	..()
	var/obj/actionholder/A
	for(A in args)
		queque.Add(A)

/proc/Mastermind(var/goal, var/mob/goai/actor)
	//Get plans
	var/options = GetPlans(goal, actor)
	//Evaluate plans
	var/datum/PlanHolder/plan = EvalPlans(options)
	//Execute if found
	if(plan)
		actor.active_plan = plan

/proc/GetPlans(var/Goal, var/mob/goai/actor, var/list/parent = null)
//returns a list of datums holding queques of actions meeting the Goal the Actor can perform
	if(!(actor))
		return

	//if(!(mobactions || mobactions.len))
	var/list/mobactions = actor.actionslist //a local copy of the mob's list - so we can remove actions from the tally
	var/obj/actionholder/action
	var/list/masterlist = list() //holds data containing queques of actions for evaluation


	//first, let's see if any of our actions can do what we want
	if(!(mobactions.len))
		return

	for(action in mobactions) //cycle through all actions the mob has

		var/list/currentplan = list() //holds an action queque
		if(parent)
			currentplan = parent //higher-level queque is inherited and branched out
		var/list/Effects = action.GetEffects()

		if(Goal in Effects) //prune branches for aimless actions

			//now, let's see if we can actually do it
			var/list/Requirements = action.GetPreconditions() //TODO: Make this a list, see above

			if(Goal in Requirements) //prevents infinite loops
				continue

			var/allclear = 1
			if(Requirements.len)
				for(var/Requirement in Requirements)
					if(!(Requirement in actor.mobstatuslist)) //reqs met, good to go
						allclear = 0
			if(allclear)
				currentplan += action
				var/packagedplan = new /datum/PlanHolder(arglist(currentplan))
				masterlist += packagedplan
			else //we can't do it just now, but we might if we do stuff first...
				var/subbranch = GetPlans(Goal, actor, currentplan) //we need to go deeper!
				for(var/datum/PlanHolder/P in subbranch)
					var/subbranchplan = currentplan + P.queque //if there's more than 1 path available, return all
					var/packagedplan = new /datum/PlanHolder(arglist(subbranchplan))
					masterlist += packagedplan
	return masterlist

	//now, we have all our workable solutions tallied up
	//time to check which one suits our purposes best

/proc/EvalPlans(var/list/plans)
	var/minimal = 0 //index of least-cost plan
	var/best_cost = 1.#INF //least cost found
	var/current_index = 0
	for(var/datum/PlanHolder/PH in plans)
		current_index++
		var/cost = 0
		for(var/obj/actionholder/AH in PH)
			cost += AH.cost
		if(cost < best_cost)
			minimal = current_index
	if(minimal)
		return plans[minimal]
	return