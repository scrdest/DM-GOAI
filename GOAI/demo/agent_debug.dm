
/mob/goai/verb/RebootGoai()
	set src in view(1)

	LobotomizeGoai()

	sleep(0)
	life = 1

	var/datum/brain/new_brain = CreateBrain()
	brain = new_brain

	return


/mob/goai/verb/LobotomizeGoai()
	set src in view(1)

	life = 0

	if(brain)
		brain.life = 0
		brain.active_plan = null
		brain.selected_action = null

		if(brain.running_action_tracker)
			brain.running_action_tracker.SetFailed()

		if(brain.running_action_tracker)
			brain.running_action_tracker = null

		del(brain)

	return


/mob/goai/verb/InspectAgentVars()
	set src in view(1)

	usr << "#============================================#"
	usr << "|              GOAI AGENT: [src]              "

	for(var/V in src.vars)
		usr << "| - [V] = [src.vars[V]]"

	usr << "#============================================#"

	return



/mob/goai/verb/InspectAgentNeeds()
	set src in view(1)

	usr << "#============================================#"
	usr << "|              GOAI AGENT: [src]              "

	for(var/N in src.needs)
		usr << "| - [N] = [src.needs[N]]"

	usr << "#============================================#"

	return



/mob/goai/verb/InspectAgentState()
	set src in view(1)

	usr << "#============================================#"
	usr << "|              GOAI AGENT: [src]              "

	for(var/S in src.states)
		usr << "| - [S] = [src.states[S]]"

	usr << "#============================================#"

	return


/mob/goai/verb/InspectAgentActions()
	set src in view(1)

	usr << "#============================================#"
	usr << "|              GOAI AGENT: [src]              "

	for(var/A in src.actionslist)
		usr << "| - [A] = [src.actionslist[A]?.charges]"

	usr << "#============================================#"

	return