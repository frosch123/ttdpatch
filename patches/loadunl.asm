// New cargo load/unload code. The LoadUnloadCargo proc below overrides the original
// LoadUnloadCargo proc of TTD, reproducing all of its code. Anything that would
// modify the old LoadUnloadCargo proc should be added here instead, with correct
// switch checks. The default code path (the one that is taken if no switches are
// enabled) should not set or depend on the veh.modflags bits (clearing them is OK,
// though).

#include <std.inc>
#include <veh.inc>
#include <flags.inc>
#include <station.inc>
#include <human.inc>
#include <bitvars.inc>

extern acceptcargofn,addexpenses,addfeederprofittoexpenses,calc_te_a
extern calcvehweight,callbackflags,cargotypes,cargotypesloading
extern checkrandomcargotrigger,checkstationcargoemptytrigger,consistempty
extern ecxcargooffset,ecxcargooffset_force,generateincometexteffect
extern generatesoundeffect,getirrplatformlength,getloadamountcallback
extern invalidatehandle,ishumanplayer,lastaccel,loadwaittime,maxloadamount
extern miscgrfvar,miscmodsflags,mountaintypes,numvehloadable
extern numvehstillunloading,patchflags,randomconsisttrigger,stationarray2ofst
extern stationcargowaitingmask,stationcargowaitingnotmask
extern stationplatformtrigger,totalloadamount,transferprofit
extern updatestationgraphics
extern vehcallback,stationplatformanimtrigger
extern convertplatformsinremoverailstation




// The original proc is separated to several smaller procs to make it a bit more
// understandable and eliminate some near jumps. These procs still share the same
// stack frame, though, (defined below), so EBP is sacred everywhere.

%push LoadUnloadCargo

%define %$framesize 18		// size of all local vars defined below

%define %$engine		(ebp+0)		// D: points to the engine of the consist
%define %$income		(ebp+4)		// D: income of the load/unload
						// (feederservice doesn't touch this to avoid the text effect resulting)
%define %$cargomoved		(ebp+8)		// W: sum of cargo loaded/unloaded (used for time calculation if gradualloading is off)
%define %$currstationptr	(ebp+0xa)	// D: points to the station where the loading/unloading is taking place
%define %$currstationidx	(ebp+0xe)	// B: same, but the ID instead of the pointer
%define %$flags			(ebp+0xf)	// B: redraw flags: bit 0 - vehicle window must be redrawn;
						//	bit 1 - vehicle and station windows must be redrawn
%define %$stationlength		(ebp+0x10)	// B: length of the current station, may contain junk if not called for trains
%define %$cargooffset		(ebp+0x11)	// B: offset to the current cargo from station.cargos

// Helper function for newcargos support. With newcargos, the current cargo may not
// have a slot allocated. If you need to be sure there's a slot allocated for your
// cargo, call this with ecx=offset returned by ecxcargooffset. The function will
// try allocating a new slot and return it in ecx. If there's no free slot, cl
// will be FFh
ensurecargoslot:
	testflags newcargos
	jnc	.offset_ok
	or	cl,cl
	jns	.offset_ok

	mov	al, [esi+veh.cargotype]
	call	ecxcargooffset_force

	mov	[%$cargooffset],cl

.offset_ok:
	ret

// Unload vehicle cargo to station (the cargo goes to wait on the station, player doesn't get money)
// in:	ebx -> station
//	ecx: cargo offset
//	esi -> current vehicle
//	edi -> engine
// safe: eax, ebx, ecx, edx
UnloadCargoToStation:
	call	ensurecargoslot
	or	cl,cl
	jns	.offset_ok

	// no free slot, we can't allow the proc to continue
	// we must wait until a slot becomes free, or the player notices the problem
	or	byte [esi+veh.modflags], 1 << MOD_NOTDONEYET
	ret

.offset_ok:
// Old code to update enroutefrom and enroutetime if needed
	mov	byte [ebx+station.timesinceunload], 0
	mov	dx, [ebx+station.cargos+ecx+stationcargo.amount]
	and	edx, [stationcargowaitingmask]
	jnz	.cargoalreadywaiting
	mov	al, [esi+veh.cargotransittime]
	mov	[ebx+station.cargos+ecx+stationcargo.enroutetime], al
	mov	al, [esi+veh.cargosource]
	mov	[ebx+station.cargos+ecx+stationcargo.enroutefrom], al
	jmp	short .cargosourceok

.cargoalreadywaiting:
	mov	al, [esi+veh.cargotransittime]
	cmp	al, [ebx+station.cargos+ecx+stationcargo.enroutetime]
	jb	.stationcargoolder
	mov	[ebx+station.cargos+ecx+stationcargo.enroutetime], al

