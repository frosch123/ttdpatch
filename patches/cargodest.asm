#include <std.inc>
#include <dest.inc>
#include <veh.inc>
#include <station.inc>
#include <win32.inc>
#include <flags.inc>
#include <textdef.inc>
#include <town.inc>
#include <pusha.inc>

extern outofmemoryerror
extern stationarray2ptr,station2ofs_ptr
extern cargodestroutecmpfactor, cdstrtcostexprthrshld
extern acceptcargofn
extern ensurecargoslot, transferprofit, addfeederprofittoexpenses
extern stationcargowaitingnotmask,stationcargowaitingmask
extern patchflags
extern loadcargounroutedquantity
extern cdstcargopacketinitttl
extern specialtext1, newtexthandler, newcargotypenames
extern kernel32hnd
extern cdstunroutedscoreval, cdstnegdistfactorval, cdstnegdaysfactorval, cdstroutedinitscoreval
extern cargodestroutediffmax, cdstatlastmonthcyclicroutecull, cargodestflags
extern cargodestwaitmult, cargodestwaitslew, getymd

//uncoment for debugging purposes
//#undef DEBUG
//#define DEBUG 1

#define MODE 1
//0 = old (modified recursive iteratively depth-first search)
//1 = new (more or less Djikstra's/Uniform Cost Search. ie. same as above but using a sorted queue rather than the stack)

// save pointer data
//uvard cargopacketstore
//uvard cargopacketstore_size
uvard cargodestdata
uvard cargodestdata_size
// save ends

//uvarb cargodestgameoptionflag

//uvarb cargodestroutecomparisonshiftfactor

uvarb cargodestgenflags, 32

global initcargodestmemory
initcargodestmemory:
	call freecargodestdata
	//call freecargopacketstore
	pushad
#if WINTTDX
/*	push byte 4				// PAGE_READWRITE
	push 0x1000				// AllocateType MEM_COMMIT
	push 0x10000				// Size 64k is a good starting size
	push DWORD [cargopacketstore]		// Address
	call dword [VirtualAlloc]
	cmp eax, [cargopacketstore]
	jne NEAR outofmemoryerror
	mov ebp, eax
	mov DWORD [cargopacketstore_size], 0x10000
*/
	push byte 4				// PAGE_READWRITE
	push 0x1000				// AllocateType MEM_COMMIT
	push cargodestdata_initialsize 		// Size
	push DWORD [cargodestdata]		// Address
	call dword [VirtualAlloc]
	or eax, eax
	jz NEAR outofmemoryerror
	cmp eax, [cargodestdata]
	jne NEAR outofmemoryerror
	mov DWORD [cargodestdata_size], cargodestdata_initialsize
#endif

	mov DWORD [eax+cargodestgamedata.version], 2
	mov DWORD [eax+cargodestgamedata.headerlength], cargodestgamedata.datastart
	mov DWORD [eax+cargodestgamedata.cddfirstfree], 0
	mov DWORD [eax+cargodestgamedata.cddusedend], cargodestgamedata.datastart
	mov DWORD [eax+cargodestgamedata.cddfreeleft], cargodestdata_initialsize-cargodestgamedata.datastart

	popad
	ret

global cargodestinitpostload
cargodestinitpostload:
	pushad
	mov WORD [cargodestlastglobalperiodicpreproc], 0
	mov ebp, [cargodestdata]
	cmp DWORD [ebp+cargodestgamedata.version], 2
	jae NEAR .nofixoldestwaiting

	mov ax, [currentdate]
	call [getymd]
	movzx ebx, bl
	movzx eax, WORD [currentdate]
	sub eax, ebx
	//eax=last date oldest waiting times updated

	mov esi, stationarray
	mov edi, [stationarray2ptr]
	xor ecx, ecx
.preloop:
	cmp WORD [esi+station.XY], 0
	je NEAR .prenext
	mov ebx, [edi+station2.cargoroutingtableptr]
	or ebx, ebx
	jz NEAR .prenext
	mov edx, [ebp+ebx+routingtable.nexthoprtptr]
	or edx, edx
	jz NEAR .prenext
.doadjustoldestwaiting:
	cmp WORD [ebp+edx+routingtableentry.dayswaiting], 0
	je .ok
	sub [ebp+edx+routingtableentry.dayswaiting], ax
	neg WORD [ebp+edx+routingtableentry.dayswaiting]
.ok:
	mov edx, [ebp+edx+routingtableentry.next]
	or edx, edx
	jnz .doadjustoldestwaiting
.prenext:
	add esi, station_size
	add edi, station2_size
	inc cl
	cmp cl, numstations
	jb .preloop

	mov DWORD [ebp+cargodestgamedata.version], 2
.nofixoldestwaiting:
	popad
	ret

global alloccargodestdataobj	//32 bytes long
alloccargodestdataobj:		//ebp = [cargodestdata]
				//returns relative pointer in eax, trashes ecx
				//returned data always zeroed
	mov eax, [ebp+cargodestgamedata.cddfirstfree]
	or eax, eax
	jz .expand
	xor ecx, ecx
	mov [eax+ebp+4], ecx
	mov [eax+ebp+8], ecx
	mov [eax+ebp+12], ecx
	mov [eax+ebp+16], ecx
	mov [eax+ebp+20], ecx
	mov [eax+ebp+24], ecx
	mov [eax+ebp+28], ecx
	xchg ecx, [eax+ebp]
				//now ecx is relative pointer of next free space or 0
	mov [ebp+cargodestgamedata.cddfirstfree], ecx
	ret
.expand:
	mov eax, [ebp+cargodestgamedata.cddusedend]
	add DWORD [ebp+cargodestgamedata.cddusedend], byte 32
	sub DWORD [ebp+cargodestgamedata.cddfreeleft], byte 32
	js .allocmoremem
	ret
.allocmoremem:
#if WINTTDX
	pushad
	add eax, ebp
	push eax
	push byte 4				// PAGE_READWRITE
	push 0x1000				// AllocateType MEM_COMMIT
	push 0x10000				// Size 64k is a good starting size
	push eax				// Address
	call dword [VirtualAlloc]
	pop ecx
	cmp eax, ecx
	jne NEAR outofmemoryerror
	add DWORD [ebp+cargodestgamedata.cddfreeleft], 0x10000
	add DWORD [cargodestdata_size], 0x10000
	sub eax, ebp
	popad
	ret
#else
        jmp outofmemoryerror
#endif

global freecargodestdataobj	//ebp = [cargodestdata]
freecargodestdataobj:		//eax = relative pointer to data to be freed
				//returns nothing, trashes ecx
	mov ecx, eax
	xchg ecx, [ebp+cargodestgamedata.cddfirstfree]
	mov [eax+ebp], ecx

	ret

/*
global freecargopacketstore
	cmp DWORD [cargopacketstore_size], 0
	je .nofree
	pushad
	push 0x4000				// MEM_DECOMMIT
	push DWORD cargopacketstore_reservesize // dwSize
	push DWORD [cargopacketstore]		// Address
	call DWORD [VirtualFree]
	mov DWORD [cargopacketstore_size], 0
	popad
.nofree:
	ret
*/

global freecargodestdata
freecargodestdata:
#if WINTTDX
	cmp DWORD [cargodestdata_size], 0
	je .nofree
	pushad
	push 0x4000				// MEM_DECOMMIT
	push DWORD cargodestdata_reservesize	// dwSize
	push DWORD [cargodestdata]		// Address
	call DWORD [VirtualFree]
	mov DWORD [cargodestdata_size], 0
	popad
.nofree:
#endif
	ret

global unlinkcargopacket			//eax=cargo packet relative ptr
unlinkcargopacket:				//ebp=[cargodestdata]
						//trashes: ecx, edx
	mov ecx, [eax+ebp+cargopacket.location]
	mov edx, ecx
	shr edx, 16
	jz .end
	cmp edx, 2
	je .veh
	jb .station
	int3
.end:
	mov DWORD [eax+ebp+cargopacket.location], 0
	ret
.veh:
	xor edx, edx
	xchg edx, [eax+ebp+cargopacket.prevptr]
	or edx, edx
	jnz NEAR .simpleunlink
	movzx ecx, cx
	lea edx, [cargodestgamedata.vehcplist+ebp+ecx*4]
	xor ecx, ecx
	xchg ecx, [eax+ebp+cargopacket.nextptr]
	mov [edx], ecx
	or ecx, ecx
	jz .end
	mov DWORD [ecx+ebp+cargopacket.prevptr], 0
	jmp .end
.station:
	xor edx, edx
	xchg edx, [eax+ebp+cargopacket.prevptr]
	xor ecx, ecx
	xchg ecx, [eax+ebp+cargopacket.nextptr]
	//edx=previous or zero
	//ecx=next or zero
	//eax=current (to be removed)
	or ecx, ecx
	jz .s1
	mov [ecx+ebp+cargopacket.prevptr], edx
	or edx, edx
	jz .frontunlink
	mov [edx+ebp+cargopacket.nextptr], ecx
	jmp .end
.s1:
	or edx, edx
	jz .lastunlink
.rearunlink:
	push edx
	call getstroutetablefromcp
	pop ecx
	mov DWORD [ecx+ebp+cargopacket.nextptr], 0
	or edx, edx
	jz .end
	mov [edx+ebp+routingtable.cargopacketsrear], ecx
	jmp .end
.frontunlink:
	push ecx
	call getstroutetablefromcp
	pop ecx
	mov DWORD [ecx+ebp+cargopacket.prevptr], 0
	or edx, edx
	jz .end
	mov [edx+ebp+routingtable.cargopacketsfront], ecx
	jmp .end
.lastunlink:
	call getstroutetablefromcp
	or edx, edx
	jz .end
	xor ecx, ecx
	mov [edx+ebp+routingtable.cargopacketsrear], ecx
	mov [edx+ebp+routingtable.cargopacketsfront], ecx
	jmp .end

.simpleunlink:
	//edx=previous
	//eax=current (to be removed)
	xor ecx, ecx
	xchg ecx, [eax+ebp+cargopacket.nextptr]
	//ecx=previous or 0
	mov [edx+ebp+cargopacket.nextptr], ecx
	or ecx, ecx
	jz .end
	mov [ecx+ebp+cargopacket.prevptr], edx
	jmp .end


getstroutetablefromcp:		//cargo packet in eax
				//returns cargo routing table in edx or zero
				//returns station2 ptr in ecx
	movzx ecx, WORD [eax+ebp+cargopacket.location]
getstroutetablefromstid:	//station id in ecx
				//returns cargo routing table in edx or zero
				//returns station2 ptr in ecx

	cmp ecx, numstations
	jb .ok
	xor edx, edx		//frankly this is indicative of a Serious Error�
#if WINTTDX && DEBUG		//not much can be done about it now though, and this operation (in the current usage of this function) erases the error anyway
	int3			//flag it if anyone is interested
#endif
	ret

.ok:
	lea edx, [ecx*8]
	lea edx, [edx*8+edx]
	sub edx, ecx
	mov ecx, [stationarray2ptr]
	add ecx, edx
	add ecx, edx
	mov edx, [ecx+station2.cargoroutingtableptr]
//	or edx, edx
//	jz .fail
	ret
//.fail:
//	int3
//	ret

fastunlinkstationcargopacket:			//eax=cargo packet relative ptr
						//ebp=[cargodestdata]
						//ebx=station routing table
						//trashes: ecx, edx
	xor edx, edx
	xchg edx, [eax+ebp+cargopacket.prevptr]
	xor ecx, ecx
	xchg ecx, [eax+ebp+cargopacket.nextptr]

						//this would be so much easier with cmov
	or edx, edx
	jz .a1
	mov [edx+ebp+cargopacket.nextptr], ecx
	jmp .a2
.a1:
        mov [ebx+ebp+routingtable.cargopacketsfront], ecx
.a2:

	or ecx, ecx
	jz .b1
	mov [ecx+ebp+cargopacket.prevptr], edx
	jmp .b2
.b1:
        mov [ebx+ebp+routingtable.cargopacketsrear], edx
.b2:

	ret


global linkcargopacket				//eax=cargo packet relative ptr (assumes currently unlinked)
linkcargopacket:				//ebp=[cargodestdata]
						//ebx=new location
						//trashes: ecx, edx
						//inserts to the *front* of the queue
	mov [eax+ebp+cargopacket.location], ebx
	mov ecx, ebx
	shr ecx, 16
	jz .end
	cmp ecx, 2
	jb .station
	je .veh
.int3:
	int3
.end:
	ret
.station:
	movzx ecx, bx
	cmp bx, 250
	jae .int3
	lea edx, [ecx*8]
	lea edx, [edx*8+edx]
	sub edx, ecx
	mov ecx, [stationarray2ptr]
	mov edx, [ecx+edx*2+station2.cargoroutingtableptr]
	or edx, edx
	jz .int3
