#ifndef COMMON_H
#define COMMON_H
//
// This file is part of TTDPatch
// Copyright (C) 1999 by Josef Drexler
//
// common.h: Definitions pertinent to both C code and Assembler code
//

// this is for checking if the code loader works right
#define MAGIC 0x6b5a3f83
#define MOREMAGIC 0x45cb7e39

#define nflags 8		// number of longs with flags switch bits
#define nflagssw (nflags-1)	// number of above flag dwords which can be set by cmd/cfg switches


// bit numbers for the patchflags variable.
// Don't add any defines BUT patchflags bit numbers between the BEGIN and END
// (because this file has to be parsed externally too)
// BEGIN PATCHFLAGS
#define uselargerarray		 0	// Use larger vehicle array
#define usenewcurves		 1	// Use new curves
#define usenewmountain		 2	// Use new mountain (must be usenewcurves+1)
#define usenewnonstop		 3	// Use new non-stop handling
#define increasetraincount	 4	// Increase number of trains
#define increaservcount		 5	// Increase number of road vehicles
#define abandonedroads		 6	// Abandoned roads lose their owner
#define autorenew		 7	// Renew vehicles if they're old
#define gotodepot		 8	// Allow adding depots to vehicles' orders
#define increaseplanecount	 9	// Increase number of planes
#define increaseshipcount	10	// Increase number of ships
#define eternalgame		11	// play forever, date doesn't stop at 2070
#define keepsmallairports	12	// Keep small airports forever
#define largerstations		13	// Stations may be further apart
#define morestationtracks	14	// up to 7 tracks per station
#define longerbridges		15	// bridges up to 127 squares long
#define improvedloadtimes	16	// improved load time calculation
//#define moreindustriesperclimate 17	// Enables more industries and cargo in climates
#define followvehicle		17	// follow vehicle motion in main map
#define presignals		18	// use pre-signals
#define extpresignals		19	// extended pre-signal setups
#define noinflation		20	// Turn off inflation
#define maxloanwithctrl		21	// Borrow/Repay maximum amount with Ctrl
#define persistentengines	22	// Persistent engines while they exist
#define fullloadany		23	// Full load is full if any type full
#define signalsontrafficside	24	// railroad signals on the side road vehicles drive on
#define morethingsremovable	25	// More things can be removed, at a cost
//#define aibooster		26	// Increase AI recursion factor
#define	trams			26	// Trams
#define buildwhilepaused	27	// build while paused
#define newlineup		28	// Make busses and trucks wait at their stops
#define moretoylandfeatures	29	// random land features normally disabled in toyland
#define generalfixes		30	// several general fixes
#define win2k			31	// fix up some routines for win2k
#define bribe			32	// add "bribe" option to LA menu
#define noplanecrashes		33	// control when and how planes crash
#define showspeed		34	// show train/etc. speed in window
#define officefood		35	// office towers accept food too
#define usesigncheat		36	// Sign Cheats
#define cheatscost		37	// all cheats actually cost their money
#define diskmenu		38	// add load option to disk menu
#define moreairports		39	// new maximum airport numbers: 9; lrg=4, sml=3, hp=1, of=0
#define mammothtrains		40	// maximum train length is 127
#define allowtrainrefit		41	// Allow train refitting
#define showfulldate		42	// always show full date with day/mo/yr
#define subsidiaries		43	// allow humans to take over AI subsidiaries
#define gradualloading		44	// load vehicles gradually (not all at once)
#define moveerrorpopup		45	// move error popups to top-right corner
#define setsignal1waittime	46	// set time for trains to wait on 1-way signals
#define setsignal2waittime	47	// set time for trains to wait on 2-way signals
#define maskdisasters		48	// disable disasters selectively
#define forceautorenew		49	// when on, autorenew sends vehicles to depots
#define morenews		50	// generate news reports on more events
#define unifiedmaglev		51	// monorail and maglev unified
#define newbridgespeeds		52	// new speed limits on monorail and maglev tubular bridges
#define maprefresh		53	// override map refresh frequency
#define saveoptdata		54	// Save/load optional data in the extra chunks
#define newtrains		55	// new models for trains, and new graphics
#define newrvs			56	// ...and road vehicles
#define newships		57	// ...and ships
#define newplanes		58	// ...and planes (don't change any of newtrains...newplanes)
#define newstations		59	// Enable new station graphics
#define electrifiedrail		60	// electrified railways instead of two maglev types
#define largertowns		61	// make some or all towns grow larger
#define newerrorpopuptime	62	// new error popup expiration time
#define newtowngrowthfactor	63	// new town growth recursion factor
#define miscmods		64	// miscellaneous modifications to the ways other switches work
#define loadallgraphics		65	// always load grfs regardless of climate/ID/etc.
#define morebuildoptions	66	// remove checks that prevent construction of some objects
#define semaphoresignals	67	// build semaphores before 1975
#define morehotkeys		68	// New Hotkeys
#define plantmanytrees		69	// Plant many trees at once
#define tracktypecostdiff	70	// Different types of track cost differently
#define morecurrencies		71	// Allows using more currencies
#define manualconvert		72	// Allows converting tracks to different type manually
#define newtowngrowthrate	73	// new town growth rate calculation rules
#define displmoretownstats	74	// display more statistics for each town
#define enhancegui		75	// enhance TTD GUI
#define newagerating		76	// Makes ratings more tolerant to vehicle ages
#define buildonslopes		77	// Build stations etc. on ledges on sloped land
#define buildoncoasts		78	// Build on coasts/waterbanks w/o having to clear them first
#define disconnectontimeout	79	// disconnect games if a timeout occurs
#define fastwagonsell		80	// Sell whole consist with Ctrl
#define newrvcrash		81	// Modify train/rv crashes
#define stableindustry		82	// Prevent industry closedowns with stable economy
#define newperformance		83	// Calculate profit performance score in a more reasonable way
#define sortvehlist		84	// Sort vehicles in list windows
#define newspapercolour		85	// Newspapers are in colour after 2000
#define sharedorders		86	// Allow shared or copied orders
#define showprofitinlist	87	// Show profit in list of consists
#define moresteam		88	// Show more steam plumes
#define losttrains		89	// warn about lost trains...
#define lostrvs			90	// ...road vehs...
#define lostships		91	// ...ships
#define lostaircraft		92	// ...and aircraft
#define canals			93	// canals and locks
#define gamespeed		94	// Make the gamespeed adjustable using hotkeys
#define higherbridges		95	// advance bridges
#define mousewheel		96	// allow using mouse wheel
#define morewindows		97	// more windows allowed on screen
#define newhouses		98	// allow new house graphics to be added by a grf file
#define newbridges		99	// allow setting bridge properties
#define newtownnames		100	// allow defining new town name styles
#define moreanimation		101	// allow more tiles to be animated
#define newshistory		102	// save the last 32 news messages, and display them
#define custombridgeheads	103	// allow custom bridge heads
#define newcargodistribution	104	// better cargo distribution when more than 1 station is in range
#define windowsnap		105	// snap windows together
#define newindustries		106	// support new industries
#define locomotiongui		107	// locomotion style gui
#define tempsnowline		108	// enable snow line on temperate
#define newsounds		109	// allow new sound effects
#define morestats		110	// save some more company statistics
#define autoreplace		111	// autoreplace old vehicle