.stationcargoolder:
	mov	al, [%$currstationidx]
	cmp	al, [ebx+station.cargos+ecx+stationcargo.enroutefrom]
	je	.cargosourceok
	mov	al, [esi+veh.cargosource]
	mov	[ebx+station.cargos+ecx+stationcargo.enroutefrom], al

.cargosourceok:
// the next step is deciding how much to unload in this step
	mov	ax, [esi+veh.currentload]

	testflags gradualloading
	jnc	.unloadamountok

	// with gradualloading, don't allow the full amount to be unloaded instantly
	call	maxloadamount
	cmp	ax,word [esi+veh.currentload]
	jb	.notdoneyet

	dec	byte [numvehstillunloading]		// vehicle will be empty
	jmp	.nomoreleft

.notdoneyet:
	or	byte [esi+veh.modflags],(1 << MOD_MORETOUNLOAD)+(1 << MOD_NOTDONEYET)

.nomoreleft:
	sub	[totalloadamount],ax

.unloadamountok:
	add	[%$cargomoved],ax			// BUGFIX
	movzx	eax,ax
	add	eax, edx
	sub	edx, eax			//now dx=-unload_amount

	cmp	eax, [stationcargowaitingmask]	// if amount>mask, it won't fit when putting back the amount, so truncate it
	jb	.nounloadoverflow
	mov	eax, [stationcargowaitingmask]

.nounloadoverflow:

	testflags feederservice
	jnc	.nocash

	// with feederservice, you get fake income for unloading (then fake cost for loading later)
	push	byte PL_ORG+PL_NOTTEMP
	call	ishumanplayer
	jne	.nocash

	bts	dword [esi+veh.modflags],MOD_DIDCASHIN 	// did we do this already?
	jc	.nocash

	pusha
	mov	al,byte [esi+veh.cargosource]
	mov	ah,byte [%$currstationidx]
	mov	bx,word [esi+veh.currentload]
	mov	ch,byte [esi+veh.cargotype]
	mov	dl,byte [esi+veh.cargotransittime]
	call	transferprofit
	sub	[edi+veh.profit],eax
	call	addfeederprofittoexpenses
	popa

.nocash:
	add	[esi+veh.currentload], dx
	jnz	.notempty

//if the vehicle finished unloading, clear the cash flag
	and	byte [esi+veh.modflags],~ (1 << MOD_DIDCASHIN)

.notempty:
	//actually add cargo to the station
	mov	dx, [stationcargowaitingnotmask]
	and	word [ebx+station.cargos+ecx+stationcargo.amount], dx
	or	[ebx+station.cargos+ecx+stationcargo.amount], ax

	or	byte [%$flags], 2	// both the vehicle and the station windows need redrawing
	ret

// Accept vehicle cargo at station (the cargo goes away, player gets money)
// in:	ebx -> station
//	esi -> current vehicle
//	edi -> engine
// safe: eax, ebx, ecx, edx
AcceptCargoAtStation:
	mov	byte [ebx+station.timesinceunload], 0
	mov	ax, [esi+veh.currentload]
	mov	bx, ax	// for [acceptcargofn]
//	movzx	ax, cl					// BUG!!!!!!!!!!!!!!!!!!!!!!!!
//	add	[%$cargomoved], ax

//decide how much to unload in this step
	testflags gradualloading
	jnc	.amountok		// no gradual loading - unload all

.gradualaccept:
	or	byte [esi+veh.modflags],(1 << MOD_MORETOUNLOAD)+(1 << MOD_NOTDONEYET)
	or	eax, -1
	call	maxloadamount

	cmp	ax, [esi+veh.currentload]
	jb	.stillnottoomuch

	mov	ax, [esi+veh.currentload]
	dec	byte [numvehstillunloading]

.stillnottoomuch:
	sub	[totalloadamount],ax
.amountok:
	sub	[esi+veh.currentload], ax
	add	[%$cargomoved], ax			// BUGFIX

//Get the money for the delivery. Be careful to do it only once, since with gradualloading, there may me more steps

	bts	dword [esi+veh.modflags],MOD_DIDCASHIN	// it's OK to set this even with gradualloading off, since
							// the next cmp will always set zf (if gradualloading is off, all
							// the cargo is unloaded always)
	jc	.dontcashin

	mov	al, [esi+veh.cargosource]
	mov	ah, [%$currstationidx]
	mov	dl, [esi+veh.cargotransittime]
	mov	ch, [esi+veh.cargotype]
	call	dword [acceptcargofn]
	add	[%$income], eax

