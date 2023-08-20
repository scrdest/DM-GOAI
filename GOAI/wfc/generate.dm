/* ============  WaveFunction Collapse (WFC) in a nutshell  ============
**
** Every WFC-procgennable 'point' (turf or a blob of turfs) is in one of two states:
**
** 1) Superposition
** 2) Collapsed
**
** Our goal is to get all points into the Collapsed state and they all start in
** the Superposition (if they don't, we don't need to generate them).
**
** Collapsed state is unexciting
**
*/

/area/procgen/wfc/proc/generate(var/list/transition_map)
	set waitfor = FALSE

	sleep(0)


