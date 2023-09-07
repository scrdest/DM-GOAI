/turf/deepmaint_plating
	icon = 'icons/turf/floors.dmi'
	//icon_state = "plating"
	icon_state = "rockvault"

	wfc_overwritable = TRUE


/turf/deepmaint_plating/ztele
	icon = 'icons/turf/floors.dmi'
	icon_state = "plating"
	//icon_state = "rockvault"

	var/teleproba = 100


/turf/deepmaint_plating/ztele/New(var/atom/loc)
	..(loc)

	if(!isnull(src.teleproba) && prob(src.teleproba))
		if(isnull(associated_wfc_overwritables))
			associated_wfc_overwritables = list()

		var/obj/step_trigger/deepmaint_teleport/tele = new(src)
		associated_wfc_overwritables.Add(tele)


/turf/deepmaint_plating_door
	icon = 'icons/turf/floors.dmi'
	icon_state = "panelscorched"
	//icon_state = "floorgrime"

	wfc_overwritable = TRUE
	associated_wfc_overwritables = null

	var/teleproba = 30


/turf/deepmaint_plating_door/New(var/atom/loc)
	..(loc)

	var/obj/cover/autodoor/AD = new()
	AD.loc = src

	if(isnull(src.associated_wfc_overwritables))
		src.associated_wfc_overwritables = list()

	if(!isnull(src.teleproba) && prob(src.teleproba))
		var/obj/step_trigger/deepmaint_teleport/tele = new(src)
		associated_wfc_overwritables.Add(tele)

	src.associated_wfc_overwritables.Add(AD)


/turf/deepmaint_wall
	icon = 'icons/turf/walls.dmi'
	icon_state = "r_wall"

	wfc_overwritable = TRUE

	density = TRUE
	opacity = FALSE
	//opacity = TRUE


/turf/deepmaint_wall/border
	// Special wall variant; does not regenerate w/ WFC.
	// Meant for the world edge.
	wfc_overwritable = FALSE


/turf/deepmaint_wall/probably
	// % chance of disappearing
	var/improbability = 5


/turf/deepmaint_wall/probably/New(var/atom/loc, var/improbability_override = null)
	..(loc)

	var/wall_improba = (isnull(improbability_override) ? src.improbability : improbability_override)

	if(prob(wall_improba))
		spawn(0)
			ChangeTurf(src, /turf/deepmaint_plating)
