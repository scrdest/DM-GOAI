
/datum/brain/New(var/list/actions = null, var/list/init_memories = null, var/init_action = null, var/datum/brain/with_hivemind = null, var/list/init_personality = null, var/newname = null, var/dict/init_relationships = null)
	..()

	src.name = (newname ? newname : name)

	src.memories = new /dict(init_memories)
	src.hivemind = with_hivemind

	src.last_need_update_times = list()
	src.perceptions = new()
	src.relations = new(init_relationships)
	PUT_EMPTY_LIST_IN(src.pending_instant_actions)
	src.attachments = new()
	src.RegisterBrain()

	if(init_personality)
		src.personality = init_personality

	else if(isnull(src.personality) && !isnull(src.personality_template_filepath))
		src.personality = PersonalityTemplateFromJson(src.personality_template_filepath)

	if(actions)
		src.actionslist = actions.Copy()

	if(init_action && (init_action in actionslist))
		src.running_action_tracker = DoAction(init_action)

	src.InitNeeds()
	//src.InitStates()

	return
