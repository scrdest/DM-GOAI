/* Contains basic definitions of the senses system.
//
// General design principles here:
//
// - Senses process some 'sensory' data on a tick-by-tick basis
// - Senses communicate with the AI by setting/updating Memories
// - Senses are invoked by the SenseSystem for scheduling, ECS-style
//   (SenseSystems reside in agent AI procs; not part of this spec)
*/

/sense
    // to keep typepaths compact...
    parent_type = /datum
    var/processing = FALSE


/sense/proc/ProcessTick(var/owner)
    // overall logic goes here;
    // gather some data & set memories.
    return
