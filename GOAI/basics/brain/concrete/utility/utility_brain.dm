/* Concrete implementation of the Brain logic using IAUS-style Utility
//
//
// The underscore in the filename is just to trick DM into sorting this correctly.
*/


/datum/brain/utility
	// NOTE: we'll reuse actionslist from the parent for ActionSets; this is not ideal
	//       but I don't want to refactor the parent into a GOAPy subclass.
	var/list/file_actionsets = null