.dontcashin:
	cmp	word [esi+veh.currentload], 0
	jne	.notemptyyet

//if the vehicle finished unloading, clear the cash and unload flags
	and	byte [esi+veh.modflags],~ ((1 << MOD_MORETOUNLOAD)+(1 << MOD_DIDCASHIN))

.notemptyyet:
	or	byte [%$flags], 1		// only the vehicle window needs update, station cargo hasn't changed
	ret

// limit cargo if freighttrains is on so the train can start
// in:	ax: max. amount
//	esi->vehicle
//	edi->engine
// out:	ax: limited amout
// safe: eax
freighttrains_limitcargo:
	// need to check if the train wouldn't get too heavy to start
.tryagain:
	pusha
	mov dx,[esi+veh.currentload]
	mov ebx,[esi+veh.veh2ptr]
	mov cx,[ebx+veh2.fullweight]
	add [esi+veh.currentload],ax
	call calcvehweight
	mov ebx,[esi+veh.veh2ptr]
	mov [ebx+veh2.fullweight],ax
	xchg esi,edi
	movzx eax, word [esi+veh.maxspeed]
	shr eax, 1
	call calc_te_a
	xchg esi,edi
	mov [esi+veh.currentload],dx
	mov ebx,[esi+veh.veh2ptr]
	mov [ebx+veh2.fullweight],cx
	popa

	cmp dword [lastaccel],0
	jg .nottoomuch

	// new load would be too much, try a little less, otherwise set loading done
	shr ax,1
	jnz .tryagain
	or byte [edi+veh.modflags],1<<MOD_ISFULL

.nottoomuch:
	ret

// Load cargo from station
// in:	ebx->station
//	ecx:cargo offset
//	esi->vehicle
//	edi->engine
// safe: eax, ebx, ecx, edx
LoadCargoFromStation:
	call	ensurecargoslot
	or	cl,cl
	jns	.offset_ok

	// this cargo type wasn't here before, and there's no space for its slot either,
	// so just quit - there's nothing to load anyway
.ret:
	ret

.offset_ok:
	testflags fifoloading
	jnc	near .nofifo

	// with FIFO loading, only vehicles that have reserved can do full loading, so check modflags
	// if that fails, check queue and reserve if allowed.
	// if we aren't allowed to load, we're done, so return from the proc
	test	word [edi+veh.currorder], 0x40
	jz	near .nofifo

	test	byte [esi+veh.modflags+1], 1 << (MOD_HASRESERVED-8)
	jnz	near .reserved

	mov	eax, [esi+veh.veh2ptr]
.queueloop:
	mov	eax, [eax+veh2.prevptr]
	test	eax, eax
	jz	near .reserve
	mov	edx, [eax+veh2.vehptr]
	test	byte [edx+veh.modflags], 1 << MOD_MORETOUNLOAD
	jnz	.queueloop
	ret

.overflow:
	mov	ah, [ebx+station2.cargos+ecx+stationcargo2.rescount]
	mov	al, [esi+veh.cargotype]
	push	ebp
	test	ah, ah
	jz	.consistreserve
	cmp	esi, edi
	je	.popret

// Check to see if all currently loading vehicles are part of this consist.
	mov	ebp, edi
.consistloop1:
	mov	dx, [ebp+veh.capacity]
	sub	dx, [ebp+veh.currentload]
	jz	.nextveh1		// no capacity
	cmp	al, [ebp+veh.cargotype]
	jne	.nextveh1		// wrong cargo
	bt	dword [ebp+veh.modflags], MOD_HASRESERVED
	sbb	ah, 0			// dec ah if this vehicle is loading
	jz	.consistreserve		// if ah hits 0, all loading vehicles are in this consist
.nextveh1:
	cvivp	ebp, [ebp+veh.nextunitidx]
	cmp	esi, ebp
	jne	.consistloop1
.popret:
	pop	ebp
	ret

// Reserve for all unreserved vehicles in consist.
.consistreserve:
	mov	ebp, edi
.consistloop2:
	mov	dx, [ebp+veh.capacity]
	sub	dx, [ebp+veh.currentload]
	jz	.nextveh2		// no capacity
	cmp	al, [ebp+veh.cargotype]
	jne	.nextveh2		// wrong cargo
	bts	dword [ebp+veh.modflags], MOD_HASRESERVED
	jc	.nextveh2		// already reserved
	extcall dequeueveh
	inc	byte [ebx+station2.cargos+ecx+stationcargo2.rescount]
	add	[ebx+station2.cargos+ecx+stationcargo2.resamt], dx

