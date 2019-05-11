#define RECURSION_DEPTH_SENTINEL 5
#define PLANNED_KEY "plans"
#define DEFERRED_KEY "deferred"
#define EVALUATED_KEY "evaluated"

// GOAP CORE:
// Considering available actions as nodes in a dense graph,
// we can extend motion planning algos to planning in general.
//
// This is assuming we know the space of possible actions at the time
// of planning and execution and their comparative costs, but for NPCs,
// we can specify that as an a priori edict.
//
// To avoid exploding the server with all the calculations,
// and ensure we can account for unexpected state transitions,
// the algorithm applied here is a breadth-first variant of IDA*:
//
// Each call returns a (possibly empty) list of quick solutions,
// and another one storing arglists to apply in the next call
// to be used to search for a more complicated, more optimal solution.
//
// A cool side-effect of that approach is that you can manipulate
// the depth of search to tweak the NPC Agent's sophistication.

/proc/GetPlans(var/list/goals, var/list/actions, var/list/startstate, var/list/explored, var/prior_cost=1)
	//returns a list of datums holding queues of actions meeting the Goals the Actor can perform
	world.log << "   "
	world.log << "Goals: [goals ? goals.Join(" & ") : "None"]"

	if(!(actions && actions.len))
		return
	var/list/actionspace = actions.Copy() // may be redundant, but avoids accidental side-effects

	if(!(startstate))
		startstate = list()

	var/list/results = list(PLANNED_KEY=list(), DEFERRED_KEY=list(), EVALUATED_KEY=list())

	var/list/state = startstate.Copy()
	var/list/partials = list()

	for(var/datum/actionholder/tail_act in explored)
		if(!(tail_act in partials))
			partials.Add(tail_act) // we're iterating anyway so no point calling Copy()
		var/list/tail_fx = tail_act.GetEffects()
		world.log << "Tail Action: [tail_act]"

		state = upsert(state, tail_fx)
		for(var/k in state)
			world.log << "[tail_act] state: {[k] = [state[k].Join(",")]}]"

	for(var/datum/actionholder/action in actionspace)
		if(action in partials)
			continue
		var/list/unmet = list()
		var/list/ActEffects = action.GetEffects()

		if(!(ActEffects && ActEffects.len))
			continue

		if (any_in(ActEffects, goals))
			var/list/Preconds = action.GetPreconditions() || list()
			world.log << "[action.name] preconds: [Preconds ? Preconds.Join(", ") : "NONE!"]..."

			if(all_in(Preconds, goals))
				// cycle in the graph
				world.log << "Cycle!"
				continue

			unmet.Add(right_disjoint(unmet, right_disjoint(ActEffects, goals)))
			unmet.Add(right_disjoint_assoc(unmet, right_disjoint(state, Preconds)))
			if(unmet && unmet.len)
				world.log << "[action.name] unmet: [unmet.Join(";")]."
			world.log << "[action.name] meets goals: [(ActEffects & goals).Join(";")]."

			var/Cost = prior_cost + action.cost // refactorme!

			if(!(unmet && unmet.len))
				// Immediately available steps meeting the goal
				var/datum/PlanHolder/newplan = new(Cost, list(action))
				world.log << "Appending immediate plan [newplan.queue.Join(" -> ")] @ [Cost]"
				results[PLANNED_KEY][newplan] = newplan.cost

			else
				// Actions that require other steps to be taken first
				var/list/subplan_template = list(unmet, actionspace, state, partials+list(action), Cost)
				results[DEFERRED_KEY][action] = subplan_template
				world.log << "Saving plan template [subplan_template.Join(", ")]"

		for(var/datum/actionholder/parent_action in partials)
			world.log << "Partials: [partials.Join(", ")]"
			var/list/subplan_template = partials[parent_action]
			if(!subplan_template)
				continue
			var/list/subplans = GetPlans(arglist(subplan_template))

			if(!(subplans && PLANNED_KEY in subplans))
				continue

			// evaluate partials
			subplans = subplans[PLANNED_KEY]
			for(var/datum/PlanHolder/p in subplans)
				var/subcost = prior_cost + subplans[p] + parent_action.cost
				var/list/intermeds = p.queue
				var/datum/PlanHolder/subplan = new(subplans[p], intermeds + list(parent_action))
				if(subplan && !isnull(subcost))
					world.log << "Appending deferred plan [subplan.queue.Join(" -> ")] @ [subcost]"
					results[PLANNED_KEY][subplan] = subcost

	if((!(results && results.len)))
		world.log << "Got no valid plans."

	return results

