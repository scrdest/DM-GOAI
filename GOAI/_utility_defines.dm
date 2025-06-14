/*
// Macros for the Utility AI module.
// Would it be nicer to have them grouped with the actual code? Yes.
// Is the DM compiler dumber than a bag of extra-chonky bricks and so we cannot do that? Also yes.
*/



/* ============================================= */

// Normalization scale for Activations.
// We can scale either 0 -> 1 or 0 -> 100, not sure yet what's better so we'll macro it
# define ACTIVATION_NONE 0
# define ACTIVATION_FULL 1

// Abstracting for the sake of replacing w/ less of a hack later (maybe the new `::` operator?)
# define STR_TO_PROC(procpath) text2path(procpath)


/* ============================================= */

/*
// Functions inlined for efficiency, because see top comment:
*/

// (1) Clamps input to low/high bookmarks & (2) scales the result to the slice of the bookmark interval (e.g. i=5 for lo=2, hi=8 == 50%)
# define NORMALIZE_UTILITY_INPUT(i, Lo, Hi) (ACTIVATION_FULL * ((clamp(i, Lo, Hi) - Lo) / (Hi - Lo)))

// Corrective factor calculations; we need this, otherwise multiple constraints bias scores down.
// Based on the Mike Lewis/Dave Mark lecture @ GDC15
# define UTILITY_MITIGATING_FACTOR(NumConstraints) (1 - (1 / max(1, NumConstraints || 0)))

// vvv THIS is the actual correction, the above is just a helper
# define CORRECT_UTILITY_SCORE(Score, NumConstraints) (Score + (Score * UTILITY_MITIGATING_FACTOR(NumConstraints)))

// Core utility calculation - normalize inputs, fuzz, then get an Activation response from a curve.
// e.g. UTILITY_CONSIDERATION(5, 2, 8, 0, GLOBAL_PROC_REF(curve_linear)) => 0.5
//  or: UTILITY_CONSIDERATION(5, 2, 8, 0, GLOBAL_PROC_REF(curve_binary)) => 0.0
//  or: UTILITY_CONSIDERATION(5, 0, 4, 0, GLOBAL_PROC_REF(curve_linear)) => 1.0
//  or: UTILITY_CONSIDERATION(5, 0, 4, 50, GLOBAL_PROC_REF(curve_linear)) => (0.5 to 1.0)
//  or: UTILITY_CONSIDERATION(3, 0, 4, 25, GLOBAL_PROC_REF(curve_linear)) => (0.5 to 1.0)
//  or: UTILITY_CONSIDERATION(5, 2, 8, 50, GLOBAL_PROC_REF(curve_linear)) => (0.0 to 1.0)
// Note that at NoisePerc>=100, the curve inputs are dominated by noise.
# define UTILITY_CONSIDERATION(RawData, LoMark, HiMark, NoisePerc, CurveProc) call(CurveProc)(clamp(NORMALIZE_UTILITY_INPUT(RawData, LoMark, HiMark) + ((rand() - 0.5) * (NoisePerc / 50)), ACTIVATION_NONE, ACTIVATION_FULL))


/* ============================================= */

/*
// Priority weights.
//
// Raw adjusted score gets multiplied by this to get 'true' Utility.
// IOW, a fully-activated Normal action will never beat a fully-activated Urgent action
//      but a full-activation Normal may beat a weak Urgent.
*/

// If you see that, someone messed up and this action should be ignored as malformed
# define UTILITY_PRIORITY_BROKEN 0

// Ambient/idle interactions:
# define UTILITY_PRIORITY_LOW 1

// Generic 'do stuff' actions:
# define UTILITY_PRIORITY_NORMAL 2

// Important 'relaxed' actions like dealing with critical needs, or unimportant alert actions like patrolling:
# define UTILITY_PRIORITY_ELEVATED 4

// Executing the current GOAP plan:
# define UTILITY_PRIORITY_PLANACTION 6

// Very short-term life-or-death risk reactions, e.g. self-defense, running away:
# define UTILITY_PRIORITY_URGENT 8

// IMMEDIATE emergencies, e.g. using a Heal ability when on the last few points of HP
// There's no point in running away if you'll just bleed out in the process, after all:
# define UTILITY_PRIORITY_EMERGENCY 16

// Soft override, should be only used rarely, if ever.
// Could come up if you use a hierarchical AI, e.g. master/minion, where the master can force available actions:
# define UTILITY_PRIORITY_FORCED 128


# define DEFAULT_PLANACTION_PRIORITY UTILITY_PRIORITY_PLANACTION

/* ============================================= */

/* == Context Keys == */
# define CTX_KEY_POSITION "position"
# define CTX_KEY_FILTERTYPE "if_contains_type"


/* ============================================= */

/* ====  SerDe JSON schemas  ==== */

// Generic:
# define JSON_KEY_VERSION "version"

