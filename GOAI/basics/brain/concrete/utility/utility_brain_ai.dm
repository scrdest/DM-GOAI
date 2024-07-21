/*
// Things that help us get the AI handling this Brain (if any).
*/

/datum/brain/utility/GetAiController()
	var/datum/utility_ai/commander = null
	var/__commander_backref = src.attachments.Get(ATTACHMENT_CONTROLLER_BACKREF)

	# ifdef UTILITYBRAIN_LOG_CONTROLLER_LOOKUP
	UTILITYBRAIN_DEBUG_LOG("Backref is [__commander_backref] @ L[__LINE__] in [__FILE__] | <@[src]>")
	# endif

	if(IS_REGISTERED_AI(__commander_backref))
		commander = GOAI_LIBBED_GLOB_ATTR(global_goai_registry[__commander_backref])

	ASSERT(commander)
	return commander


/datum/brain/utility/proc/GetRequester() // () -> Any
	var/datum/utility_ai/mob_commander/controller = src.GetAiController()
	//var/pawn = controller?.GetPawn()
	//return pawn
	return controller
