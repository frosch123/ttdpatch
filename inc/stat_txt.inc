// definition of static text strings (i.e. language independent strings)
//
// define with	stxt <id>,<string>
// you can add additional lines with "db" following the stxt definition,
// they will become part of the string
//
// use with e.g. mov ax,statictext(<id>)
//
// example:
//
// stxt helloworld,"Hello World!",13,10,0
// stxt multiline,"This is the first line.",13,10
// stxt_cont	db "This is the second line.",13,10,0
//
// mov ax,statictext(helloworld)
//
//
// For reference, some of the special codes:
//	7B: print dword
//	7C: print signed word
//	7D: print signed byte
//	7E: print unsigned word
//	7F: print dword in currency units
//	80: print substring (TID from ref stack)
//	81: print substring (TID from next 2 bytes)
//	82: print date (day, month, year)
//	83: print month and year
//	84: print signed word in speed units
//	85: pop word from ref stack
//	86: rotate up last 3 words on ref stack
//	87: print signed word in litres
//	9A: print unsigned qword
// Colours:
//	88: Blue
//	89: Light Gray
//	8A: Light Orange
//	8B: Red
//	8C: Purple
//	8D: Olive
//	8E: Orange
//	8F: Green
//	90: Yellow
//	91: Yellowish Green
//	92: Pink
//	93: Brown
//	94: White
//	95: Light Blue
//	96: Dark Gray
//	97: Medium Gray
//	98: Black


stxt ident, 0x80,0		// draw the next textid on the stack
stxt ident2, 0x80,0x80,0	// same with two textids
stxt popword, 0x85,0		// pops a word from textrefstack
stxt popdword, 0x85,0x85,0	// pops a dword from textrefstack
stxt empty, 0

stxt num1, 0x98,"1",0
stxt num2, 0x98,"2",0
stxt num3, 0x98,"3",0
stxt num4, 0x98,"4",0
stxt num5, 0x98,"5",0
stxt num6, 0x98,"6",0
stxt num7, 0x98,"7",0
stxt numplus7, 0x98,"+7",0


//stxt num8, 0x98,"8",0
//stxt num9, 0x98,"9",0
//stxt num10, 0x98,"10",0
//stxt num11, 0x98,"11",0
//stxt num12, 0x98,"12",0
//stxt num13, 0x98,"13",0
//stxt num14, 0x98,"14",0
//stxt num15, 0x98,"15",0
//

stxt numplus, 0x98,"+",0
stxt numminus, 0x98,"-",0

stxt towncargo3typesandamounts, 0x98,"  ",0x80,": ",0x8e,0x7b	// continued in the next string
stxt towncargo2typesandamounts, 0x98,"  ",0x80,": ",0x8e,0x7b	// continued in the next string
stxt towncargo1typeandamount, 0x98,"  ",0x80,": ",0x8e,0x7b,0

stxt profit_black, 0x98,0x7f,0x98,0
stxt profit_red, 0x8b,0x7f,0x98,0
stxt profit_orange, 0x8e,0x7f,0x98,0
stxt profit_yellow, 0x90,0x7f,0x98,0
stxt profit_yellowishgreen, 0x91,0x7f,0x98,0
stxt profit_green, 0x8f,0x7f,0x98,0

stxt textclr_lightorange, 0x8a,0

stxt newdeletebutton, 0x85,0x85,0x80,0
stxt newfullloadbutton, 0x85,0x85,0x85,0x80,0
stxt vehlist_sortbutton, 0x85,0x85,0x85,0x98,0x80,0
stxt vehlist_menubutton, 0x98,0xaa,0

stxt newnonstopbutton, 0x9A, 0x5
stxt_cont dd newnonstopptr1
stxt_cont db 0

stxt newunloadbutton, 0x9A, 0x5
stxt_cont dd newunloadptr1
stxt_cont db 0


stxt txtetoolbox_dropdown, 0x98,0xaa,0

