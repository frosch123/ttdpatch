#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <station.inc>
#include <textdef.inc>
#include <window.inc>
#include <airport.inc>

extern variabletofind,variabletowrite
extern airportlayoutptrs,airportsizes,airportmovementdataptrs
extern airportspecialflags,airportcallbackflags,aircraftmovement
extern airportspecialmovements,airportmovementdatasizes,airporttypenames
extern airportstarthangarnodes

begincodefragments

codefragment oldinitairportstate,6
	mov [esi+station.airporttype],al

codefragment_call newinitairportstate, initairportstate, 8

codefragment findairportsizetable,15
	mov di, [esi+station.airportXY]
	movzx edx, byte [esi+station.airporttype]

codefragment findairportmovementdata,10
	movzx eax, byte [ebx+station.airporttype]

codefragment oldgetnewaircraftop,-14
	movzx ebx, byte [esi+veh.aircraftop]

codefragment_call newgetnewaircraftop,getnewaircraftop,8

codefragment findaircraftmovement,25
	movzx edi, byte [esi+veh.movementstat]
	shl edi,1

codefragment findaircraftexitdepot
	bts word [ebx+station.airportstat], 7
	mov word [esi+veh.speed],0

codefragment findaircraftstartload,-6
	cmp al,2
	jz $+2+0x4c

codefragment findaircraftland,-4
	mov byte [esi+veh.ysize],2
	push eax

codefragment findaircraftenterhangar,-5
	mov byte [esi+veh.aircraftop],0
	mov ax,[esi+veh.currorder]

codefragment findaircrafttakeoffeffect,-4
	mov al,0x0d
	jmp $+5+0x212

codefragment findaircraftyield,-4
	mov byte [esi+veh.ysize],0x18
	mov ax, [esi+veh.currorder]

codefragment oldaircraftyield_newop
	mov byte [esi+veh.aircraftop],0x12
	db 0xc6, 0x46, 0x62		// mov byte [esi+veh.movementstat],...

codefragment_jmp newaircraftyield_newop,aircraftyield_newop,5

codefragment findaircraftselectwinelems,-10
	dw 0x3059
	db 3,0xe

codefragment olddrawairportselwindow
	test byte [airporttypeavailmask],1

codefragment newdrawairportselwindow
	movzx eax, byte [selectedairporttype]
	cmp al, NUMOLDAIRPORTS
	jae .good
	bt [airporttypeavailmask],eax
	jc .good
	mov al,0
	test byte [airporttypeavailmask],1
	jnz .good_new
	mov al,1
.good_new:
	mov [selectedairporttype],al
.good:
	mov ax, [airporttypenames+eax*2]
	mov [textrefstack],ax
	mov ebx,[esi+window.activebuttons]
	and bl,0x3f
	setfragmentsize 92, 1

codefragment oldairportsizetext,2
	mov bx,0x305b

codefragment newairportsizetext
	dw ourtext(airporttype)

codefragment oldairportseltypeclick
	cmp cl,3
	je near $+6+0x8e

codefragment newairportseltypeclick
	cmp cl,3
	jb fragmentstart+27
	cmp cl,5
	ja fragmentstart+27
	ijmp airportseltypeclick

codefragment oldairportsel_eventhandler,3
	cmp dl,cWinEventClick
	je near $+6-0x32d

codefragment_call newairportsel_eventhandler,airportsel_eventhandler,6

codefragment oldnewaircraftorder
	cmp byte [esi+veh.aircraftop],0x12
	jne $+2+7

codefragment_call newnewaircraftorder,newaircraftorder,13

codefragment oldstopaircraft_isinflight
	cmp byte [edx+veh.aircraftop],4
	jb $+2+0x15

codefragment_call newstopaircraft_isinflight,stopaircraft_isinflight,10

codefragment oldstoprotor
	mov al, [edi+veh.aircraftop]
	cmp al, 1

codefragment newstoprotor
	mov al, [edi+veh.currorder]
	and al, 0x1f
	cmp al, 3
	setfragmentsize 9
	db 0x75			// ja -> jne

codefragment oldbuynewaircraft
	mov al, [landscape2+ebp]
	mov [esi+veh.targetairport],al

codefragment_call newbuynewaircraft,buynewaircraft,6

endcodefragments

ext_frag newvariable,findvariableaccess,oilfieldaccepts

exported patchnewairports
	patchcode initairportstate
	mov esi,airportlayoutptrs
	xchg esi,[edi+lastediadj+41]
	mov edi,airportlayoutptrs
	times 3 movsd

	stringaddress findairportsizetable
	mov esi,[edi]
	mov [variabletofind],esi
	mov edi,airportsizes
	mov [variabletowrite],edi
	movsd
	movsw
	mov word [edi],0x101
	patchcode oilfieldaccepts,newvariable,1,1	// generalfixes has overwritten an instance, overwrite it yet again
	multipatchcode findvariableaccess,newvariable,3	// fix the remaining 3 pointers

	stringaddress findairportmovementdata
	mov esi,airportmovementdataptrs
	xchg esi,[edi]
	mov edi,airportmovementdataptrs
	times 4 movsd

	and dword [airportspecialflags],0
	and dword [airportcallbackflags],0
	mov dword [airportmovementdatasizes],0x1d1d1d1d
	mov word [airporttypenames],statictext(airportsel_smallairport)
	mov word [airporttypenames+2],statictext(airportsel_largeairport)
	mov word [airporttypenames+4],statictext(airportsel_heliport)
	or dword [airportstarthangarnodes],byte -1

	patchcode getnewaircraftop
	storeaddress findaircraftmovement,1,1,aircraftmovement

	storeaddress findaircraftexitdepot,1,1,airportspecialmovements+(1*4)
	storeaddress findaircraftstartload,1,1,airportspecialmovements+(2*4)
	storeaddress findaircraftland,1,1,airportspecialmovements+(3*4)
	storeaddress findaircraftenterhangar,1,1,airportspecialmovements+(5*4)
	storefunctionaddress findaircrafttakeoffeffect,1,1,airportspecialmovements+(6*4)
	storeaddress findaircraftyield,1,1,airportspecialmovements+(8*4)

	multipatchcode oldaircraftyield_newop,newaircraftyield_newop,2

	stringaddress findaircraftselectwinelems,1,1
	add word [edi+2],10
	mov word [edi+10],statictext(airportsel_typebutton)
	mov al,[edi+16]
	sub al,21
	mov [edi+4],al
	inc al
	mov [edi+14],al
	add al,10
	mov [edi+16],al
	mov word [edi+22],0x0225	// downward pointing black triangle
	mov byte [edi+24],0

	patchcode drawairportselwindow
	patchcode airportsizetext
	patchcode airportseltypeclick
	patchcode airportsel_eventhandler

	patchcode newaircraftorder
	patchcode stopaircraft_isinflight
	patchcode stoprotor
	patchcode buynewaircraft
	ret