.quickstation:					//eax=cargo packet relative ptr (assumes currently unlinked)
						//ebp=[cargodestdata]
						//edx=station's cargo routing table
						//trashes: ecx
						//inserts to the *front* of the queue
						//does not change the location field
	mov ecx, [edx+ebp+routingtable.cargopacketsfront]
	mov [edx+ebp+routingtable.cargopacketsfront], eax
	or ecx, ecx
	jnz .common
	mov [edx+ebp+routingtable.cargopacketsrear], eax
	jmp .common
.veh:
	movzx edx, bx
	mov ecx, eax
	xchg [cargodestgamedata.vehcplist+ebp+edx*4], ecx
.common:
	//eax=new packet
	//ecx=old first packet or zero
	or ecx, ecx
	jz .firstinsert
	mov [ecx+ebp+cargopacket.prevptr], eax
.firstinsert:
	mov [eax+ebp+cargopacket.nextptr], ecx
	ret

global getorcreatevehstatuscp
getorcreatevehstatuscp:	//ebp=[cargodestdata]
			//ecx=veh id
			//returns status packet in eax
	call getvehstatuscp
	or eax, eax
	jnz .ret
	push ebx
	push edx
	push ecx
	call alloccargodestdataobj
	mov ebx, [esp]
	or ebx, 0x20000
	call linkcargopacket
	mov BYTE [eax+ebp+cargopacket.flags], 2
	pop ecx
	pop edx
	pop ebx
.ret:
	ret

getvehstatuscp:		//ebp=[cargodestdata]
			//ecx=veh id
			//returns status packet in eax or zero if none

	mov eax, [cargodestgamedata.vehcplist+ebp+ecx*4]
	jmp .check
.loop:
	test BYTE [eax+ebp+cargopacket.flags], 2
	jnz .end
.next:
	mov eax, [eax+ebp+cargopacket.nextptr]
.check:
	or eax, eax
	jnz .loop
.end:
	ret


splitcargopacket:	//eax=old cargo packet
			//dx=amount to split off
			//ebp=[cargodestdata]
			//returns new packet in ebx (unlinked)
			//trashes ecx
	mov ebx, eax
	push edx
	call alloccargodestdataobj
	xchg eax, ebx
//	mov edx, [eax+ebp+cargopacket.lasttransprofit]
//	mov [ebx+ebp+cargopacket.lasttransprofit], edx
	mov edx, [eax+ebp+cargopacket.flags]
	mov [ebx+ebp+cargopacket.flags], edx
	mov dx, [eax+ebp+cargopacket.datearrcurloc]
	mov [ebx+ebp+cargopacket.datearrcurloc], dx
	mov edx, [eax+ebp+cargopacket.lastboardedst]
	mov [ebx+ebp+cargopacket.lastboardedst], edx
	mov edx, [eax+ebp+cargopacket.sourcest]
	mov [ebx+ebp+cargopacket.sourcest], edx
	pop edx
	sub [eax+ebp+cargopacket.amount], dx
	mov [ebx+ebp+cargopacket.amount], dx
	ret

uvarb acceptcargoatstationflag	//1=non-routed cargo is accepted here
				//2=routed cargo has been accepted and unloaded here
				//4=unload all cargo here (unload order)
				//8=vehicle definitely not finished unloading
				//16=vehicle definitely done unloading


uvarb acceptcargotempcargooffsetval
uvard acceptcargotemplastengine
uvarw acceptcargotemplaststationandcargo
uvarw acceptcargoroutedaccepted

// Accept vehicle cargo at station (the cargo goes away, player gets money)
// in:	esi -> current vehicle
//	edi -> engine
//	ax = max amount to unload in this step
//	bx = amount to credit for standard cargo
//	ebp -> loadunl.asm stack frame
//      ecx=cargo offset (maybe unchecked)
// out:	ax = amount unloaded in this step
//	bx = unrouted cargo quantity to charge
//	dx = unrouted quantity unloaded in this step
//	trashable: ecx, edx
global AcceptCargoAtStation_CargoDestAdjust
AcceptCargoAtStation_CargoDestAdjust:
	mov BYTE [acceptcargotempcargooffsetval], 0
	mov WORD [acceptcargoroutedaccepted], 0
	push eax	//max load amount
	push ebx	//becomes unrouted amount
	push edi	//engine
	push ebp	//stack frame
	push eax	//unload amount left

	call nexthoproutebuild

	movzx ecx, BYTE [ebp+0xE]
	or ecx, 0x10000

	mov ebp, [cargodestdata]

	movzx eax, WORD [esi+veh.idx]
	mov eax, [ebp+eax*4+cargodestgamedata.vehcplist]

	//eax = first cargo packet of vehicle

	jmp .startcploop

.ttlfail:
	or BYTE [eax+ebp+cargopacket.flags], 1
	mov BYTE [eax+ebp+cargopacket.ttl], 0		//keep it at zero
#if WINTTDX && DEBUG
	pushad
	mov ebx, [esp+4+32]	//stack frame
	movzx bx, BYTE [ebx+0xE]	//station id
	mov DWORD [specialtext1], ttlfailmess
	mov [textrefstack], bx
	mov edi, textrefstack+2
	mov ebx, eax
	call stos_vehname
	call outcargodestloadunloaddbgmess
	popad
#endif
.arrivedatdest:
	or dx, dx
	jz NEAR .acceptfail

	push eax

#if WINTTDX && DEBUG
	test BYTE [cargodestdebugflag], 0x10
	jz .nooutacceptmess
	pushad
	mov ebx, [esp+4+4+32]	//stack frame
	movzx bx, BYTE [ebx+0xE]	//station id
	mov DWORD [specialtext1], acceptmess
	mov [textrefstack+2], bx
	mov [textrefstack], dx
	mov edi, textrefstack+4
	mov ebx, eax
	call stos_vehname
	call outcargodestloadunloaddbgmess
	popad
.nooutacceptmess:
#endif

	//mov dx, [esp+4] //eax, max unload amount
	mov bx, [eax+ebp+cargopacket.amount]
	cmp bx, dx
	jbe .nosubfrompacket
	or BYTE [acceptcargoatstationflag], 8
	mov bx, dx
.nosubfrompacket:
	sub [eax+ebp+cargopacket.amount], bx
	add [acceptcargoroutedaccepted], bx

	sub [esp+4], bx

	mov dx, [currentdate]
	sub dx, [eax+ebp+cargopacket.dateleft]

	or dh, dh
	jz .nosaturatedays
	mov dl, 0xFF
.nosaturatedays:

	test    BYTE [eax+ebp+cargopacket.flags], 1
	jnz	.skipcostcalc
	mov	al, [eax+ebp+cargopacket.sourcest]
	mov	ah, cl   //station id
	//mov	dl, [esi+veh.cargotransittime]
	mov	ch, [esi+veh.cargotype]
	call	dword [acceptcargofn]
	mov ecx, [esp+8]		//ebp: stack frame
	add	[ecx+4], eax		//income
	movzx ecx, BYTE [ecx+0xE]
	or ecx, 0x10000
.skipcostcalc:
	pop eax

	or BYTE [acceptcargoatstationflag], 2

	cmp WORD [eax+ebp+cargopacket.amount], 0
	jne NEAR .cploopnext

	push edi
	mov edi, [esp+4+4]
	push ecx
	push DWORD [eax+ebp+cargopacket.nextptr]
	call clearlasttransprofit
	call unlinkcargopacket
	call freecargodestdataobj
	pop eax
	pop ecx
	pop edi
	jmp .startcploop

.unloadcargohere:
	push ecx
.unloadcargohere_popecx:
	mov ebp, [esp+8]			//stack frame
	mov ebx, [ebp+0xA]                      //station ptr
	movzx ecx, BYTE [ebp+0x11]                      //cargo offset
	call	ensurecargoslot                 //this means that a cargo slot must be available for unloading to occur
	mov ebx, ebp
	mov ebp, [cargodestdata]
	mov [acceptcargotempcargooffsetval], cl
	or cl,cl
	jns .offset_ok
.unloadfail:
	pop ecx                                 //fail, no cargo slot, set flag to force waiting
.acceptfail:
	or BYTE [acceptcargoatstationflag], 8
	jmp .cploopnext

.offset_ok:
	mov dx, [eax+ebp+cargopacket.amount]
	mov bx, [esp+4]

#if WINTTDX && DEBUG
	test BYTE [cargodestdebugflag], 0x20
	jz .nooutunloadmess
	pushad
	mov edx, [esp+4+4+32]		//stack frame
	movzx dx, BYTE [edx+0xE]	//station id
	mov DWORD [specialtext1], unloadmess
	mov [textrefstack+2], dx
	mov [textrefstack], bx
	mov edi, textrefstack+4
	mov ebx, eax
	call stos_vehname
	call outcargodestloadunloaddbgmess
	popad
.nooutunloadmess:
#endif

	or bx, bx
	jz .unloadfail
	cmp dx, bx
	ja .splitpacket
	call .checkspaceandunload
	sub [esp+4], dx
	mov cl, [esp]
	call .domoneyandcargoinc
	push DWORD [eax+ebp+cargopacket.nextptr]
	call unlinkcargopacket
	mov ecx, [esp+4]
	mov [eax+ebp+cargopacket.location], ecx
	mov edx, [esp+12]			//stack frame
	mov edx, [edx+0x12]			//routing table ptr of station
	call linkcargopacket.quickstation
	pop eax
	pop ecx
	jmp .startcploop

.splitpacket:
	mov dx, bx
	call .checkspaceandunload
	or BYTE [acceptcargoatstationflag], 8
	call splitcargopacket
	mov ecx, [esp]
	mov [ebx+ebp+cargopacket.location], ecx
	sub [esp+4], dx
	call .domoneyandcargoinc
	mov edx, [esp+8]			//stack frame
	mov edx, [edx+0x12]			//routing table ptr of station
	xchg eax, ebx
	call linkcargopacket.quickstation
	xchg eax, ebx
	pop ecx
	jmp .cploopnext

.domoneyandcargoinc:			//eax=cargo packet
					//cl=station id
					//ebp=[cargodestdata]
					//dx=amount
					//esi=vehicle
					//edi=engine
					//trashes dx
	testflags feederservice
	jnc .domoneyandcargoinc_ret
	pusha
	mov bx, dx
	mov ch,byte [esi+veh.cargotype]
	mov dx, [currentdate]
	sub dx, [eax+ebp+cargopacket.datearrcurloc]
	or dh, dh
	jz .timeok
	mov dl, 0xFF    //saturate days
.timeok:
        lea esi, [eax+ebp+cargopacket.lasttransprofit]
	mov al, [eax+ebp+cargopacket.lastboardedst]
	mov ah, cl
	call transferprofit
	sub [edi+veh.profit], eax
	add [esi], eax
	call addfeederprofittoexpenses
	popa
.domoneyandcargoinc_ret:
	mov dx, [currentdate]
	mov [eax+ebp+cargopacket.datearrcurloc], dx
	ret

.checkspaceandunload:			//ecx=current cargo slot for station
					//esi=vehicle
					//dx=amount
					//trashable: ebx, ecx

        mov ebx, [esp+12]		//stack frame
	add ecx, [ebx+0xA]		//station ptr

	cmp BYTE [station.cargos+ecx+stationcargo.enroutefrom], 0xFF
	jne .enroutefromok
	mov byte [station.cargos+ecx+stationcargo.enroutetime], 0
	mov bl, [ebx+0xE]		//station ID
	mov [station.cargos+ecx+stationcargo.enroutefrom], bl
.enroutefromok:

	mov bp, [station.cargos+ecx+stationcargo.amount]
	push ecx
	mov bx, bp
	mov cx, [stationcargowaitingnotmask]
	and bp, cx
	xor bx, bp                      //bx=cargo amount
	add bx, dx
	test bx, cx
	pop ecx
	jz NEAR .checkspaceandunload_ok
.ejectcargo:
	//eject cargo from station sans payment to make space
	push edi
	push ebp
	push eax
	push edx
        mov edi, [esp+12+16]		//stack frame
	mov edi, [edi+0xA]		//station ptr
	add edi, [station2ofs_ptr]
	mov ebp, [cargodestdata]
	mov eax, [edi+station2.cargoroutingtableptr]
	or eax, eax
	jz .ejectcargonocps

	mov eax, [ebp+eax+routingtable.cargopacketsrear]
.ejectcargocheckpacket:
	or eax, eax
	jz .ejectcargonocps
	test BYTE [eax+ebp+cargopacket.flags], 2	//not a cargo packet
	jnz .ejectcargonextpacket
	mov dl, [esi+veh.cargotype]
	cmp dl, [ebp+eax+cargopacket.cargo]
	jne .ejectcargonextpacket
	//this packet will be ejected
	sub bx, [ebp+eax+cargopacket.amount]
	push DWORD [ebp+eax+cargopacket.prevptr]
	push ecx
	call unlinkcargopacket
	call freecargodestdataobj
	pop ecx
	pop eax
	test bx, [stationcargowaitingnotmask]
	jz .doneejectcargo
	jmp .ejectcargocheckpacket


.ejectcargonextpacket:
	mov eax, [ebp+eax+cargopacket.prevptr]
	jmp .ejectcargocheckpacket

