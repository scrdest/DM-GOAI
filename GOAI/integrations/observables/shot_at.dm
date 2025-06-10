//	Observer Pattern Implementation: Shot At
//		Registration type: /atom
//
//		Raised when: A ranged attack of some sort attempts to impact the target.
//		             This does NOT require a successful hit (can be raised on whiffs).
//
//		Arguments that the called proc should expect:
//			/atom/victim: The thing that (almost) got hit.
//			/atom/source: The thing that tried to hit us.
//			/turf/victimloc: Where did we get hit?
//			/turf/sourceloc: Where did the attack come from?
//			angle: Incidence angle of the shot.

GLOBAL_TYPED_NEW(shot_at_event, /singleton/observ/shot_at)

/singleton/observ/shot_at
	name = "Shot At"
	expected_type = /atom
