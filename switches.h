#ifndef SWITCHES_H
#define SWITCHES_H
//
// This file is part of TTDPatch
// Copyright (C) 1999, 2000 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// switches.h: header file for switches.c
//

#include "types.h"

#ifndef C
#	define C	// for common.h
#endif

#include "common.h"


// When adding things here, also add them to category_names in switches.c
enum en_categories {
	CAT_BASIC = 0,
	CAT_VEH,
	CAT_VEH_RAIL,
	CAT_VEH_ROAD,
	CAT_VEH_AIR,
	CAT_VEH_ORDERS,
	CAT_TERRAIN,
	CAT_INFST,
	CAT_INFST_BRIDGE,
	CAT_INFST_RAIL,
	CAT_INFST_RAIL_SIGNAL,
	CAT_INFST_ROADS,
	CAT_INFST_STATION,
	CAT_HOUSESTOWNS,
	CAT_HOUSESTOWNS_GROWTH,
	CAT_INDUSTRIESCARGO,
	CAT_FINANCEECONOMY,
	CAT_DIFFICULTY,
	CAT_INTERFACE,
	CAT_INTERFACE_NEWS,
	CAT_INTERFACE_VEH,
	CAT_INTERFACE_WINDOW,
	CAT_CARGODEST,

	CAT_NONE,
};
typedef enum en_categories categories;
#define CAT_FIRST CAT_BASIC
#define CAT_LAST  CAT_NONE

	// this defines the bits to be set by the switches.
typedef struct {
	int cmdline;		// the command line switch for this
	const char *cfgcmd;	// the configuration file command
	int comment;		// the comment written by -W
	const char *manpage;	// the name of the manual page describing the switch
	int bit:9;		// the bit to be set.  -1 for special handling, -2 if none
	unsigned radix:4;	// 0=auto, 1=force octal, 2=force dec, 3=force hex; +4=invert
	unsigned varsize:3;	// 0=u8  1=u16  2=s16  3=s32  4=s8
	int category;		// see above
	s32 range[3];		// lower and upper bounds for the value, and the default.
				// -1/-1 = none (yes/no)
	int order;		// order in which switches appeared in ttdpatch.cfg
	void _fptr *var;	// variable to change if special
				// (NULL if *really* special, -1 if obsolete)
	int bitswitchid;	// bit switch ID
} switchinfo;

typedef struct {
		u32 magic;
		u32 flags[nflags];
		u32 datasize;

		struct {
			#define defbyte(name)		u8 name;
			#define defword(name)		u16 name;
			#define deflong(name)		u32 name;
			#define defbytes(name, count)	u8 name[count];
			#define defwords(name, count)	u16 name[count];
			#define deflongs(name, count)	u32 name[count];

			#include "flagdata.h"

			#undef defbyte
			#undef defword
			#undef deflong
			#undef defbytes
			#undef defwords
			#undef deflongs
		} data;

} paramset, _fptr *pparamset;


#if defined(IS_SWITCHES_CPP)
#	define ISEXTERN
#else
#	define ISEXTERN extern
#endif

// ISEXTERN for uninitialized, extern for initialized variables
ISEXTERN pparamset flags;
extern int showswitches;
extern int writeverfile;

extern char ttdoptions[128+1024*WINTTDX];
ISEXTERN int alwaysrun;

ISEXTERN char tempstr[17];

// Flags used for debugging. 0=default, -1=no, 1=yes
ISEXTERN struct {
  signed char	useversioninfo,	// use version info if available
		swap,		// swap out the real-mode code (-1=never, 1=always, 0=if low memory)
		runcmdline,	// don't parse the rest of the cmdline, just run it
		checkttd,	// check TTDLOAD[W].OVL
		checkmem,	// complain if the memory is too low
		readcfg,	// read TTDPATCH.CFG
		chkswitchdep,	// check dependencies between switches
		warnwait,	// don't wait for key on warnings; do or don't abort
		terminatettd,	// terminate TTD after finding new version info
		langdatafile,	// load lang.data from language.dat instead of the exe
		noshowleds,	// disable programming keyboard LED indicators
		switchorder,	// write cfg switches always in alphabetic order
		dumpswitches,	// dump switch list to swtchlst.txt
		protcodefile,	// load protected mode code from ttdprot?.bin instead of the exe
		relocofsfile,	// load reloc ofs from reloc.bin file
		patchdllfile,	// does nothing, but needed to make auxfiles.c happy
		noregistry,	// use noregistry hack
		norunttd;	// don't actually execute TTD
} debug_flags;

void check_debug_switches(int *const argc, const char *const **const argv);

struct consoleinfo {
  int width, height;
  unsigned attrib;

  // OS-specific console functions defined in dos.c or windows.c
  // as appropriate. With this approach we can link makelang
  // with switches.c without having to link everything else as well.
  int (*cprintf)(const char *, ...);
  void (*setcursorxy)(int, int);
  void (*clrconsole)(int, int, int, unsigned);
  // more functions may be added here in the future
};


void allswitches(int reallyall, int swon);
void commandline(int argc, const char *const *argv);
void showtheswitches(const struct consoleinfo *const pcon);
void get_code_offsets(pparamset protptr);
int dumpswitches(int type);

#define setf(bitnum, val) (void) \
( \
	flags->flags[(bitnum)>>5] &= ~( (u32) 1 << ((bitnum)&31)), \
	flags->flags[(bitnum)>>5] |= ( ( (u32) val & 1) << ((bitnum)&31)) \
)

#define getf(bitnum) \
( \
	( (flags->flags[(bitnum)>>5] & ( (u32) 1 << ((bitnum)&31)) ) != 0) \
)

#define setf1(bitnum) (void) \
( \
	flags->flags[(bitnum)>>5] |= ( (u32) 1 << ((bitnum)&31)) \
)

#define clearf(bitnum) (void) \
( \
	flags->flags[(bitnum)>>5] &= ~( (u32) 1 << ((bitnum)&31)) \
)


// macros and functions for dealing with two-character constants
// NOTE: do not use explicit multi-character constants, they're not portable
// use maketwochars() instead
#define firstchar(x) ((x) & 0xff)
#define secondchar(x) ((x) >> 8)
#define maketwochars(c1, c2) ((c1) | ((c2) << 8))
char *dchartostr(int ch);


#undef ISEXTERN

#endif
