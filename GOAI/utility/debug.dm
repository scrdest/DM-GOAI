
/mob/verb/SetGlobalUtilityAiRate(var/rate as num)
	set category = "Debug Utility AI"

	if(rate <= 0)
		return

	for(var/datum/utility_ai/ai in GOAI_LIBBED_GLOB_ATTR(global_goai_registry))
		ai.ai_tick_delay = max(1, rate)

	to_chat(usr, "Set global Utility AI tickrate to [rate]")
	return