// Consideration schema:
# define JSON_KEY_CONSIDERATION_INPPROC "input_proc"
# define JSON_KEY_CONSIDERATION_CURVEPROC "curve_proc"
# define JSON_KEY_CONSIDERATION_LOMARK "lo_mark"
# define JSON_KEY_CONSIDERATION_HIMARK "hi_mark"
# define JSON_KEY_CONSIDERATION_NOISESCALE "noise_scale"
# define JSON_KEY_CONSIDERATION_NAME "name"
# define JSON_KEY_CONSIDERATION_DESC "description"
# define JSON_KEY_CONSIDERATION_ACTIVE "active"
# define JSON_KEY_CONSIDERATION_ARGS "input_args"

// ActionTemplate schema:
# define JSON_KEY_CONSIDERATIONS "considerations"
# define JSON_KEY_ACT_CTXPROC "context_procs"
# define JSON_KEY_ACT_CTXARGS "context_args"
# define JSON_KEY_ACT_HANDLER "handler"
# define JSON_KEY_ACT_HANDLERTYPE "is_function"
# define JSON_KEY_ACT_HARDARGS "args"  // hardcoded args, to avoid code duplication for nearly identical Actions
# define JSON_KEY_ACT_PRIORITY "priority"
# define JSON_KEY_ACT_CHARGES "charges"
# define JSON_KEY_ACT_ISINSTANT "instant"
# define JSON_KEY_ACT_NAME "name"
# define JSON_KEY_ACT_DESCRIPTION "description"
# define JSON_KEY_ACT_ACTIVE "active"
# define JSON_KEY_ACT_PRECONDS "preconditions"
# define JSON_KEY_ACT_EFFECTS "effects"
# define JSON_KEY_ACT_MINLOD "min_lod"
# define JSON_KEY_ACT_MAXLOD "max_lod"

// ActionSet schema:
# define JSON_KEY_ACTSET_NAME "name"
# define JSON_KEY_ACTSET_ACTIVE "active"
# define JSON_KEY_ACTSET_ACTIONS "actions"

# define JSON_KEY_ACTSET_TTL_REMOVE "ttl_removal"
# define JSON_KEY_ACTSET_TTL_DEACTIVATE "ttl_deactivate"
# define JSON_KEY_ACTSET_TIME_RETRIEVED "time_retrieved"
# define JSON_KEY_ACTSET_FRESHNESS_PROC "freshness_proc"
# define JSON_KEY_ACTSET_FRESHNESS_PROC_ARGS "freshness_proc_args"

// Utility/GOAP interface schema:
# define JSON_KEY_PLANACTION_ACTIONKEY "key"
# define JSON_KEY_PLANACTION_RAW_HANDLERPROC "raw_handler"
# define JSON_KEY_PLANACTION_HANDLERPROC "handler"
# define JSON_KEY_PLANACTION_PRIORITY "priority"
# define JSON_KEY_PLANACTION_PRECONDITIONS "preconditions"
# define JSON_KEY_PLANACTION_EFFECTS "effects"
# define JSON_KEY_PLANACTION_TARGET_KEY "target_key"
# define JSON_KEY_PLANACTION_HANDLER_LOCARG "location_key"
# define JSON_KEY_PLANACTION_HANDLER_ISFUNC "is_function"
# define JSON_KEY_PLANACTION_HASMOVEMENT "has_movement"
# define JSON_KEY_PLANACTION_DESCRIPTION "description"
# define JSON_KEY_PLANACTION_CTXARGS "context_args"
# define JSON_KEY_PLANACTION_CTXFETCHER_OVERRIDE "context_fetcher"

// PersonalityTemplate schema
# define PERSONALITY_KEY_TRAIT_NAME "name"
# define PERSONALITY_KEY_MIN_VALUE "min_value"
# define PERSONALITY_KEY_MAX_VALUE "max_value"


/*
// Personality trait keys
//
// (NOTE: not necessarily exhaustive! These can be defined arbitrarily in PersonalityTemplates
//  what you see here is keys we might NEED to reference in code)
*/

// Effectively 'damage'-reduction on morale loss from hits.
# define PERSONALITY_TRAIT_STEADFAST "Steadfast"

/* ============================================= */

# define RETAIN_LAST_ACTIONS_TTL 300

# define DYNAMIC_QUERY_CACHE_TTL 20
# define DYNAMIC_QUERY_CACHE_GLOBAL_TTL 3000
# define DYNAMIC_QUERY_CACHE_GLOBAL_TTL_FUZZ 20

// Pawn-handling
# ifdef GOAI_LIBRARY_FEATURES
	#define RESOLVE_PAWN(PawnVar) (PawnVar)
	#define REFERENCE_PAWN(PawnVar) (PawnVar)
# endif

# ifdef GOAI_SS13_SUPPORT
	#define RESOLVE_PAWN(PawnVar) (GOAI_LIBBED_WEAKREF_RESOLVE(PawnVar))
	#define REFERENCE_PAWN(PawnVar) (weakref(PawnVar))
# endif

/*
// The code to implement SmartObjects is extremely boilerplate 99% of the time. These macros write it for you.
*/
# define GOAI_ACTIONSET_FROM_FILE_BOILERPLATE(OBJTYPE, AS_FNAME) \
\
##OBJTYPE/GetUtilityActions(var/requester, var/list/args = null) { \
	var/list/my_action_sets = list(); \
	ASSERT(fexists(AS_FNAME)); \
	var/datum/action_set/myset = ActionSetFromJsonFile(AS_FNAME); \
	myset.origin = src; \
	my_action_sets.Add(myset); \
	return my_action_sets \
} ;

