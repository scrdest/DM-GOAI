
# ifdef GOAI_LIBRARY_FEATURES
GOAI_ACTIONSET_FROM_FILE_BOILERPLATE(/obj/cover/table, GOAI_SMARTOBJECT_PATH("table.json"))
GOAI_HAS_UTILITY_ACTIONS_BOILERPLATE_PROXIMITY_CHEBYSHEV(/obj/structure/table, 1)
# endif

# ifdef GOAI_SS13_SUPPORT
GOAI_ACTIONSET_FROM_FILE_BOILERPLATE(/obj/structure/table, GOAI_SMARTOBJECT_PATH("ss13_table.json"))
GOAI_HAS_UTILITY_ACTIONS_BOILERPLATE_PROXIMITY_CHEBYSHEV(/obj/structure/table, 1)
# endif
