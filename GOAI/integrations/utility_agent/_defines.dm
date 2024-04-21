
#define UTILITY_SMARTOBJECT_SENSES 1


# ifdef GOAI_LIBRARY_FEATURES
	#define RESOLVE_PAWN(PawnVar) (PawnVar)
	#define REFERENCE_PAWN(PawnVar) (PawnVar)
# endif

# ifdef GOAI_SS13_SUPPORT
	#define RESOLVE_PAWN(PawnVar) (PawnVar?.resolve())
	#define REFERENCE_PAWN(PawnVar) (weakref(PawnVar))
# endif
