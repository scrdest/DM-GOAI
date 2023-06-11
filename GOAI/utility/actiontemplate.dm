/* ==  ACTION TEMPLATES  == */

/datum/utility_action_template
	/* This class represents an action *template*.
	// A true Action is Template + Context.
	// For example, Attack(<X>) is a Template where X is a context variable.
	// Attack(BadDude) is an Action where we bound BadDude as the value of X in the Attack(<X>) Template.
	//
	// IMPORTANT: While you *can* technically subclass these, a better idea is to use JSONs and SerDe methods to
	//            load in ActionTemplates from files. This makes the AI much faster to iterate on and 'moddable'.
	*/
	var/name = "Action"
	var/description = null
	var/active = TRUE  // meant to granularly disable options (e.g. for cooldowns) without affecting the whole ActionSet.
	var/context_fetcher = null // a proc that generates candidate context for the action
	var/handler = null
	var/instant = FALSE
	var/charges = PLUS_INF

	// Weight multiplier for a given action's urgency; please use the macro'd values for this!
	var/priority_class = UTILITY_PRIORITY_BROKEN // If SerDe goes bad, this will wind up being zero and so ignore malformed Templates

	// An arraylist of Considerations to check when deciding.
	var/list/considerations


/datum/utility_action_template/New(var/list/bound_considerations, var/handler = null, var/context_fetcher = null, var/priority = null, var/charges = null, var/instant = null, var/name_override = null, var/description_override = null, var/active = null)
	SET_IF_NOT_NULL(bound_considerations, src.considerations)
	SET_IF_NOT_NULL(context_fetcher, src.context_fetcher)
	SET_IF_NOT_NULL(handler, src.handler)
	SET_IF_NOT_NULL(priority, src.priority_class)
	SET_IF_NOT_NULL(charges, src.charges)
	SET_IF_NOT_NULL(instant, src.instant)
	SET_IF_NOT_NULL(name_override, src.name)
	SET_IF_NOT_NULL(description_override, src.description)
	SET_IF_NOT_NULL(active, src.active)

	if(!src.considerations)
		UTILITYBRAIN_DEBUG_LOG("WARNING: no Considerations bound to Action [src.name] @ L[__LINE__]!")

	if(!src.handler)
		UTILITYBRAIN_DEBUG_LOG("WARNING: no Handler bound to Action [src.name] @ L[__LINE__]!")


/datum/utility_action_template/proc/GetCandidateContexts(var/requester) // Optional<Any> -> Optional<array<assoc>>
	/*
	// A mostly-convenience-API for fetching all *RELEVANT* contexts.
	// Little more than a wrapper over a dispatch to the bound proc.
	//
	// Emphasis on relevant b/c you SHOULD NOT test all possible candidates;
	// if a context is not particularly likely to succeed, don't fetch it at all!
	*/
	if(!(src.context_fetcher))
		UTILITYBRAIN_DEBUG_LOG("WARNING: no ContextFetcher bound to Action [src.name] @ L[__LINE__]!")
		return

	var/list/contexts = call(src.context_fetcher)(src, requester)
	UTILITYBRAIN_DEBUG_LOG("INFO: found [contexts?.len] contexts for Action [src.name] @ L[__LINE__]")
	return contexts


/datum/utility_action_template/proc/ScoreAction(var/list/context, var/requester) // (Optional<assoc>, Optional<Any>) -> float
	// Evaluates the Utility of a potential Action in the given context.
	// One Action might have different Utility for different Contexts.
	// As such, we can check multiple combinations of Template + Context and only turn the best into true Actions.
	var/score = run_considerations(
		inputs=src.considerations,
		context=context,
		cutoff_thresh=null,
		requester=requester
	)
	var/utility = score * src.priority_class
	return utility


/datum/utility_action_template/proc/ToAction(var/list/bound_context, var/handler_override = null, var/charges_override = null, var/instant_override = null) // Optional<assoc> -> UtilityAction
	// Turns a template into a concrete Action for the Agent to run; effectively an Action factory.
	var/action_name = src.name // todo bind args here too
	var/handler = DEFAULT_IF_NULL(handler_override, src.handler)
	var/charges = DEFAULT_IF_NULL(charges_override, src.charges)
	var/instant = DEFAULT_IF_NULL(instant_override, src.instant)
	var/list/action_args = bound_context

	var/datum/utility_action/new_action = new(action_name, handler, charges, instant, action_args)
	return new_action

