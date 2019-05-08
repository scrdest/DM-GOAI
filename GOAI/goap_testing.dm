/datum/actionholder/testAction
	name = "Test Action"

/datum/actionholder/testAction/New(var/newname, var/newcost, var/list/neweffects, var/list/newpreconds)
	. = ..()
	src.name = newname ? newname : src.name
	src.cost = newcost ? newcost : src.cost
	src.effects = neweffects ? (src.effects + neweffects) : src.effects
	src.preconds = newpreconds ? (src.preconds + newpreconds) : src.preconds

/mob/verb/testGetPlans()
	var/datum/actionholder/testAction/Action1 = new("ActionWithCost1", 1, list(1, 2))
	var/datum/actionholder/testAction/Action2 = new("Action3Meeter",   1, list(2), list(5))
	var/datum/actionholder/testAction/Action3 = new("Action4Meeter",   1, list(3), list(2))
	var/datum/actionholder/testAction/Action4 = new("Action4",   1, list(1,3), list(3))
	var/datum/actionholder/testAction/Action5 = new("Action5",   1, list(1), list(3,4))
	var/datum/actionholder/testAction/Action6 = new("Action6",   1, list(1), list(2))
	var/datum/actionholder/testAction/Action7 = new("Action7",         1, list(4), list(2))
	var/datum/actionholder/testAction/Action8 = new("Action8",         1, list(1), list(4))
	var/datum/actionholder/testAction/Action9 = new("Action9",         1, list(5))
	world.log << "Testing..."
	var/list/queue = GetPlans(list(1,4,5), list(Action1, Action2, Action3, Action4, Action5, Action6, Action7, Action8, Action9))
	if(queue)
		var/i = 1
		for(var/datum/PlanHolder/key in queue)
			var/list/val = queue[key]
			var/list/planqueue = key.queue
			world.log << "([i++]) {[planqueue ? planqueue.Join("=>") : key] : [val]}"
	else
		world.log << "No actions found!"
