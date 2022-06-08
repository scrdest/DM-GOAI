
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
