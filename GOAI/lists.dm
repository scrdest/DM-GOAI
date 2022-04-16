/*
 * Holds procs to help with list operations
 * Contains groups:
 *			Misc
 *			Sorting
 */

/*
 * Shamelessly ripped from SS13 code.
 */


// Return the index using dichotomic search
/proc/FindElementIndex(var/A, list/L, cmp)
	var/i = 1
	var/j = L.len
	var/mid

	while(i < j)
		mid = round((i+j)/2)

		if(call(cmp)(L[mid],A) < 0)
			i = mid + 1
		else
			j = mid

	if(i == 1 || i ==  L.len) // Edge cases
		return (call(cmp)(L[i],A) > 0) ? i : i+1
	else
		return i