.ejectcargonocps:
	mov bx, [stationcargowaitingmask]
.doneejectcargo:
	pop edx
	pop eax
	pop ebp
	pop edi
.checkspaceandunload_ok:
	or bx, bp
	mov [station.cargos+ecx+stationcargo.amount], bx

	mov ebp, [cargodestdata]
	ret

//.checkspaceandunload_fail:
//	//pop ecx
//	mov ebp, [cargodestdata]
//	pop ecx                         //eat return address
//	jmp .unloadfail

	//[esp]=unload amount left
	//[esp+4]=stack frame
	//[esp+8]=engine
	//[esp+12]=unrouted amount left
	//eax=cargo packet
	//ecx=current location
	//ebp=[cargodestdata]
.cploop:
	test BYTE [eax+ebp+cargopacket.flags], 2	//not a cargo packet
	jnz NEAR .cploopnext
	mov dx, [eax+ebp+cargopacket.amount]
	sub [esp+12], dx
	mov dx, [esp] //eax, max unload amount

	movzx ebx, BYTE [eax+ebp+cargopacket.destst]
	cmp bl, cl
	je .arrivedatdest
	or ebx, 0x10000

	//ttl check
	test BYTE [esi+veh.modflags], (1 << MOD_DIDCASHIN)      //only decrement the ttl once
	jnz NEAR .nottlcheck
	sub BYTE [eax+ebp+cargopacket.ttl], 1
	jc .ttlfail
.nottlcheck:

	test BYTE [acceptcargoatstationflag], 4
	jnz .unloadcargohere

	push ecx
	mov ecx, ebx

	//checking loop
	mov ebx, [esp+4+4]			//stack frame
	mov edx, [ebx+0x12]			//routing table ptr of station
	or edx, edx
	jz .cploopnext_popecx
	movzx ebx, BYTE [ebx+0x16]			//id of next station
	cmp bl, -1
	je .unloadcargohere_popecx
	or ebx, 0x10000

	//TODO: is the following really a good idea?
	cmp [eax+ebp+cargopacket.destst], bl
	je .cploopnext_popecx			//next stop of the vehicle is the destination, don't unload packet

	mov edx, [edx+ebp+routingtable.destrtptr]
.routecheckloop:				//check each entry of this stations far routing table for entries to the final destniation with a next hop of the vehicles next stop
	or edx, edx
	jz .unloadcargohere_popecx		//if none are found unload
	cmp [edx+ebp+routingtableentry.nexthop], ebx
	jne .nextroutecheckiteration
	cmp [edx+ebp+routingtableentry.dest], ecx
	jne .nextroutecheckiteration
	push edx
	mov dh, [edx+ebp+routingtableentry.cargo]
	cmp dh, [esi+veh.cargotype]
	pop edx
	je .cploopnext_popecx			//if any (there should only be one really) are found, don't unload

.nextroutecheckiteration:
	mov edx, [edx+ebp+routingtableentry.next]
	jmp .routecheckloop

.cploopnext_popecx:
	pop ecx
.cploopnext:
	mov eax, [eax+ebp+cargopacket.nextptr]
.startcploop:
	or eax, eax
	jnz .cploop
.finishedcp:

	pop edx         //amount left out of max unload in this step
	pop ebp

        test BYTE [acceptcargoatstationflag], 2
        jz .notaccepted
	mov ebx,[ebp+0xA]//[%$currstationptr]
	add ebx,[station2ofs_ptr]
	movzx ecx, byte [esi+veh.cargotype]
	bts dword [ebx+station2.acceptedsinceproc],ecx
	bts dword [ebx+station2.acceptedthismonth],ecx
	bts dword [ebx+station2.everaccepted],ecx
.notaccepted:

	pop edi
	pop ebx         //amount of unrouted cargo to charge
	pop eax         //original max amount to unload

	//let x=routed cargo unloaded in this step
	//let y=routed cargo present before unloading
	//let bx=unrouted cargo present
	//let ax=original max amount to unload
	//let b (bx original)=original total amount of cargo
	//let dx=amount left out of original max amount to unload
	//let z=amount to unload in this step

	//x=ax-dx
	//y=b-bx
	//z=min(x+bx,ax)
	//z=min(ax-dx+bx,ax)
	//z=ax+min(bx-dx,0)
	//z=ax-dx+min(bx,dx)
	//return z in ax

	//assuming that all routed cargo is unloaded (x==y)
	//amount of unrouted cargo remaining after this unload:
	//bx-(z-x)
	//bx-min(bx,dx)
	//bx+max(-bx,-dx)
	//max(0,bx-dx)
	//therefore loading not finished if bx>dx

	test BYTE [acceptcargoatstationflag], 8		//if nothing is unloaded in this step, we're done
	jnz .notmaybedoneloading
	test BYTE [acceptcargoatstationflag], 1
	jz .doneloading
	cmp bx, dx
	jae .notmaybedoneloading
.doneloading:
	//and byte [esi+veh.modflags],~ ((1 << MOD_MORETOUNLOAD)+(1 << MOD_DIDCASHIN))
	or BYTE [acceptcargoatstationflag], 16
.notmaybedoneloading:

	sub ax, dx

	cmp bx, dx
	jae .ok1
	mov dx, bx
.ok1:
	add ax, dx

	test BYTE [acceptcargoatstationflag], 1
	jnz .nodenynormalaccept
	sub ax, dx			//this should kill off any chance of cargo being accepted that isn't explicitly routed there
	xor bx, bx
	xor dx, dx
.nodenynormalaccept:

	push edi
	mov edi, [station2ofs_ptr]
	add edi, [ebp+0xA]		//station ptr
	mov cx, [acceptcargoroutedaccepted]
	add cx, bx
	add WORD [edi+station2.activitythismonth], cx
	jnc .actok
	mov WORD [edi+station2.activitythismonth], -1	//saturate
.actok:
	pop edi

#if WINTTDX && DEBUG
	test BYTE [cargodestdebugflag], 0x80
	jz .nooutacceptendmess
	pushad
	mov [textrefstack], ax
	mov [textrefstack+2], dx
	mov [textrefstack+4], bx
	movzx bx, BYTE [ebp+0xE]	//station id
	mov [textrefstack+6], bx
	mov DWORD [specialtext1], acceptendmess
	mov edi, textrefstack+8
	call stos_vehname

	call outdebugcargomessage
	popad
.nooutacceptendmess:
#endif


	ret

//esi=vehicle
//ebp=loadunl.asm stack frame
global nexthoproutebuild
nexthoproutebuild:
	pushad
	movzx ecx, BYTE [ebp+0xE]
	or ecx, 0x10000

	mov ebp, [cargodestdata]

//begin building next hop route data
	test BYTE [esi+veh.modflags], (1 << MOD_DIDCASHIN)
	jnz NEAR .nobuildroute
	cmp WORD [esi+veh.capacity], 0
	je NEAR .nobuildroute
	movzx edx, WORD [esi+veh.idx]
	cmp WORD [ebp+cargodestgamedata.vehrttimelist+edx*2], 0
	je NEAR .nobuildroute
	mov dl, [esi+veh.cargotype]
	mov dh, [esi+veh.prevstid]
	or dh, dh
	jz NEAR .nobuildroute
	dec dh
	cmp dh, cl
	je NEAR .nobuildroute
	mov BYTE [esi+veh.prevstid], 0
	cmp DWORD [acceptcargotemplastengine], edi
	jne .buildroute
	cmp WORD [acceptcargotemplaststationandcargo], dx
	je NEAR .nobuildroute
.buildroute:							//try to avoid doing the same action over and over when a multi-part vehicle arrives
	mov [acceptcargotemplastengine], edi
	mov [acceptcargotemplaststationandcargo], dx
	mov eax, ecx
	mov bl, dl
	movzx ecx, dh
	call getstroutetablefromstid
	or edx, edx
	jz NEAR .nobuildroute

	//eax=current locatiom
	//bl=cargo
	//ecx=station2 ptr
	//edx=routing table of previous node

	mov [cdestcurstationptr], ecx	//note that now contains station2 not station

	mov ecx, [edx+ebp+routingtable.nexthoprtptr]
	or ecx, ecx
	jz .addentry
.nexthopcheckloop:
	cmp [ecx+ebp+routingtableentry.cargo], bl
	jne .nexthopcheckloopnext
	cmp [ecx+ebp+routingtableentry.dest], eax
	jne .nexthopcheckloopnext
	//found old routing entry which will do fine
	push eax
	mov ax, [currentdate]
	mov [ecx+ebp+routingtableentry.lastupdated], ax
	movzx edx, WORD [esi+veh.idx]
	sub ax, [ebp+cargodestgamedata.vehrttimelist+edx*2]
	sub ax, [ecx+ebp+routingtableentry.mindays]
	sar ax, 2
#if WINTTDX && DEBUG
	add ax, [ecx+ebp+routingtableentry.mindays]
	jns .rtmkok
	int3		//oh noes!
.rtmkok:
	mov [ecx+ebp+routingtableentry.mindays], ax
#else
	add [ecx+ebp+routingtableentry.mindays], ax
#endif
	mov eax, ecx
	pop ecx
	jmp .donebuildroute
.nexthopcheckloopnext:
	mov ecx, [ecx+ebp+routingtableentry.next]
	or ecx, ecx
	jnz .nexthopcheckloop
.addentry:
	push eax
	push eax
	push edx
	call alloccargodestdataobj
	pop edx
	pop DWORD [eax+ebp+routingtableentry.dest]
	mov ecx, [esp+4+_pusha.ebp]
	mov ecx, [ecx+0x12]                     //routing table of current station
	mov [eax+ebp+routingtableentry.destrttable], ecx
	mov [eax+ebp+routingtableentry.cargo], bl
	mov ecx, eax
	xchg ecx, [edx+ebp+routingtable.nexthoprtptr]
	mov [eax+ebp+routingtableentry.next], ecx
	mov cx, [currentdate]
	mov [eax+ebp+routingtableentry.lastupdated], cx
	movzx edx, WORD [esi+veh.idx]
	sub cx, [ebp+cargodestgamedata.vehrttimelist+edx*2]
	mov [eax+ebp+routingtableentry.mindays], cx

	//run minimalistic far route recalculation at route start station
	push eax
	mov cx, [currentdate]
	xchg cx, [cargodestlastglobalperiodicpreproc]	//this effectively disables the global pre-processing
	mov edi, [cdestcurstationptr]
	mov esi, edi
	sub esi, [station2ofs_ptr]
	call cargodeststationperiodicproc
	mov [cargodestlastglobalperiodicpreproc], cx
	pop eax

	pop ecx
.donebuildroute:
#if WINTTDX && DEBUG
	test BYTE [cargodestdebugflag], 4
	jz .nobuildroute
	pushad
	push eax
	mov edi, textrefstack
	movzx ax, BYTE [acceptcargotemplaststationandcargo+1]
	stosw
	mov esi, [esp+4+32+_pusha.ebp]	//stack frame
	mov esi, [esi+0xA]	//station ptr
	call stos_stationname
	mov DWORD [specialtext1], localroutemsg
	call outdebugcargomessage
	mov edi, textrefstack
	pop ebx
	call stos_routedata
	mov DWORD [specialtext1], routedumpmess
	call outdebugcargomessage
	popad
#endif
.nobuildroute:
//end building next hop route data
	popad
	ret

uvarb cargodestloadflags
	//1=more routed cargo waiting to be loaded onto this vehicle in the station

// Load cargo from station
// in:	ebx->station
//	ecx=cargo offset (valid)
//	esi->vehicle
//	edi->engine
//	ebp -> loadunl.asm stack frame
//	ax=max amount to load (always <= dx)
//	dx=amount of cargo in the station
// out:	ax=amount to actually load
//trashable: none
global LoadCargoFromStation_CargoDestAdjust
LoadCargoFromStation_CargoDestAdjust:
	or ax, ax
	je NEAR .finalret
	push ebp
	push edx		//amount of cargo in station
	push ecx		//cargo
	push edi
	mov edi, ebp
	push eax		//max amount to load
	push edx		//becomes amount of unrouted cargo in the station
	push eax		//becomes amount remaining of load limit
	mov ebp, [cargodestdata]
	movzx edx, BYTE [edi+0x16]
	or edx, 0x10000				//location of next hop


	mov ebx, [edi+0x12]			//routing table of current station
	or ebx, ebx
	jz NEAR .quit
	mov eax, [ebx+ebp+routingtable.cargopacketsrear]
	jmp .startcploop

.loadpacket:
	mov cx, [eax+ebp+cargopacket.amount]
	mov bx, [esp]
	or bx, bx
	jz NEAR .loadfail
	//eax=cargo packet
	//bx=amount of load limit remaining
	//cx=amount of cargo in packet
	//edx=location of next station
	//esi=vehicle ptr
	//edi=stack frame
	//ebp=[cargodestdata]

