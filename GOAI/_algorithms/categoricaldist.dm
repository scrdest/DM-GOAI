/*
** Categorical Distribution object.
**
** Represents a probability distribution having K possible values,
** each value having either a probability P (or equivalently weight W; then
**
**     P(x) = W(x) / sum(W(*))
**
**   where 'x' is some value and '*' is the set of all possible values, 'x' included
** )
**
** We will generally favor the weight-based formulation in this implementation because it's nicer to work with
** and easy to renormalize to probabilities if need be.
**
**
** INTUITION: This is the probability of getting *any particular side* when using unfair, *loaded dice*.
**            The weight corresponds to how much... weight (mass), we've added to this side of the dice.
**
** Veteran DM-wranglers will recognize that this is effectively what the non-list flavor of pick() kind-of provides.
** Unfortunately, DM very characteristically half-assed this functionality, so it's only available for sampling
** and only for a very specific, funky syntactic construct.
**
** In contrast, this object can be constructed from plain old lists and manipulated before sampling.
**
**
** STATS! (WHUH)! WHAT IS THIS GOOD FOR?
**
** - Absolutely everything you'd use pick() for, but wish you could use a list as input
** - Sampling without replacement (e.g. powers - you *don't* want to pick the same one twice, so it should stop being a viable pick once chosen)
** - Conditional sampling (e.g. WFC - the adjacent tiles influence the weights of the target tile dynamically)
** - In general, anytime the pick weights can vary dynamically and/or you don't know all possible output values upfront.
**
*/

/distribution/categorical
	// Store the total of weights added for easy normalization and sampling
	var/weight_total = 0

	// Store the number of items added for sanity checking
	var/expected_length = 0

	// Because our objects are not necessarily hashable and DM is a pain, we need to do this SparseSet-style
	// One list is the actual weights indexed by list offset, the other is the value indexed by the same offset.
	// When retrieving values, we first sample using the former, then check what it maps to in the latter

	// position2weight
	var/list/weights = null

	// position2value
	var/list/weight_vals = null


/distribution/categorical/New(var/list/new_weights)
	// new_weights is expected to be a list<val, weight>

	if(isnull(src.weights))
		src.weights = list()
	else
		src.weights.Cut()

	if(isnull(src.weight_vals))
		src.weight_vals = list()
	else
		src.weight_vals.Cut()

	if(isnull(new_weights))
		new_weights = list()

	var/idx = 0

	for(var/val in new_weights)
		if(isnull(val))
			continue

		var/wgt = new_weights[val]

		if(isnull(wgt))
			continue

		idx++

		while(src.weight_vals.len < idx)
			src.weight_vals.len++

		src.weight_vals[idx] = val

		while(src.weights.len < idx)
			src.weights.len++

		src.weights[idx] = wgt
		src.weight_total += wgt

	src.expected_length = idx

	ASSERT(src.weight_vals.len == src.expected_length)
	ASSERT(src.weights.len == src.expected_length)
	return src


/distribution/categorical/sample()
	/*
	** Imagine that we have a length of rope made out of multiple dyed pieces spliced together.
	**   The pieces all have different lengths. If we cut this rope at a random point, what would
	**   be the odds of getting cut for each color? Yep - this is a categorical distribution with
	**   the odds being proportional to how long each colored piece is.
	**
	** So, flipping the scenario, this is how we can *sample* from this distribution.
	**   We take the 'length of the rope' (sum of weights), sample a random number between
	**   zero and this length, then subtract each piece's length from this number and see
	**   which color we're at when we've reached zero.
	*/

	if(!src.expected_length)
		// If there's nothing to sample, don't bother
		return

	var/curr_idx = 1
	var/curr_piece_length = src.weights[curr_idx]

	// We have to use 'pure' rand() or we skew the results as rand(L, H) only returns integers.
	var/cut_point = (rand() * src.weight_total) - curr_piece_length

	while(cut_point > 0)
		curr_piece_length = src.weights[++curr_idx]
		cut_point -= curr_piece_length

	var/result = src.weight_vals[curr_idx]
	return result


/distribution/categorical/proc/get_weight_for_key(var/key)
	var/match = 0

	// We need to do a linear scan to find key matches, which is not great, but
	//   the key space is most likely going to be small, so it should be OK.
	// Might wind up refactoring this back to a hashmap list again...
	for(var/idx = 1, idx <= src.expected_length, idx++)
		if(src.weight_vals[idx] == key)
			match = idx
			break

	var/weight = null

	if(match)
		weight = src.weights[match]

	return weight


/* ----------  NORMALIZATION STUFF  ---------- */

