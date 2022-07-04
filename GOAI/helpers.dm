
/proc/floor(x)
	return round(x)

/proc/ceil(x)
	return -round(-x)


/proc/greater_than(var/left, var/right)
	var/result = left > right
	//world << "GT: [result], L: [left], R: [right]"
	return result


/proc/greater_or_equal_than(var/left, var/right)
	var/result = left >= right
	//world << "GT: [result], L: [left], R: [right]"
	return result

/proc/dir2name(var/dir)
	var/qry = "[dir]"

	var/list/lookup = list(
		"1" = "NORTH",
		"2" = "SOUTH",
		"4" = "EAST",
		"8" = "WEST",
		"5" = "NORTHEAST",
		"9" = "NORTHWEST",
		"6" = "SOUTHEAST",
		"10" = "SOUTHWEST",
		"16" = "UP",
		"32" = "DOWN"
	)

	var/result = lookup[qry]
	return result