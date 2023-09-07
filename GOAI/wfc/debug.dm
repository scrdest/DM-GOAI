/mob/verb/test_wfc_full()
	var/mapname = "genmap.json"
	generate_wfc_map("rules.json")
	generate_from_wfc_file(mapname, overwrite_all = FALSE, zlevel = 1)
	generate_from_wfc_file(mapname, overwrite_all = FALSE, zlevel = 2)
	return


/*
/mob/verb/test_wfc_full_force()
	generate_wfc_map_full("rules.json", TRUE)
	return
*/

/mob/verb/go_up()
	usr.yeet_up()
	return


/mob/verb/test_wfc_rebuild_data()
	generate_wfc_map()
	usr << "Map data rebuilt"
	return


/mob/verb/test_wfc_pregenerated()
	var/mapname = "genmap.json"
	generate_from_wfc_file(mapname)
	return


/mob/verb/test_wfc_periodic_gen()
	spawn(0)
		while(TRUE)
			generate_wfc_map_full("rules.json", FALSE)
			usr << "Regenerating in 20s"
			sleep(200)
			usr << "Regenerating!"
	return
