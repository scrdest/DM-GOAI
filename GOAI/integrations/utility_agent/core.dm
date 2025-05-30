/datum/utility_ai
	var/name = "utility AI"
	var/life = TRUE
	var/paused = FALSE

	// Pawn - an AI-controlled entity.
	// This can be a mob/atom, a faction datum, a squad wrapper datum for multiple mobs/atoms, etc.
	// Note this can also be left blank if you want a purely abstract AI.
	# ifdef GOAI_LIBRARY_FEATURES
	var/datum/pawn
	# endif

	# ifdef GOAI_SS13_SUPPORT
	var/weakref/pawn
	# endif

	// If TRUE, calls src.InitPawn(), skips if FALSE
	// Set to FALSE as an optimization to skip an unnecessary call
	// or to defer the Pawn initializer until later (e.g. for spawners, which might customize some vars first).
	//
	// NOTE: if you wish to defer it, it's on *YOU* as the user to call <ai_instance>.InitPawn() later!
	var/initialize_pawn = TRUE

	// If TRUE, calls src.InitRelations(), skips if FALSE
	// Set to FALSE as an optimization to skip an unnecessary call
	// or to defer the initializer until later (e.g. for spawners, which might customize some vars first).
	//
	// NOTE: if you wish to defer it, it's on *YOU* as the user to call <ai_instance>.InitRelations() later!
	var/initialize_relations = TRUE

	// Associated Brain
	// Brains are a datastructure for AI-adjacent information like memories, perceptions, needs, etc.
	var/datum/brain/utility/brain = null

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

	// What time to wake the AI up for the next tick
	var/waketime = 0

	// Default value for the no_cache args when reading data from JSON.
	// If TRUE, will re-read the files every time (slower, but allows editing in real-time).
	// If FALSE, will read each file once and store it forever globally (unless someone else forces a refresh); fast, should be the default.
	var/disable_so_cache = FALSE

	var/registry_index

	// Optional - for map editor. Set this to force initial action. Must be valid (in available actions).
	var/initial_action = null

	#ifndef GOAI_USE_GENERIC_DATUM_ATTACHMENTS_SYSTEM
	/* Dynamically attached junk */
	var/dict/attachments
	#endif


/datum/utility_ai/proc/InitRelations()
	// Allows overwriting the Brain's relations with AI's own.
	if(!(src.brain))
		return

	var/datum/relationships/relations = src.brain.relations
	if(!istype(relations))
		relations = new()

	src.brain.relations = relations
	return relations


/datum/utility_ai/proc/InitPawn()
	// Allows subclasses to specify how/whether to create a Pawn
	return


/datum/utility_ai/proc/PreSetupHook()
	// Hook. Allows subclasses to add any arbitrary pre-init logic.
	// As a matter of API contract, hooks should never override (always do '..()'!)
	return


/datum/utility_ai/proc/PostSetupHook()
	// Hook. Allows subclasses to add any arbitrary post-init logic, just before Life()
	// As a matter of API contract, hooks should never override (always do '..()'!)
	return


/datum/utility_ai/New(var/active = null, var/init_pawn = null, var/init_relations = null)
	..()

	/*
	// Controls whether to call Life(), effectively activating the AI logic.
	//
	// You might want to have it disabled if you want to manage the AI 'lifecycle'
	// manually. For example, have the AI only activate when a player first moves
	// nearby.
	*/
	SET_IF_NOT_NULL(init_pawn, src.initialize_pawn)
	SET_IF_NOT_NULL(init_relations, src.initialize_relations)
	var/true_active = (isnull(active) ? TRUE : active)

	//var/spawn_time = world.time
	//src.last_update_time = spawn_time
	src.attachments = new()

	src.PreSetupHook()
	src.RegisterAI()

	src.brain = src.CreateBrain()

	if(src.initialize_pawn)
		src.InitPawn()

	if(src.initialize_relations)
		src.InitRelations()

	src.InitSenses()
	src.UpdateBrain()

	src.PostSetupHook()

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


/datum/utility_ai/proc/GetPawn()
	var/datum/mypawn = null
	mypawn = (mypawn || RESOLVE_PAWN(src.pawn))
	return mypawn



/datum/utility_ai/proc/RegisterLifeSystems()
	// Adds any number of subsystems.
	// Subclasses should ..() this.
	// Each subsystem should be spawn(0)'d off to fork/background them.

	#ifdef UTILITY_SMARTOBJECT_SENSES
	// Perception updates
	spawn(0)
		while(src.life)
			src.SensesSystem()
			sleep(src.senses_tick_delay)
	#endif

	return


/datum/utility_ai/proc/Life()
	src.RegisterLifeSystems()

	// AI
	spawn(0)
		while(src.life)
			var/cleaned_up = src.CheckForCleanup()
			if(cleaned_up)
				return

			if(!src.paused)
				// Run the Life update function.
				src.LifeTick()

			// Fix the tickrate to prevent runaway loops in case something messes with it.
			// Doing it here is nice, because it saves us from sanitizing it all over the place.
			src.ai_tick_delay = max(WITH_UTILITY_SLEEPTIME_STAGGER(src?.base_ai_tick_delay || 0), MIN_AI_SLEEPTIME)
			var/sleeptime = min(MAX_AI_SLEEPTIME, src.ai_tick_delay)

			src.waketime = (world.time + src.ai_tick_delay)

			// Wait until the next update tick.
			while(world.time < src.waketime)
				sleep(sleeptime)
