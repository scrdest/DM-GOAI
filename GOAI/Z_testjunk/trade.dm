#warn DEBUG MODULE INCLUDED!

/mob/verb/ShowMarket()
	var/msg = "Marketplace - current state is: [json_encode(GOAI_LIBBED_GLOB_ATTR(global_marketplace))]"
	to_world_log(msg)
	to_chat(usr, msg)
	return
