// Keys for the needfuls
# define NEED_COVER "cover"
# define NEED_PATROL "patrol"
# define NEED_ENEMIES "enemies"
# define NEED_OBEDIENCE "obedience"

// Keys for the states
# define STATE_INCOVER "in_cover"
# define STATE_DOWNTIME "no_orders"
# define STATE_HASGUN "has_gun"
# define STATE_CANFIRE "can_shoot"

// Subsystem loop schedules
# define COMBATAI_AI_TICK_DELAY 5
# define COMBATAI_MOVE_TICK_DELAY 5
# define COMBATAI_FIGHT_TICK_DELAY 25

//
# define MEM_TIME_LONGTERM 10000

// Keys for the memory dict
# define MEM_SHOTAT "ShotAt"
# define MEM_THREAT "Threat"
# define MEM_CURRLOC "MyCurrLocation"
# define MEM_PREVLOC "MyPrevLocation"

// Penalty value that should entirely eliminate an option unless there's absolutely no alternatives:
# define MAGICNUM_DISCOURAGE_SOFT 10000

// Various keys used by 'AI ghost' data (last-known-pos stuff)
# define KEY_GHOST_X "posX"
# define KEY_GHOST_Y "posY"
# define KEY_GHOST_Z "posZ"
# define KEY_GHOST_POS_TUPLE "posTuple"
# define KEY_GHOST_POS_TRIPLE "posTriple"
# define KEY_GHOST_ANGLE "posAngle"