.nextveh2:
	movzx	ebp, word [ebp+veh.nextunitidx]
	cmp	bp, 0-1
	je	.doneres
	cvivp	ebp
	jmp	short .consistloop2
.doneres:
	pop	ebp
	jmp	short .allowfifo

.reserve:
	mov	dx, [esi+veh.capacity]
	sub	dx, [esi+veh.currentload]
	jz	near .done		// No remaining capacity; we're done.
	mov	ax, [ebx+station.cargos+ecx+stationcargo.amount]
	and	ax, [stationcargowaitingmask]
	add	ebx, [stationarray2ofst]
	sub	ax, [ebx+station2.cargos+ecx+stationcargo2.resamt]
	jb	.overflow
	cmp	ax, dx
	jb	.overflow
	call	dequeueveh
	or	byte [esi+veh.modflags+1], 1 << (MOD_HASRESERVED-8)
	inc	byte [ebx+station2.cargos+ecx+stationcargo2.rescount]
	add	[ebx+station2.cargos+ecx+stationcargo2.resamt], dx
.allowfifo:
	sub	ebx, [stationarray2ofst]	// ebx points to the station struc again

.reserved:
.nofifo:
//original code to update some station fields
	mov	byte [ebx+station.cargos+ecx+stationcargo.timesincevisit], 0
	mov	edx, [%$engine]
	cmp	byte [edx+veh.class], 11h
	mov	dx, [edx+veh.maxspeed]
	jnz	.notroadveh
	shr	dx, 1

.notroadveh:
	or	dh, dh
	jz	.speednottoomuch
	mov	dx, 0FFh

.speednottoomuch:
	mov	[ebx+station.cargos+ecx+stationcargo.lastspeed], dl
	mov	dl, [currentyear]
	sub	dl, [esi+veh.yearbuilt]
	mov	[ebx+station.cargos+ecx+stationcargo.lastage], dl

// check how much we can load from the station
	mov	dx, [ebx+station.cargos+ecx+stationcargo.amount]
	and	dx, [stationcargowaitingmask]
	jz	near .done		// station is empty - we can't load, obviously
	mov	ax, [esi+veh.capacity]
	sub	ax, [esi+veh.currentload]
// now ax contains the remaining capacity of the vehicle

	testflags gradualloading
	jnc	.notfulload

	test	byte [edi+veh.currorder],0x40
	jz	.notfulload

	// check whether we're done loading
	or	ax,ax
	jz	.notfulload

	// consist not done with loading yet
	// even if we're not loading cargo right now (full load order)
	or	byte [edi+veh.modflags],1 << MOD_NOTDONEYET

.notfulload:

	cmp	ax, dx
	jbe	.enough
	mov	ax, dx
.enough:
	or	ax,ax
	jz	.nothing

	call	checkrandomcargotrigger

	testflags gradualloading
	jnc	.donthurtflags
	or	byte [esi+veh.modflags],1 << MOD_NOTDONEYET

.donthurtflags:
.nothing:
// with gradualloading, we don't load the whole amount in one step
	testflags gradualloading
	jnc	.gotloadamount

	call	maxloadamount

	testflags freighttrains
	jnc	.nolimitcargo
	cmp	byte [esi+veh.class],0x10
	jne	.nolimitcargo

	// check whether using realistic acceleration for this track type
	push ecx
	movzx ecx,byte [edi+veh.tracktype]
	cmp byte [mountaintypes+ecx],3
	pop ecx
	jne .nolimitcargo		// not realistic

	call	freighttrains_limitcargo

.nolimitcargo:
	sub	[totalloadamount],ax

.gotloadamount:
	cmp	ax,dx
	jne	.notempty

	call	checkstationcargoemptytrigger

.notempty:

	testflags feederservice
	jnc	.noadjustprofit

	// with feederservice, picking up en-route cargo will cause fake cost to make up
	// with the fake income unloading produced
	push	byte PL_ORG+PL_NOTTEMP
	call	ishumanplayer
	jne	.noadjustprofit

	pusha

	push ax

	// was it en-route?
	mov	al,[ecx+station.cargos+stationcargo.enroutefrom+ebx]
	mov	ah,[%$currstationidx]

	pop bx

	cmp	al,ah
	je	.noadjustprofit_pop

	// is en-route
	mov	edx,[%$currstationptr]
	mov	dl,[edx+station.cargos+ecx+stationcargo.enroutetime]
	mov	ch,[esi+veh.cargotype]
	call	transferprofit
	add	[edi+veh.profit],eax

	neg	eax
	call	addfeederprofittoexpenses

.noadjustprofit_pop:
	popa
	
