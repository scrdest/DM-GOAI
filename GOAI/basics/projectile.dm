# ifdef GOAI_LIBRARY_FEATURES

/obj/projectile
	name = "Projectile"
	//icon = 'icons/effects/beam.dmi'
	icon = 'icons/obj/projectiles.dmi'
	//icon_state = "b_beam"
	icon_state = "laser"

	var/atom/source = null
	var/scale = 1
	var/dist = 1
	var/angle = 0
	var/lifetime = 5


/obj/projectile/New(var/atom/new_source = null, var/new_scale = null, var/new_dist = null, var/new_angle = null, var/custom_sprite = null)
	..()

	source = (isnull(new_source) ? loc : new_source)
	src.UpdateVector(new_source, new_scale, new_dist, new_angle)
	name = "Beam @ [source]"

	icon_state = (isnull(custom_sprite) ? icon_state : custom_sprite)

	src.PostNewHook()


/obj/projectile/proc/UpdateVector(var/atom/new_source = null, var/new_scale = null, var/new_dist = null, var/new_angle = null)
	source = (isnull(new_source) ? source : new_source)
	scale = (isnull(new_scale) ? scale : new_scale)
	dist = (isnull(new_dist) ? dist : new_dist)
	angle = (isnull(new_angle) ? angle : new_angle)

	var/matrix/beam_transform = new()
	var/turn_angle = -angle // normal Turn() is clockwise (y->x), we want (x->y).
	var/x_translate = dist * cos(angle)
	var/y_translate = dist * sin(angle)

	if((angle > 135 || angle <= -45))
		// some stupid nonsense with how matrix.Turn() works requires this
		turn_angle = 180 - angle

	beam_transform.Scale(1, scale)

	beam_transform.Turn(90) // the icon is vertical, so we reorient it to x-axis alignment
	beam_transform.Turn(turn_angle)

	beam_transform.Translate(0.5 * x_translate * world.icon_size, 0.5 * y_translate * world.icon_size)

	src.x = source.x
	src.y = source.y
	src.transform = beam_transform


/obj/projectile/proc/PostNewHook()
	var/true_lifetime = lifetime // placeholder for proper validation :^)

	spawn(true_lifetime)
		del(src)


/gun_cycle_handler
	// An attachment that contains cycling (cooldown, reload, etc.) logic for guns.
	var/shoot_allowed = FALSE
	var/owned_gun = null


/gun_cycle_handler/New(var/owned_obj)
	if(owned_obj)
		src.owned_gun = GOAI_LIBBED_WEAKREF(owned_obj)
	return


/gun_cycle_handler/proc/force_allow()
	// Should reset the handler to whatever state is needed to allow shooting.
	// Meant to be used for external callers for things like reload logic, where
	// we coerce the thing into a known shootable state.
	return


/gun_cycle_handler/proc/handle_post_shot()
	// Anything that should happen after each shot.
	// Can include cooldown, cycling (for semiauto), etc.
	return


/gun_cycle_handler/always
	// Can always shoot
	shoot_allowed = TRUE


/gun_cycle_handler/cooldown
	// A cycle limited by a cooldown time
	var/cooling = FALSE
	var/cooldown_time_deterministic = 17
	var/cooldown_time_random = 3


/gun_cycle_handler/cooldown/handle_post_shot()
	src.shoot_allowed = FALSE
	if(!src.cooling)
		src.cooldown()
	return


/gun_cycle_handler/cooldown/force_allow()
	src.shoot_allowed = TRUE
	src.cooling = FALSE
	return


/gun_cycle_handler/cooldown/proc/cooldown()
	set waitfor = FALSE

	if(src.cooling)
		// avoid double-cooling which would cause weird flip-flopping due to concurrency issues
		return

	src.cooling = TRUE
	sleep(cooldown_time_deterministic + rand(-cooldown_time_random, cooldown_time_random))
	src.cooling = FALSE
	src.shoot_allowed = TRUE
	return


/gun_cycle_handler/reload_owned
	// a reload cycle-handler that owns the bullets (as opposed to reffing the gun for them)
	var/ammo_capacity = 6
	var/ammo_current = 6


/gun_cycle_handler/reload_owned/handle_post_shot()
	src.ammo_current--

	if(src.ammo_current <= 0)
		src.ammo_current = 0
		src.shoot_allowed = FALSE

		// raise the Gun Dry event
		var/obj/item/mygun = GOAI_LIBBED_WEAKREF_RESOLVE(src.owned_gun)
		if(istype(mygun))
			GOAI_LIBBED_GLOB_ATTR(gun_dry_event.raise_event(mygun))
	return


