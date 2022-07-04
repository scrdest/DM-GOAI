/datum/brain
	var/name = "brain"
	var/life = 1
	var/list/needs
	var/list/states
	var/list/actionslist
	var/list/active_plan
	var/dict/memories


	var/is_planning = 0
	var/selected_action = null
	var/datum/ActionTracker/running_action_tracker = null

	var/list/last_need_update_times
	var/last_mob_update_time
	var/last_action_update_time
	var/planning_iter_cutoff = 30

	var/datum/GOAP/planner


/datum/brain/New(var/list/actions = null, var/list/init_memories = null, var/init_action = null)
	..()

	if(actions)
		actionslist = actions.Copy()

	if(init_action && init_action in actionslist)
		running_action_tracker = DoAction(init_action)

	memories = new /dict(init_memories)

	InitNeeds()
	InitStates()

	return


/datum/brain/proc/HasMemory(var/mem_key)
	var/found = (mem_key in memories.data)
	//world.log << "Memory for key [mem_key] [found ? "TRUE" : "FALSE"]"
	return found


/datum/brain/proc/GetMemory(var/mem_key, var/default = null, by_age = FALSE)
	if(HasMemory(mem_key))
		var/datum/memory/retrieved_mem = memories.Get(mem_key, null)

		if(isnull(retrieved_mem))
			//world.log << "Retrieved default Memory for removed [mem_key]"
			return default

		var/relevant_age = by_age ? retrieved_mem.GetAge() : retrieved_mem.GetFreshness()

		if(relevant_age < retrieved_mem.ttl)
			//world.log << "Retrieved Memory: [mem_key]"
			return retrieved_mem


		memories[mem_key] = null

	//world.log << "Retrieved default Memory for missing [mem_key]"
	return default


/datum/brain/proc/SetMemory(var/mem_key, var/mem_val, var/mem_ttl)
	var/datum/memory/retrieved_mem = memories.Get(mem_key)

	if(isnull(retrieved_mem))
		//world.log << "Inserting Memory for [mem_key] with [mem_val]"
		retrieved_mem = new(mem_val, mem_ttl)
		memories.Set(mem_key, retrieved_mem)

	else
		//world.log << "Updating Memory for [mem_key] with [mem_val]"
		retrieved_mem.Update(mem_val)

	return retrieved_mem


/datum/brain/proc/InitNeeds()
	needs = list()
	return needs


/datum/brain/proc/InitStates()
	states = list()
	return states


/datum/brain/proc/Life()
	/* Something like the commented-out block below *SHOULD* be here as it's a base class
	// but since this runs an infinite ticker loop, I didn't want to waste CPU cycles running
	// procs that just do a 'return' forever. May get restored later at some point if having
	// a solid ABC outweighs the risks.

	while(life)
		LifeTick()
		sleep(AI_TICK_DELAY)
	*/
	return


/datum/brain/proc/LifeTick()
	return


/datum/brain/concrete


/datum/brain/concrete/proc/CreatePlan(var/list/status, var/list/goal)
	is_planning = 1
	var/list/path = null

	var/list/params = list()
	// You don't have to pass args like this; this is just to make things a bit more readable.
	params["start"] = status
	params["goal"] = goal
	/* For functional API variant:
	params["graph"] = mob_actions
	params["adjacent"] = /proc/get_actions_agent
	params["check_preconds"] = /proc/check_preconds_agent
	params["goal_check"] = /proc/goal_checker_agent
	params["get_effects"] = /proc/get_effects_agent
	*/
	params["cutoff_iter"] = planning_iter_cutoff


	var/datum/Tuple/result = planner.Plan(arglist(params))

	if (result)
		path = result.right

	is_planning = 0
	return path


/datum/brain/concrete/Life()
	while(life)
		LifeTick()
		sleep(AI_TICK_DELAY)
	return


/datum/brain/concrete/proc/OnBeginLifeTick()
	return