#if WINTTDX && DEBUG
	test BYTE [cargodestdebugflag], 0x40
	jz .nooutloadmess
	pushad
	movzx dx, BYTE [edi+0xE]	//station id
	mov DWORD [specialtext1], loadmess
	mov [textrefstack+2], dx
	mov [textrefstack], bx
	mov edi, textrefstack+4
	mov ebx, eax
	call stos_vehname
	call outcargodestloadunloaddbgmess
	popad
.nooutloadmess:
#endif

	cmp cx, bx
	ja .splitpacket
	sub [esp], cx
	push edx
	mov dx, cx
	call .loadmoneydatefunc
	push DWORD [eax+ebp+cargopacket.prevptr]
	mov ebx, [edi+0x12]			//routing table ptr of station
	call fastunlinkstationcargopacket
	mov ebx, 0x20000
	mov bx, [esi+veh.idx]
	call linkcargopacket
	pop eax
	pop edx
	jmp .startcploop
.splitpacket:
	or BYTE [cargodestloadflags], 1
	sub [esp], bx
	push edx
	mov dx, bx
	call .loadmoneydatefunc			//this is suboptimal
	call splitcargopacket
	push eax
	mov eax, ebx
	mov ebx, 0x20000
	mov bx, [esi+veh.idx]
	call linkcargopacket
	pop eax
	pop edx
	jmp .cploopnext

.loadmoneydatefunc:     //eax=cargo packet
			//edi=stack frame
			//esi=vehicle
			//ebp=[cargodestdata]
			//trashes cx

	mov cl, [edi+0xE]		//station idx
	xchg [eax+ebp+cargopacket.lastboardedst], cl
	cmp cl, -1
	mov cx, [currentdate]
	jne .notfirstdepart
	mov [eax+ebp+cargopacket.dateleft], cx
.notfirstdepart:
	mov [eax+ebp+cargopacket.datearrcurloc], cx
	ret



.loadfail:
	or BYTE [cargodestloadflags], 1
	jmp .cploopnext
.cploop:
	test BYTE [eax+ebp+cargopacket.flags], 2	//not a cargo packet
	jnz NEAR .cploopnext
	mov cl, [esi+veh.cargotype]
	cmp cl, [eax+ebp+cargopacket.cargo]
	jne .cploopnext
	mov cx, [eax+ebp+cargopacket.amount]
	sub [esp+4], cx
	cmp dl, -1
	je .cploopnext
	cmp [eax+ebp+cargopacket.destst], dl
	je .loadpacket

	//routing check

	mov ebx, [edi+0x12]
	mov ecx, [ebx+ebp+routingtable.destrtptr]
	or ecx, ecx
	jz .cploopnext
	mov ebx, 0x10000
	mov bl, [eax+ebp+cargopacket.destst]
.routecheckloop:
	cmp [ecx+ebp+routingtableentry.nexthop], edx
	jne .nextroutecheckiteration
	cmp [ecx+ebp+routingtableentry.dest], ebx
	jne .nextroutecheckiteration
	push edx
	mov dh, [ecx+ebp+routingtableentry.cargo]
	cmp dh, [esi+veh.cargotype]
	pop edx
	je .loadpacket

.nextroutecheckiteration:
	mov ecx, [ecx+ebp+routingtableentry.next]
	or ecx, ecx
	jnz .routecheckloop

.cploopnext:
	mov eax, [eax+ebp+cargopacket.prevptr]
.startcploop:
	or eax, eax
	jnz .cploop
.finishedcp:


.quit:
	pop edx		//amount of load limit remaining

	pop ebx		//amount of unrouted cargo in station

	or ebx, ebx
	jns .routedamountok
#if WINTTDX & DEBUG
	int3		//negative amount of unrouted cargo in station. This is Bad�.
#endif
	xor ebx, ebx
.routedamountok:

	pop eax		//original max load amount

	sub ax, dx	//ax=routed amount loaded so far

	mov cx, dx
	cmp bx, dx
	jae .ok1
	mov cx, bx
.ok1:			//cx=min(bx,dx)=extra amount of unrouted cargo that can be loaded


	add ax, cx
	mov [loadcargounroutedquantity], cx     //amount of unrouted cargo loaded in this step

	pop edi


	mov cx, [esi+veh.currentload]
	or cx, cx
	jnz .noresetcargosource
	push ecx
	mov ecx, [esp+12]
	mov ecx, [ecx+0xE]		//cur station id
	mov [esi+veh.cargosource], cl
	pop ecx
.noresetcargosource:
	sub cx, [esi+veh.capacity]
	jz .doneload
//	cmp cx, ax
//	je .doneload
	test BYTE [cargodestloadflags], 1
	jnz .notdoneload	//no cargo left
	cmp bx, dx
	jbe .doneload
.notdoneload:
	or byte [esi+veh.modflags],1 << MOD_NOTDONEYET
.doneload:

	pop ecx		//cargo
	pop edx		//original station cargo amount
	pop ebp
	mov ebx, [ebp+0xA]      //restore station ptr
.finalret:

#if WINTTDX && DEBUG
	test BYTE [cargodestdebugflag+1], 1
	jz .nooutacceptendmess
	pushad
	mov [textrefstack], ax
	mov dx, [loadcargounroutedquantity]
	mov [textrefstack+2], dx
	movzx bx, BYTE [ebp+0xE]	//station id
	mov [textrefstack+4], bx
	mov edi, textrefstack+6
	call stos_vehname
	mov DWORD [specialtext1], loadendmess

	call outdebugcargomessage
	popad
.nooutacceptendmess:
#endif

	ret

clearlasttransprofit:	//eax=cargo packet
			//edi=stack frame
			//esi=vehicle
			//ebp=[cargodestdata]
	testflags feederservice
	jnc .ret
	pusha
	add ebp, eax
	xor eax, eax
	xchg eax, [ebp+cargopacket.lasttransprofit]
	neg eax
	mov edi, [edi]				//engine
	sub [edi+veh.profit],eax
	call addfeederprofittoexpenses
	popa
.ret:
	ret


uvarw cargodestlastglobalperiodicpreproc
#if MODE
uvard searchqueuestart
#endif

uvarb stationpassarray, 256

//called by station2.asm:monthlystationupdate, nexthoproutebuild
global cargodeststationperiodicproc
cargodeststationperiodicproc:		//edi=station2 ptr
					//esi=station ptr
					//ebp=[cargodestdata]
					//trashable: eax, edi
					//returns nothing

	pushad
	mov ebp, [cargodestdata]
	mov ax, [currentdate]
	cmp ax, [cargodestlastglobalperiodicpreproc]
	je NEAR .nopreproc
	mov [cargodestlastglobalperiodicpreproc], ax
	xor ecx, ecx
	mov [cdstatlastmonthcyclicroutecull], ecx
	mov esi, stationarray
	mov edi, [stationarray2ptr]
.preloop:
	cmp WORD [esi+station.XY], 0
	je NEAR .prenext
	xor ebx, ebx
	xchg WORD [edi+station2.activitythismonth], bx
	mov WORD [edi+station2.activitylastmonth], bx
	mov ebx, [edi+station2.cargoroutingtableptr]
	or ebx, ebx
	jz NEAR .prenext

	//set to oldest waiting in that station routable on that path
	//use old distant routes

	mov edx, [ebp+ebx+routingtable.nexthoprtptr]
	lea eax, [ebx+routingtable.nexthoprtptr-routingtableentry.next]
	push eax
.preinnerloop:
	mov ax, [currentdate]
	sub ax, [cdstrtcostexprthrshld]
	or edx, edx
	jz NEAR .preinnerloopend
	cmp ax, [ebp+edx+routingtableentry.lastupdated]
	ja NEAR .killoldlocalroute
	
	mov ch, [ebp+edx+routingtableentry.cargo]

//distant route loop
	test BYTE [cargodestflags], 2
	jz .nofarrouteoldestwaitingtablemake
	pushad
	mov edi, stationpassarray
	mov ecx, 256/4
	xor eax, eax
	cld
	rep stosd
	mov esi, [ebp+edx+routingtableentry.dest]
	mov edi, [ebp+ebx+routingtable.destrtptr]
	or edi, edi
	jz .doneoldestwaitingtablemake
.prepacketfarrouteloop:
        mov eax, [ebp+edx+routingtableentry.dest]
	cmp eax, [ebp+edi+routingtableentry.nexthop]
	jne .prepacketfarroutenext
	cmp ch, [ebp+edi+routingtableentry.cargo]
	jne .prepacketfarroutenext
	movzx eax, BYTE [ebp+edi+routingtableentry.dest]
	or BYTE [stationpassarray+eax], 1
.prepacketfarroutenext:
	mov edi, [ebp+edi+routingtableentry.next]
	or edi, edi
	jnz .prepacketfarrouteloop
.doneoldestwaitingtablemake:
	popad
.nofarrouteoldestwaitingtablemake:
//ends

	//calc oldest waiting
	//lazily assume that the oldest is the last in the queue which matches
	mov eax, [ebp+ebx+routingtable.cargopacketsrear]
	push edi
	push esi
.prepacketloop:
	or eax, eax
	jz .nooldest

	//check packet
	cmp ch, [ebp+eax+cargopacket.cargo]
	//cmp ch, [ebp+edx+routingtableentry.cargo]
	jne .prepacketnext
	movzx esi, BYTE [ebp+eax+cargopacket.destst]
	or esi, 0x10000
	cmp esi, [ebp+edx+routingtableentry.dest]
	je .gotoldest

	//switchable for now, turn off to try to prevent positive/oscillatory feedback of route costs caused excessive gain. Eg. an empty route causing
	//a massive route/traffic spike through that route (overshoot), which results next month in the hop wait time being enormous
	//as the route is clogged with a giant backlog from old packets now routable through it. The following month there is an overshoot
	//response in the other direction of no far routes being routed through it as the waiting time is too long, such that the route becomes empty again, etc.

	test BYTE [cargodestflags], 2
	jz .nofarrouteoldestwaiting
	and esi, 0xFF
	cmp BYTE [stationpassarray+esi], 0
	jne .gotoldest

.nofarrouteoldestwaiting:

.prepacketnext:
	mov eax, [ebp+eax+cargopacket.prevptr]
	jmp .prepacketloop

.nooldest:
	mov ax, [currentdate]
	jmp .gotoldestdate
.gotoldest:
	mov ax, [ebp+eax+cargopacket.datearrcurloc]
.gotoldestdate:
	pop esi
	pop edi
#if WINTTDX && DEBUG
	test BYTE [cargodestdebugflag+1], 4
	jz .nosetoldestwaitingroutemess
	pushad
	push edx
	mov [textrefstack+4], ax
	movzx ax, BYTE [ebp+ebx+routingtable.location]
	mov [textrefstack], ax
	movzx ax, BYTE [ebp+edx+routingtableentry.dest]
	mov [textrefstack+2], ax
	mov DWORD [specialtext1], setoldestwaitinglocalroutemsg
	call outdebugcargomessage
	mov edi, textrefstack
	pop ebx
	call stos_routedata
	mov DWORD [specialtext1], routedumpmess
	call outdebugcargomessage
	popad
.nosetoldestwaitingroutemess:
#endif

	neg ax
	add ax, [currentdate]

	cmp WORD [cargodestwaitslew], 0
	jz .noslewcheck	
	push ebx
	push ecx
	mov cx, [ebp+edx+routingtableentry.dayswaiting]
	mov bx, [cargodestwaitslew]
	//ax=new waiting time
	//cx=old waiting time
	sub ax, cx
	//ax=increase in waiting time
	js .negcheck
	cmp ax, bx
	jbe .donecheck
	mov ax, bx
	jmp .donecheck

.negcheck:
	neg ax
	cmp ax, bx
	jbe .donecheckneg
	mov ax, bx
.donecheckneg:
	neg ax	
	
.donecheck:
	add ax, cx	
	pop ecx
	pop ebx
.noslewcheck:

	mov [ebp+edx+routingtableentry.dayswaiting], ax
	mov [esp], edx
	mov edx, [ebp+edx+routingtableentry.next]
	jmp .preinnerloop
.killoldlocalroute:
#if WINTTDX && DEBUG
	test BYTE [cargodestdebugflag+1], 2
	jz .nokilloldroutemess
	pushad
	push edx
	mov edi, textrefstack
	movzx ax, BYTE [ebp+ebx+routingtable.location]
	stosw
	movzx ax, BYTE [ebp+edx+routingtableentry.dest]
	stosw
	mov DWORD [specialtext1], killoldlocalroutemsg
	call outdebugcargomessage
	mov edi, textrefstack
	pop ebx
	call stos_routedata
	mov DWORD [specialtext1], routedumpmess
	call outdebugcargomessage
	popad
.nokilloldroutemess:
#endif
	push ecx
	mov eax, edx
	mov edx, [esp+4]
	mov ecx, [ebp+eax+routingtableentry.next]
	push ecx
	mov [ebp+edx+routingtableentry.next], ecx
	call freecargodestdataobj
	pop edx
	pop ecx
	jmp .preinnerloop

.preinnerloopend:
	add esp, 4
