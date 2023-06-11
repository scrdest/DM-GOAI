
/* Response curves
//
// Simply map a single (normalized) input to an output normalized to the same range.
// Outputs are then soft-ANDed with multiplication.
// We want to be able to call() these, so we cannot inline them with macros.
*/

/proc/curve_linear(var/input) // float -> activation (float)
	// The simplest possible curve, just returns normalized input.
	// So, anything at/below the Lo bookmark will have probability 0%;
	// anything at or above the Hi will be 100%;
	// everything else is a simple Lerp between the two.
	world.log << "CurveLinear input: [input]"
	return input


/proc/curve_antilinear(var/input) // float -> activation (float)
	// The same as Linear, but inverted - as input increases, Activation *decreases*.
	world.log << "CurveAntiLinear input: [input]"
	var/result = ACTIVATION_FULL - input
	return result


/proc/curve_binary(var/input)
	// The 'logically' simplest curve.
	// Equivalent to an If-statement - bound action will have Utility
	//   if and only if the condition is True.
	// Useful for Actions like Attack(enemy), where if there's no enemy, there's no point whatsoever.

	world.log << "CurveBinary input: [input]"
	var/activation = ACTIVATION_NONE

	if(input >= ACTIVATION_FULL)
		// the '>=' not strictly needed, '==' would do, but I'm paranoid vOv
		activation = ACTIVATION_FULL

	return activation


/proc/curve_antibinary(var/input)
	// Like Binary, but with inverted logic; acts like a NOT gate.

	world.log << "CurveAntiBinary input: [input]"
	var/activation = ACTIVATION_FULL

	if(input >= ACTIVATION_FULL)
		// the '>=' not strictly needed, '==' would do, but I'm paranoid vOv
		activation = ACTIVATION_NONE

	return activation


/proc/curve_square(var/input)
	// Similar to Linear, but more 'binary', in that weak activations
	// get more attenuated by getting squished towards zero.
	// IOW, penalizes 'waffley' activations but not as hard as Binary.
	world.log << "CurveSquare input: [input]"
	return input ** 2


/proc/curve_antisquare(var/input)
	// Flipped Square, Activation falls with higher inputs
	world.log << "CurveAntiSquare input: [input]"
	var/result = ACTIVATION_FULL - (input ** 2)
	return result



/proc/curve_fakegauss_a(var/input)
	// This is a bell curve; it looks like a Gaussian curve
	// centered on x=0.5 with an arbitrary stddev (actually picked
	// so that the minima in <0; 1> have activation of exactly 10%).
	//
	// It is NOT generated like a proper Gaussian, but it can play one on TV.
	//
	// Handy if you want a 'golden mean' value for some parameter,
	// like a bandpass filter in signal processing.

	world.log << "CurveFakeGauss36 input: [input]"

	// replace '0.5' with another constant float in <0;1> to center at that value
	var/dist = (input - 0.5) ** 2

	// replace '36' with another constant to get a sharper (high) or smoother (low) dropoff further away from 0.5
	var/result = (1 / (1 + 36 * dist))

	// In principle you could dynamically parameterize the curves, but out of scope for now
	return result


/proc/curve_anti_fakegauss_a(var/input)
	// As usual, inverse of - in this case - fakegauss_a. Primarily for completeness' sake.
	//
	// This creates a slightly exotic curve, 'carving out' a band of discouraged values
	// from an interval between bookmarks; in other words, if you want to AVOID a 'middle'
	// value but you don't care in which direction (high or low) you flee from it.
	//
	// As such, it's hard to find a natural analogy as a showcase. One might be a stamina-consuming
	// Charge action, which is good at close range (attack directly) or, at long range, used as a dash,
	// but at mid-range the stamina drain combined with relative proximity to enemies means you just
	// exhaust yourself sprinting but don't have enough energy to follow through with attacks.

	world.log << "CurveAntiFakeGauss36 input: [input]"

	var/dist = (input - 0.5) ** 2

	var/result = (1 / (1 + 36 * dist))
	return ACTIVATION_FULL - result