/datum/brain/concrete/LifeTick()
	OnBeginLifeTick()

	if(running_action_tracker) // processing action
		var/running_is_active = running_action_tracker.IsRunning()
		world << "ACTIVE ACTION: [running_action_tracker.tracked_action] @ [running_is_active]"

		if(running_action_tracker.IsStopped())
			running_action_tracker = null

	else if(selected_action) // ready to go
		world << "SELECTED ACTION: [selected_action]"
		running_action_tracker = DoAction(selected_action)
		selected_action = null

	else if(active_plan && active_plan.len)
		world << "ACTIVE PLAN: [active_plan] ([active_plan.len])"
		if(active_plan.len) //step done, move on to the next
			selected_action = lpop(active_plan)

	else //no plan & need to make one
		var/list/curr_state = states.Copy()
		var/list/goal_state = list()

		for (var/need_key in needs)
			var/need_val = needs[need_key]
			curr_state[need_key] = need_val

			if (need_val < NEED_THRESHOLD)
				goal_state[need_key] = NEED_SAFELEVEL

			if (goal_state && goal_state.len && (!is_planning))
				//world.log << "Creating plan!"

				spawn(0)
					var/list/raw_active_plan = CreatePlan(curr_state, goal_state)

					if(raw_active_plan)
						//world.log << "Created plan [raw_active_plan]"
						var/first_clean_pos = 0

						for (var/planstep in raw_active_plan)
							first_clean_pos++
							if(planstep in actionslist)
								break

						raw_active_plan.Cut(0, first_clean_pos)
						active_plan = raw_active_plan

					else
						world.log << "Failed to create a plan"


			else //satisfied, can be lazy
				Idle()

	return


/datum/brain/verb/DoAction(Act as anything in actionslist)
	//world.log << "DoAction act: [Act]"

	if(!(Act in actionslist))
		return null

	var/datum/ActionTracker/new_actiontracker = new /datum/ActionTracker(Act)
	//world.log << "New Tracker: [new_actiontracker] [new_actiontracker.tracked_action] @ [new_actiontracker.creation_time]"
	running_action_tracker = new_actiontracker

	return new_actiontracker


/datum/brain/concrete/proc/Idle()
	return



/datum/brain/concrete/sim
	var/decay_per_dsecond = 0.1


/datum/brain/concrete/sim/New(var/list/actions)
	..()

	needs = list()
	needs[MOTIVE_SLEEP] = NEED_THRESHOLD
	needs[MOTIVE_FOOD] = NEED_THRESHOLD
	needs[MOTIVE_FUN] = NEED_THRESHOLD

	var/spawn_time = world.time
	last_need_update_times = list()
	last_mob_update_time = spawn_time
	last_action_update_time = spawn_time

	actionslist = actions

	var/datum/GOAP/demoGoap/new_planner = new /datum/GOAP/demoGoap(actionslist)
	planner = new_planner

	//Life()


/datum/brain/concrete/sim/proc/DecayNeeds()
	for (var/need_key in needs)
		MotiveDecay(need_key, null) // TODO: change this null to an assoc list lookup

	last_mob_update_time = world.time


/datum/brain/concrete/sim/OnBeginLifeTick()
	DecayNeeds()


/datum/brain/concrete/sim/proc/GetMotive(var/motive_key)
	if(isnull(motive_key))
		return

	if(!(motive_key in needs))
		return

	var/curr_value = needs[motive_key]
	return curr_value


/datum/brain/concrete/sim/proc/ChangeMotive(var/motive_key, var/value)
	if(isnull(motive_key))
		return

	var/fixed_value = min(NEED_MAXIMUM, max(NEED_MINIMUM, (value)))
	needs[motive_key] = fixed_value
	last_need_update_times[motive_key] = world.time
	world.log << "Curr [motive_key] = [needs[motive_key]]"


/datum/brain/concrete/sim/proc/AddMotive(var/motive_key, var/amt)
	if(isnull(motive_key))
		return

	var/curr_val = needs[motive_key]
	ChangeMotive(motive_key, curr_val + amt)


/datum/brain/concrete/sim/proc/MotiveDecay(var/motive_key, var/custom_decay_rate = null)
	var/now = world.time
	var/decay_rate = (isnull(custom_decay_rate) ? decay_per_dsecond : custom_decay_rate)

	if(!(motive_key in last_need_update_times))
		last_need_update_times[motive_key] = now

	var/last_update_time = last_need_update_times[motive_key]
	var/deltaT = (world.time - last_update_time)
	var/curr_value = needs[motive_key]
	var/cand_tiredness = curr_value - deltaT * decay_rate

	ChangeMotive(motive_key, cand_tiredness)
