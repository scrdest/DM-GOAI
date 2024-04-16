/datum/utility_ai
	var/name = "utility AI"
	var/life = TRUE
	var/paused = FALSE

	var/list/needs

	// Associated Brain
	var/datum/brain/utility/brain

	// Unlike mob commanders, factions don't have a natural 'self' SmartObject source.
	// Instead, we give them a bunch of actionsets here, as appropriate for their type.
	// Note this isn't used directly; we'll use this attribute to define this datum as a SmartObject.
	var/list/innate_actions_filepaths = null

	var/list/senses // array, primary DS for senses
	var/list/senses_index // assoc, used for quick lookups/access only

	// Private-ish, generally only debug procs should touch these
	var/base_ai_tick_delay = UTILITYAI_AI_TICK_DELAY // this is the base value, should
	var/ai_tick_delay = UTILITYAI_AI_TICK_DELAY // this is the actually used sleep; == base_ai_tick_delay + rand()
	var/senses_tick_delay = COMBATAI_SENSE_TICK_DELAY

	// what time to wake the AI up for the next tick
	var/waketime = 0

	var/registry_index

	// Optional - for map editor. Set this to force initial action. Must be valid (in available actions).
	var/initial_action = null

	// Dynamically attached junk
	var/dict/attachments

	// These two are, by and large, relics of earlier code and are, practically speaking, DEPRECATED!
	var/list/actionslist
	var/list/actionlookup


/datum/utility_ai/proc/InitActionLookup()
	/* Largely redundant; initializes handlers, but
	// InitActions should generally use AddAction
	// with a handler arg to register them.
	// Mostly a relic of past design iterations.
	*/
	var/list/new_actionlookup = list()
	return new_actionlookup


/datum/utility_ai/proc/InitActionsList()
	// DEPRECATED
	var/list/new_actionslist = list()
	return new_actionslist


/datum/utility_ai/proc/InitNeeds()
	// Allows overwriting the Brain's needs with AI's own.
	src.needs = list()

	if(!(src.brain))
		return src.needs

	var/list/needs = src.brain.needs

	if(isnull(needs) || !istype(needs))
		needs = list()

	src.brain.needs = needs

	return src.needs


/datum/utility_ai/proc/InitRelations()
	// Allows overwriting the Brain's relations with AI's own.
	if(!(src.brain))
		return

	var/datum/relationships/relations = src.brain.relations
	if(isnull(relations) || !istype(relations))
		relations = new()

	src.brain.relations = relations
	return relations


/datum/utility_ai/proc/PreSetupHook()
	return


/datum/utility_ai/New(var/active = null)
	..()

	/*
	// Controls whether to call Life(), effectively activating the AI logic.
	//
	// You might want to have it disabled if you want to manage the AI 'lifecycle'
	// manually. For example, have the AI only activate when a player first moves
	// nearby.
	*/
	var/true_active = (isnull(active) ? TRUE : active)

	//var/spawn_time = world.time
	//src.last_update_time = spawn_time
	src.attachments = new()
	src.actionlookup = src.InitActionLookup()  // order matters!
	src.actionslist = src.InitActionsList()

	//src.PreSetupHook()
	src.RegisterAI()

	src.brain = src.CreateBrain()
	src.InitNeeds()
	src.InitRelations()
	src.InitSenses()
	src.UpdateBrain()

	//src.PostSetupHook()

	if(true_active)
		src.Life()


/datum/utility_ai/proc/CleanDelete()
	src.life = FALSE

	var/datum/brain/mybrain = src.brain
	if(mybrain && istype(mybrain))
		mybrain.CleanDelete()

	deregister_ai(src.registry_index)
	return TRUE


# ifdef GOAI_SS13_SUPPORT
/datum/utility_ai/Destroy()
	src.CleanDelete()
	. = ..()
	return
# endif


/datum/utility_ai/proc/ShouldCleanup()
	// purely logical, doesn't DO the cleanup
	return FALSE


/datum/utility_ai/proc/CheckForCleanup()
	// purely application, runs ShouldCleanup() and handles state as needed
	// this is just an abstract method for overrides to plug into though
	return FALSE


/datum/utility_ai/proc/LifeTick()
	return TRUE


/datum/utility_ai/proc/Life()
	// LifeTick WOULD be called here (in a loop) like so...:
	/*
		spawn(0)
			while(src.life)
				src.CheckForCleanup()
				src.LifeTick()
	*/
	// ...except this would just spin its wheels here, and children
	//    will need to override this anyway to add additional systems
	return TRUE


