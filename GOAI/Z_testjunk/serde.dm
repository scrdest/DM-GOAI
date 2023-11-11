/mob/verb/LoadConsideration(fp as file)
	set category = "SerDe"

	var/data = json_decode(file2text(fp))
	to_chat(usr, " ")
	to_chat(usr, "loaded [data]")

	var/list/considerations = UtilityConsiderationArrayFromData(data)

	if(isnull(considerations))
		to_chat(usr, "Failed to load Considerations")
		return

	for(var/datum/cons in considerations)
		to_chat(usr, "Consideration: [cons]")
		to_chat(usr, "---------------------")

		for(var/ConsVar in cons.vars)
			to_chat(usr, "o [ConsVar] => [cons.vars[ConsVar]]")

	return


/mob/verb/LoadActionTemplate(fp as file)
	set category = "SerDe"

	var/data = json_decode(file2text(fp))
	to_chat(usr, " ")

	var/datum/utility_action_template/loaded_action_template = ActionTemplateFromData(data)

	if(isnull(loaded_action_template))
		to_chat(usr, "Failed to load an ActionTemplate")
		return

	for(var/AtVar in loaded_action_template.vars)
		to_chat(usr, "o [AtVar] => [loaded_action_template.vars[AtVar]]")

	return



/mob/verb/LoadActionSet(fp as file)
	set category = "SerDe"

	var/data = json_decode(file2text(fp))
	to_chat(usr, " ")

	var/datum/action_set/new_actionset = ActionSetFromData(data)

	if(isnull(new_actionset))
		usr << "Failed to load an ActionSet"
		return

	usr << "o active => [new_actionset.active]"

	for(var/datum/utility_action_template/loaded_action_template in new_actionset.actions)
		usr << " "
		usr << "-- [loaded_action_template.name] --"
		for(var/AtVar in loaded_action_template.vars)
			usr << "o [AtVar] => [loaded_action_template.vars[AtVar]]"

	return
