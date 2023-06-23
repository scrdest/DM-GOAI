/mob/verb/EnableDebug()
	set category = "Debug"
	src.verbs.Add(/client/proc/debug_variables)
	to_chat(usr, "[src] now wields the ultimate powah!")
	return