// Graphic Status Window
stxt grfnameline,   0x95,0x80,0
stxt grfnamelineselected,   0x94,0x80,0
stxt grfwitherror,  0x8b,"/",0x98,"!",0x8b,"\  ",0x95,0x80,0
stxt grfwitherrorselected,  0x8b,"/",0x98,"!",0x8b,"\  ",0x94,0x80,0

stxt stickybutton, 0x98, "S", 0

// For transparent station signs in company colors
// works only because of a new color handler...
stxt signstationcol1, 0x99,0x9A,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol2, 0x99,0x9B,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol3, 0x99,0x9C,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol4, 0x99,0x9D,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol5, 0x99,0x9E,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol6, 0x99,0x9F,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol7, 0x99,0xA0,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol8, 0x99,0xA1,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol9, 0x99,0xA2,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol10, 0x99,0xA3,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol11, 0x99,0xA4,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol12, 0x99,0xA5,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol13, 0x99,0xA6,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol14, 0x99,0xA7,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol15, 0x99,0xA8,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol16, 0x99,0xA9,0x80,0x20,0x81,0xD1,0x30,0x00
// all the above in small size for the farthest zoom level
stxt signstationcol1s, 0xE,0x99,0x9A,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol2s, 0xE,0x99,0x9B,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol3s, 0xE,0x99,0x9C,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol4s, 0xE,0x99,0x9D,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol5s, 0xE,0x99,0x9E,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol6s, 0xE,0x99,0x9F,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol7s, 0xE,0x99,0xA0,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol8s, 0xE,0x99,0xA1,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol9s, 0xE,0x99,0xA2,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol10s, 0xE,0x99,0xA3,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol11s, 0xE,0x99,0xA4,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol12s, 0xE,0x99,0xA5,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol13s, 0xE,0x99,0xA6,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol14s, 0xE,0x99,0xA7,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol15s, 0xE,0x99,0xA8,0x80,0x20,0x81,0xD1,0x30,0x00
stxt signstationcol16s, 0xE,0x99,0xA9,0x80,0x20,0x81,0xD1,0x30,0x00

stxt continuedtrain, 0x98,"        +",0

stxt grfnotice, 0x94,0x80,0

stxt freightmulti, 0x80," ",0x94,"(x",0x7c,")",0

// these must be in order, they have 0, 1 or 2 additional textids
stxt railstationquery0, 0x81, 0x5e, 0x30, 0
stxt railstationquery1, 0x81, 0x5e, 0x30, ": ", 0x98,0x80, 0
stxt railstationquery2, 0x81, 0x5e, 0x30, ": ", 0x98,0x80, ", ", 0x98,0x80, 0

stxt vehstat_olddepot,  0x8c,0x7c,0	// purple
stxt vehstat_stopped,   0x94,0x7c,0	// white
stxt vehstat_stoppedold,0x89,0x7c,0	// gray

stxt fixednumber, "000",0

stxt townnamesize, 0x94,0x80," (", 0x7B, ")", 0

stxt printbyte, 0x7D, 0

//these must be in this order :)
stxt depotsize4, 0x98, "4 (2)", 0
stxt depotsize5, 0x98, "5 (3)", 0
stxt depotsize6, 0x98, "6 (3)", 0
stxt depotsize7, 0x98, "7 (4)", 0
stxt depotsize8, 0x98, "8 (4)", 0
stxt depotsize9, 0x98, "9 (5)", 0
stxt depotsize10, 0x98, "10 (5)", 0
stxt depotsize11, 0x98, "11 (6)", 0
stxt depotsize12, 0x98, "12 (6)", 0
stxt depotsize13, 0x98, "13 (7)", 0
stxt depotsize14, 0x98, "14 (7)", 0
stxt depotsize15, 0x98, "15 (8)", 0
stxt depotsize16, 0x98, "16 (8)", 0
stxt depotsize17, 0x98, "17 (9)", 0
stxt depotsize18, 0x98, "18 (9)", 0
stxt depotsize19, 0x98, "19 (10)", 0
stxt depotsize20, 0x98, "20 (10)", 0
stxt depotsize21, 0x98, "21 (11)", 0
stxt depotsize22, 0x98, "22 (11)", 0
stxt depotsize23, 0x98, "23 (12)", 0
stxt depotsize24, 0x98, "24 (12)", 0
stxt depotsize25, 0x98, "25 (13)", 0
stxt depotsize26, 0x98, "26 (13)", 0
stxt depotsize27, 0x98, "27 (14)", 0
stxt depotsize28, 0x98, "28 (14)", 0
stxt depotsize29, 0x98, "29 (15)", 0
stxt depotsize30, 0x98, "30 (15)", 0
stxt depotsize31, 0x98, "> 30 (> 15)", 0

