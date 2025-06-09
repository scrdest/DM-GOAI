// Assoc list that will store handles to SmartObjects
// to avoid duplicating a ton of heavy I/O work needlessly.

GLOBAL_LIST_EMPTY(smartobject_cache)

// The _Unused arg is just for call-like syntax
# define SMARTOBJECT_CACHE_LAZY_INIT(_Unused) if(isnull(GOAI_LIBBED_GLOB_ATTR(smartobject_cache)) || !islist(GOAI_LIBBED_GLOB_ATTR(smartobject_cache))) { GOAI_LIBBED_GLOB_ATTR(smartobject_cache) = list() }
