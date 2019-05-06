/datum/actionholder/testAction
	name = "Test Action"

/datum/actionholder/testAction/New(var/newname, var/newcost, var/list/neweffects, var/list/newpreconds)
	. = ..()
	src.name = newname ? newname : src.name
	src.cost = newcost ? newcost : src.cost
	src.effects = neweffects ? (src.effects + neweffects) : src.effects
	src.preconds = newpreconds ? (src.preconds + newpreconds) : src.preconds

/mob/verb/testGetAction()
	var/datum/actionholder/testAction/Action1 = new("ActionWithCost1", 1, list(1))
	var/datum/actionholder/testAction/Action2 = new("Action2MeeterOnly", 999, list(3, 2))
	var/datum/actionholder/testAction/Action3 = new("Action2EffectOnly", 999, list(1,3, 2), list(2))
	world.log << "Testing..."
	var/list/queue = EvaluateStepTo(1, list(Action1, Action2, Action3))
	if(queue)
		for(var/key in queue)
			var/val = queue[key]
			world.log << "{[key] : [val]}"
	else
		world.log << "No actions found!"


/mob/verb/testGetPlans()
	var/datum/actionholder/testAction/Action1 = new("ActionWithCost1", 1, list(1, 2))
	var/datum/actionholder/testAction/Action2 = new("Action3Meeter",   1, list(2))
	var/datum/actionholder/testAction/Action3 = new("Action4Meeter",   1, list(3), list(2))
	var/datum/actionholder/testAction/Action4 = new("Action4Effect",   1, list(1,3), list(3))
	var/datum/actionholder/testAction/Action5 = new("Action5Effect",   1, list(1), list(3,4))
	var/datum/actionholder/testAction/Action6 = new("Action6Effect",   1, list(1), list(2))
	world.log << "Testing..."
	var/list/queue = GetPlans(list(1), list(Action1, Action2, Action3, Action4, Action5, Action6))
	if(queue)
		var/i = 1
		for(var/datum/PlanHolder/key in queue)
			var/list/val = queue[key]
			var/list/planqueue = key.queue
			world.log << "([i++]) {[planqueue ? planqueue.Join(", ") : key] : [val]}"
	else
		world.log << "No actions found!"
