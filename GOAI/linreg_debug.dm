/*
Temporary disable - gets in the way in the dropdown

/turf/verb/TestLinRegTo()
	set src in view()

	usr << " "
	usr << "SRC: [src], USR: [usr]"
	var/result = LinRegress(AtomToVector2d(usr), AtomToVector2d(src))
	usr << "LinReg result to [src]: [result]"
	usr << " "
	return result
*/

/turf/verb/TestAngleTo()
	set src in view()

	usr << " "
	usr << "SRC: [src], USR: [usr]"
	var/coeff = LinRegress(AtomToVector2d(usr), AtomToVector2d(src))
	var/angle = arctan(coeff)
	usr << "AngleTo result to [src]: [angle]"
	usr << " "
	return angle


/turf/verb/TestEuclidOffsetTo(dist as num)
	set src in view()

	usr << " "
	usr << "SRC: [src], USR: [usr]"
	var/Vector2d/result = GetEuclidStepOffset(AtomToVector2d(usr), AtomToVector2d(src), dist)
	usr << "GetEuclidStepOffset result to [src]: [result] ([result.x], [result.y])"
	return result


/turf/verb/TestEuclidStepToRaw(dist as num)
	set src in view()

	usr << " "
	usr << "SRC: [src], USR: [usr]"
	var/Vector2d/result = GetEuclidStepPos(AtomToVector2d(usr), AtomToVector2d(src), dist)
	usr << "GetEuclidStepPos result to [src]: [result] ([result.x], [result.y])"
	usr << " "
	return result


/turf/verb/TestEuclidStepToTurf(dist as num)
	set src in view()

	usr << " "
	usr << "SRC: [src], USR: [usr]"
	var/Vector2d/result = GetEuclidStepPos(AtomToVector2d(usr), AtomToVector2d(src), dist)
	var/atom/out_pos = CoordsToTurf(result, src.z)

	usr << "CoordsToTurf result: [out_pos]"
	usr << " "
	return out_pos


/turf/verb/TestEuclidWalkToPos(steps as num)
	set src in view()

	var/total_dist = EuclidDistance(usr, src)
	usr << " "
	usr << "SRC: [src], USR: [usr], DIST: [total_dist]"

	var/true_steps = max(1, abs(steps))
	var/stepsize = total_dist / true_steps
	usr << "STEPSIZE: [stepsize]"
	usr << ""

	var/starting_z = usr.z  // in case usr changes z-levels during calculation, we copy by value here

	var/Vector2d/curr_pos = AtomToVector2d(usr)
	var/Vector2d/targ_pos = AtomToVector2d(src)

	var/atom/curr_turf = CoordsToTurf(curr_pos, starting_z)

	var/terminated = FALSE

	for(var/i = 1, i <= true_steps, i++)
		var/curr_step_size = stepsize * i

		if (curr_step_size >= total_dist)
			curr_step_size = total_dist
			terminated = TRUE

		var/Vector2d/step_result = GetEuclidStepPos(curr_pos, targ_pos, curr_step_size)
		usr << "GetEuclidStepPos result TO [targ_pos] ([targ_pos.x], [targ_pos.y]) @ STEP [curr_step_size]: [step_result] ([step_result.x], [step_result.y])"

		curr_turf = CoordsToTurf(step_result, starting_z)

		usr << "CoordsToTurf result FROM [step_result] ([step_result.x], [step_result.y]) TO [targ_pos] ([targ_pos.x], [targ_pos.y]): [curr_turf]"
		usr << " "

		if(terminated)
			break

	usr << " "
	return


/obj/vectorbeam
	name = "Beam"
	icon = 'icons/effects/beam.dmi'
	icon_state = "r_beam"

	var/atom/source = null
	var/scale = 1
	var/dist = 1
	var/angle = 0


/obj/vectorbeam/proc/UpdateVector(var/atom/new_source = null, var/new_scale = null, var/new_dist = null, var/new_angle = null)
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

	world.log << "SpinAngle [angle], YTrans: [y_translate]"

	beam_transform.Scale(1, scale)

	beam_transform.Turn(90) // the icon is vertical, so we reorient it to x-axis alignment
	beam_transform.Turn(turn_angle)

	beam_transform.Translate(0.5 * x_translate * world.icon_size, 0.5 * y_translate * world.icon_size)

	src.x = source.x
	src.y = source.y
	src.transform = beam_transform


/obj/vectorbeam/proc/PostNewHook()
	return


/obj/vectorbeam/New(var/atom/new_source = null, var/new_scale = null, var/new_dist = null, var/new_angle = null)
	..()

	source = (isnull(new_source) ? loc : new_source)
	src.UpdateVector(new_source, new_scale, new_dist, new_angle)
	name = "Beam @ [source]"

	src.PostNewHook()


/obj/vectorbeam/verb/Delete()
	set src in view()
	del(src)


/mob/verb/DeleteBeams()
	for(var/obj/vectorbeam/VB in view())
		del(VB)


/obj/vectorbeam/vanishing/PostNewHook()
	. = ..()

	spawn(20)
		del(src)


/turf/verb/DrawVectorbeam()
	set src in view()

	var/dist = EuclidDistance(usr, src)

	var/dx = (src.x - usr.x)
	var/dy = (src.y - usr.y)
	var/angle = arctan(dx, dy)

	var/Vector2d/vec_length = dist
	var/Vector2d/vec_dist = dist

	var/obj/vectorbeam/vanishing/new_beam = new(usr.loc, vec_length, vec_length, angle)
	usr << "Spawned new beam [new_beam]"

