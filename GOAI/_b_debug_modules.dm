// Uncomment defines as needed to enable various loggers.

//# define DEBUG_LOGGING 0
// # define RAYTRACE_DEBUG_LOGGING 0
// # define ADD_ACTION_DEBUG_LOGGING 0
# define RUN_ACTION_DEBUG_LOGGING 0
//# define MOVEMENT_DEBUG_LOGGING 0
// # define OBSTACLEHUNT_DEBUG_LOGGING 0
// # define VALIDATE_ACTION_DEBUG_LOGGING 0
# define ACTION_RUNTIME_DEBUG_LOGGING 0
# define ACTIONTRACKER_DEBUG_LOGGING 0
# define PLANNING_DEBUG_LOGGING 0
# define MOTIVES_DEBUG_LOGGING 0
//# define DIRBLOCKER_DEBUG_LOGGING 0
//# define GOAP_INSPECTION_LOGGING 0
# define UTILITYBRAIN_DEBUG_LOGGING 0
# define UTILITYBRAIN_LOG_UTILITIES 0
//# define UTILITYBRAIN_LOG_CONTEXTS 0
//# define UTILITYBRAIN_LOG_CONTROLLER_LOOKUP 0
//# define UTILITYBRAIN_LOG_ACTIONCOUNT 0
# define UTILITYBRAIN_LOG_CONSIDERATION_INPUTS 0
# define UTILITYBRAIN_LOG_AXIS_SCORES 0
//# define UTILITYBRAIN_LOG_CURVE_INPUTS 0

# define DEBUG_UTILITY_INPUT_FETCHERS 1

# ifdef ACTION_RUNTIME_DEBUG_LOGGING
# define ACTION_RUNTIME_DEBUG_LOG(X) to_world_log(X)
# else
# define ACTION_RUNTIME_DEBUG_LOG(X)
# endif


# ifdef DEBUG_LOGGING
#define MAYBE_LOG(X) to_world_log(X)
#define MAYBE_LOG_TOSTR(X) to_world_log(#X + ": [X]")
# else
#define MAYBE_LOG(X)
#define MAYBE_LOG_TOSTR(X)
# endif