stxt onecargotype, 0x80,0x85,0x85,0
stxt twocargotypes, 0x80,", ",0x80,0

stxt newindugentitle, 0x94,0x80,0
stxt newindugenbutton, 0x85,0x98,0x80,0

stxt newindu_onecargo,		0x80,0x80,0
stxt newindu_twocargoes,	0x80,0x80,", ",0x80,0x80,0

stxt gamespeed0, "l",0xab,0
stxt gamespeed1, " ",0xab,0
stxt gamespeed2, " <",0
stxt gamespeed3, 0
stxt gamespeed4, "> ",0
stxt gamespeed5, 0xbb," ",0
stxt gamespeed6, 0xbb,"l",0

stxt engineinfodisplay, 0x81
stxt_cont	dw ourtext(engineinfo2)
stxt_cont	db 0x0d,0x98,0x80,0
stxt wagoninfodisplay, 0x80,0x80,0x0d,0x98,0x80,0

stxt opengrfstatus, 0x98,0x81
stxt_cont	dw ourtext(grfstatusmenu)
stxt_cont	db 0

stxt newgametitle, 0x94, 0x81
stxt_cont	dw ourtext(newgame)
stxt_cont	db 0

stxt microtext, 0x0e, 0x80, 0

stxt whitedword, 0x94,0x7B,0

stxt ellipsis, '...', 0

stxt checkmark, 0xad, 0

stxt elecrailconstitle, 0x81
stxt_cont	dw ourtext(elecrailconstitle),
stxt_cont	db 0
stxt elecrailconsmenu, 0x81
stxt_cont	dw ourtext(elecrailconsmenu)
stxt_cont	db 0

stxt special12, 0x81
stxt_cont	dw statictext(special1)
stxt_cont	db 0x81
stxt_cont	dw statictext(special2)
stxt_cont	db 0

stxt disp64bitcash_black, 0x98, 0x9a, 0x00, 0x00
stxt disp64bitcash_white, 0x94, 0x9a, 0x00, 0x00
stxt disp64bitcash_red, 0x8b, 0x9a, 0x00, 0x00	// must follow disp64bitcash_white

stxt airportsel_typebutton, 0x98,0x80,0
stxt airportsel_smallairport, 0x9A,0x02,0x81,0x59,0x30,0
stxt airportsel_largeairport, 0x9A,0x02,0x81,0x5a,0x30,0
stxt airportsel_heliport, 0x9A,0x02,0x81,0x6b,0x30,0

stxt trdlg_lt,"<",0
stxt trdlg_gt,">",0
stxt trdlg_lte,"<=",0
stxt trdlg_gte,">=",0

stxt trdlg_txt_depot,0x81,
stxt_cont dw ourtext(gototraindepot)
stxt_cont db " ",0x81
stxt_cont dw statictext(trdlg_txt_XY)
stxt_cont db 0

stxt trdlg_txt_XY, "X:",0x7E," Y:",0x7E,0

stxt trdlg_txt_3,"- ",0x80," ",0x80," ",0x80,0
//var,op,station name
//var,op,statictext(printdword)/empty,[dword]
//var,op,statictext(trdlg_txt_depot)/empty,[depot's town name,x,y]
//var,is green/is red/empty,statictext(trdlg_txt_XY)/empty,[x,y]

