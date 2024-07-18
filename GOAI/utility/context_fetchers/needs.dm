
CTXFETCHER_CALL_SIGNATURE(/proc/ctxfetcher_get_needs)
	// Returns an array of contexts, each holding one Need key.
	//
	// The context_args "below" and "above" allow thresholding emitted Needs by their current value.
	// Threshold semantics should be fairly intuitive if used individually (primary use-case).
	//
	// If you use BOTH, the behavior depends on whether the predicates intersect (i.e. below > above).
	// If they do, the thresholds are ANDed,
	//   so e.g. [above=30, below=70] emits all Needs between 30 & 70 (only mediocre values).
	// If they don't, they are instead ORed,
	//   so e.g. [above=75, below=25] emits all Needs that are NOT in the (25, 75) range (only extreme values).

	if(isnull(requester))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester for ctxfetcher_get_needs is null @ L[__LINE__] in [__FILE__]!")
		return null

	var/datum/utility_ai/requester_ai = requester

	if(!istype(requester_ai))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requester [requester] for ctxfetcher_get_needs is not an AI @ L[__LINE__] in [__FILE__]!")
		return null

	var/datum/brain/requesting_brain = requester_ai.brain

	if(!istype(requesting_brain))
		UTILITYBRAIN_DEBUG_LOG("WARNING: requesting_brain [requesting_brain] for ctxfetcher_get_needs is not a brain @ L[__LINE__] in [__FILE__]!")
		return null

	var/list/contexts = list()

	var/list/needs_by_weight = requesting_brain.GetNeedWeights() // assoc of {key: weight}!
	if(!needs_by_weight)
		return contexts

	CONTEXT_GET_OUTPUT_KEY(var/context_key)

	var/raw_below_threshold = context_args?["below"]
	var/raw_above_threshold = context_args?["above"]

	var/below_threshold = isnull(raw_below_threshold) ? NEED_MAXIMUM : raw_below_threshold
	var/above_threshold = isnull(raw_above_threshold) ? NEED_MINIMUM : raw_above_threshold
	var/disjoint_thresh = (below_threshold < above_threshold)

	for(var/need_key in needs_by_weight)
		var/need_weight = needs_by_weight[need_key]

		if(!need_weight)
			// skip zero/null weights
			UTILITYBRAIN_DEBUG_LOG("WARNING: ctxfetcher_get_needs need [need_key] weight is irrelevant! @ L[__LINE__] in [__FILE__]!")
			continue

		var/curr_need_value = requesting_brain.GetNeedAmountCurrent(need_key, null)

		if(isnull(curr_need_value))
			UTILITYBRAIN_DEBUG_LOG("WARNING: ctxfetcher_get_needs need [need_key] value is null! @ L[__LINE__] in [__FILE__]!")
			continue

		var/aboveness = (curr_need_value >= above_threshold)
		var/belowness = (curr_need_value <= below_threshold)

		if(disjoint_thresh)
			// we're looking for tails, so only one predicate can be satisfied
			if(!(aboveness || belowness))
				continue
		else
			// we're looking for an intersection, so both must be satisfied
			if(!(aboveness && belowness))
				continue

		// We survived the checks; emit a context

		var/list/subctx = list()
		// currently emit need keys only
		// we may want to do current val/weight/whatever later for optimization
		// but we can derive them from the keys for now
		subctx[context_key] = need_key
		/*
		// uncomment for multiple values per context
		subctx["value"] = curr_need_value
		subctx["weight"] = need_weight
		*/
		ARRAY_APPEND(contexts, subctx)

	return contexts
