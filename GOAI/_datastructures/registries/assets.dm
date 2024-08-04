/*
// Various entities will need to have their assets (money, commodities) tracked for economy purposes.
//
// We COULD do it OOP-style and do it on each datum, but that would be painfully heterogenous and not
// really take any advantage of OOP features anyway, as this logic is abstract and uniform.
//
// It would also mean allocating memory for a ton of entities which will NEVER use it in any way.
// Instead, we'll do it ECS/database style, any entity that needs to have an 'account' here will
// just need to register its (stable) ID into a list here.
//
// A positive side-effect is that if suddenly your sandwich needs to track its $$$, we COULD do it
// without extending the class API in any way - just calling to register it and to update as needed.
*/

# ifdef GOAI_LIBRARY_FEATURES
var/global/list/global_asset_registry
# endif
# ifdef GOAI_SS13_SUPPORT
GLOBAL_LIST_EMPTY(global_asset_registry)
# endif

#define ASSETS_TABLE_LAZY_INIT(_Unused) if(isnull(GOAI_LIBBED_GLOB_ATTR(global_asset_registry)) || !islist(GOAI_LIBBED_GLOB_ATTR(global_asset_registry))) { GOAI_LIBBED_GLOB_ATTR(global_asset_registry) = list() }

#define HAS_REGISTERED_ASSETS(id) (id && GOAI_LIBBED_GLOB_ATTR(global_asset_registry) && (id in GOAI_LIBBED_GLOB_ATTR(global_asset_registry)))
#define CREATE_ASSETS_TRACKER(id) (GOAI_LIBBED_GLOB_ATTR(global_asset_registry)[id] = list())
#define GET_ASSETS_TRACKER(id) (GOAI_LIBBED_GLOB_ATTR(global_asset_registry)[id])
#define UPDATE_ASSETS_TRACKER(id, new_data) (GOAI_LIBBED_GLOB_ATTR(global_asset_registry)[id] = new_data)
