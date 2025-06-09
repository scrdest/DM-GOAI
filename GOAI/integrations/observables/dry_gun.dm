//	Observer Pattern Implementation: Gun Dry
//		Registration type: /obj/item
//
//		Raised when: Something tries to fire a weapon but fails due to it being out of ammo.
//		             Should NOT be raised if the item does NOT take ammo or fails for unrelated reasons.
//
//		Arguments that the called proc should expect:
//			/obj/item/weapon: The thing that needs reloading.

GLOBAL_TYPED_NEW(gun_dry_event, /singleton/observ/gun_dry)

/singleton/observ/gun_dry
	name = "Gun Is Dry"
	expected_type = /obj/item
