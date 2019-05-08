/proc/pop(list/listfrom)
	if (listfrom.len > 0)
		var/picked = listfrom[listfrom.len]
		listfrom.len--
		return picked
	return null

/proc/all_in(var/list/haystack, var/list/needles)
	if(!(needles && haystack))
		return 0
	for(var/item in needles)
		if(!(item in haystack))
			return 0
	return 1

/proc/any_in(var/list/haystack, var/list/needles)
	if(haystack)
		if(!needles)
			return 0
		for(var/n in needles)
			if(n in haystack)
				return 1
	return null

/proc/left_disjoint(var/list/haystack, /var/list/needles)
	if(!haystack)
		return needles
	var/list/disjoint = list()
	for(var/i in needles)
		if(!(i in haystack))
			disjoint += i
	return disjoint
