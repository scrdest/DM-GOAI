// A persistent service that stores and fetches Chunk data


var/global/datum/fractserver/fractserver_singleton = null


/datum/fractserver
	/*
	** This is a close analogue to chunkserver (and a blatant edited copypasta of a lot of the code).
	** The difference is fractserver handles multi-level scaling better.
	*/

	var/scale_factor = 3

	// might change this to a list indexed by offset later
	var/dict/chunks = null


/datum/fractserver/New(var/scale_factor = 3)
	. = ..()

	src.scale_factor = scale_factor
	chunks = new()


/datum/fractserver/proc/FractChunkForTile(var/posX, var/posY, var/posZ, var/heightDelta = 1)
	if(isnull(posX) || isnull(posY) || isnull(posZ))
		return

	if(isnull(chunks))
		chunks = new()

	var/curr_h = 1
	var/curr_x = posX
	var/curr_y = posY
	var/curr_z = posZ

	var/outstandingHeightDelta = max(0, (heightDelta || 1))
	var/chunk_key = "[curr_h]/[curr_x],[curr_y],[curr_z]"

	while(outstandingHeightDelta --> 0)
		chunk_key = fractal_parents_twod_numerical(curr_x, curr_y, curr_z, curr_h)

		if(!(chunk_key))
			ASSERT(chunk_key) // so we get an error for now
			// oops, cannot proceed!
			return null

		var/regex/matcher = TWOD_FRACTCOORDS_REGEX
		matcher.Find(chunk_key)
		var/list/groups = matcher.group

		curr_h = text2num(groups[1])
		curr_x = text2num(groups[2])
		curr_y = text2num(groups[3])
		curr_z = text2num(groups[4])

	var/datum/chunk/retrieved_chunk = chunks.Get(chunk_key)

	if(isnull(retrieved_chunk))
		retrieved_chunk = new(curr_x, curr_y, curr_z, src.scale_factor)
		chunks[chunk_key] = retrieved_chunk

	return retrieved_chunk


/datum/fractserver/proc/FractChunkForAtom(var/atom/A, var/heightDelta = 1)
	if(!A)
		return

	var/posX = A.x
	var/posY = A.y
	var/posZ = A.z

	var/result = FractChunkForTile(posX, posY, posZ, heightDelta)

	return result


/proc/GetOrSetFractserver(var/scale_factor = 3)
	var/datum/fractserver/local_fractserver = fractserver_singleton

	if (isnull(local_fractserver))
		local_fractserver = new(scale_factor)
		fractserver_singleton = local_fractserver

	return local_fractserver


/mob/verb/test_GetOrSetFractserver()
	set category = "Fractal Coords Debug"
	var/datum/fractserver/local_fractserver = fractserver_singleton

	usr << "FractServer pre is: [local_fractserver || "null"]"
	local_fractserver = GetOrSetFractserver()
	usr << "FractServer post is: [local_fractserver || "null"]"


/turf/verb/test_FractChunkForAtom()
	set src in view()
	set category = "Fractal Coords Debug"

	var/datum/fractserver/local_fractserver = GetOrSetFractserver()

	var/datum/chunk/retrieved_chunk = local_fractserver.FractChunkForAtom(src)

	usr << "Retrieved chunk is: [retrieved_chunk || "null"]"
	usr << "Retrieved chunk pos: [retrieved_chunk?.centerX || "null"], [retrieved_chunk?.centerY || "null"], [retrieved_chunk?.centerZ || "null"] @ width [retrieved_chunk?.width || "null"]"


/turf/verb/test_FractChunkForAtomDoubleH()
	set src in view()
	set category = "Fractal Coords Debug"

	var/datum/fractserver/local_fractserver = GetOrSetFractserver()

	var/datum/chunk/retrieved_chunk = local_fractserver.FractChunkForAtom(src, 2)

	usr << "Retrieved chunk is: [retrieved_chunk || "null"]"
	usr << "Retrieved chunk pos: [retrieved_chunk?.centerX || "null"], [retrieved_chunk?.centerY || "null"], [retrieved_chunk?.centerZ || "null"] @ width [retrieved_chunk?.width || "null"]"

