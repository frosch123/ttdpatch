
struc playerailoc
	.xy:		resw 1	// 00h:location
			resb 0x0a-$
	.direction:	resb 1	// 0Ah
	.cargotype:	resb 1	// 0Bh
			resb 0x14-$
endstruc
// starts at offset given in [77914] (normally 52a62)
struc player
	.name: 		resw 1	// 00h:name text ID; 0 for non-existing players
	.nameparts:	resd 1	// 02h:text ref stack argument for name text ID
	.face:		resd 1	// 06h:face, bitcoded
	.managername:	resw 1	// 0ah:manager name text ID
	.managernameparts:resd 1// 0ch:02h:text ref stack argument for manager name text ID
	.cash:		resd 1	// 10h:	cash of player	(use [addexpenses] to modify for overflow protection)
	.loan:		resd 1	// 14h: loan of player
	.colourscheme	resb 1	// 18h: Company's Colour Scheme
	.cashfract:	resb 1	// 19h: fraction of cash, for subtracting sub-dollar amounts
	.quartersindebt:resb 1	// 1ah: number of quarters player has been in debt
	.introuble:	resb 1	// 1bh: AI: company is in trouble/Player: company bankrupt
	.takeovercost:	resd 1	// 1ch: amount required to take over company
	.takeovercountdown:resw 1//20h: AI: ticks until take-over offer issued/Player: ticks until bankrupt
	.cargotypesdelivered:resd 1//22h:bit mask of cargo types delivered in this quarter
	.thisyearexpenses:resd 12//26h: several types of expenses in this year
			resb 0xc2-$
	.thisquarterincome:resd 1//c2h: income in this quarter
			resb 0xd6-$
	.lastquarterincome:
			resd 1	// d6h:	income in last quarter
			resb 0x2b6-$
	.inaugurated:	resw 1	// 2b6h:year the company was launched (full, not 1920-based)
			resb 0x2bb-$
	.aiaction:	resb 1	// 2bbh:current AI action
			resb 0x2c2-$
	.AIServiceFrom:	resb playerailoc_size
			resb 0x2d6-$
	.AIServiceTo:	resb playerailoc_size
			resb 0x2ea-$
	.AIServiceVia1:	resb playerailoc_size
			resb 0x2fe-$
	.AIServiceVia2:	resb playerailoc_size

			resb 0x3a3-$
	.tracktypes:	resb 1	// 3a3h:number of track types available for building
	.hqlocation: 	resw 1	// 3a4h:location of headquarters
	.shareowners:	resb 4	// 3a6h:owners of the four shares
			resb 0x3b2-$
endstruc

// bit numbers for the bits in player2.colschemes
#define COLSCHEME_HAS2CC 0	// is 2nd company colour defined?
#define COLSCHEME_SPECIAL 1	// special colours for...
#define COLSCHEME_STEAM 1	// ...steam engines	
#define COLSCHEME_DIESEL 2	// ...diesel engines
#define COLSCHEME_ELECTRIC 3	// ...electric engines
#define COLSCHEME_MONORAIL 4	// ...monorail engines
#define COLSCHEME_MAGLEV 5	// ...maglev engines
#define COLSCHEME_DMU 6		// ...DMU
#define COLSCHEME_EMU 7		// ...EMU
#define COLSCHEME_PASS 8	// ...passenger wagons
#define COLSCHEME_FREIGHT 9	// ...freight wagons

#define COLSCHEME_BUS 10	// ...busses
#define COLSCHEME_TRAM 11	// ...trams
#define COLSCHEME_TRUCK 12	// ...trucks

#define COLSCHEME_PASHIP 13	// ...passenger ships
#define COLSCHEME_FRSHIP 14	// ...freight ships

#define COLSCHEME_SAPLANE 15	// ...small airport
#define COLSCHEME_LAPLANE 16	// ...large airport
#define COLSCHEME_FRPLANE 17	// ...freight plane
#define COLSCHEME_HELI 18 	// ...helicopter

#define COLSCHEME_NUM 18	// total number of special colours above


// NOTE: Don't rearrange fields here, only add new fields beyond the end,
//	 otherwise old savegames need adjusting after load
struc player2
	.colschemes:	resd 1	// bit mask of COLSCHEME_# flags above
	.col2:		resb 1	// 2nd company colour
	.specialcol:	resb 2*COLSCHEME_NUM	// special colours, 1st and 2nd
	.unused:	resb 3	// unused, may not be zero-initialized
	.cash:		resd 2	// 64-bit cash amount
			resb player_size-$
endstruc

%if player2.cash != 0x2c
	%error "player2.cash has moved, this is bad"
%endif