.noadjustprofit:
// actually load the cargo from the station
	testflags fifoloading
	jnc	.unres
	test	byte [esi+veh.modflags+1], 1<<(MOD_HASRESERVED-8)
	jz	.unres
	add	ebx, [stationarray2ofst]
	sub	[ebx+station2.cargos+ecx+stationcargo2.resamt], ax
	sub	ebx, [stationarray2ofst]
.unres:
	sub	[ebx+station.cargos+ecx+stationcargo.amount], ax
	mov	byte [ebx+station.timesinceload], 0
	add	[%$cargomoved], ax
	add	[esi+veh.currentload], ax
	test	ax,ax
	jz	.nothingmoved
	mov	dl, [ebx+station.cargos+ecx+stationcargo.enroutefrom]
	mov	[esi+veh.cargosource], dl
	mov	dl, [ebx+station.cargos+ecx+stationcargo.enroutetime]
	mov	[esi+veh.cargotransittime], dl
	mov	dx, [esi+veh.capacity]
	cmp	dx, [esi+veh.currentload]
	jnz	.notfull
// Vehicle is full; reduce rescount so next vehicle can load, and mark as has-not-reserved so the exit proc doesn't decrement again
	and	byte [esi+veh.modflags+1], ~ (1 << (MOD_HASRESERVED-8) )
	add	ebx, [stationarray2ofst]
	dec	byte [ebx+station2.cargos+ecx+stationcargo2.rescount]
	sub	ebx, [stationarray2ofst]
.notfull:
.nothingmoved:
	or	byte [%$flags], 2			// both the vehicle and the station windows need redrawing
	mov	ax, [esi+veh.idx]
	mov	[ebx+station.lastvehicle], ax
.done:
	ret

// Get the time that should be spent waiting after a load/unload step
// out:	ax: time to spend
// safe: eax, ebx, ecx, edx, esi, edi
GetLoadUnloadTime:
	mov	esi, [%$engine]

	testflags gradualloading
	jc	.gradualalgo

	cmp	byte [esi+veh.class], 10h
	movzx	eax,word  [%$cargomoved]
	jne	.gotloadtime_add20
	mov	edi, esi
	xor	dl, dl
	xor	cl, cl

// count vehicles in the consist
.gettrainlen_nextveh:
	cmp	word [edi+veh.capacity],0
	je	.nocapacity
	inc	cl
.nocapacity:
	movzx	edi, word [edi+veh.nextunitidx]
	inc	dl
	cmp	di, -1
	je	.gottrainlen
	shl	edi, vehicleshift
	add	edi, [veharrayptr]
	jmp	.gettrainlen_nextveh

.gottrainlen:
	mov	dh,[%$stationlength]
	shl	dh,1

// now ax=total amount of cargo moved;
// cl=number of vehicles with capacity; dl=length of consist; dh=length of station*2

	testflags improvedloadtimes
	jc	.improvedalgo

// original algo: time= moved_cargo*2*(1+number_of_wagons_sticking_out)+20
	shl	ax, 1
	sub	dl, dh
	jbe	.gotloadtime_add20
	xor	dh, dh
	push	ax
	mul	dx
	mov	dx, ax
	pop	ax
	add	ax, dx

.gotloadtime_add20:
	add	ax, 20
	ret

.gradualalgo:
// If gradualloading is on, each round lasts the same regardless of amount of cargo moved
// Just before leaving the station, an extra 20-tick delay is done
	movzx	ebx,byte [esi+veh.class]

	mov	al,5
	mul	byte [loadwaittime+ebx-0x10]
	test	byte [esi+veh.modflags],1 << MOD_NOTDONEYET
	jnz	.exit

	mov	ax,20
.exit:
	ret

.improvedalgo:
// improved load/unload time calculation if loadtime is on but gradualloading isn't
	or	cl,cl
	jz	.nodividebyzerothanks

	// find how much is loaded into every vehicle
	push	edx
	movzx	ebx,cl
	xor	edx,edx
	add	eax,ebx	// to round up
	dec	eax
	div	ebx		// to get sufficient precision
	pop	edx

	// now eax is the time taken for the load/unload process
	// calc back to the other format (and double time to make up the change)
.nodividebyzerothanks:
	shl	eax,3
	add	eax,byte 10
	mov	ebx,eax

.checkexcess:		// if train doesn't fit completely, double the time
	sub	cl,dh
	jle	.noexcess
	add	eax,ebx
	jmp	.checkexcess	// maybe too long still (2 platforms, >8 cars)

.noexcess:
	ret

