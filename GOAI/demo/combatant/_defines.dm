// Keys for the needfuls
# define NEED_COVER "cover"
# define NEED_PATROL "patrol"
# define NEED_ENEMIES "enemies"
# define NEED_OBEDIENCE "obedience"
# define NEED_COMPOSURE "composure"

// Keys for the states
# define STATE_INCOVER "in_cover"
# define STATE_DOWNTIME "no_orders"
# define STATE_HASGUN "has_gun"
# define STATE_CANFIRE "can_shoot"
# define STATE_PANIC "panic"

// Subsystem loop schedules
# define COMBATAI_SENSE_TICK_DELAY 3
# define COMBATAI_AI_TICK_DELAY 5
# define COMBATAI_MOVE_TICK_DELAY 5
# define COMBATAI_FIGHT_TICK_DELAY 25

// Memory system constants
# define MEM_TIME_LONGTERM 10000

// Keys for the memory dict
# define MEM_SHOTAT "ShotAt"
# define MEM_THREAT "Threat"
# define MEM_THREAT_SECONDARY "ThreatSecondary"
# define MEM_WAYPOINT_LKP "WaypointLKP"
# define MEM_CURRLOC "MyCurrLocation"
# define MEM_PREVLOC "MyPrevLocation"

// Penalty value that should entirely eliminate an option unless there's absolutely no alternatives:
# define MAGICNUM_DISCOURAGE_SOFT 10000

// How much getting shot decays the AI's COMPOSURE need.
# define MAGICNUM_COMPOSURE_LOSS_ONHIT 10

// Various keys used by 'AI ghost' data (last-known-pos stuff)
# define KEY_GHOST_X "posX"
# define KEY_GHOST_Y "posY"
# define KEY_GHOST_Z "posZ"
# define KEY_GHOST_POS_TUPLE "posTuple"
# define KEY_GHOST_POS_TRIPLE "posTriple"
# define KEY_GHOST_ANGLE "posAngle"

# define KEY_ACTION_AIM "Aim"
# define KEY_AIM_TARGET "aimTarget"

# define WAYPOINT_FUZZ_X 5
# define WAYPOINT_FUZZ_Y 5

# define KEY_PERS_MINSAFEDIST "MinSafeDist"
# define KEY_PERS_FRUSTRATION_THRESH "FrustrationRepathMaxthresh"