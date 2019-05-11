/datum/actionholder/testAction
	name = "Test Action"

/datum/actionholder/testAction/New(var/newname, var/newcost, var/list/neweffects, var/list/newpreconds)
	. = ..()
	src.name = newname ? newname : src.name
	src.cost = newcost ? newcost : src.cost
	src.effects = upsert(src.effects, neweffects)
	src.preconds = upsert(src.preconds, newpreconds)

var/global/list/need2name = list(
	"1" = "food",
	"2" = "comfort",
	"3" = "tools",
	"4" = "money",
	"5" = "chair"
)

/mob/verb/testGetPlansByArgs()
	var/inputs = input("Enter a comma-separated string of integer goals", "Goals", null) as text|null
	var/depth = min(input("Enter max search depth", "Depth", 5) as num, 1)
	var/list/arggoals = (inputs && length(inputs)) ? splittext(inputs, ",") : null
	var/list/formatted_goals = list()
	for(var/goal in arggoals)
		var/needkey = need2name["[goal]"]
		formatted_goals[needkey] = goal
	return src.testGetPlans(formatted_goals, depth)

/mob/verb/testGetPlansSimple()
	return src.testGetPlans()

/mob/proc/testGetPlans(var/list/goals, var/maxdepth=5)
	if(!(goals && goals.len))
		goals = list( "comfort"=list(2),"tools"=list(3) )
	var/datum/actionholder/testAction/Action1 = new("Eat leftovers", 1, list("food"=list(1), "comfort"=list(2)))
	var/datum/actionholder/testAction/Action2 = new("Sit on a chair",   1, list("comfort"=list(2)), list("chair"=list(5)))
	var/datum/actionholder/testAction/Action3 = new("Get tools",   1, list("tools"=list(3)), list("comfort"=list(2)))
	var/datum/actionholder/testAction/Action4 = new("Cook dinner",   1, list("food"=list(1),"tools"=list(3)), list("tools"=list(3)))
	var/datum/actionholder/testAction/Action5 = new("Action5",   1, list("food"=list(1)), list("tools"=list(3),"money"=list(4)))
	var/datum/actionholder/testAction/Action6 = new("Action6",   1, list("food"=list(1)), list("comfort"=list(2)))
	var/datum/actionholder/testAction/Action7 = new("Action7",         1, list("money"=list(4)), list("comfort"=list(2)))
	var/datum/actionholder/testAction/Action8 = new("Buy groceries",   1, list("food"=list(1)), list("money"=list(4)))
	var/datum/actionholder/testAction/Action9 = new("Build a chair",   1, list("chair"=list(5)))
	world.log << "   "
	world.log << "   "
	world.log << "Testing..."

	var/list/queue = list()
	var/list/solutions = list()
	var/sentinel = 0
	while(sentinel++ < maxdepth)
		world.log << "=========="
		if(!(queue && queue.len))
			queue.len++
			queue[1] = GetPlans(goals, list(Action1, Action2, Action3, Action4, Action5, Action6, Action7, Action8, Action9))

		var/list/iteration = pick(queue)
		if(!iteration)
			continue

		var/list/immediates = iteration[PLANNED_KEY] || list()
		var/i = 1
		for(var/datum/PlanHolder/key in immediates)
			var/list/val = immediates[key]
			var/list/planqueue = key.queue
			world.log << "([i]) {[planqueue ? planqueue.Join("=>") : key] : [val]}"
			solutions.Add("[sentinel].[i]: [planqueue.Join("=>")]")


		var/list/deferred = iteration[DEFERRED_KEY]
		if(deferred && deferred.len)
			var/subeval_action = pick(deferred)
			var/list/subeval_args = deferred[subeval_action]
			deferred.Remove(subeval_action)

			if(!(subeval_args && subeval_args.len))
				world.log << "Subargs missing!"

			if(subeval_args)
				world.log << "EV'd: [subeval_args.Join("|")]"
				world.log << "EV'd (goals): [subeval_args[1].Join("|")]"
				for(var/k in subeval_args[3])
					world.log << "EV'd (state) `[k]`: [subeval_args[3][k]]"
				world.log << "EV'd (exlrd): [subeval_args[4].Join("|")]"

				var/list/subiter = GetPlans(arglist(subeval_args))
				if(subiter)
					var/list/subimmediates = subiter[PLANNED_KEY] || list()
					var/j = 1
					for(var/datum/PlanHolder/subkey in subimmediates)
						var/list/subval = subimmediates[subkey]
						var/list/subplanqueue = list(subeval_action) + subkey.queue
						solutions.Add("[sentinel].[i].[j]: {[subplanqueue ? subplanqueue.Join("=>") : subkey] : [subval]}")
					j++
		i++
	world.log << "   "
	world.log << "------------------"
	world.log << "SOLUTIONS:"
	for(var/s in solutions)
		world.log << s
	world.log << "------------------"