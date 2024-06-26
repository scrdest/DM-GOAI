/*
// This is the actual data for a faction (a container for
// stuff like relationships, members and whatever else).
//
// The faction AI should NOT have stuff like this directly
// hardcoded anywhere - if it does, we cannot have factions
// that are NOT driven by AI (and we might need it for stuff
// like PC factions, where we want third-party AIs to access
// this data without having an AI loop for the PC faction itself.
*/

/datum/faction_data
	var/name = "unknown faction"

	// Relations list (outbound)
	var/datum/relationships/relations

	// Tags, for inbound relations
	// (at the most basic, the faction name can be the only tag)
	var/list/tags

	// Faction Registry index
	var/registry_index

	// Associated Actions
	var/list/actionset_files = null


/datum/faction_data/proc/RegisterFaction()
	// Registry pattern, to facilitate querying all Factions
	if(!(GOAI_LIBBED_GLOB_ATTR(global_faction_registry)))
		GOAI_LIBBED_GLOB_ATTR(global_faction_registry) = list()

	if(src.registry_index)
		GOAI_LIBBED_GLOB_ATTR(global_faction_registry)[src.registry_index] = src
		return GOAI_LIBBED_GLOB_ATTR(global_faction_registry)

	GOAI_LIBBED_GLOB_ATTR(global_faction_registry) += src
	src.registry_index = GOAI_LIBBED_GLOB_ATTR(global_faction_registry.len)

	if(!(src.name))
		src.name = src.registry_index

	return GOAI_LIBBED_GLOB_ATTR(global_faction_registry)


/datum/faction_data/proc/BuildRelations()
	var/datum/relationships/new_relations = new()
	return new_relations


/datum/faction_data/proc/BuildTags()
	var/list/mytags = list()
	return mytags


/datum/faction_data/New(var/newname, var/datum/relationships/init_relations = null, var/list/init_tags = null, var/list/actionsets = null)
	. = ..()

	if(newname)
		src.name = newname

	if(init_relations)
		src.relations = init_relations

	if(init_tags)
		src.tags = init_tags

	if(actionsets)
		src.actionset_files = actionsets

	// Populate data structures (do not override existing)
	src.relations = (src.relations || src.BuildRelations())
	src.tags = (src.tags || src.BuildTags())

	// Sign up to the registry for queries once ready
	src.RegisterFaction()

	return


/* SmartObject */
GOAI_HAS_UTILITY_ACTIONS_BOILERPLATE_VARLIST(/datum/faction_data, actionset_files)

/datum/faction_data/GetUtilityActions(var/requester, var/list/args = null)
	var/list/my_action_sets = list()

	if(!src.actionset_files)
		return my_action_sets

	for(var/action_bundle_json_fp in src.actionset_files)
		if(!fexists(action_bundle_json_fp))
			GOAI_LOG_ERROR("[src.name] - Filepath [action_bundle_json_fp] does not exist - skipping!")
			continue

		try
			var/datum/action_set/myset = ActionSetFromJsonFile(action_bundle_json_fp)
			myset.origin = src
			my_action_sets.Add(myset)

		catch(var/exception/e)
			world.Error(e)

	return my_action_sets