/* HasUtilityActions() impls */

// Always available:
# define GOAI_HAS_UTILITY_ACTIONS_BOILERPLATE_ALWAYS(OBJTYPE) \
\
##OBJTYPE/HasUtilityActions(var/requester, var/list/args = null) { \
	return TRUE \
} ;

// Available if a list in our variable is non-empty:
# define GOAI_HAS_UTILITY_ACTIONS_BOILERPLATE_VARLIST(OBJTYPE, LISTVAR) \
##OBJTYPE/HasUtilityActions(var/requester, var/list/args = null) {\
	return (##LISTVAR) \
} ;

// Is 'us', broadly speaking:
# define GOAI_HAS_UTILITY_ACTIONS_BOILERPLATE_ISPAWN(OBJTYPE) \
\
##OBJTYPE/HasUtilityActions(var/requester, var/list/args = null) { \
	if(requester == src) {\
		return TRUE \
	}; \
	var/datum/utility_ai/mob_commander/commander = requester; \
	if(!istype(commander)) {\
		return FALSE \
	}; \
	var/pawn = commander.GetPawn(); \
	return (pawn == src) \
};

// Available if nearby (by Chebyshev dist; requires source to be an atom!):
# define GOAI_HAS_UTILITY_ACTIONS_BOILERPLATE_PROXIMITY_CHEBYSHEV(OBJTYPE, MAXDIST) \
##OBJTYPE/HasUtilityActions(var/requester, var/list/args = null) {\
	var/atom/requester_atom = requester; \
	if(istype(requester_atom)) { \
		return (CHEBYSHEV_DISTANCE_TWOD(requester_atom, src, PLUS_INF) <= MAXDIST) \
	}; \
	var/datum/utility_ai/mob_commander/commander = requester; \
	if(!istype(commander)) {\
		return FALSE \
	}; \
	var/atom/pawn = commander.GetPawn(); \
	return (CHEBYSHEV_DISTANCE_TWOD(pawn, src, PLUS_INF) <= MAXDIST) \
};

// Available if nearby (by Manhattan dist; requires source to be an atom!):
# define GOAI_HAS_UTILITY_ACTIONS_BOILERPLATE_PROXIMITY_MANHATTAN(OBJTYPE, MAXDIST) \
##OBJTYPE/HasUtilityActions(var/requester, var/list/args = null) {\
	var/atom/requester_atom = requester; \
	if(istype(requester_atom)) { \
		return (MANHATTAN_DISTANCE_TWOD(requester_atom, src, PLUS_INF) <= MAXDIST) \
	}; \
	var/datum/utility_ai/mob_commander/commander = requester; \
	if(!istype(commander)) {\
		return FALSE \
	}; \
	var/atom/pawn = commander.GetPawn(); \
	return (MANHATTAN_DISTANCE_TWOD(pawn, src, PLUS_INF) <= MAXDIST) \
};

// Available if in inventory/contents, non-recursively:
# define GOAI_HAS_UTILITY_ACTIONS_BOILERPLATE_INVENTORY_SIMPLE(OBJTYPE) \
##OBJTYPE/HasUtilityActions(var/requester, var/list/args = null) { \
	var/atom/requester_atom = requester; \
	if(istype(requester_atom)) { \
		return (src in requester_atom) \
	}; \
	var/datum/utility_ai/mob_commander/commander = requester; \
	if(!istype(commander)) { \
		return FALSE \
	}; \
	var/atom/pawn = commander.GetPawn(); \
	return (src in pawn) \
};


// Available if a memory value for a given key is exactly this entity:
# define GOAI_HAS_UTILITY_ACTIONS_BOILERPLATE_IS_MEMORY(OBJTYPE, MemoryKey) \
##OBJTYPE/HasUtilityActions(var/requester, var/list/args = null) { \
	var/datum/utility_ai/commander = requester; \
	if(!istype(commander)) { \
		return FALSE \
	}; \
	var/datum/brain/commander_brain = commander.brain; \
	if(!istype(commander_brain)) { \
		return FALSE \
	}; \
	var/mem = commander_brain.GetMemoryValue(MemoryKey); \
	return (src == mem) \
};

// Available if a memory value for a given key CONTAINS this entity (generally, memories storing lists):
# define GOAI_HAS_UTILITY_ACTIONS_BOILERPLATE_INSIDE_MEMORY(OBJTYPE, MemoryKey) \
##OBJTYPE/HasUtilityActions(var/requester, var/list/args = null) { \
	var/datum/utility_ai/commander = requester; \
	if(!istype(commander)) { \
		return FALSE \
	}; \
	var/datum/brain/commander_brain = commander.brain; \
	if(!istype(commander_brain)) { \
		return FALSE \
	}; \
	var/list/mem = commander_brain.GetMemoryValue(MemoryKey); \
	return (islist(mem) && (src in mem)) ; \
};
