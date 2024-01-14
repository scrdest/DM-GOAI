

/atom
	var/list/worldstate = null


/atom/proc/SetWorldstate(var/key, var/val)
	if(isnull(src.worldstate))
		src.worldstate = list()

	src.worldstate[key] = val
	return src


/atom/proc/GetWorldstate(var/key, var/default = null)
	if(isnull(src.worldstate))
		src.worldstate = list()

	var/val = src.worldstate[key]

	if(isnull(val))
		return default

	return val

