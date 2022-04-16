/*
// ==   N-tuple types   ==
// Basically just a fixed-size list, not a Trve(TM) tuple, since it's mutable.
//
// Just helps ensure we get outputs of expected size at compile-time
// (of course with DM being DM, if they aren't, we just get a NULL, yey)
//
// This could be fairly trivially replaced with normal DM lists, but
// it's a bit more readable and I can't be bothered to refactor it.
*/

/datum/Tuple
	var/left = null
	var/right = null


/datum/Tuple/New(var/fst, var/snd)
	left = fst
	right = snd


/datum/Triple
	var/left = null
	var/middle = null
	var/right = null


/datum/Triple/New(var/new_left, var/new_mid, var/new_right)
	left = new_left
	middle = new_mid
	right = new_right


/datum/Quadruple
	var/first = null
	var/second = null
	var/third = null
	var/fourth = null


/datum/Quadruple/New(var/new_first, var/new_second, var/new_third, var/new_fourth)
	first = new_first
	second = new_second
	third = new_third
	fourth = new_fourth



/datum/Quadruple/proc/QuadCompare(var/datum/Quadruple/left, var/datum/Quadruple/right)
	// returns 1 if Right > Left
	// returns -1 if Right < Left
	// return 0 if Right == Left

	if (right.first > left.first)
		return 1

	if (right.first < left.first)
		return -1

	if (right.second > left.second)
		return 1

	if (right.second < left.second)
		return -1

	if (right.third > left.third)
		return 1

	if (right.third < left.third)
		return -1

	if (right.fourth > left.fourth)
		return 1

	if (right.fourth < left.fourth)
		return -1

	return 0



/datum/Quadruple/proc/ActionCompare(var/datum/Quadruple/left, var/datum/Quadruple/right)
	/*
	// returns 1 if Right > Left
	// returns -1 if Right < Left
	// return 0 if Right == Left
	//
	// This is just a cut-down version of the QuadCompare proc.
	*/

	if (right.first > left.first)
		return 1

	if (right.first < left.first)
		return -1

	if (right.second > left.second)
		return 1

	if (right.second < left.second)
		return -1

	/* For this GOAP implementation, our standard key is at most
	// the first two values (iteration, for BFS, and cost, for
	// Astarry-ness), and the rest can be whatever, so we return 0.
	//
	// If you use a custom key generator proc, you will probably need
	// to use a custom proc instead of this one as well.
	*/
	return 0

