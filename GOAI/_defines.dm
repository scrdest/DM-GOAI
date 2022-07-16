# define PI 3.14159265
# define LOG2(x) log(2, x)

# define AI_TICK_DELAY 5

# define NEED_MINIMUM 0
# define NEED_THRESHOLD 50
# define NEED_SAFELEVEL 75
# define NEED_SATISFIED 95
# define NEED_MAXIMUM 100

# define MOTIVE_SLEEP "Energy"
# define MOTIVE_FOOD "Calories"
# define MOTIVE_FUN "Entertainment"

# define RESOURCE_FOOD "FoodItems"
# define RESOURCE_MONEY "Money"
# define RESOURCE_TIME "Time"

# define PLUS_INF 1.#INF
# define GOAP_KEY_SRC "source"

# ifdef DEBUG_LOGGING
# define MAYBE_LOG(X) world.log << X
# define MAYBE_LOG_TOSTR(X) world.log << #X + ": [X]"
# else
# define MAYBE_LOG(X)
# define MAYBE_LOG_TOSTR(X)
# endif

# define get_turf(A) get_step(A,0)

# define GUN_DISPERSION 5
