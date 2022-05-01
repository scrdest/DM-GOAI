
/mob/goai/agent/verb/RebootGoai()
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

	sleep(AI_TICK_DELAY + AI_TICK_DELAY)
	life = 1

	var/datum/brain/sim/new_brain = CreateBrain()
	brain = new_brain

	Life()

	return