/obj/item/gun
	name = "Gun"
	icon = 'icons/obj/gun.dmi'
	icon_state = "laser"

	var/ammo_sprite = null
	var/dispersion = GUN_DISPERSION
	var/projectile_raycast_flags = RAYTYPE_BEAM

	var/cycle_handler_path = /gun_cycle_handler/cooldown
	var/gun_cycle_handler/cycle_handler = null


/obj/item/gun/New(var/atom/location)
	..()

	loc = location

	ammo_sprite = pick(
		1; "laser",
		1; "bluelaser",
		1; "xray",
	)

	if(!istype(src.cycle_handler))
		if(ispath(src.cycle_handler_path, /gun_cycle_handler))
			src.cycle_handler = new src.cycle_handler_path()

	return


/obj/item/gun/proc/shoot(var/atom/At, var/atom/From)
	if(!(src.cycle_handler?.shoot_allowed))
		return

	src.cycle_handler?.handle_post_shot()

	var/atom/source = (isnull(From) ? src : From)

	var/atom/Hit = AtomDensityRaytrace(source, At, list(source), src.projectile_raycast_flags, dispersion, TRUE)

	if(!istype(Hit))
		// this generally shouldn't happen
		return

	var/dx = null
	var/dy = null

	dx = (Hit.x - source.x)
	dy = (Hit.y - source.y)

	var/vec_length = sqrt(SQR(dx) + SQR(dy))
	var/angle = arctan(dx, dy)
	var/turf/srcloc = get_turf(source)

	var/obj/projectile/newbeam = null

	if(istype(srcloc))
		newbeam = new(srcloc, vec_length, vec_length, angle, ammo_sprite)

	// NOTE: The source of the event is *the thing getting hit*, for the purpose of listeners!
	// We are deeply unlikely to want to listen for a particular gun instead of a particular target.
	GLOB.shot_at_event.raise_event(Hit, get_turf(Hit), source, srcloc, angle)

	Hit.RangedHitBy(angle, From)

	/*
	// legacy event-esque thing
	if(Hit?.attachments)
		var/datum/event_queue/hit/hitqueue = Hit.attachments.Get(ATTACHMENT_EVTQUEUE_HIT)

		if(istype(hitqueue))
			var/datum/event/hit/hit_evt = new("Hit @ [world.time]", angle, From)
			hitqueue.Add(hit_evt)
	*/

	return newbeam


/obj/item/gun/proc/Fire(var/atom/At, var/atom/From)
	src.shoot(At, From)
	return


/obj/item/gun/verb/Shoot(var/atom/At as mob in view())
	set src in view(0)

	if(!(src.cycle_handler?.shoot_allowed))
		to_chat(usr, "[src] cannot shoot right now.")

	else
		shoot(At, usr)


/obj/item/test_grenade
	name = "Grenade???"
	icon = 'icons/obj/grenade.dmi'
	icon_state = "grenade_active"


/obj/item/test_grenade/proc/Boom()
	spawn(10)
		flick("explosion", src)
		sleep(9)
		qdel(src)

# endif


/proc/grenade_yeet(
	# ifdef GOAI_LIBRARY_FEATURES
	var/obj/item/test_grenade/grenade,
	#endif
	# ifdef GOAI_SS13_SUPPORT
	var/obj/item/grenade/grenade,
	#endif
	var/atom/To,
	var/atom/From
)
	if(isnull(grenade))
		return

	if(isnull(To))
		return

	if(isnull(From))
		return

	# ifdef GOAI_LIBRARY_FEATURES
	var/atom/impactee = AtomDensityRaytrace(From, To, list(From), RAYTYPE_PROJECTILE_NOCOVER, FALSE)

	var/expected_dist = get_dist(From, To)
	var/impact_dist = isnull(impactee) ? null : get_dist(From, impactee)

	var/true_impactee = impactee

	if(isnull(impact_dist) || impact_dist > expected_dist)
		true_impactee = To

	var/turf/endturf = get_turf(true_impactee)

	grenade.Boom()

	walk_to(grenade, endturf, ((isturf(true_impactee) && endturf.density) ? 1 : 0))
	#endif

	# ifdef GOAI_SS13_SUPPORT
	grenade.activate()
	grenade.throw_at(To, get_dist(From, To), grenade.throw_speed)
	#endif

	return


/proc/grenade_spawnyeet(var/atom/To, var/atom/From)
	if(isnull(To))
		return

	if(isnull(From))
		return

	var/turf/startturf = get_turf(From)

	if(isnull(startturf))
		return

	# ifdef GOAI_LIBRARY_FEATURES
	var/obj/item/test_grenade/grenade = new(startturf)
	#endif

	# ifdef GOAI_SS13_SUPPORT
	var/obj/item/grenade/grenade = new(startturf)
	#endif

	grenade_yeet(grenade, To, From)
	return