.prenext:
	add esi, station_size
	add edi, station2_size
	inc cl
	cmp cl, numstations
	jb .preloop
	popad
	pushad
	mov ebp, [cargodestdata]
.nopreproc:

	mov edi, [edi+station2.cargoroutingtableptr]
	or edi, edi
	jz NEAR .end
	xor eax, eax
	xchg eax, [edi+ebp+routingtable.destrtptr]
	mov [cdestcurstationptr], esi

	//freeing loop: fast unlink and deallocate of all far entries at this station
.loop:
	or eax, eax
	jz .loopdone
	mov ebx, [eax+ebp+routingtableentry.next]
	call freecargodestdataobj
	mov eax, ebx
	jmp .loop
.loopdone:

	mov edx, [edi+ebp+routingtable.nexthoprtptr]
	mov [startroutingtable], edi

#if MODE
	cmp DWORD [searchqueuestart], 0
	je .sqs_ok
	int3	//oh noes
.sqs_ok:
#endif

.buildloop:
	or edx, edx
	jz .buildloopend
	push DWORD [edx+ebp+routingtableentry.next]
	movzx ebx, BYTE [edx+ebp+routingtableentry.cargo]

	push ebx
	sub esp, 8
	movzx esi, WORD [edx+ebp+routingtableentry.mindays]
	movzx ebx, WORD [edx+ebp+routingtableentry.dayswaiting]
	or ebx, ebx
	jz .nocargowaitingcost
	imul ebx, [cargodestwaitmult]
	shr ebx, 8
	add si, bx
.nocargowaitingcost:
	push esi
	mov esi, [edx+ebp+routingtableentry.destrttable]
	mov [esp-12+16], esi
	mov esi, [edx+ebp+routingtableentry.dest]

	push DWORD [startroutingtable]
	push DWORD [edx+ebp+routingtableentry.destrttable]
	mov [esp-4+20], esi
#if MODE
	call queuenextnodes
#else
	call addroutesreachablefromthisnodeandrecurse
#endif
	add esp, 24
/*
	call alloccargodestdataobj

	//prepend to queue.
	mov ecx, [searchqueuestart]
	mov [ebp+eax+searchqueueitem.next], ecx
	mov [searchqueuestart], eax

	pop DWORD [ebp+eax+searchqueueitem.currentrt]
	pop DWORD [ebp+eax+searchqueueitem.prevrt]
	pop DWORD [ebp+eax+searchqueueitem.days]
	pop DWORD [ebp+eax+searchqueueitem.nexthoprt]
	pop DWORD [ebp+eax+searchqueueitem.nexthoploc]
	pop DWORD [ebp+eax+searchqueueitem.currentcargo]
*/
	pop edx
	jmp .buildloop
.buildloopend:

#if MODE
.outerloop:
	mov ecx, [searchqueuestart]
	or ecx, ecx
	jz NEAR .end
	xor eax, eax
	xor edx, edx
	mov ebx, searchqueuestart
	or edi, BYTE -1
.queueloop:
//ecx=current queue item
//edi=lowest cost so far
//eax=associated queue item
//edx=address of previous item pointer to associated queue item

	mov esi, [ebp+ecx+searchqueueitem.days]
	cmp esi, edi
	jae .iterate
	mov edi, esi
	mov edx, ebx
	mov eax, ecx
.iterate:
	lea ebx, [ebp+ecx+searchqueueitem.next]
	mov ecx, [ebx]
.nextitem:
	or ecx, ecx
	jnz .queueloop

	or eax, eax
	jz NEAR .end

	mov ebx, [ebp+eax+searchqueueitem.currentcargo]
	push ebx
	push DWORD [ebp+eax+searchqueueitem.nexthoploc]
	push DWORD [ebp+eax+searchqueueitem.nexthoprt]
	push edi
	push DWORD [ebp+eax+searchqueueitem.prevrt]
	mov esi, [ebp+eax+searchqueueitem.currentrt]
	push esi

	mov ecx, [ebp+eax+searchqueueitem.next]
	mov [edx], ecx

	call freecargodestdataobj

	//iterate over destination enties in start routing table in eax
	mov eax, [startroutingtable]
	lea ecx, [eax+routingtable.nexthoprtptr-routingtableentry.next]
	mov [tempprevroutingtableentrystore], ecx

	mov eax, [eax+ebp+routingtable.nexthoprtptr]
	mov edx, esi
	mov ecx, [esi+ebp+routingtable.location]
	mov esi, [esp+4+16-4]	//current next hop routing table
	call addroutesreachablefromthisnodeandrecurse_checkloop
	cmp ecx, 1
	je NEAR .doneandnext

	mov eax, [startroutingtable]
	lea ecx, [eax+routingtable.destrtptr-routingtableentry.next]
	mov [tempprevroutingtableentrystore], ecx

	mov eax, [eax+ebp+routingtable.destrtptr]
	mov ecx, [edx+ebp+routingtable.location]
	mov edx, ecx
	mov esi, [esp+16-4]	//current next hop routing table
	call addroutesreachablefromthisnodeandrecurse_checkloop
	cmp ecx, 1
	je NEAR .doneandnext

	//edi=current cost in days
	//bl=cargo
	//edx=final destination location

//yet another check, make sure that no cyclic routes between two nodes are created, as those are BAD�
	mov eax, [esp+16-4]
	mov eax, [ebp+eax+routingtable.destrtptr]
	or eax, eax
	jz .donecycliccheck
	push edi
	lea ecx, [esi+routingtable.destrtptr-routingtableentry.next]
	mov esi, edx
	mov edi, [startroutingtable]
.cycloop:
	//eax=far route of next hop node being tested
	//bl=cargo
	//[esp]=current cost in days
	//esi=final destination
	//ecx=previous far route or fudged
	//edi=start routing table

	cmp [ebp+eax+routingtableentry.dest], esi
	jne .cycnextroute
	cmp [ebp+eax+routingtableentry.cargo], bl
	jne .cycnextroute
	cmp [ebp+eax+routingtableentry.destrttable], edi
	jne .cycnextroute

	//ALERT: cyclic route between two adjacent nodes detected. Battle stations!
	pop edi
	inc DWORD [cdstatlastmonthcyclicroutecull]
	cmp [ebp+eax+routingtableentry.mindays], edi
	jbe NEAR .doneandnext		//the node we were going through has a route through this station which is shorter
					//than the route we would have created, therefore abandon creating the new route

	//the route on the other station is longer, hence it must be exterminated and the new route indeed created from this station

	mov esi, [ebp+eax+routingtableentry.next]
	mov [ebp+ecx+routingtableentry.next], esi
	call freecargodestdataobj
	jmp .donecycliccheck

.cycnextroute:
	mov ecx, eax
	mov eax, [ebp+eax+routingtableentry.next]
	or eax, eax
	jnz .cycloop
	pop edi
.donecycliccheck:
//ends



	mov esi, [esp-4+4]
	//esi=routing table of final destination

	call alloccargodestdataobj
	mov [eax+ebp+routingtableentry.cargo], bl

	mov ebx, [esi+ebp+routingtable.location]
	mov [eax+ebp+routingtableentry.dest], ebx

	mov ecx, [startroutingtable]
	mov ebx, eax
	xchg [ecx+ebp+routingtable.destrtptr], ebx
	mov [eax+ebp+routingtableentry.next], ebx

	mov ecx, [esp-4+16]
	mov [eax+ebp+routingtableentry.destrttable], ecx

	mov ecx, [esp-4+20]
	mov [eax+ebp+routingtableentry.nexthop], ecx

	mov [eax+ebp+routingtableentry.mindays], di

	mov cx, [currentdate]
	mov [eax+ebp+routingtableentry.lastupdated], cx

#if WINTTDX && DEBUG
	test BYTE [cargodestdebugflag], 8
	jz .nodbgmess
	pushad
	push eax
	mov edi, textrefstack
	mov esi, [cdestcurstationptr]      //station ptr
	call stos_stationname
	mov DWORD [specialtext1], farroutemsg
	call outdebugcargomessage
	mov edi, textrefstack
	pop ebx
	call stos_routedata
	mov DWORD [specialtext1], routedumpmess
	call outdebugcargomessage
	popad
.nodbgmess:
#endif

	call queuenextnodes
.doneandnext:
	add esp, 24

	jmp .outerloop
#endif
.end:

	popad
	ret

uvard startroutingtable
uvard cdestcurstationptr

uvard tempprevroutingtableentrystore

#if MODE

//[startroutingtable]=start routing table
//[cdestcurstationptr]=current start station ptr
//[esp+24]=current cargo
//[esp+20]=next hop from start, location
//[esp+16]=next hop from start, routing table
//[esp+12]=cost (in days) so far
//[esp+8]=previous node routing table
//[esp+4]=this node routing table
//ebp=[cargodestdata]
//trashable: eax, ebx, ecx, edx, edi, esi
//c calling convention
queuenextnodes:
	mov edx, [esp+4]
	mov edx, [edx+ebp+routingtable.nexthoprtptr]
	or edx, edx
	jz NEAR .finish
	mov ebx, [esp+24]
.loop:
	mov esi, [edx+ebp+routingtableentry.destrttable]
	or esi, esi
	jz NEAR .next
	cmp esi, [startroutingtable]
	je NEAR .next
	cmp [edx+ebp+routingtableentry.cargo], bl
	jne NEAR .next
	cmp esi, [esp+16]
	je NEAR .next
	cmp esi, [esp+8]
	je NEAR .next

	//esi=routing table of final destination
	//edx=routing table entry to final destination from last node
	//bl=cargo

	xor edi, edi
	movzx edi, WORD [edx+ebp+routingtableentry.dayswaiting]
	imul edi, [cargodestwaitmult]
	shr edi, 8
	add di, [edx+ebp+routingtableentry.mindays]
	jc NEAR .next			//route is way too long
	add di, [esp+12]
	jc NEAR .next			//route is way too long

	call alloccargodestdataobj

	//prepend to queue.
	//appending would almost certainly be better, examine later
	mov ecx, [searchqueuestart]
	mov [ebp+eax+searchqueueitem.next], ecx
	mov [searchqueuestart], eax

	mov [ebp+eax+searchqueueitem.currentcargo], ebx
	mov ecx, [esp+20]
	mov [ebp+eax+searchqueueitem.nexthoploc], ecx
	mov ecx, [esp+16]
	mov [ebp+eax+searchqueueitem.nexthoprt], ecx
	mov [ebp+eax+searchqueueitem.days], edi
	mov ecx, [esp+4]
	mov [ebp+eax+searchqueueitem.prevrt], ecx
	mov [ebp+eax+searchqueueitem.currentrt], esi


.doneandnext:
	mov eax, [startroutingtable]
	mov bl, [esp+24]
.next:
	mov edx, [edx+ebp+routingtableentry.next]
	or edx, edx
	jnz .loop
.finish:
	ret

#else

//[startroutingtable]=start routing table
//[cdestcurstationptr]=current start station ptr
//[esp+24]=current cargo
//[esp+20]=next hop from start, location
//[esp+16]=next hop from start, routing table
//[esp+12]=cost (in days) so far
//[esp+8]=previous node routing table
//[esp+4]=this node routing table
//ebp=[cargodestdata]
//trashable: eax, ebx, ecx, edx, edi, esi
//c calling convention
addroutesreachablefromthisnodeandrecurse:
	mov edx, [esp+4]
	mov edx, [edx+ebp+routingtable.nexthoprtptr]
	or edx, edx
	jz NEAR .finish
	mov ebx, [esp+24]
	mov eax, [startroutingtable]
.loop:
	mov esi, [edx+ebp+routingtableentry.destrttable]
	or esi, esi
	jz NEAR .next
	cmp esi, eax
	je NEAR .next
	cmp [edx+ebp+routingtableentry.cargo], bl
	jne NEAR .next
	cmp esi, [esp+16]
	je NEAR .next

	//eax=start routing table
	//esi=routing table of final destination
	//edx=routing table entry to final destination from last node
	//bl=cargo

	movzx edi, WORD [edx+ebp+routingtableentry.dayswaiting]
	imul edi, [cargodestwaitmult]
	shr edi, 8	
	add di, [edx+ebp+routingtableentry.mindays]
	jc NEAR .next			//route is way too long
	add di, [esp+12]
	jc NEAR .next			//route is way too long

	//iterate over destination enties in start routing table in eax
	lea ecx, [eax+routingtable.nexthoprtptr-routingtableentry.next]
	mov [tempprevroutingtableentrystore], ecx

	mov eax, [eax+ebp+routingtable.nexthoprtptr]
	push esi
	mov ecx, [esi+ebp+routingtable.location]
	mov esi, [esp+4+16]
	call addroutesreachablefromthisnodeandrecurse_checkloop
	pop esi
	cmp ecx, 1
	je NEAR .doneandnext
	jna .noint3_
	int3  			//distant route tried to update a near route, fail
