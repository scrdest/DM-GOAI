//	Observer Pattern Implementation: Meleed By
//		Registration type: /atom
//
//		Raised when: A melee attack of some sort attempts to impact the target.
//		             This does NOT require a successful hit (can be raised on whiffs).
//
//		Arguments that the called proc should expect:
//			/atom/victim: The thing that (almost) got hit.
//			/atom/source: The thing that (almost) hit us.

GLOBAL_TYPED_NEW(meleed_by_event, /singleton/observ/meleed_by)

/singleton/observ/meleed_by
	name = "Meleed By"
	expected_type = /atom
