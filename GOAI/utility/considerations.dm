
/datum/consideration
	/* This datum is designed to be a 'persistent' representation of a Consideration,
	// As such, it's meant to be 'recycled'; don't delete it or put temporary state in here.
	// If you do need a one-off fsr, use the UTILITY_CONSIDERATION() macro directly.
	// If you don't want to account for this activation,
	*/

	var/id // int
	var/active = TRUE // bool; so that we can disable these without del()-ing them.

	var/lo_bookmark = 0
	var/hi_bookmark = 100

	var/name = "consideration"
	var/description = "<no description>"

	var/response_curve_proc // Fn<float -> float>
	var/get_input_val_proc // Fn<() -> float>


/datum/consideration/New(var/input_val_proc, var/curve_proc, var/loMark = null, var/hiMark = null, var/id = null, var/name = null, var/description = null, var/active = null)
	ASSERT(input_val_proc)
	ASSERT(curve_proc)

	src.get_input_val_proc = input_val_proc
	src.response_curve_proc = curve_proc

	if(!isnull(loMark))
		src.lo_bookmark = loMark

	if(!isnull(hiMark))
		// I did naaaaaaaht...
		src.hi_bookmark = hiMark

	if(!isnull(id))
		src.id = id

	if(!isnull(name))
		src.name = name

	if(!isnull(description))
		src.description = description

	if(!isnull(active))
		src.active = active


/datum/consideration/proc/Activate() // () -> bool
	src.active = TRUE
	return src.active


/datum/consideration/proc/Deactivate() // () -> bool
	src.active = FALSE
	return src.active


/datum/consideration/proc/Run(var/raw_input) // float -> float
	// Core processing for the Consideration.
	// Takes in *raw* input values, they'll get normalized in here!

	if(isnull(src.response_curve_proc))
		UTILITYBRAIN_DEBUG_LOG("ERROR: Response curve proc of Consideration `[src.name]` is null @ L[__LINE__] in [__FILE__]!")
		return ACTIVATION_NONE

	if(isnull(raw_input))
		UTILITYBRAIN_DEBUG_LOG("ERROR: Raw input to Consideration `[src.name]` is null @ L[__LINE__] in [__FILE__]!")
		return ACTIVATION_NONE

	if(!(src.active))
		UTILITYBRAIN_DEBUG_LOG("Consideration `[src.name]` is not active.")
		return ACTIVATION_NONE

	UTILITYBRAIN_DEBUG_LOG("UtilityConsideration raw data is [raw_input], LO: [src.lo_bookmark], HI: [src.hi_bookmark]")

	var/activation = UTILITY_CONSIDERATION(raw_input, src.lo_bookmark, src.hi_bookmark, src.response_curve_proc)
	return activation


/datum/consideration/proc/FetchAndRun(var/list/context, var/requester = null) // (Optional<assoclist>, Any) -> float
	// Convenience proc; fetches input data from a the input proc then calls Run() onnit.

	if(isnull(src.get_input_val_proc))
		UTILITYBRAIN_DEBUG_LOG("ERROR: Input proc of Consideration `[src.name]` is null, @ L[__LINE__] in [__FILE__]!")
		return ACTIVATION_NONE

	if(isnull(src.response_curve_proc))
		UTILITYBRAIN_DEBUG_LOG("ERROR: Response curve proc of Consideration `[src.name]` is null @ L[__LINE__] in [__FILE__]!")
		return ACTIVATION_NONE

	if(!(src.active))
		return ACTIVATION_NONE

	var/raw_input = call(src.get_input_val_proc)(context, requester)
	//UTILITYBRAIN_DEBUG_LOG("INFO: Raw input for Consideration `[src.name]` is [raw_input || "null"] <- [src.get_input_val_proc]; CTX: [context], RQS: [requester] @ L[__LINE__] in [__FILE__]!")

	var/activation = src.Run(raw_input)

	return activation


/proc/run_considerations(var/list/inputs, var/list/context = null, var/cutoff_thresh = null, var/requester = null) // ([/datum/consideration], Optional<assoc>, float, Optional<Any>) -> float
	/* This is the core scoring engine for any Utility decision.
	// We run through all Consideration Axes for a Decision, ANDing them together. This gives us the Activation score.
	// Activations turn into Utilities proper after postprocessing - after we multiply Activation by a PriorityWeight.
	// More on that in the actual Decision docs.
	//
	// - inputs: (array-)list of Considerations
	// - cutoff_thresh: optional float; if the total drops below this we throw the whole Decision away as an option.
	*/

	if(isnull(inputs))
		UTILITYBRAIN_DEBUG_LOG("ERROR: run_considerations input list is null @ L[__LINE__] in [__FILE__]!")
		return ACTIVATION_NONE

	var/axis_count = 0
	var/total = ACTIVATION_FULL

	var/valid_cutoff = !(isnull(cutoff_thresh))
	var/cutoff = clamp(cutoff_thresh, ACTIVATION_NONE, ACTIVATION_FULL)

	UTILITYBRAIN_DEBUG_LOG("INFO: run_considerations total is [total]")

	for(var/datum/consideration/axis in inputs)
		UTILITYBRAIN_DEBUG_LOG(" ")

		if(isnull(axis))
			UTILITYBRAIN_DEBUG_LOG("WARNING: null Consideration axis on iteration [axis_count+1] @ L[__LINE__] in [__FILE__]!")
			continue

		axis_count++
		var/axis_score = axis.FetchAndRun(context, requester)
		UTILITYBRAIN_DEBUG_LOG("INFO: Axis score for axis [axis_count] is: [axis_score]")

		// Multiply scores to get a probabilistic logical AND on criteria
		total = total * axis_score
		UTILITYBRAIN_DEBUG_LOG("INFO: run_considerations total is [total]")

		if(valid_cutoff && total < cutoff)
			// If we already know we have better candidates, we can stop.
			return ACTIVATION_NONE

	// Rescale to remove downward bias from adding more Considerations
	var/adjusted_total = CORRECT_UTILITY_SCORE(total, axis_count)

	return adjusted_total