.noint3_:

	mov eax, [startroutingtable]
	lea ecx, [eax+routingtable.destrtptr-routingtableentry.next]
	mov [tempprevroutingtableentrystore], ecx

	mov eax, [eax+ebp+routingtable.destrtptr]
	mov ecx, [esi+ebp+routingtable.location]
	mov esi, [esp+16]
	call addroutesreachablefromthisnodeandrecurse_checkloop
	cmp ecx, 1
	je NEAR .doneandnext
	ja NEAR .updateandstartrecursion

	//edi=current cost in days
	//bl=cargo
	//edx=routing table entry to final destination from last node


//yet another check, make sure that no cyclic routes between two nodes are created, as those are BAD�
	mov eax, [esp+16]
	mov eax, [ebp+eax+routingtable.destrtptr]
	or eax, eax
	jz .donecycliccheck
	push edi
	lea ecx, [esi+routingtable.destrtptr-routingtableentry.next]
	mov esi, [edx+ebp+routingtableentry.dest]
	mov edi, [startroutingtable]
.cycloop:
	//eax=far route of next hop node being tested
	//bl=cargo
	//[esp]=current cost in days
	//edx=routing table entry to final destination from last node
	//esi=final destination
	//ecx=previous far route or fudged
	//edi=start routing table

	cmp [ebp+eax+routingtableentry.dest], esi
	jne .cycnextroute
	cmp [ebp+eax+routingtableentry.cargo], bl
	jne .cycnextroute
	cmp [ebp+eax+routingtableentry.destrttable], edi
	jne .cycnextroute

	//ALERT: cyclic route between two adjacent nodes detected. Battle stations!
	pop edi
	inc DWORD [cdstatlastmonthcyclicroutecull]
	cmp [ebp+eax+routingtableentry.mindays], edi
	jbe NEAR .doneandnext		//the node we were going through has a route through this station which is shorter
					//than the route we would have created, therefore abandon creating the new route

	//the route on the other station is longer, hence it must be exterminated and the new route indeed created from this station

	mov esi, [ebp+eax+routingtableentry.next]
	mov [ebp+ecx+routingtableentry.next], esi
	call freecargodestdataobj
	jmp .donecycliccheck

.cycnextroute:
	mov ecx, eax
	mov eax, [ebp+eax+routingtableentry.next]
	or eax, eax
	jnz .cycloop
	pop edi
.donecycliccheck:
//ends


	mov esi, [edx+ebp+routingtableentry.destrttable]
	//esi=routing table of final destination

	call alloccargodestdataobj
	mov [eax+ebp+routingtableentry.cargo], bl

	mov ebx, [esi+ebp+routingtable.location]
	mov [eax+ebp+routingtableentry.dest], ebx

	mov ecx, [startroutingtable]
	mov ebx, eax
	xchg [ecx+ebp+routingtable.destrtptr], ebx
	mov [eax+ebp+routingtableentry.next], ebx

	mov ecx, [esp+16]
	mov [eax+ebp+routingtableentry.destrttable], ecx

	mov ecx, [esp+20]
	mov [eax+ebp+routingtableentry.nexthop], ecx

.updateandstartrecursion:
	mov [eax+ebp+routingtableentry.mindays], di

	mov cx, [currentdate]
	mov [eax+ebp+routingtableentry.lastupdated], cx

#if WINTTDX && DEBUG
	test BYTE [cargodestdebugflag], 8
	jz .nodbgmess
	pushad
	push eax
	mov edi, textrefstack
	mov esi, [cdestcurstationptr]      //station ptr
	call stos_stationname
	mov DWORD [specialtext1], farroutemsg
	call outdebugcargomessage
	mov edi, textrefstack
	pop ebx
	call stos_routedata
	mov DWORD [specialtext1], routedumpmess
	call outdebugcargomessage
	popad
.nodbgmess:
#endif

	//eax=routing table entry to final destination from start
	//esi=routing table of final destination
	//edx=routing table entry to final destination from last node
	//edi=current cost in days

	push edx

	push DWORD [esp+4+24]
	push DWORD [esp+8+20]
	push DWORD [esp+12+16]
	push edi
	push DWORD [esp+16+4+4]
	push esi
	call addroutesreachablefromthisnodeandrecurse
	add esp, 24

	pop edx

.doneandnext:
	mov eax, [startroutingtable]
	mov bl, [esp+24]
.next:
	mov edx, [edx+ebp+routingtableentry.next]
	or edx, edx
	jnz .loop
.finish:
	ret

#endif

	//eax = first routing table entry or 0 of source station
	//ecx = current target destination location
	//esi= current next hop routing table
	//di = current cost in days
	//bl = cargo
	//trashes: eax, esi
	//returns: ecx:
		//0=continue and perhaps add new route
		//1=abandon
		//2=update route, eax and esi must be sensibly set
addroutesreachablefromthisnodeandrecurse_checkloop:
	push ecx
	push esi
	or eax, eax
	jz NEAR .donecheck
.checkloop:
	cmp [eax+ebp+routingtableentry.cargo], bl
	jne NEAR .nextcheck
	cmp [eax+ebp+routingtableentry.dest], ecx
	jne NEAR .nextcheck
	cmp [eax+ebp+routingtableentry.destrttable], esi
	jne .differentnodecheck
	//we're going over ourselves!
	//if the new route to this destination through the initial next node is shorter, carry on recursing, else stop here
	cmp [eax+ebp+routingtableentry.mindays], di
	jbe NEAR .doneandnext
	//update and recurse from here
	push eax
	call addroutesreachablefromthisnodeandrecurse_checkloop.nextcheck
	pop eax
	add esp, 8	//pop esi,ecx
	mov esi, [edx+ebp+routingtableentry.destrttable]
	mov ecx, 2
#if MODE
	int3
#endif
	ret
	//jmp .updateandstartrecursion
.differentnodecheck:
	//For comparing against next hop routes, include the initial waiting time...
	movzx esi, WORD [eax+ebp+routingtableentry.dayswaiting]
	imul esi, [cargodestwaitmult]
	shr esi, 8
	add si, [eax+ebp+routingtableentry.mindays]

	//esi is now the cost of the route through a different first node (other)
	cmp edi, esi
	je .done_differentnodecheck	//routes are identical (unlikely but whatever...)
	jb .newroutebetter		//this route is better, maybe delete other
	//other route is better (esi is smaller), maybe abandon this one

	movzx ecx, WORD [cargodestroutediffmax]
	add ecx, esi
//	jc .diffcont1			//route threshold is *enormous*	(user is an imbecile), do next test
					//this level of fail is currently impossible so don't test for it
	cmp edi, ecx
	ja NEAR .doneandnext		//new route too long
.diffcont1:

	imul esi, [cargodestroutecmpfactor]
	db 0x2E				//branch not taken
	jo .done_differentnodecheck	//route threshold is *enormous* (user is a plonker), this route is fine.
	shr esi, 16
	cmp edi, esi
	ja NEAR .doneandnext		//new route too long
	jmp .done_differentnodecheck
.newroutebetter:
	//this route is better (edi is smaller), maybe zap other one

	movzx ecx, WORD [cargodestroutediffmax]
	add ecx, edi
//	jc .diffcont2			//route threshold is *enormous*	(user is an imbecile), do next test
					//this level of fail is currently impossible so don't test for it
	cmp esi, ecx
	ja NEAR .exterminateoldroute	//old route too long
.diffcont2:

	push edi
	imul edi, [cargodestroutecmpfactor]
	db 0x3E		//branch taken
	jno .nobadlen	//players who fail this jump ought to be hit by a huge branch misprediction penalty :P (and have god awful routing)
	//route threshold is *enormous*, other route is fine
	pop edi
	jmp .done_differentnodecheck
.nobadlen:
	shr edi, 16
	cmp esi, edi
	pop edi
	jbe .done_differentnodecheck	//old route OK
.exterminateoldroute:
	//old route (eax length esi) is no good, exterminate it
	mov esi, [eax+ebp+routingtableentry.next]

	call freecargodestdataobj

	mov ecx, [tempprevroutingtableentrystore]	//this always works, is fudged if first attached
	mov [ecx+ebp+routingtableentry.next], esi
	mov eax, esi

	//cloned from below, keep in sync
	mov ecx, [esp+4]
	mov esi, [esp]

	jmp .iteratecheck

.done_differentnodecheck:
	//see above
	mov ecx, [esp+4]
	mov esi, [esp]
.nextcheck:
        mov [tempprevroutingtableentrystore], eax
	mov eax, [eax+ebp+routingtableentry.next]
.iteratecheck:
	or eax, eax
	jnz .checkloop
.donecheck:
	xor ecx, ecx
	add esp, 8
	ret
.doneandnext:
	mov ecx, 1
	add esp, 8
	ret


//esi=station
//edi=station2
//cl=loop counter (250-station id)
global cargodestinitstationroutingtable
cargodestinitstationroutingtable:
	pushad
//	xor edx, edx
//	mov eax, esi
//	sub eax, stationarray
//	mov ecx, station_size
//	div ecx
//	mov ebx, eax			//station ID
	mov ebx, 250 | 0x10000
	sub bl, cl
	mov ebp, [cargodestdata]
	call alloccargodestdataobj
//	or ebx, 0x10000
	mov [eax+ebp+routingtable.location], ebx
	mov [edi+station2.cargoroutingtableptr], eax
	popad
	ret

global cargodestinitstationroutingtable_all
cargodestinitstationroutingtable_all:
	pushad
	mov esi,stationarray
	mov edi,[stationarray2ptr]
	mov ecx, numstations
.loop:
	cmp WORD [esi+station.XY], 0
	je .skip
	call cargodestinitstationroutingtable
.skip:
	add esi,station_size
	add edi,station2_size
	loop .loop
	popad
	ret

//esi=station ptr
//dl=station id
//ebx=cargo type
//ax=amount
//trashable: none
//returns: ax=amount

//some inspiration stolen from: http://hg.openttd.org/developers/celestar/cargodest.hg/file/5cef98ae76ac/src/routing.cpp#l595

uvard cdestgencurscoretotal

global addcargotostation_cargodesthook
addcargotostation_cargodesthook:
	or ax, ax
	jz NEAR .finalret
	pushad
	sub esp, 0x100*4
		//low word=min days
		//score=init score + dest st last month activity - manhatten distance * factor1 - min days * factor2
		//negative scores excluded
	mov ebp, eax
	xor eax, eax
	mov [cdestgencurscoretotal], eax	//total score: if this overflows, the user is obviously doing something wrong
	mov ecx, 0x100
	cld
	mov edi, esp
	rep stosd
	movzx eax, bp
	mov ebp, [cargodestdata]
	mov cl, [cargodestgenflags+ebx]	//0: all cargo is by preferance routed
	cmp cl, 2			//1: all cargo is routed (or dropped at source)
	je NEAR .popret			//2: all cargo is unrouted (old behaviour)
	cmp cl, 3			//3: mix of routed and unrouted cargo generated.
	jne .nounroute
	mov edi, [cdstunroutedscoreval]
	mov DWORD [esp+0xFF*4], edi
	add [cdestgencurscoretotal], edi
.nounroute:
	mov edi, [station2ofs_ptr]
	mov edi, [edi+esi+station2.cargoroutingtableptr]
	or edi, edi
	jz NEAR .popret

//gather data on available detsinations and their minumum costs
	push esi
	lea esi, [esp+4]
	mov ecx, [ebp+edi+routingtable.nexthoprtptr]
	or ecx, ecx
	jz .nonexthop
.nexthop:
	call dorouteassimilation
	mov ecx, [ebp+ecx+routingtableentry.next]
	or ecx, ecx
	jnz .nexthop
.nonexthop:
	mov ecx, [ebp+edi+routingtable.destrtptr]
	or ecx, ecx
	jz .nodest
.dest:
	call dorouteassimilation
	mov ecx, [ebp+ecx+routingtableentry.next]
	or ecx, ecx
	jnz .dest
.nodest:
	pop esi
//------

//calculate scores and total
	xor ecx, ecx
	mov ebp, stationarray
.calcloop:
	movzx edi, WORD [esp+ecx*4]
	or edi, edi
	jz NEAR .calcnext

	testflags newcargos
	jc .newcargos_testaccept
	mov eax, ebx
	shl eax, 3
	test BYTE [ebp+station.cargos+eax+stationcargo.amount+1], 80h
	jnz .accept
	jmp .zeroscore
.newcargos_testaccept:
	bt dword [ebp+station2ofs+station2.acceptedcargos], ebx
	jnc .zeroscore
.accept:

	neg edi
	imul edi, DWORD [cdstnegdaysfactorval]
	call getstmanhattandistance
	imul eax, DWORD [cdstnegdistfactorval]
	sub edi, eax
	test BYTE [cargodestflags], 1
	jnz .noactivityadd
	add edi, [ebp+station2ofs+station2.activitylastmonth]
.noactivityadd:
	add edi, [cdstroutedinitscoreval]
	jns .scoreok
	//negative score, don't bother trying to route cargo there...
.zeroscore:
	xor edi, edi
.scoreok:
	mov [esp+ecx*4], edi
	add [cdestgencurscoretotal], edi