// Set-up vehicles before starting a round of gradual loading/unloading
// in:	esi->engine
// safe: eax, ebx, ecx, edx, edi
SetupGradualLoad:
	and	byte [esi+veh.modflags],~ (1 << MOD_NOTDONEYET)

	mov	al,255
	cmp	byte [esi+veh.class],0x10
	jne	.gotnumveh

	mov	al,[%$stationlength]
	shl	al,4 // Gives you the full station length

.lstart:
	push	edi // store registors
	push	ecx
	mov	edi,esi // Move id to edi so it can be changed with out messing up other code
	mov	cl,0 // Blank the counter

.lgetlen:
	cmp	word [edi+veh.capacity],0 // If vehicle has no cap, skip (So it works as before)
	je	.lgetveh

	mov	ah,[edi+veh.shortened] // Get vehicle length
	and	ah,0x7F
	neg	ah
	add	ah,0x8

.lstatlen:
	sub	al,ah // Decrease station length left
	jb	.ldone // If negitive, jump to end
	inc	cl // Increase counter

.lgetveh:
	movzx	edi,word [edi+veh.nextunitidx] // Get next vehicle id in consist
	cmp	di,-1
	je	.ldone	// Jump to end if no id

	shl	edi,vehicleshift
	add	edi,[veharrayptr]
	jmp	.lgetlen

.ldone:
	mov	al,cl // Move new value back
	pop	ecx // Restore registors
	pop	edi

.gotnumveh:
	mov	[numvehloadable],al
	mov	[consistempty],al	// al is nonzero
	mov	edi,esi
	xor	ecx,ecx
	movzx	eax,al
	mov	[cargotypesloading],ecx
	mov	edx, [%$currstationptr]

	testflags newcargos
	jnc	.stationptr_ok

	add	edx, [stationarray2ofst]

.stationptr_ok:
.nextveh:
	cmp	word [edi+veh.capacity],0
	je	.getnextveh

	movzx 	ebx,byte [edi+veh.cargotype]
	bts	[cargotypesloading],ebx

	sub	al,1	// can't use dec, because it doesn't set carry
	adc	al,0	// make sure it stays at zero
	jc	.toolong

	xchg	esi,edi
	call	getloadamountcallback
	xchg	esi,edi
	add	cx,bx

.toolong:
	cmp	word [edi+veh.currentload],0
	je	.getnextveh

	mov	byte [consistempty],0

	test	byte [edi+veh.modflags],1 << MOD_MORETOUNLOAD
	jz	.getnextveh

		// check whether the vehicle is going to try unloading
	test	byte [esi+veh.currorder],0x20	// forced unload
	jnz	.canunload

	mov	bl,[edi+veh.cargosource]		// not at source station?
	cmp	bl,[%$currstationidx]
	je	.notunloading

	movzx	ebx,byte [edi+veh.cargotype]		// does it accept it?

	testflags newcargos
	jnc	.normalaccepttest

	bt	dword [edx+station2.acceptedcargos],ebx
	jc	.canunload
	jmp	short .notunloading

.normalaccepttest:
	test	byte [edx+station.cargos+ebx*stationcargo_size+stationcargo.amount+1],0x80
	jz	.notunloading

.canunload:
	inc	ah
	jmp	short .getnextveh

.notunloading:
	and	byte [edi+veh.modflags],~(1 << MOD_MORETOUNLOAD)

.getnextveh:
	movzx	edi,word [edi+veh.nextunitidx]
	cmp	di,-1
	je	.done

	shl	edi,vehicleshift
	add	edi,[veharrayptr]
	jmp	.nextveh

.done:
	// now cx=maximum amount of cargo that can be moved in each round
	// by all waggons that fit in the station

	// with MISCMODS_GRADUALLOADBYWAGON,
	// - amount of waggons is unlimited
	// - totalloadamount is sum of cargo that can be moved by the
	//   waggons that fit in the station
	//   (small bug: this doesn't give the right number if the first
	//    waggons have small loadamount, and the remaining ones have
	//    a large loadamount or vice versa)
	// - amount each waggon can load is unlimited
	//
	// without MISCMODS_GRADUALLOADBYWAGON
	// - amount of waggons is limited by how many fit in the station
	// - total amount is unlimited
	// - amount each waggon can load is limited by loadamount[vehtype]
	//

	test	byte [miscmodsflags],MISCMODS_GRADUALLOADBYWAGON
	jnz	.bywaggon

	or	ecx,byte -1
	jmp	short .setamounts

.bywaggon:
	mov	byte [numvehloadable],0xff

.setamounts:
	mov	[totalloadamount],cx
	mov	[numvehstillunloading],ah

	cmp	byte [consistempty],0
	je	.notempty

	mov	al,4
	call	randomconsisttrigger

