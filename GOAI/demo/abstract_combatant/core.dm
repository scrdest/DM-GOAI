/* In this module:
===================

 - AI Mainloop (Life()/LifeTick())
 - Init for subsystems per AI (by extension - it's in Life())

*/

# define STEP_SIZE 1
# define STEP_COUNT 1


/datum/goai
	var/life = GOAI_AI_ENABLED

	var/list/needs
	var/list/states
	var/list/actionslist
	var/list/actionlookup
	var/list/inventory
	var/list/senses

	var/list/last_need_update_times
	var/last_action_update_time

	var/planning_iter_cutoff = 30
	var/pathing_dist_cutoff = 60

	var/datum/brain/brain

	// Private-ish, generally only debug procs should touch these
	var/ai_tick_delay = COMBATAI_AI_TICK_DELAY

	// Optional - for map editor. Set this to force initial action. Must be valid (in available actions).
	var/initial_action = null



/datum/goai/proc/LifeTick()
	return TRUE



/datum/goai/proc/Life()
	// LifeTick WOULD be called here (in a loop) like so...:
	/*
		spawn(0)
			while(src.life)
				src.LifeTick()
	*/
	// ...except this would just spin its wheels here, and children
	//    will need to override this anyway to add additional systems
	return TRUE


/datum/goai/proc/SetState(var/key, var/val)
	if(!key)
		return

	world.log << "[src]: setting state [key] => [val] on the mob!"
	states[key] = val

	if(brain)
		brain.SetState(key, val)

	return TRUE


/datum/goai/proc/GetState(var/key, var/default = null)
	if(!key)
		world.log << "[src]: [key] is null!"
		return

	if(brain && (key in brain.states))
		return brain.GetState(key, default)

	if(key in states)
		return states[key]

	return default