.calcnext:
	inc ecx
	add ebp, station_size
	cmp ecx, numstations
	jb .calcloop
//------

//try (in vain?) to make the random-seed more random...
	mov ecx, [randomseed1]
	//begin lame bit-shuffling
	mov ebp, 32
.bitfiddleloop:
	xor ecx, 0xAAAAAAAA
	ror ecx, cl
	add ecx, 0x55555555
	dec ebp
	jnz .bitfiddleloop

	mov ebp, edx	//source station id

	//to get a random number between 0 and [cdestgencurscore]
	//	seed*[cdestgencurscore] >> 32
	mov eax, [cdestgencurscoretotal]
	or eax, eax
	jz NEAR .noroutedestfounderr
	mul ecx
	//result is in edx

	xor ecx, ecx
.getloop:
	sub edx, [esp+ecx*4]
	js .founddest
	inc cl
	jnz .getloop
	//boo, something went wrong
	jmp .noroutedestfounderr
.founddest:
	cmp cl, 0xFF
	je NEAR .popret	//type 3 unrouted cargo

	push ebp
	mov ebp, [cargodestdata]
	push ecx
	call alloccargodestdataobj
	pop ecx
	mov [eax+ebp+cargopacket.destst], cl
	pop ecx
	mov [eax+ebp+cargopacket.sourcest], cl
	mov cx, [esp+0x400+_pusha.eax]
	mov [eax+ebp+cargopacket.amount], cx
	mov [eax+ebp+cargopacket.cargo], bl
	mov cx, [currentdate]
	//mov [eax+ebp+cargopacket.dateleft], cx
	mov [eax+ebp+cargopacket.datearrcurloc], cx
	mov ecx, [station2ofs_ptr]
	mov edx, [esi+ecx+station2.cargoroutingtableptr]
	mov cl, [cdstcargopacketinitttl]
	mov [eax+ebp+cargopacket.ttl], cl
	mov ecx, [ebp+edx+routingtable.location]
	mov [eax+ebp+cargopacket.location], ecx
	mov BYTE [eax+ebp+cargopacket.lastboardedst], -1
	call linkcargopacket.quickstation

.popret:
	mov eax, [esp+0x400+_pusha.eax]
	mov edi, [station2ofs_ptr]
	add WORD [edi+esi+station2.activitythismonth], ax
	jnc .finalpopret
	mov WORD [edi+esi+station2.activitythismonth], -1	//saturate
.finalpopret:
	add esp, 0x100*4
	popad
.finalret:
	ret
.noroutedestfounderr:
	cmp BYTE [cargodestgenflags+ebx], 1
	jne .popret
	mov DWORD [esp+0x400+_pusha.eax], 0		//unrouted cargo is verbotten, drop cargo
	jmp .finalpopret

dorouteassimilation:
	push eax
	push ebx
	push edx
	cmp bl, [ebp+ecx+routingtableentry.cargo]
	jne .nostore
	movzx eax, BYTE [ebp+ecx+routingtableentry.dest]
	mov bx, [esi+eax*4]	//current minimum number of days
	mov dx, [ebp+ecx+routingtableentry.mindays]
	or bx, bx		//no minimum (existing value = 0)
	jz .store
	cmp bx, dx
	jbe .nostore
.store:
	mov [esi+eax*4], dx	//change stored minimum if new value is lower
.nostore:
	pop edx
	pop ebx
	pop eax
	ret

//ebp=dest station ptr, esi=source station ptr
//returns value in eax
getstmanhattandistance:
	movzx eax, WORD [ebp+station.XY]
	sub al, [esi+station.XY]
	jns .noneg1
	neg al
.noneg1:
	sub ah, [esi+station.XY+1]
	jns .noneg2
	neg ah
.noneg2:
	add al, ah
	movzx eax, al
	adc ah, 0
	ret


global cargodestdelvehentryhook
cargodestdelvehentryhook:       //esi=vehicle ptr being deleted
				//trashable: all
	movzx edi, WORD [esi+veh.idx]
	mov ebp, [cargodestdata]
	xor eax, eax
	mov [ebp+cargodestgamedata.vehrttimelist+edi*2], ax
	xchg eax, [ebp+cargodestgamedata.vehcplist+edi*4]
	or eax, eax
	jz .ret
.loop:
#if WINTTDX && DEBUG
	test BYTE [cargodestdebugflag+1], 8
	jz .nokillpacketmess
	pushad
	push eax
	mov DWORD [specialtext1], vehkillcpmess
	call outdebugcargomessage
	mov edi, textrefstack
	pop ebx
	call stos_packetdata
	mov DWORD [specialtext1], packetdumpmess
	call outdebugcargomessage
	popad
.nokillpacketmess:
#endif
	push DWORD [ebp+eax+cargopacket.nextptr]
	call freecargodestdataobj
	pop eax
	or eax, eax
	jnz .loop
.ret:
	ret

	//edi=vehicle
	//esi=station
	//al=station id
	//cx=amount of cargo in vehicle
	//trashable: ebp
	//return amount of unroutable cargo in vehicle in cx
global cargodestdelstationpervehhook
cargodestdelstationpervehhook:
	push edx
	mov ebp, [cargodestdata]
	movzx edx, WORD [edi+veh.idx]
	inc al
	cmp BYTE [edi+veh.prevstid], al
	jne .prevstidok
	mov BYTE [edi+veh.prevstid], 0
	mov WORD [ebp+cargodestgamedata.vehrttimelist+edx*2], 0
.prevstidok:
	dec al
	mov edx, [ebp+cargodestgamedata.vehcplist+edx*4]
	or edx, edx
	jz .end
.loop:
	test BYTE [edx+ebp+cargopacket.flags], 2	//not a cargo packet
	jnz .iterate
	sub cx, [ebp+edx+cargopacket.amount]
	cmp [ebp+edx+cargopacket.destst], al
	je .kill
	cmp [ebp+edx+cargopacket.sourcest], al
	je .kill
.iterate:
	mov edx, [ebp+edx+cargopacket.nextptr]
.next:
	or edx, edx
	jnz .loop
.end:
	pop edx
	ret
.kill:
	push DWORD [ebp+edx+cargopacket.nextptr]
	push eax
	push ecx
	mov eax, edx
	mov dx, [eax+ebp+cargopacket.amount]
	sub word [edi+veh.currentload],dx
#if WINTTDX && DEBUG
	call statdeathdelcpobj
#endif
	call unlinkcargopacket
	call freecargodestdataobj
	pop ecx
	pop eax
	pop edx
	jmp .next

	//edi=station to check
	//esi=station being deleted
	//      NB: the above two cannot be the same
	//al=station id being deleted
	//ebp=cargo offset
	//ah=cargo
	//ecx=0
	//trashable: none
	//return amount of routed cargo in station of that cargo in cx
global cargodestdelstationperstationhook
cargodestdelstationperstationhook:
	push ebx
	push edx
	mov ebx, [cargodestdata]
	mov edx, edi
	add edx, [station2ofs_ptr]
	mov edx, [edx+station2.cargoroutingtableptr]
	or edx, edx
	jz .end
	mov edx, [edx+ebx+routingtable.cargopacketsfront]
	or edx, edx
	jz .end
.loop:
	test BYTE [ebx+edx+cargopacket.flags], 2	//not a cargo packet
	jnz .adv
	cmp [ebx+edx+cargopacket.cargo], ah
	jne .adv
	cmp [ebx+edx+cargopacket.destst], al
	je .kill
	cmp [ebx+edx+cargopacket.sourcest], al
	je .kill
	add cx, [ebx+edx+cargopacket.amount]
.adv:
	mov edx, [ebx+edx+cargopacket.nextptr]
.next:
	or edx, edx
	jnz .loop
.end:
	pop edx
	pop ebx
	ret
.kill:
	push DWORD [ebx+edx+cargopacket.nextptr]
	push eax
	push ecx
	mov eax, edx
	mov dx, [eax+ebx+cargopacket.amount]
	sub [edi+station.cargos+ebp+stationcargo.amount],dx
	xchg ebx, ebp
#if WINTTDX && DEBUG
	call statdeathdelcpobj
#endif
	call unlinkcargopacket
	call freecargodestdataobj
	xchg ebx, ebp
	pop ecx
	pop eax
	pop edx
	jmp .next

	//edi=station to check
	//esi=station being deleted
	//      NB: the above two cannot be the same
	//al=station id being deleted
	//trashable: ebp, ecx
global cargodestdelstationperstationhook2
cargodestdelstationperstationhook2:
	pushad
	movzx ebx, al
	or ebx, 0x10000
	mov ebp, [cargodestdata]
	mov esi, edi
	mov edi, [edi+station2ofs+station2.cargoroutingtableptr]
	or edi, edi
	jz .done
	lea eax, [edi+routingtable.nexthoprtptr-routingtableentry.next]
	call .docheckgenfunc
	lea eax, [edi+routingtable.destrtptr-routingtableentry.next]
	call .docheckgenfunc
.done:
	popad
ret
.docheckgenfunc:
	mov edx, eax
	mov eax, [eax+ebp+routingtableentry.next]
.next:
	or eax, eax
	jz .ret
	cmp [eax+ebp+routingtableentry.dest], ebx
	je .kill
        cmp [eax+ebp+routingtableentry.nexthop], ebx
        jne .docheckgenfunc
.kill:
	push DWORD [eax+ebp+routingtableentry.next]
	call statdeathdelrteobj
	pop eax
	mov [edx+ebp+routingtableentry.next], eax
	jmp .next

.ret:
	ret

	//esi=station
	//al=station id
global cargodestdelstationfinalhook
cargodestdelstationfinalhook:
	pushad
	lea edi, [esi+station2ofs]
	mov ebp, [cargodestdata]

	xor edx, edx
	xchg edx, [edi+station2.cargoroutingtableptr]
	or edx, edx
	jz NEAR .noroutingtable

	mov eax, [edx+ebp+routingtable.cargopacketsfront]
	or eax, eax
	jz .nopackets
.packetloop:
	push DWORD [eax+ebp+cargopacket.nextptr]
#if WINTTDX && DEBUG
	call statdeathdelcpobj
#endif
	call freecargodestdataobj
	pop eax
	or eax, eax
	jnz .packetloop
.nopackets:
	mov [edx+ebp+routingtable.cargopacketsfront], eax
	mov [edx+ebp+routingtable.cargopacketsrear], eax

	mov eax, [edx+ebp+routingtable.nexthoprtptr]
	or eax, eax
	jz .nonexthop
.nexthoploop:
	push DWORD [eax+ebp+routingtableentry.next]
	call statdeathdelrteobj
	pop eax
	or eax, eax
	jnz .nexthoploop
.nonexthop:
	mov [edx+ebp+routingtable.nexthoprtptr], eax

	mov eax, [edx+ebp+routingtable.destrtptr]
	or eax, eax
	jz .nofar
.farloop:
	push DWORD [eax+ebp+routingtableentry.next]
	call statdeathdelrteobj
	pop eax
	or eax, eax
	jnz .farloop
.nofar:
	mov [edx+ebp+routingtable.destrtptr], eax

	mov eax, edx
	call freecargodestdataobj

.noroutingtable:

	popad
	ret

//esi=vehicle, bx=date adjustment
global cargodesteternalgamevehage
cargodesteternalgamevehage:
	pushad
	mov ebp, [cargodestdata]
	or ebp, ebp
	jz .end
	movzx edx, WORD [esi+veh.idx]
	mov ax, [ebp+cargodestgamedata.vehrttimelist+edx*2]
	or ax, ax
	jz .nodate
	sub ax, bx
	mov [ebp+cargodestgamedata.vehrttimelist+edx*2], ax
.nodate:
	mov edx, [ebp+cargodestgamedata.vehcplist+edx*4]
	call agepacketlisting
.end:
	popad
	ret

//esi=station
//edi=station2
//bx=age adjustment
global cargodesteternalgamestatage
cargodesteternalgamestatage:
	pushad
	mov ebp, [cargodestdata]
	or ebp, ebp
	jz .end
	mov ecx, [edi+station2.cargoroutingtableptr]
	or ecx, ecx
	jz .end
	mov edx, [ebp+ecx+routingtable.cargopacketsfront]
	call agepacketlisting
	mov edx, [ebp+ecx+routingtable.nexthoprtptr]
	call ageroutingentrylisting
	mov edx, [ebp+ecx+routingtable.destrtptr]
	call ageroutingentrylisting
.end:
	popad
	ret

//edx=first packet or zero, ebp=[cargodestdata], bx=date adjustment
agepacketlisting:
	or edx, edx
	jz .end
.loop:
	test BYTE [edx+ebp+cargopacket.flags], 2	//not a cargo packet
	jnz .iterate

	mov ax, [edx+ebp+cargopacket.dateleft]
	or ax, ax
	jz .noleft
	sub ax, bx
	mov [edx+ebp+cargopacket.dateleft], ax
.noleft:
	mov ax, [edx+ebp+cargopacket.datearrcurloc]
	or ax, ax
	jz .iterate
	sub ax, bx
	mov [edx+ebp+cargopacket.datearrcurloc], ax