// NOTE!! If you add a bit here, also add it to patchflagsfixedmap in vars.ah!!

#define lastbitdefaulton	111	// META: last bit defined to be set by -a 

// add new flags that should be on by default above, flags off by default below

#define firstbitdefaultoff	192	// META: first bit defined not to be set by -a unless DEBUG

#define setnewservinterval	192	// Set service internal
#define feederservice		193	// forced unload if station accepts
#define selectstationgoods	194	// Only transported station goods appear
#define multihead		195	// Allow arbitrary number of engines in train
#define newstartyear		196	// new default start year
#define planespeed		197	// Fix plane speed to be 4 x faster
#define lowmemory		198	// Run with little memory, only 2.5MB
#define experimentalfeatures	199	// Latest experimental features; disabled by default.
#define stretchwindow		200	// stretch Win version window
#define freighttrains		201	// multiply freight train cargo carried
#define enhanceddiffsettings	202	// enhanced difficulty settings
#define wagonspeedlimits	203	// enable speed limits for wagons
#define townbuildnoroads	204	// towns build no roads
#define pathbasedsignalling	205	// path based signalling
#define aichoosechances		206	// specify with which chances the ai will try to use rail/rv/air/ship
#define resolutionwidth		207	// Resolution Width
#define resolutionheight	208	// Resolution Height
#define fifoloading		209	// FIFO loading
#define townroadbranchprob	210	// Change the chance of a town creating a road branch
#define newcargos		211	// support new cargos
#define onewayroads		212	// Enable support for one-way roads
#define irrstations		213	// Enable support for irregular stations
#define enhancemultiplayer	214	// allow more than two players in multiplayer
#define autoslope		215	// allows to terraform without destroying tile structure
#define enhancetunnels		216	// allow building bridges on tunnel entrances
#define shortrvs		217	// allow shortened RVs
#define articulatedrvs		218	// allow articulated RVs

// NOTE!! If you add a bit here, also add it to patchflagsfixedmap in vars.ah!!

#define lastbitdefaultoff	218	// META: last bit defined not to be set by -a unless DEBUG

// so far unused flags, simply to remember what names I've used already
// the numbers of these can be changed as desired
//#define moresignals		 ?	// make tunnels&bridges behave as if there were signals
//#define hugeairport		 ?	// build huge airports

#define lastbitcommandline	223	// META: last bit that can be set by -a
					// 	 i.e. all but the last DWORD

// END PATCHFLAGS


// these go always in the last bits of the last flag DWORD, and can't
// be modified by command line or config switches
// if any of these need versiondata, be sure to always turn them on separately
// in function allswitches in switches.c.
#define usenoregistry		246	// Use registry.ini instead of the Windows registry
#define rvpower			247	// Set if road vehicles set to realistic accel.
#define patchprocbitflag	248	// Used to indicate a bit in patchproc list
#define enhancedkbdhandler	249	// Can we install an enhanced keyboard handler?
#define dontshowkbdleds		250	// don't let enhanced kbd handler mess with LEDs in DOS version
#define onlygetversiondata	251	// Terminate after collecting version data
#define recordversiondata	252	// Whether we're recording version data
#define canmodifygraphics	253	// Can we modify graphics?
#define noflag			254	// Reserved. A flag that's always zero
#define anyflagset		255	// is any flag set?

#if WINTTDX
#define TTDPATCH_IPC_EVENT_NAME	"TTDPatch:SyncEvent"
#define TTDPATCH_IPC_SHM_NAME	"TTDPatch:SharedMemory"
#endif	// WINTTDX

#define TTDPATCH_DAT_FILE	"ttdpatch.dat"

#endif // COMMON_H
