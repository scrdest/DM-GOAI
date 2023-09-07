# define STEP_TRIGGER_INVISIBILITY 101

/proc/yeet_trg_up(var/atom/movable/trg)
	world << "YEET!"

	if(!istype(trg, /atom/movable))
		return FALSE

	var/next_z = ((trg.z || world.maxz) + 1)
	if(next_z > world.maxz)
		next_z = 1

	if(next_z)
		trg.z = next_z
		return TRUE

	return FALSE


/proc/yeet_trg_down(var/atom/movable/trg)
	if(!istype(trg, /atom/movable))
		return FALSE

	var/next_z = ((trg.z || 1) - 1)
	if(next_z <= 0)
		next_z = world.maxz

	if(next_z)
		trg.z = next_z
		return TRUE

	return FALSE


/proc/yeet_trg_to_z(var/atom/movable/trg, var/to_z)
	if(!istype(trg, /atom/movable))
		return FALSE

	if(!to_z || to_z > world.maxz)
		return FALSE

	trg.z = to_z
	return TRUE


/atom/proc/yeet_up()
	return yeet_trg_up(src)

/atom/proc/yeet_down()
	return yeet_trg_down(src)

/atom/proc/yeet_to_z(var/to_z)
	return yeet_trg_to_z(src, to_z)


/obj/step_trigger
	var/step_include_trigger_obj = TRUE
	var/step_callback = null
	var/list/step_callback_args = null

	var/unstep_include_trigger_obj = TRUE
	var/unstep_callback = null
	var/list/unstep_callback_args = null

	invisibility = STEP_TRIGGER_INVISIBILITY


/obj/step_trigger/Crossed(var/atom/movable/O)
	. = ..(O)

	if(src.step_callback)
		spawn(0)
			var/list/_cbargs = list()

			if(src.step_include_trigger_obj)
				_cbargs.Add(O)

			if(!isnull(src.step_callback_args))
				_cbargs.Add(src.step_callback_args)

			call(src.step_callback)(arglist(_cbargs))


/obj/step_trigger/Uncrossed(var/atom/movable/O)
	. = ..(O)

	if(src.unstep_callback)
		spawn(0)
			var/list/_cbargs = list()

			if(src.unstep_include_trigger_obj)
				_cbargs.Add(O)

			if(!isnull(src.unstep_callback_args))
				_cbargs.Add(src.unstep_callback_args)

			call(src.unstep_callback)(arglist(_cbargs))


/obj/step_trigger/deepmaint_teleport
	unstep_callback = /proc/yeet_trg_up