.notempty:
	mov	edx,5
	call	stationplatformanimtrigger

	push	0x10
	mov	edx,[cargotypesloading]
	call	stationplatformtrigger
	ret


//---------------------------------------------------------------
//---------------------------------------------------------------

global LoadUnloadCargo
LoadUnloadCargo:

	sub	esp, %$framesize		// set up stack frame
	mov	ebp, esp

// stop the vehicle and set up our stack vars
	and	word [esi+veh.speed], 0
	mov	byte [%$flags],0
	and	dword [%$income], 0
	and	word [%$cargomoved], 0
	mov	[%$engine], esi
	mov	al, [esi+veh.owner]
	mov	[curplayer], al
	movzx	eax,byte [esi+veh.laststation]
	mov	[%$currstationidx], al

	testmultiflags losttrains,lostrvs,lostships,lostaircraft	// actually, this won't hurt even without lostvehs
	jz .nolostvehs							// we skip it just to save some cycles

	// with lost vehicles, reset traveltime if this is a scheduled stop
	mov	ecx,[esi+veh.scheduleptr]
	movzx	ebx,byte [esi+veh.currorderidx]
	mov 	ecx,[ecx+2*ebx]
	cmp	ch,al
	jne	.notgoodstop
	and 	cl,0x1f
	cmp	cl,1
	jne	.notgoodstop
	and	word [esi+veh.traveltime],0

.notgoodstop:
.nolostvehs:
	imul    ax, station_size
	add	eax, [stationarrayptr]
	mov	[%$currstationptr], eax

// get the length of the station (this will only be used for trains)
	testflags irrstations
	jc .irrgetstationlen

	mov	dl,[eax+station.platforms]
	xchg eax, esi
	call convertplatformsinremoverailstation
	xchg eax, esi
	mov	[%$stationlength],dl
	jmp short .donegetstationlen
.irrgetstationlen:	
	push	esi
	movzx	esi,word [esi+veh.XY]
	call	getirrplatformlength	// works for regular or irregular stations
	mov	[%$stationlength],al
	pop	esi
.donegetstationlen: 

	testflags gradualloading
	jnc	.dontsetupgradload

	call	SetupGradualLoad

.dontsetupgradload:
	mov	edi, esi

// now we'll loop through all vehicles of the consist, donig one load/unload step for each
// esi will point to the current vehicle, while edi points to the engine
.nextvehinconsist:
	and	byte [esi+veh.modflags],~ (1 << MOD_NOTDONEYET)
	cmp	word [esi+veh.capacity], 0
	je	near .VehicleDone		// vehicles with no capacity don't matter

// get the offset of the cargo inside the station struc; with newcargos, it isn't simply cargotype*8
// WARNING: the offset can be set to FFh, which means there's no slot allocated yet.
// Call ensurecargoslot before using this value, or make a special case for FFh!
	testflags newcargos
	jnc	.normalcargooffset

	mov	ebx, [%$currstationptr]
	mov	al, [esi+veh.cargotype]
	call	ecxcargooffset
	jmp	short .gotcargooffset

.normalcargooffset:
	movzx	ecx, byte [esi+veh.cargotype]
	shl	ecx,3

.gotcargooffset:
	mov	[%$cargooffset],cl

// With gradual loading, we don't load and unload a vehicle in the same step.
// We start loading only if the "more to unload" flag is clear.
	testflags gradualloading
	jnc	.dontcheckmods
	btr	dword [esi+veh.modflags],MOD_MORETOUNLOAD
	jnc	near .DoLoad

.dontcheckmods:
	cmp	word [esi+veh.currentload], 0
	je	.DoLoad				// nothing to unload - start loading
	mov	ebx, [%$currstationptr]

// don't unload cargo coming from the current station, unless we have a forced unload order
	mov	al, [esi+veh.cargosource]
	cmp	al, [%$currstationidx]
	jne	.cargonotfromhere
	test	word [edi+veh.currorder], 20h
	jz	.DoLoad
	jmp	short .DoUnload

.cargonotfromhere:

// first, we decide whether our cargo is accepted here
	testflags newcargos
	jc	.newcargos_testaccept

	test	word [ebx+station.cargos+ecx+stationcargo.amount], 8000h
	jnz	.accept
	jmp	short .noaccept

.newcargos_testaccept:
	mov	edx,ebx
	movzx	eax,byte [esi+veh.cargotype]
	add	edx, [stationarray2ofst]
	bt	dword [edx+station2.acceptedcargos],eax
	jnc	.noaccept

