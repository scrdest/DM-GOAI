// Extends turfchunk class with WFCish attributes

/datum/chunk
	// What prefab has been assigned, if any.
	// Implicitly, null is unassigned and non-null is finalized.
	var/wfc_assignment = null

	// Assignment probability distribution.
	// WFC will mutate this by assigning neighbors,
	// until it's the lowest-entropy item to assign next, at which point
	// it will receive a non-null wfc_assignment.
	var/wfc_probas = null
