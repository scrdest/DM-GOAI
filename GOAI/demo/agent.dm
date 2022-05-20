# define STEP_SIZE 1
# define STEP_COUNT 1


/mob/goai
	var/life = 1
	icon = 'icons/mob/human_races/r_human.dmi'
	icon_state = "preview"
	var/list/needs
	var/list/states
	var/list/actionslist
	var/list/inventory

	var/datum/ActivePathTracker/active_path

	var/is_repathing = 0
	var/is_moving = 0

	var/list/last_need_update_times
	var/last_mob_update_time
	var/last_action_update_time

	var/planning_iter_cutoff = 30
	var/pathing_dist_cutoff = 60

	var/datum/brain/brain


/mob/goai/verb/Posess()
	set src in view()

	if(!(usr && usr.client))
		return

	if(usr.loc == src)
		usr.loc = src.loc
		return

	usr.loc = src

	return


/mob/goai/proc/GetActionsList()
	var/list/new_actionslist = list()
	return new_actionslist


/mob/goai/proc/CreateBrain(var/list/custom_actionslist = null)
	var/list/new_actionslist = (custom_actionslist ? custom_actionslist : actionslist)
	var/datum/brain/new_brain = new /datum/brain(new_actionslist)
	new_brain.states = states.Copy()
	return new_brain


/mob/goai/New()
	..()

	InitNeeds()
	InitStates()

	UpdateBrain()

	var/spawn_time = world.time
	last_mob_update_time = spawn_time
	actionslist = GetActionsList()

	var/datum/brain/new_brain = CreateBrain(actionslist)
	brain = new_brain

	Life()


/mob/goai/proc/InitNeeds()
	needs = list()
	return needs


/mob/goai/proc/InitStates()
	states = list()
	return states


/mob/goai/proc/UpdateBrain()
	if(!brain)
		return

	brain.needs = needs.Copy()
	brain.states = states.Copy()

	return TRUE


/mob/goai/proc/Life()
	return 1


/mob/goai/proc/SetState(var/key, var/val)
	if(!key)
		return

	states[key] = val

	if(brain)
		brain.states[key] = val

	return 1


/mob/goai/proc/GetState(var/key, var/default = null)
	if(!key)
		return

	if(brain && (key in brain.states))
		return brain.states[key]

	if(key in states)
		return states[key]

	return default


/mob/goai/verb/Say(words as text)
	world << "([name]) says: '[words]'"