.accept:
// the cargo is accepted - we should still unload if feederservice is on and a human player has forced unload
// in all other cases, the cargo will be accepted
	testflags feederservice
	jnc	.DoAccept
	test	word [edi+veh.currorder], 20h
	jz	.DoAccept
	push	byte PL_ORG+PL_NOTTEMP
	call	ishumanplayer
	jnz	.DoAccept
	jmp	short .DoUnload

.noaccept:
// The cargo isn't accepted - unload it if it's a forced unload, start loading otherwise
	test	word [edi+veh.currorder], 20h
	jz	.DoLoad
	
.DoUnload:						// unload cargo to station, cargo isn't accepted but stays there
	call	UnloadCargoToStation
	jmp	short .UnloadAcceptDone

.DoAccept:						// accept cargo of the vehicle and get money for it
	call	AcceptCargoAtStation

.UnloadAcceptDone:
	testflags gradualloading
	jc	.VehicleDone		// if gradualloading is on, we must finish unloading before trying loading
.DoLoad:
// start the loading phase

// if gradualloading is in the by-wagon mode, we can't start loading until all vehicles finish unloading
	testflags gradualloading
	jnc	.canstartload

	test	byte [miscmodsflags],MISCMODS_GRADUALLOADBYWAGON
	jz	.canstartload

	cmp byte [numvehstillunloading],0
	jne	.VehicleDone

.canstartload:
	and	byte [esi+veh.modflags],~ (1 << MOD_NOTDONEYET)
// no loading if we have a forced unload
	test	word [edi+veh.currorder], 20h
	jnz	near .VehicleDone

	mov	ebx, [%$currstationptr]
	movzx	ecx, byte [%$cargooffset]
	call	LoadCargoFromStation

.VehicleDone:
	testflags gradualloading
	jnc	.gotonextveh

	// copy MOD_NOTDONEYET to consist
	mov	al,byte [esi+veh.modflags]
	and	al,1 << MOD_NOTDONEYET
	or	[edi+veh.modflags],al

	test	byte [miscmodsflags],MISCMODS_GRADUALLOADBYWAGON
	jnz	.gotonextveh

	// only unload as many train vehicles at a time as fit in the station
	cmp	byte [esi+veh.class],0x10
	jne	.gotonextveh

	test al,1 << MOD_NOTDONEYET
	jz short .gotonextveh

	sub byte [numvehloadable],1
	adc byte [numvehloadable],0

.gotonextveh:
	movzx	esi, word [esi+veh.nextunitidx]
	cmp	si, -1
	je	.consistdone
	shl	esi, vehicleshift
	add	esi, [veharrayptr]
	jmp	.nextvehinconsist

.consistdone:

	call	GetLoadUnloadTime
//now ax=loadtime

	mov	[esi+veh.loadtime], ax
	cmp	byte [%$flags], 0
	je near	.done

	// play sound effect, if enabled
	testmultiflags newsounds
	jz .nosoundcallback

	movzx ebx,byte [esi+veh.vehtype]
	test byte [callbackflags+ebx],0x80
	jz .nosoundcallback

	mov byte [miscgrfvar],9
	mov al,0x33
	call vehcallback
	mov byte [miscgrfvar],0
	jc .nosoundcallback

	call [generatesoundeffect]

.nosoundcallback:

//refresh the vehicle window
	mov	bx, [esi+veh.idx]
	mov	al, 0Eh
	call	[invalidatehandle]
	test	byte [%$flags], 2
	jz	.dontrefreshstationwindow

	testflags newstations
	jnc	.noredrawstation

	push	esi
	mov	esi,[%$currstationptr]
	call	updatestationgraphics
	pop	esi

.noredrawstation:
//refresh the station window
	movzx	bx, byte [%$currstationidx]
	mov	al, 11h
	call	[invalidatehandle]

.dontrefreshstationwindow:
//add the profit
	mov	ebx, [%$income]
	or	ebx, ebx
	jz	.done
	sub	[esi+veh.profit], ebx
	call	[addexpenses]
//play cash sound for human1
	mov	al, [curplayer]
	cmp	al, [human1]
	jne	.dontplaycashsound
	push	esi
	mov	eax, 12h
	call	[generatesoundeffect]
	pop	esi

.dontplaycashsound:
//generate the text effect
	mov	ax, [esi+veh.xpos]
	mov	cx, [esi+veh.ypos]
	mov	dl, [esi+veh.zpos]
	push	esi
	push	ebp
	call	[generateincometexteffect]
	pop	ebp
	pop	esi

.done:
//remove stack frame
	mov	al, [%$flags]
	add	esp,%$framesize
	ret

%pop
