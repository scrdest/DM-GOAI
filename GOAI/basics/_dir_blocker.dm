/datum/directional_blocker
	/* A component that indicates that whatever object its attached to
	behaves like a directional blocker (e.g. SS13 'small' windows or flipped tables).
	*/
	var/blocks = null
	var/block_all = FALSE


/datum/directional_blocker/New(var/block_dirs, var/block_all_dirs = FALSE)
	blocks = (block_dirs ? block_dirs : blocks)
	block_all = (block_all_dirs ? block_all_dirs : block_all)


/datum/directional_blocker/proc/Blocks(var/dir)
	if(block_all)
		return TRUE

	return blocks & dir
