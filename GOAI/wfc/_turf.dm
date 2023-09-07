/turf
	var/wfc_overwritable = FALSE

	// list of refs to objects to delete on overwrite
	var/list/associated_wfc_overwritables = null


/turf/procgen
	icon = 'icons/urist/turf/uristturf.dmi'
	icon_state = "tramfloor"

	wfc_overwritable = TRUE


/turf/procgen/wfc

