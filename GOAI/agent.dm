#define RECURSION_DEPTH_SENTINEL 20

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

/mob/goai/agent/proc/GainAction(var/datum/actionholder/target)
	if(istype(target, /datum/actionholder))
		var/datum/actionholder/trg = New(target)
		trg.owner = src
		trg.loc = src.loc
		src.actionslist += trg

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

/datum/actionholder
	var/name = "Do stuff"
	var/cost = 9999
	var/list/effects
	var/list/preconds
	var/loc = null
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

//BEGIN GOAP CORE: Build a tree of actions depth-first, take valids and A* through lowest cost path to action accomplishing the goal

/datum/PlanHolder
	var/list/queue = list()
	var/cost = null

/datum/PlanHolder/New(var/plancost, var/list/actions)
	..()
	src.cost = plancost
	if(actions)
		for(var/datum/actionholder/A in actions)
			src.queue.Add(A)

/proc/EvaluateStepTo(var/list/goals, var/list/actionspace, var/list/state)
	// Score all actions wrt an immediate followup state and a heuristic.
	//
	// e.g. if the final goal is to get from state A -> state C on a path A->B->C,
	// calculate the score for all the actions leading from A->B, or from B->C
	//
	// * var/list/goals - the desired state to transition to.
	// * var/list/actionspace - a list of Action datums available in the current state
	// ===> returns an assoc list, (action=score);

	if(!actionspace)
		return

	if(!state)
		state = list()

	var/list/queue = list()

	for(var/datum/actionholder/action in actionspace)
		var/list/Preconds = action.GetPreconditions()
		world.log << "[action.name] preconds: [Preconds ? Preconds.Join(", ") : "NONE!"]..."
		if(!(Preconds && Preconds.len) || (Preconds in state))
			var/cost = action.cost // refactorme!
			queue[action] = cost
	return queue

/proc/GetPlans(var/list/goals, var/list/actions, var/list/startstate, var/list/explored, var/recdepth=1)
	//returns a list of datums holding queues of actions meeting the Goals the Actor can perform
	world.log << "Goals: [goals ? goals.Join(" & ") : "None"]"

	if(!(actions && actions.len))
		return
	var/list/actionspace = actions.Copy() // may be redundant, but avoids accidental side-effects

	if(!(startstate))
		startstate = list()

	var/list/plan_queues = list() // assoc list, {planholder=cost}
	var/list/state = startstate.Copy()
	var/list/evaluated = explored ? explored.Copy() : list()
	actionspace.Remove(evaluated)


	var/sentinel = recdepth // terminates the loop cleanly
	if(sentinel < RECURSION_DEPTH_SENTINEL && !(all_in(state, goals)))
		sleep(-1)

		// Immediately available steps meeting the goal
		var/list/subqueue = EvaluateStepTo(goals, actionspace)
		if(subqueue && subqueue.len)
			for(var/datum/actionholder/immediateAct in subqueue)

				var/list/immediateActEffects = immediateAct.GetEffects()

				if(!(immediateActEffects && immediateActEffects.len))
					continue

				if (all_in(immediateActEffects, goals))
					var/datum/PlanHolder/newplan = new(subqueue[immediateAct], list(immediateAct))
					world.log << "Appending plan [newplan.queue.Join(" -> ")] @ [newplan.cost]"
					plan_queues[newplan] = newplan.cost
					evaluated += immediateAct

		// Actions that require other steps to be taken first
		for(var/datum/actionholder/intermedAct in actionspace)
			if(intermedAct in evaluated)
				continue // we know about them already

			var/list/intermedState = intermedAct.GetEffects()
			if(!intermedState)
				continue

			if(all_in(intermedState, goals))
				var/list/requirements = intermedAct.GetPreconditions() || list()

				var/loopy = 0
				for(var/Goal in goals)
					if(Goal in requirements)
						loopy = 1
				if(loopy)
					continue

				var/list/unmet = list()

				for(var/req in requirements)
					if(req in state)
						continue
					unmet += req

				if(!isnull(unmet) && unmet.len)
					world.log << "Unmet: [unmet.Join(";")]"
					var/list/subplans = GetPlans(unmet, actionspace, state, evaluated, recdepth+1) || list()

					for(var/datum/PlanHolder/p in subplans)
						var/subcost = subplans[p] + intermedAct.cost
						var/list/intermeds = p.queue
						var/datum/PlanHolder/fullplan = new(subplans[p], intermeds + list(intermedAct))
						if(fullplan && !isnull(subcost))
							if(recdepth <= 1)
								world.log << "Appending plan [fullplan.queue.Join(" -> ")] @ [subcost]"
							plan_queues[fullplan] = subcost
	return plan_queues