/distribution/categorical/proc/normalize()
	/* Normalizes weights in-place, returning normalized self */
	for(var/idx = 1, idx <= src.expected_length, idx++)
		var/raw_wgt = src.weights[idx]
		var/normalized_wgt = raw_wgt / src.weight_total
		src.weights[idx] = normalized_wgt

	src.weight_total = 1  // by definition
	return src


/distribution/categorical/proc/get_normalized_weights_by_key()
	/* Normalizes weights and just puts them into a returned assoc list.
	** Use this if you need normalized K-V PAIRS, but still need the OG values too.
	*/
	var/list/normallist = list()

	for(var/idx = 1, idx <= src.expected_length, idx++)
		var/raw_val = src.weight_vals[idx]
		var/raw_wgt = src.weights[idx]
		var/normalized_wgt = raw_wgt / src.weight_total

		normallist[raw_val] = normalized_wgt

	return normallist


/distribution/categorical/proc/get_normalized_weights_by_index()
	/* Normalizes weights and just puts them into a returned 'array-style' list.
	** Use this if you need normalized VALUES, but still need the OG values too.
	*/
	var/list/normallist = list()

	for(var/idx = 1, idx <= src.expected_length, idx++)
		var/raw_wgt = src.weights[idx]
		var/normalized_wgt = raw_wgt / src.weight_total
		normallist.Add(normalized_wgt)

	return normallist


/distribution/categorical/proc/new_normalized()
	/* Normalizes weights and puts them into a NEW distribution.
	** Use this if you need a normalized DISTRIBUTION, but still need the OG values too.
	*/
	var/distribution/categorical/normdist = new(get_normalized_weights_by_key())
	return normdist

/* ------------------------------------------------ */


/* ----------  ENTROPY  ---------- */

/distribution/categorical/proc/entropy()
	var/total = 0
	var/list/normallist = src.get_normalized_weights_by_index()

	for(var/wgt in normallist)
		var/val = wgt * (2 ** wgt)
		total += val

	return total

/* ------------------------------------------------ */


/* ----------  Distribution products  ---------- */

/distribution/categorical/proc/joint_distribution_weights(var/distribution/categorical/other)
	/* Returns the weights of an (approximate) joint distribution of two categorical distributions.
	** Formally, we get P(X | A, B) ~= P(X|A) * P(X|B), by elementwise multiplication.
	*/
	if(isnull(other))
		return

	var/list/other_weights = other.get_normalized_weights_by_key()

	var/list/joint_weights = list()

	for(var/key in other_weights)
		var/mine = src.get_weight_for_key(key) || 0
		var/theirs = other_weights[key] || 0

		var/product_weight = mine * theirs

		if(product_weight <= 0)
			continue

		joint_weights[key] = product_weight

	return joint_weights


/distribution/categorical/proc/joint_distribution(var/distribution/categorical/other)
	/* Like joint_distribution_weights, except returns a proper distribution. */
	if(isnull(other))
		return

	var/list/joint_weights = src.joint_distribution_weights(other)
	var/distribution/categorical/joint_distr = new(joint_weights)

	return joint_distr

/* ------------------------------------------------ */


/mob/verb/test_catdist_basic()
	set category = "Stats Debug"

	var/distribution/categorical/catdist = new(list("a" = 5, "b" = 1, "c" = 2, "d" = 4))

	var/result = catdist.sample()
	usr << result


/mob/verb/test_catdist_adv(inp as text)
	set category = "Stats Debug"

	var/list/decoded_input = json_decode(inp)
	if(isnull(decoded_input))
		usr << "Could not parse input: `[inp]` as JSON"

	var/distribution/categorical/catdist = new(decoded_input)
	var/result = catdist.sample()
	usr << result


/mob/verb/test_catdist_entropy(inp as text)
	set category = "Stats Debug"

	var/list/decoded_input = json_decode(inp)
	if(isnull(decoded_input))
		usr << "Could not parse input: `[inp]` as JSON"

	var/distribution/categorical/catdist = new(decoded_input)
	var/result = catdist.entropy()
	usr << result


/mob/verb/test_catdist_joint(inp as text)
	set category = "Stats Debug"

	var/list/decoded_input = json_decode(inp)
	if(isnull(decoded_input))
		usr << "Could not parse input: `[inp]` as JSON"

	var/distribution/categorical/leftdist = new(list("a" = 5, "b" = 1, "c" = 2, "d" = 4, "e" = 2))
	var/distribution/categorical/rightdist = new(decoded_input)

	var/list/joint_weights = leftdist.joint_distribution_weights(rightdist)
	usr << json_encode(leftdist.weights)
	usr << json_encode(rightdist.weights)
	usr << json_encode(joint_weights)
