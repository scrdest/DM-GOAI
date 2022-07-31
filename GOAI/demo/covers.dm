/mob/IsCover(var/transitive = FALSE, var/for_dir = null, var/default_for_null_dir = FALSE)
	// For now. Mobs being cover is fine in principle,
	// but it messes with testing (ghost counts as cover!)
	return FALSE


/obj/cover
	// Abstract Base Class, do not use directly!
	icon = 'icons/obj/structures.dmi'
	icon_state = "woodenbarricade"
	density = 1


/obj/cover/proc/Setup()
	return


/obj/cover/proc/GenerateCoverData()
	cover = new()
	return cover


/obj/cover/proc/UpdateIcon()
	return icon_state


/obj/cover/New()
	Setup()
	GenerateCoverData()
	UpdateIcon()


/obj/cover/barricade
	name = "Barricade"
	icon_state = "woodenbarricade"


/obj/cover/table
	name = "Table"
	icon_state = "wood_table" // fsr cannot use a var here

	var/icon_standing = "wood_table"
	var/icon_flipped = "woodflip0"
	var/flipped = FALSE


/obj/cover/table/Setup()
	directional_blocker = new()
	if(flipped)
		directional_blocker.blocks = src.dir


/obj/cover/table/UpdateIcon()
	icon_state = (flipped ? icon_flipped : icon_standing)

	layer = ((flipped && (dir != NORTH)) ? (MOB_LAYER + 1) : OBJ_LAYER)
	return


/obj/cover/table/GenerateCoverData()
	cover = ..()
	cover.is_active = flipped
	cover.cover_all = FALSE
	cover.cover_dir = (flipped ? dir : 0)
	return cover


/obj/cover/table/proc/Flip(var/flip_dir = null)
	if(isnull(flip_dir))
		return

	dir = flip_dir
	flipped = TRUE
	cover?.is_active = TRUE
	cover.cover_dir = flip_dir

	if(isnull(directional_blocker))
		directional_blocker = new()

	density = FALSE
	directional_blocker.blocks = flip_dir

	UpdateIcon()