.iterate:
	mov edx, [ebp+edx+cargopacket.nextptr]
.next:
	or edx, edx
	jnz .loop
.end:
	ret

//edx=first routing table entry or zero, ebp=[cargodestdata], bx=date adjustment
ageroutingentrylisting:
	or edx, edx
	jz .end
.loop:

	mov ax, [edx+ebp+routingtableentry.lastupdated]
	or ax, ax
	jz .nolu
	sub ax, bx
	mov [edx+ebp+routingtableentry.lastupdated], ax
.nolu:
//	mov ax, [edx+ebp+routingtableentry.oldestwaiting]
//	or ax, ax
//	jz .iterate
//	sub ax, bx
//	mov [edx+ebp+routingtableentry.oldestwaiting], ax

.iterate:
	mov edx, [ebp+edx+routingtableentry.next]
.next:
	or edx, edx
	jnz .loop
.end:
	ret

#if WINTTDX && DEBUG
statdeathdelcpobj:
	test BYTE [cargodestdebugflag+1], 8
	jz .nokillpacketmess
	pushad
	push eax
	mov DWORD [specialtext1], stkillcpmess
	call outdebugcargomessage
	mov edi, textrefstack
	pop ebx
	call stos_packetdata
	mov DWORD [specialtext1], packetdumpmess
	call outdebugcargomessage
	popad
.nokillpacketmess:
	ret
#endif


statdeathdelrteobj:
#if WINTTDX && DEBUG
	test BYTE [cargodestdebugflag+1], 8
	jz .nokillroutemess
	pushad
	push eax
	mov DWORD [specialtext1], routekillmess
	mov edi, textrefstack
	call stos_stationname
	call outdebugcargomessage
	mov edi, textrefstack
	pop ebx
	call stos_routedata
	mov DWORD [specialtext1], routedumpmess
	call outdebugcargomessage
	popad
.nokillroutemess:
#endif
        jmp freecargodestdataobj

global stos_locationname	//esi=location, edi=textrefstack cur ptr (adds up to 4 bytes)
stos_locationname:      	//trashes eax
	push esi
	ror esi, 16
	dec si
	jz .st
	dec si
	jz .veh
.err:
#if WINTTDX && DEBUG
	cmp DWORD [esp], 0
	je .blank
	mov ax, statictext(printhexdword)
	stosw
	mov eax, [esp]
	stosd
	pop esi
	ret
#endif
.blank:
	mov ax, statictext(empty)
	stosw
	pop esi
	ret
.st:
	shr esi, 16
	cmp esi, 250
	jae .err
        //imul esi, esi, 0x8E
	//add esi, stationarray
	//jmp stos_stationname
	mov ax, statictext(outstation)
	stosw
	mov eax, esi
	stosw
	pop esi
	ret
.veh:
	shr esi, 16-vehicleshift
	and esi, 0xFFFF<<vehicleshift
	add esi, [veharrayptr]
stos_vehname:
	movzx eax, WORD [esi+veh.engineidx]
	cmp ax, -1
	je .noengine
	mov esi, eax
	shl esi, 7
	add esi, [veharrayptr]
.noengine:
	mov ax, [esi+veh.name]
	stosw
	movzx ax, BYTE [esi+veh.consistnum]
	stosw
	pop esi
	ret

uvard cargodestdebugflag
#if WINTTDX && DEBUG
uvard cdestdbgloghndl
//uvard outputdebugstring
//uvarb cdestodstempstring, 0x400
outdebugcargomessage:
	pushad
	mov ebp, esp
	and esp, ~3	//createfile seems to choke on unaligned stacks

	push ebp
	sub esp, 0x1000
	mov edi, esp	//cdestodstempstring
	mov ax, statictext(special1)
	call newtexthandler
/*
	mov eax, [outputdebugstring]
	or eax, eax
	jnz .gotods
	push DWORD kernel32dll
	//push DWORD ntdll
	call [GetModuleHandleA]
	push DWORD outputdebugstring_name
	//push DWORD dbgprint_name
	push eax
	call [GetProcAddress]
	or eax, eax
	jz .end
	mov [outputdebugstring], eax
.gotods:
	push cdestodstempstring
	call eax
	//push cdestodstempstring
	//push percents
	//call eax
	//add esp, 8
*/
	mov eax, [cdestdbgloghndl]
	cmp eax, BYTE -1
	je .badhndl
	or eax, eax
	jnz NEAR .gothndl
.badhndl:
	push edi

        push DWORD GetSystemTimeAsFileTime_name
	push DWORD [kernel32hnd]
        call [GetProcAddress]

        or ecx, BYTE -1
	mov DWORD [textrefstack], ecx
	mov DWORD [textrefstack+4], ecx

        or eax, eax
        jz .nogettime

        push DWORD textrefstack
	call eax

.nogettime:

	sub esp, 128
	mov DWORD [specialtext1], cdestlogfile
	mov edi, esp
	mov ax, statictext(special1)
	call newtexthandler
	mov edi, esp

	push DWORD 0		// hTemplateFile
	push DWORD 128		// dwFlagsandAttributes = FILE_ATTRIBUTE_NORMAL
	//push DWORD 4		// dwCreationDisposition = OPEN_ALWAYS
	push DWORD 1		// dwCreationDisposition = CREATE_NEW
	push DWORD 0		// lpSecurityAttributes
	push DWORD 1		// dwShareMode = FILE_SHARE_READ
	push DWORD 0x40000000	// dwDesiredAccess = GENERIC_WRITE
	push edi		// lpFilename
	call [CreateFile]

	add esp, 128

	mov [cdestdbgloghndl], eax
	push DWORD 0
	push DWORD bytesread
	push DWORD 19
	push DWORD openlog
	push eax
        call DWORD [WriteFile]
        mov eax, [cdestdbgloghndl]
        pop edi
.gothndl:
	sub edi, esp
	mov ecx, esp
	push DWORD 0
	push DWORD bytesread
	push edi
	push ecx
	push eax
        call DWORD [WriteFile]
.end:
	add esp, 0x1000
	pop ebp
	mov esp, ebp
	popad
	ret

			//esi=station, edi=textrefstack cur ptr (adds up to 8 bytes)
stos_stationname:       //trashes eax, ecx
	cmp WORD [esi+station.XY], 0
	je .badstation
	mov ax, [esi+station.name]
	or ax, ax
	jz .badstation
	mov ecx, [esi+station.townptr]
	or ecx, ecx
	jz .badstation
	stosw
	mov ax, [ecx+town.citynametype]
	stosw
	mov eax, [ecx+town.citynameparts]
	stosd
	ret
.badstation:
	mov ax, statictext(empty)
	stosw
	ret

	                //ebx=routing table entry relptr
	                //ebp=[cargodestdata]
	                //edi=textrefstack cur ptr (adds up to 22 bytes)
	                //trashes eax, esi
stos_routedata:
	mov eax, ebx
	stosd
	mov esi, [ebx+ebp+routingtableentry.dest]
	call stos_locationname
	mov esi, [ebx+ebp+routingtableentry.nexthop]
	call stos_locationname
	movzx esi, BYTE [ebx+ebp+routingtableentry.cargo]
	mov ax, [newcargotypenames+esi*2]
	stosw
	movzx ax, BYTE [ebx+ebp+routingtableentry.flags]
	stosw
	mov ax, [ebx+ebp+routingtableentry.mindays]
	stosw
	mov ax, [ebx+ebp+routingtableentry.lastupdated]
	stosw
	mov ax, [ebx+ebp+routingtableentry.dayswaiting]
	stosw
	ret

	                //ebx=cargo packet relptr
	                //ebp=[cargodestdata]
	                //edi=textrefstack cur ptr (adds up to 30 bytes)
	                //trashes eax, esi
stos_packetdata:
	mov eax, ebx
	stosd
	mov esi, [ebx+ebp+cargopacket.location]
	call stos_locationname
	movzx ax, BYTE [ebx+ebp+cargopacket.destst]
	stosw
	movzx ax, BYTE [ebx+ebp+cargopacket.sourcest]
	stosw
	mov ax, [ebx+ebp+cargopacket.amount]
	stosw
	movzx eax, BYTE [ebx+ebp+cargopacket.cargo]
	mov ax, [newcargotypenames+eax*2]
	stosw
	mov ax, [ebx+ebp+cargopacket.flags]
	stosw
	movzx ax, BYTE [ebx+ebp+cargopacket.ttl]
	stosw
	movzx ax, BYTE [ebx+ebp+cargopacket.lastboardedst]
	stosw
	mov ax, [ebx+ebp+cargopacket.dateleft]
	stosw
	mov ax, [ebx+ebp+cargopacket.datearrcurloc]
	stosw
	mov eax, [ebx+ebp+cargopacket.lasttransprofit]
	stosd
	ret

	                //ebx=cargo packet relptr
	                //ebp=[cargodestdata]
	                //trashes eax, esi, edi
outcargodestloadunloaddbgmess:
        call outdebugcargomessage
        mov edi, textrefstack
        call stos_packetdata
        mov DWORD [specialtext1], packetdumpmess
        jmp outdebugcargomessage

//var outputdebugstring_name, db "OutputDebugStringA", 0
//var kernel32dll, db "kernel32.dll", 0
//var dbgprint_name, db "DbgPrint", 0
//var ntdll, db "ntdll.dll", 0
//var percents, db "%s", 0
var cdestlogfile, db "cargodestoutlog-", 0x9A, 11, ".txt", 0
var openlog, db "--- Log Opens ---", 13, 10, 0  //19 chars long, change above if modified
var GetSystemTimeAsFileTime_name, db "GetSystemTimeAsFileTime", 0

var addcargonoroutemess, db "TTDP:  1: Added ", 0x7E, " unrouted ", 0x80, " to: ", 0x80, 13, 10, 0
var addcargoroutemess, db "TTDP:  2: Added ", 0x7E, " routed ", 0x80, " to: ", 0x80, ", destination: ", 0x80, 13, 10, 0
var routedumpmess, db "TTDP:   : Relptr: ", 0x9A, 0x8, ", Dest: ", 0x80, ", Next Hop: ", 0x80, ", Cargo: ", 0x80, ", Flags: ", 0x7E, ", Mindays: ", 0x7E, ", Last Updated: ", 0x82, ", Oldest Waiting: ", 0x7E, 13, 10, 0
var localroutemsg, db "TTDP:  4: Added/Updated local route from: ", 0x9A, 12, ", to: ", 0x80, 13, 10, 0
var farroutemsg, db "TTDP:  8: Added/Updated far route for: ", 0x80, 13, 10, 0
var packetdumpmess, db "TTDP:   : Relptr ", 0x9A, 0x8, ", Location: ", 0x80, ", Dest: ", 0x9A, 12, ", Source: ", 0x9A, 12, ", Amount: ", 0x7E, ", Cargo: ", 0x80, ", Flags: ", 0x7E, ", TTL: ", 0x7E, ", Last Station: ", 0x9A, 12, ", Left: ", 0x82, ", Left Last Trans: ", 0x82, ", Last Trans Profit: ", 0x7F, 13, 10, 0
var ttlfailmess, db "TTDP:  *: Packet TTL expiry at: ", 0x9A, 12, ", Veh: ", 0x80, 13, 10, 0
var acceptmess, db "TTDP: 10: max ", 0x7E, " units of packet accepted at: ", 0x9A, 12, ", from: ", 0x80, 13, 10, 0
var unloadmess, db "TTDP: 20: max ", 0x7E, " units of packet unloaded for transfer at: ", 0x9A, 12, ", from: ", 0x80, 13, 10, 0
var loadmess, db "TTDP: 40: max ", 0x7E, " units of packet loaded from: ", 0x9A, 12, ", to: ", 0x80, 13, 10, 0
var acceptendmess, db "TTDP: 80: unloaded: ", 0x7E, ", of which unrouted: ", 0x7E, ", of which charged: ", 0x7E, ", at: ", 0x9A, 12, ", from: ", 0x80, 13, 10, 0
var loadendmess, db "TTDP:100: loaded: ", 0x7E, ", of which unrouted: ", 0x7E, ", at: ", 0x9A, 12, ", to: ", 0x80, 13, 10, 0
var killoldlocalroutemsg, db "TTDP:200: Exterminating expired local route from: ", 0x9A, 12, ", to: ", 0x9A, 12, 13, 10, 0
var setoldestwaitinglocalroutemsg, db "TTDP:400: Setting local route from: ", 0x9A, 12, ", to: ", 0x9A, 12, ", oldest waiting value to: ", 0x7E, 13, 10, 0
var vehkillcpmess, db "TTDP:800: Vehicle deletion, about to exterminate cargo packet", 13, 10, 0
var stkillcpmess, db "TTDP:800: Station deletion, about to exterminate cargo packet", 13, 10, 0
var routekillmess, db "TTDP:800: Station deletion, about to exterminate route at: ", 0x80, 13, 10, 0
uvard bytesread
#endif
