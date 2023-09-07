# define PREFAB_SIZE 3

/proc/generate_wfc_map(var/rules_json = "deepmaint.json")
	call("ss13_wfc.dll", "from_ruleset")(rules_json)
	return


/proc/generate_from_wfc_file(var/mapname = "genmap.json", var/overwrite_all = FALSE, var/zlevel = 1)
	if(!fexists(mapname))
		usr << "Map no generatey ):"
		return

	var/fh = file(mapname)
	var/data = file2text(fh)
	var/regex/map_regex = regex(@"(\d+)\|(\d+),(\d+)", "g")

	//var/list/points = list()
	var/regex/matcher = TWOD_FRACTCOORDS_REGEX
	var/list/idx_to_varkey = list(
		list("bl", "bm", "br"),
		list("ml", "mm", "mr"),
		list("tl", "tm", "tr")
	)

	spawn(0)
		while(TRUE)
			var/found = map_regex.Find(data)
			if(!found)
				break

			var/raw_state = map_regex.group[1]
			var/raw_x = map_regex.group[2]
			var/raw_y = map_regex.group[3]

			var/state = text2num(raw_state)
			var/x = text2num(raw_x)
			var/y = text2num(raw_y)

			var/coords = "2/[text2num(x) + 1],[text2num(y) + 1],[zlevel]"

			var/list/children = fractal_children_str(coords, PREFAB_SIZE)

			for(var/ch in children)
				sleep(0)

				if(!matcher.Find(ch))
					continue

				var/match_x = text2num(matcher.group[2])
				var/match_y = text2num(matcher.group[3])
				var/match_z = text2num(matcher.group[4])

				var/turf/child_turf = locate(match_x, match_y, match_z)

				// the logical OR is to convert 0s to <maxsize> because DM is 1-indexed
				var/prefab_idx_x = (match_x % PREFAB_SIZE) || PREFAB_SIZE
				var/prefab_idx_y = (match_y % PREFAB_SIZE) || PREFAB_SIZE

				var/my_varkey = idx_to_varkey[prefab_idx_y][prefab_idx_x]

				var/turf_type = null

				turf_type = state2prefab_deepmaint(state, my_varkey)

				if(turf_type && child_turf && (overwrite_all || child_turf.wfc_overwritable))
					ChangeTurf(child_turf, turf_type)
	return


/proc/generate_wfc_map_full(var/rules_json = "deepmaint.json", var/overwrite_all = FALSE, var/zlevel = 1)
	var/mapname = "genmap.json"
	generate_wfc_map(rules_json)
	generate_from_wfc_file(mapname, overwrite_all = FALSE, zlevel = zlevel)
	return