stxt whitetext,0x94,0x80,0
stxt blacktext, 0x98,0x80,0
stxt lightbluetext, 0x95,0x80,0
stxt printdword, 0x7B,0
stxt printword, 0x7E,0
stxt dash, "-",0

stxt tr_landinfotext_presig_auto, 0x81
stxt_cont dw ourtext(presigautomatic)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_landinfotext)
stxt_cont db 0
stxt tr_landinfotext_presig_manual, 0x81
stxt_cont dw ourtext(presigmanual)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_landinfotext)
stxt_cont db 0
stxt tr_landinfotext_pbs_auto, 0x81
stxt_cont dw ourtext(pathbasedauto)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_landinfotext)
stxt_cont db 0
stxt tr_landinfotext_pbs_manual, 0x81
stxt_cont dw ourtext(pathbasedmanual)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_landinfotext)
stxt_cont db 0

stxt tr_ps_landinfotext_presig_auto, 0x81
stxt_cont dw ourtext(presigautomatic)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_ps_landinfotext)
stxt_cont db 0
stxt tr_ps_landinfotext_presig_manual, 0x81
stxt_cont dw ourtext(presigmanual)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_ps_landinfotext)
stxt_cont db 0
stxt tr_ps_landinfotext_pbs_auto, 0x81
stxt_cont dw ourtext(pathbasedauto)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_ps_landinfotext)
stxt_cont db 0
stxt tr_ps_landinfotext_pbs_manual, 0x81
stxt_cont dw ourtext(pathbasedmanual)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_ps_landinfotext)
stxt_cont db 0

stxt tr_trps_landinfotext_presig_auto, 0x81
stxt_cont dw ourtext(presigautomatic)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_ps_landinfotext)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_landinfotext)
stxt_cont db 0
stxt tr_trps_landinfotext_presig_manual, 0x81
stxt_cont dw ourtext(presigmanual)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_ps_landinfotext)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_landinfotext)
stxt_cont db 0
stxt tr_trps_landinfotext_pbs_auto, 0x81
stxt_cont dw ourtext(pathbasedauto)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_ps_landinfotext)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_landinfotext)
stxt_cont db 0
stxt tr_trps_landinfotext_pbs_manual, 0x81
stxt_cont dw ourtext(pathbasedmanual)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_ps_landinfotext)
stxt_cont db ", ",0x81
stxt_cont dw ourtext(tr_landinfotext)
stxt_cont db 0

stxt extradetailswagons, 0x95,0x84,"  ",0x98,0x0E,0x7E,0x0F,0

stxt dpt_number, 0x80," (", 0x7E, ")", 0
stxt dpt_number2, " (", 0x7E, ")", 0

stxt backspace, 0x9A, 0x04, 0x01, 0

stxt tr_searchingfordepotdropdown, 0x9A, 0x03
stxt_cont dw statictext(backspace)
stxt_cont db 0x81
stxt_cont dw ourtext(tr_searching_for_depot)
stxt_cont db 0

stxt active_orders_win, 0x81
stxt_cont dw 0x8829	// \94\80 (Orders)
stxt_cont db " (*)", 0

stxt backspace2, 0x9A, 0x04, 0x02, 0

stxt landinfo_3text, 0x9A, 0x5
stxt_cont dd landinfotxtptr1
stxt_cont db ", ", 0x9A, 0x5
stxt_cont dd landinfotxtptr2
stxt_cont db ", ", 0x9A, 0x5
stxt_cont dd landinfotxtptr3
stxt_cont db 0

stxt shadebutton_shaded, 0x98, 0xAA, 0
stxt shadebutton_unshaded, 0x98, 0xA0, 0

stxt outstation, 0x9A, 12, 0
stxt printdate, 0x82, 0
stxt printhexword, 0x9A, 7, 0
stxt printhexbyte, 0x9A, 6, 0
stxt printhexdword, 0x9A, 8, 0
