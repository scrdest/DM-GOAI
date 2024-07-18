/*
// Macros and constants for the economy side of the AI
*/

/* Standard offer expiry times, in deciseconds as usual */

// 'Slow' offers are good for us and have longer TTL
// Live, 20 mins
// #define EXPIRY_TIME_SLOW 12000
// Debug, 1 min:
#define EXPIRY_TIME_SLOW 600

// 'Fast' offers are bad for us, but we make them out of desperation, short TTL
// Live, 5 mins
// #define EXPIRY_TIME_FAST 3000
// Debug, 30 seconds
#define EXPIRY_TIME_FAST 300

// This is only used for the global marketplace, but it's nicer to have it here as it's linked to the expiry times above

// Default delay between cleanup ticks
// Ideally this would be a small multiple of standard expiry times for
//   offers; this ensures AIs don't need to scan through trash offers too much.
// However, too low means we do a bunch of scanning and allocs in *here* instead,
//   so this needs to be tuned a bit to strike a good balance.
//#define DEFAULT_MARKETWATCH_TICKRATE 3000
#define DEFAULT_MARKETWATCH_TICKRATE 600
