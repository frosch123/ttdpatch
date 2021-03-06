//
// new sprites handlers
//

#include <std.inc>
#include <flags.inc>
#include <grf.inc>
#include <station.inc>
#include <veh.inc>
#include <vehtype.inc>
#include <industry.inc>
#include <ptrvar.inc>
#include <house.inc>
#include <proc.inc>
#include <transopts.inc>
#include <idf.inc>
#include <objects.inc>
#include <spriteheader.inc>

extern acttriggers,cachevehvar40x,canalfeatureids,cargoaction3,curcallback
extern curgrffile,curgrfsprite,curstationtile,curtriggers,ecxcargooffset
extern externalvars,extraindustilegraphdataarr
extern genericids,getaircraftinfo,getcargoenroutetime,getcargolastvehdata
extern getcargorating,getcargotimesincevisit,getcargowaiting,getconsistcargo
extern getcurveinfo,getexpandstate,gethouseage,gethouseanimframe
extern gethousebuildstate,gethousecount,gettileterrain,gethousezone
extern getincargo,getindustileanimframe,getindustileconststate
extern getindustilelandslope,getindustilepos,getistownlarger,getmotioninfo
extern getotherhousecount,getothernewhousecount,getplatformdirinfo
extern getplatforminfo,getplatformmiddle,getplayerinfo
extern getstationacceptedcargos,getstationpbsstate,getstationsectioninfo
extern getstationsectionmiddle,getstationterrain,gettownnumber,gettrackcont
extern getvehiclecargo,getvehidcount,getvehnuminconsist,getvehnuminrow
extern industryaction3,numextvars,patchflags,septriggerbits
extern stationcargolots,stationcargowaitingmask,stationflags,stsetids
extern triggerbits,vehids,getvehtypeflags,getcargoacceptdata
extern wagonoverride,getindutiletypeatoffset,getindutilerandombits
extern getindustilelandslope_industry,hexdigits,int21handler
extern getotherindustileanimstage,getotherindustileanimstage_industry
extern getstationanimframe,getnearbystationanimframe,getothertypedistance
extern airportaction3,getaircraftvehdata,getaircraftdestination
extern substindustile,substindustries
extern convertplatformsinecx
extern getsigtiledata

uvard grffeature
uvard curgrffeature,1,s		// must be signed to indicate "no current feature"
uvard curgrfid,1,s		// same here
uvard curaction3info
uvard mostrecentspriteblock
uvarb mostrecentgrfversion

uvard grfvarfeature		// feature to use for 40+x etc. variable handlers
uvard grfvarfeature_set_add	// set to feature when using grfvarfeature, then to -1 when done
uvard grfvarfeature_set_and,1,s	// set to zero when using grfvarfeature, then to -1 when done

uvard curstationcargo

#ifndef RELEASE
uvard grfdebug_feature
uvard grfdebug_id
uvard grfdebug_callback
uvard grfdebug_active
uvarb grfdebug_current
#endif


// find action 3 and spriteblock for each feature
//
// in:	eax=vehicle (etc.) ID
// out:	eax->action 3
//	edx=ID in grf file (for translated ones)
// 	on error eax=0

grfcalltable getaction3, dd addr(getaction3.generic)

.generic:
	mov edx,eax
	mov eax,[genericids+eax*4]
	ret

.gettrains:
	mov edx,eax
	cmp byte [wagonoverride+eax],1
	jb .nooverride

	// wagon override bit was set
	// see if the current engine has an override and if so,
	// use it instead of the current cargo ID
	test esi,esi
	jz .nooverride

	// if it's an articulated vehicle, we base the override not
	// on the engine but on the first vehicle of the artic
	movzx ebx,word [esi+veh.articheadidx]

	cmp byte [esi+veh.artictype],0xfd
	jae .artic

	movzx ebx,word [esi+veh.engineidx]

.artic:
	shl ebx,vehicleshift
	add ebx,[veharrayptr]
	movzx ebx,word [ebx+veh.vehtype]
	call checkoverride
	jc .badoverride
	ret

.getplanes:
	mov edx,eax
	cmp byte [wagonoverride+eax],1
	jb .nooverride

	// override for helicopter rotor
	// get rotor graphics if esi has sign bit set
	// use regular engine graphics if esi is empty or an engine
.rotoroverride:
	btr esi,31
	jnc .nooverride

	mov ebx,eax
	sub al,AIRCRAFTBASE
	call checkoverride
	jc .badoverride
	ret

.badoverride:
	mov eax,[curgrfid]

.nooverride:
.getrvs:
.getships:
	mov edx,eax
	mov eax,[vehids+eax*4]
	ret

.gethouses:
	movzx edx,byte [substbuilding+eax]
	mov eax,[extrahousegraphdataarr+eax*4] //8+housegraphdata.act3]
	ret
	
.getindustiles:
	movzx edx,byte [substindustile+eax]
	mov eax,[extraindustilegraphdataarr+eax*4]
	ret

.getcanals:
	mov edx,eax
	mov eax,[canalfeatureids+eax*4]
	ret

.getbridges:
	mov edx,eax
	extern bridgeaction3
	mov eax, [bridgeaction3+eax*4]
	ret

.getstations:
	movzx edx,byte [stsetids+eax*stsetid_size+stsetid.setid]
	or dword [curstationcargo],byte -1
	mov eax,[stsetids+eax*stsetid_size+stsetid.act3info]
	ret

.getindustries:
	movzx edx,byte [substindustries+eax]
	mov eax,[industryaction3+eax*4]
	ret

.getcargos:
	mov edx,eax
	mov eax,[cargoaction3+eax*4]
	ret

.getgeneric:
.getsounds:
	ud2
	
.getsignals:
	mov eax,[genericids+0xE*4]
	xor edx, edx
	ret

.getairports:
	mov eax,[airportaction3+eax*4]
	ret

.getObjects:
	// Retreive our setid and the action3
extern objectsgameiddata
	movzx edx, word [objectsgameiddata+eax*idf_gameid_data_size+idf_gameid_data.setid]
	mov eax, [objectsgameiddata+eax*idf_gameid_data_size+idf_gameid_data.act3info]
	ret

.invalidfeature:
	ud2	// another ud2 to distinguish it from the above by different address


uvard bridgecuractiontype

// find right entry in action 3
//
// in:	ecx->action3info struct
// out:	eax->right cargo type

grfcalltable getaction3cargo

.gettrains:
.getrvs:
.getships:
.getplanes:
	or ebx,byte -1
	test esi,esi
	jz .getcargo

#if 0
	movzx ebx,byte [climate]
	imul ebx,32
	add bl,[esi+veh.cargotype]
	mov bl,[cargotypes+ebx]
#endif
	movzx ebx,byte [esi+veh.cargotype]

.getcargo:
	movzx eax,word [ecx+action3info.cargo+ebx*2]
	test eax,eax
	jnz .foundit

.getcanals:
.gethouses:
.getindustiles:
.getindustries:
.getcargos:
.getairports:
.getsignals:
.default:
	movzx eax,word [ecx+action3info.defcid]
.foundit:
	ret

.getObjects:
	test esi, esi
	jnz .default

	movzx eax,word [ecx+action3info.nocargocid]
	test eax, eax
	jz .default
	ret
	
.getbridges:
	mov ebx, dword [bridgecuractiontype]
	movzx eax,word [ecx+action3info.cargo+ebx*2]
	test eax,eax
	jz .default
	ret

.stationdefault:
	movzx eax,word [ecx+action3info.nodefcargoid]
	test eax,eax		// if cargo type FE defined, prevent the default from being used
	je .default
	mov [curstationcargo],ebx	// if we get here, ebx is zero
	ret

.getstations:
	or ebx,byte -1
	test esi,esi
	jz .getcargo	// use default cargo

	mov eax,ebx

.nextstationcargo:
	inc eax
	cmp eax,NUMCARGOS
	jae .stationdefault	// no defined cargo type has cargo

	xor ebx,ebx

	cmp word [ecx+action3info.cargo+eax*2],0
	je .nextstationcargo

	testflags newcargos
	jc .hasnewcargos

	// mov bl,[cargoid+eax]
	mov ebx,[esi+station.cargos+eax*8+stationcargo.amount]
	and ebx,0xfff
	jnz .gotcargo
	jmp .nextstationcargo

.hasnewcargos:			//	eax	ebx	ecx	esi
				//	cargo#	---	org.ecx	station
	mov ebx,esi		//	cargo#	station	org.ecx	station
	mov esi,ecx		//	cargo#	station	org.ecx	org.ecx
	call ecxcargooffset	// in: eax=cargo# ebx->station; out: ecx=cargo ofs
				//	cargo#	station	offset	org.ecx
	xchg esi,ecx		//	cargo#	station	org.ecx	offset
	xchg ebx,esi		//	cargo#	offset	org.ecx	station

	cmp bl,0xff
	je .nextstationcargo

	movzx ebx,word [esi+station.cargos+ebx+stationcargo.amount]
	and ebx,[stationcargowaitingmask]
	jz .nextstationcargo

	cmp ebx,0x0fff
	jbe .gotcargo

	mov ebx,0x0fff

.gotcargo:
	mov [curstationcargo],ebx
	mov ax,[ecx+action3info.cargo+eax*2]
	ret

.getgeneric:
.getsounds:
	ud2

// process the final action 2 and return the sprite number
//
// in:	ebx->action 2 data
//	edx=direction to add to sprite
// out: eax=sprite number
//      ebx=adjusted direction to add to sprite (if necessary)
//	CF set if eax is not really a sprite number and should not be checked
//	   for being a callback result

grfcalltable getaction2spritenum

.getplanes:
	// see if direction is special (e.g. rotor)
	test dh,0x80
	jz .planesnotrotor

	// it's special, we only return the sprite base and the number of sprites
	//mov ax,[ebx+5]
	movzx eax, word [ebx+5]

	movzx cx,byte [_prespriteheader(ebx,actionfeaturedata+3)]

	lea bx,[ecx+1]
	// carry clear here
	ret

.gettrains:
.getrvs:
.getships:
.planesnotrotor:
	push edx

	movzx ecx,byte [_prespriteheader(ebx,actionfeaturedata+3)]
	push ecx	// store AND mask for later

	add ebx,3	// skip action, veh-type, and cargo-id(set-id)

	mov cl,[ebx]
	inc ebx

	test esi,esi
	jz .gotload

	movzx eax,word [esi+veh.engineidx]
	shl eax,vehicleshift
	add eax,[veharrayptr]
	cmp byte [eax+veh.totalorders],0
	je short .notloading

	mov al,byte [eax+veh.currorder]
	and al,0x1f

	cmp al,3
	jne short .notloading

	mov eax,ecx
	mov cl,[ebx]
	lea ebx,[ebx+2*eax]	// skip load states in motion

.notloading:
	movzx eax,word [esi+veh.currentload]
	mul ecx
	movzx ecx,word [esi+veh.capacity]
	inc ecx
	div ecx
	xchg eax,ecx

.gotload:		// if load info not available, use max. load
			// here, ebx points to <num-loadingtypes>
	lea ebx,[ebx+1+ecx*2]

.gotloadnum:
	movzx eax,word [ebx]
	pop ecx
	pop ebx
	and ebx,ecx	// apply AND mask for direction
	// carry clear here
	ret

.getstations:
	add ebx,3	// skip action, veh-type, and cargo-id

	movzx ecx,byte [ebx]
	inc ebx

	test esi,esi
	jz near .gotstatload

	mov eax,[curstationcargo]
	test eax,eax
	jns .notdefault

	// using default cargo (no cargo type match) -> add up total cargo waiting
	push ecx
	xor eax,eax
	xor edx,edx
.addnext:
	mov cx,[esi+station.cargos+edx*stationcargo_size+stationcargo.amount]
	and ecx,[stationcargowaitingmask]
	add eax,ecx
	cmp eax,0x0fff
	jb .notfull

	mov eax,0x0fff
	jmp short .arefull

.notfull:
	inc edx
	cmp edx,12
	jb .addnext
.arefull:
	pop ecx

.notdefault:
	mov edx,[curgrfid]
	test byte [stationflags+edx],2
	jz .notpertile

	push edx
	push ecx
	movzx ecx,byte [esi+station.platforms]
	call convertplatformsinecx
/*
	mov edx,ecx	// XXX when stat var 40+x cached, use var 49 here
	and cl,0x87
	and dl,0x78
	shr dl, 3
	cmp cl, 80h
	jb .istoosmall
	sub cl, (80h - 8h)
.istoosmall:
*/
	movzx edx, ch
	movzx ecx, cl
	//edx=len, ecx=tracks
	add ecx,edx
	xor edx,edx
	div ecx
	pop ecx
	pop edx

.notpertile:
	movzx edx,word [stationcargolots+edx*2]
	cmp eax,edx
	jb .notlots

	sub eax,edx
	neg edx
	add edx,4095

	push edx
	mov edx,ecx
	mov cl,[ebx]
	lea ebx,[ebx+2*edx]	// skip load states for little cargo
	pop edx

.notlots:
	xchg ecx,edx
	mul edx
	inc ecx
	div ecx
	xchg eax,ecx

.gotstatload:		// if load info not available, use max. load
			// here, ebx points to <num-loadingtypes>
	lea ebx,[ebx+1+ecx*2]
	movzx eax,word [ebx]
	clc
	ret
	

.getcanals:
.getcargos:
	movzx eax,word [ebx+5]
	mov ebx,edx
	add eax,ebx
	// carry clear here
	ret

.getbridges:
.gethouses:
.getindustiles:
.getairports:
.getObjects:
	//for houses and industry tiles, we return a pointer to the real data
	// in eax instead of a sprite number
	lea eax,[ebx+3]
	movzx ebx,byte [_prespriteheader(ebx,actionfeaturedata+3)]
	stc	// eax is not a sprite number
	ret

.getindustries:
	//industries can have a production data structure as a final action 2
	//return a pointer to it in eax
	lea eax,[ebx+3]
	stc
	ret

.getsignals:
	movzx eax,word [ebx+5]
	xor ebx, ebx
	// carry clear here
	ret

.getgeneric:
.getsounds:
	ud2

//
// get TTD sprite ID for new graphics
//
// in:	 ax=vehtype for vehicles, station sprite set for stations
//	 eax bit 31 set means generic feature callback
//	 bx=direction for vehicles
//	esi->vehicle/station struct or 0 if none available
//	[grffeature] must be set correctly
//
// out:	(for regular sprites)
//	ax=new sprite base
//	ebx&=dirmask for vehicles
//	all other registers preserved
// 	carry flag set and eax=0 on error (sprites not available, callback result)
//
//	(for callbacks)
//	eax=callback result, 0..7eff max
//	ebx preserved
//	carry flag set and eax=0 if callback failed (not a callback result)
//
//	(for houses)
//	eax-> building data
//	ebx=number of available sprites -1

extern newtransbits, newtransopts

global getnewsprite
getnewsprite:
#if !WINTTDX
	push es		// we need to set ES properly
	push ds
	pop es
#endif
	push edx
	push ecx
	push ebx

	// Because this is heavily used, the "testflags" is in the proc, not here.
ovar skiptransfix, 0
	jmp short .notrans	// With the next 4 bytes, this becomes mov ecx, [grffeature] if moretransopts on
// copy the appropriate transparency info into bits 4 and 6 of [displayoptions]. (6 for invisibility)
	dd grffeature
	mov edx, displayoptions
	movsx ecx, byte [newtransbits+ecx]
	test ecx, ecx
	js .notrans
	rcl byte [edx], 4
	bt [newtransopts], ecx
	cmc
	rcr byte [edx], 2
	bt [newtransopts+transopts.invis], ecx
	rcr byte [edx], 2
.notrans:
	mov [curgrfid],eax

#if MEASUREVAR40X
	or ecx,byte -1
	mov [tscvar],ecx
	call checktsc
#endif

	btr eax, 31
	mov ecx,[grffeature]
	sbb edx,edx	// -1 for generic (-> ignore feature), 0 for regular
	mov [curgrffeature],ecx
	or edx,ecx
	call [getaction3+edx*4]

#ifndef RELEASE
	cmp dword [grfdebug_active],0
	je .nodebug
	cmp byte [curcallback],2
	je .nodebug

	mov cl,[grfdebug_feature]
	cmp cl,-1
	je .gotfeature
	cmp cl,[grffeature]
	jne .nodebug
.gotfeature:
	mov cl,[grfdebug_id]
	cmp cl,-1
	je .gotid
	cmp cl,dl
	jne .nodebug
.gotid:
	mov ecx,[grfdebug_callback]
	cmp ecx,byte -1
	je .gotcb
	cmp ecx,[curcallback]
	jne .nodebug

.gotcb:
	mov byte [grfdebug_current],1
	mov ecx,[curcallback-2]		// set ecx(16:23)=callback
	mov cl,[grffeature]
	mov ch,dl
	or edx,byte -1
	test eax,eax
	jle .noact3
	mov edx,[eax+action3info.spriteblock]
	mov edx,[edx+spriteblock.grfid]
	xchg dl,dh
	rol edx,16
	xchg dl,dh
.noact3:
	param_call grfdebug_output, dword "GET ",ecx,edx

.nodebug:
#endif

	test eax,eax
	jle near .baddata

		// get spriteblock
.chain:
//	mov ecx,[eax-6]
	mov [curaction3info],eax
	mov edx,[eax+action3info.spriteblock]

	mov bl,[edx+spriteblock.version]
	mov [mostrecentgrfversion],bl

		// record file and sprite number for the crash logger
	mov ebx,[edx+spriteblock.filenameptr]
	mov [curgrffile],ebx

	mov ebx,[eax+action3info.spritenum]
	mov [curgrfsprite],ebx

		// also record the spriteblock for code following the getnewsprite call
	mov [mostrecentspriteblock],edx

	cmp byte [curcallback],2
	je near .baddata		// just set mostrecentspriteblock et al.

#if 0
		// skip numveh and vehids
	movzx ebx,byte [ecx+action3info.numveh]
	inc eax
	add eax,ebx
#endif

	// now eax-1 points to veh.ID=>cargo ID mapping
	// [eax]=number of cargo types
	// [eax+1+n*3]=cargo type	(n=0..num-1)
	// [eax+2+n*3]=cargo ID
	// [eax+1+num*3]=default ID
	//
#if 0
	movzx ecx,byte [eax]
	inc eax
	jecxz .gotcargo		// only the default; no others available
#endif
	xchg eax,ecx
	mov eax,[grffeature]
	mov ebx,eax
	and ebx,[grfvarfeature_set_and]
	add ebx,[grfvarfeature_set_add]
	mov [grfvarfeature],ebx
	call [getaction3cargo+eax*4]

//.gotcargo:
	xchg eax,ebx

	// now ebx = cargo ID sprite number
	//
	// follow randomized and variational cargo IDs until
	// we reach a real cargo ID
	//
.gotaction2:
#ifndef RELEASE
	cmp byte [grfdebug_current],0
	je .nosprdebug

	param_call grfdebug_output, dword "ACT2",ebx,0

.nosprdebug:
#endif

	mov eax,[edx+spriteblock.spritelist]
	mov ebx,[eax+ebx*4]
	mov eax,dword [_prespriteheader(ebx, spritenumber)]
	mov [curgrfsprite],eax

	mov al,[ebx+3]
	sub al,0x80
	jb .gotcargoid

	call getrandomorvariational
	test bh,bh			// got callback result?
	jns .gotaction2

.callbackresult:
#ifndef RELEASE
	cmp byte [grfdebug_current],0
	je .noresdebug

	param_call grfdebug_output, dword "RSLT",ebx,0

.noresdebug:
#endif

	cmp byte [curcallback],0	// was it really a callback?
	je .baddata

	btr ebx,16			// calculated callback results always use new-style
	jc .alwaysnewstyle

	add bh,1
	adc bh,-1			// map ff -> 00 (old style result)

.alwaysnewstyle:
	// got valid callback result
	xchg eax,ebx
	pop ebx
	and eax,0x7fff
	jmp short .done

.baddatacallback:
	// if callback fails, try to pass request on to previously installed callback
	mov eax,[curaction3info]
	mov eax,[eax+action3info.prev]
	test eax,eax
	jg .chain

.baddata:
	xor eax,eax
	pop ebx
	stc
	jmp short .return

.gotcargoid:
#if 0
	// got a non-variational/random cargo id
	// this is bad if it was a callback
	cmp byte [curcallback],0
	jne .baddatacallback
#endif

	pop edx
	push edx	// put back on stack so it can be popped by the callback code if necessary

	mov eax,[grffeature]
	call [getaction2spritenum+eax*4]
	jc .notspritenum

	// make sure it's a callback result if and only if we are in a callback
	xchg eax,ebx

	test bh,bh
	js .callbackresult

	xchg eax,ebx

.notspritenum:
	cmp byte [curcallback],0
	jne .baddatacallback

	pop ecx		// dummy pop to adjust stack

.done:
	clc

.return:
#if MEASUREVAR40X
	pushf
	mov ecx,[grffeature]
	or dword [tscvar],byte -1
	call checktsc
	popf
#endif
#ifndef RELEASE
	pushf
	cmp byte [grfdebug_current],0
	je .nooutdebug

	mov byte [grfdebug_current],0
	movzx ecx,ax
	param_call grfdebug_output, dword "SPRT",ecx,0

.nooutdebug:
	popf
#endif

	pop ecx
	pop edx
	mov dword [curgrffile],0	// for the crash logger (not AND to preserve carry flag)
	mov dword [curgrffeature],-1	// invalid feature, if not set will cause crash
#if !WINTTDX
	pop es
#endif
	ret
; endp getnewsprite


	// check whether a wagon has an override for this engine
	//
	// in:	eax=vehtype of wagon within class
	//	    (i.e. veh.vehtype-vehbase[class])
	//	ebx=vehtype of engine
	// out:	carry set if no override
	//	carry clear if override, then also eax->action3info struct
	// uses:ebx
	//
global checkoverride
checkoverride:
	mov ebx,[vehids+ebx*4]
	test ebx,ebx
	jle .nooverride		// engine has no special graphics

	mov ebx,[ebx+action3info.overrideptr]
	test ebx,ebx
	jle .nooverride

	mov eax,[ebx+eax*4]
	cmp eax,1
	ret

.nooverride:
	stc
	ret

#if 0
	movzx ecx,word [ebx+action3info.spritenum]
	mov edx,[ebx+action3info.spriteblock]
	mov bl,[ebx+action3info.numoverrides]
	xor bl,0x80
	js .nooverride		// no override for this engine

	// ok, so we have an override; the engine sprite number is
	// in ecx and the number of override action 3 entries is in bl

	push esi

	mov esi,[edx+spriteblock.spritelist]
	push edi
	push eax
	lea esi,[esi+ecx*4]
	mov edi,[esi]
	test edi,edi
	jle .isbad

	movzx edi,byte [edi+1]	// veh class
	sub al,[vehbase+edi]			// search for id in class

.trynextaction:
	add esi,4
	mov edi,[esi]
	test edi,edi
	jg .notbad

.isbad:
	pop eax
	pop edi
	pop esi

.nooverride:
	stc
	ret

.notbad:
	cmp byte [edi],3	// action 3?
	jne .trynextaction

	mov ecx, dword [_prespriteheader(edi, actionfeaturedata)]
	movzx ecx,byte [ecx+action3info.numveh]
	add edi,3

	repne scasb
	je .gotit

	dec bl
	jnz .trynextaction
	jmp .isbad

.gotit:
	pop eax
	mov eax,[esi]
	pop edi
	inc eax
	pop esi
	inc eax
	ret
#endif

uvard isother			// 0 if the action refers to the vehicle/tile/whatever, 1 if to the "other thing"

uvarb nostructvars		// 1 if in a callback that must not use 40+x or type 82/83
				// 2 if in a callback that may use 40+x/60+x with custom handler
uvard structvarcustomhnd	// handler for nostructvars=2

badaction2var:
	ud2

// handle random and/or variational set IDs
//
// in:	al=type-80
//	ebx=current sprite data
// out:	ebx=new sprite number; bit 16 set for calculated callback results
// safe:eax ecx edx
getrandomorvariational:
	push esi

	test al,2
	setnz [isother]
	jz .notother

	test esi,esi
	jz .noother

	cmp byte [nostructvars],0
	jne badaction2var

	mov ecx,[grfvarfeature]
	call [getother+ecx*4]

.noother:
	xor al,3		// change 2=>1, 3=>0, 6=>5

.notother:
	test al,1
	jnz near getvariational	// 81 or 82
	// jmp short getrandom	// 80 or 83

getrandom:	// random cargo ID
#if MEASUREVAR40X
	movzx ecx,byte [grffeature]
	or dword [tscvar],byte -1
	call checktsc
#endif

	push edx
	cmp al, 4
	jne .notother
	inc ebx
	cmp byte [grffeature], al	// al == 4
	jnb .notother
	xor eax, eax
	test esi, esi
	jz near .gotrandom

	mov al, [ebx+3]
	movzx ecx, al
	and ecx, 0x3F
	jnz .gotcount
	mov ecx, [specialgrfregisters]
.gotcount:
	and al, 0xC0
	jz short .countback	// 0x
	cmp al, 0x80
	je .engine		// 8x

	mov edx, [esi+veh.veh2ptr]
	ja .firstoftype		// Cx

.selffront:		// 4x. Count back from engine by trainidx - count
	movzx edx, byte [edx+veh2.var40x+0*4]
	sub ecx, edx
	neg ecx
	jmp short .engine

.firstoftype:		// Count back from engine by firstoftype_idx + count
	push ecx	// firstoftype_idx == trainidx - bytypeidx
	movzx ecx, byte [edx+veh2.var40x+0*4]
	sub cl, [edx+veh2.var40x+1*4]
	pop edx
	add ecx, edx

.engine:		// Count back from engine by count
	cvivp [esi+veh.engineidx]

.countback:
	jecxz .gotother
	mov edx, [veharrayptr]
	xor eax, eax
.docount:
	movzx esi, word [esi+veh.nextunitidx]
	cmp si, byte -1
	je .gotrandom
	shl esi, vehicleshift
	add esi, edx
	loop .docount
	jmp short .gotother

.notother:
	xor eax,eax
	test esi,esi
	jz .gotrandom

.gotother:
	movzx edx,byte [isother]

	mov cl,[ebx+5]

	// check which bits (if any) trigger from the current event
	mov al,[ebx+4]
	mov ah,al
	and al,[curtriggers]
	jz .nottriggeredyet	// no matching random triggers

	test ah,ah
	jns .anytrigger

	and ah,0x7f
	cmp ah,al
	jne .nottriggeredyet

.anytrigger:
	or [acttriggers],al
	movzx eax,byte [ebx+6]	// bit mask -> bits for this trigger
	shl eax,cl
	or [triggerbits],eax
	or [septriggerbits+4*edx],eax

.nottriggeredyet:
	mov eax,[grfvarfeature]
	call [getrandombits+eax*4]
#ifndef RELEASE
	mov edx,eax
#endif
	shr eax,cl
	movzx eax,al
	and al,[ebx+6]
.gotrandom:
#ifndef RELEASE
	cmp byte [grfdebug_current],0
	je .nornddebug

	param_call grfdebug_output, dword "RND ",edx,eax

.nornddebug:
#endif
	movzx ebx,word [ebx+7+eax*2]
	pop edx
	pop esi

#if MEASUREVAR40X
	mov ecx,8*2
	mov dword [tscvar],1
	call checktsc
	or dword [tscvar],byte -1
#endif
	ret


// get random bits
//
// in:	eax=0
//	ebx->action 2 data
//	ecx=grf feature
//	esi->feature struct
// out:	eax=random bits
// safe:ecx(8:31)
grfcalltable getrandombits

.gettrains:
.getrvs:
.getships:
.getplanes:
	mov al,[esi+veh.random]
	ret

.getstations:
	mov eax,[curstationtile]
//	add eax,[landscape6ptr]
	mov eax,[landscape6+eax]
	and eax,0x0f
	shl eax,16
	mov ax,[esi+station.random]
	ret

.getcanals:
	mov al, [esi+3]	// esi = canalaction2array
	ret
.getbridges:
.getgeneric:
.getcargos:
.norandom:
.getsounds:
.getairports:
.getsignals:
	ret

.gethouses:
	cmp byte [isother],0
	jnz .norandom
//	mov eax,[landscape6ptr]		// house random bits are in L6
	movzx eax,byte [landscape6+esi]
	ret

.getindustiles:
	cmp byte [isother],0
	jnz .industry
//	mov eax,[landscape6ptr]		// industry tile random bits are in L6
	movzx eax,byte [landscape6+esi]
	ret

.getindustries:
	cmp byte [isother],0
	jnz .norandom
.industry:
	movzx eax,word [esi+industry.random]
	ret

.getObjects:
	cmp byte [isother], 0
	jnz .norandom
	movzx eax, byte [landscape6+esi] // Bits are in L6
	ret

grfcalltable getrandomtriggers

.gettrains:
.getrvs:
.getships:
.getplanes:
	mov al,[esi+veh.newrandom]
	ret

.getstations:
	cmp byte [isother],0
	jnz .norandom
	mov al,[esi+station.newrandom]
	ret

.getsignals:
	ret
.getcanals:
	//mov al, [esi+3]	// esi = canalaction2array
.getbridges:
.getgeneric:
.getindustries:
.getcargos:
.norandom:
.getsounds:
.getairports:
.getObjects:
	ret

.gethouses:
	cmp byte [isother],0
	jnz .norandom
	mov al,[landscape3+esi*2]
	shr al,6
	ret

.getindustiles:
	cmp byte [isother],0
	jnz .norandom
	mov al,[landscape7+esi]
	ret

getvariationalvariable:
	movzx eax,byte [ebx]	// variable
	test al,0xc0
	js .structvar		// 80+x
	jz near .externalvar	// x

	bt eax,5		// check for 60+x variable
	adc ebx,0		// advance ebx if it is one
	mov cl,[ebx]		// cl will contain 60+x parameter (or var.num otherwise)

	cmp al,0x7b		// for 7B we need to retrieve the 'real variable' from cl
	jne .noindirect
	mov al,cl
	mov cl,[variationalparameter]

.noindirect:
	cmp al, 0x7D
	jae .paramvar		// 7D, 7E, 7F are always available, with or without structure, special handler, or anything else.

	test esi,esi
	jz .checkvaravail

	cmp byte [nostructvars],1
	je badaction2var
	ja .custom

.usevar:
	test al,0x20		// check for 0x6x variables
	jnz .paramvar

	call getspecialvar	// 40+x
	jmp short .gotval

.custom:
	// call custom var 40+x/60+x handler
	// in:	eax=var
	//	cl=parameter for 60+x
	//	esi->80+x data or 0 if none
	// out:	eax=var value
	//	CF=0 var was ok
	//	CF=1 invalid variable
	// safe:ecx
	call [structvarcustomhnd]
	jc badaction2var
	jmp short .gotval

.checkvaravail:			// variable available even without structure?
	movzx esi,byte [grfvarfeature]
	add esi,esi
	add esi,[isother]
	bt [varavailability-0x40/8+esi*8],eax
	mov esi,0		// restore esi without affecting flags
	jc .usevar
	jmp short .novar

.paramvar:			// 60+x
	call getspecparamvar
	jmp short .gotval

.structvar:			// 80+x
	test esi,esi
	jz .novar

	movzx ecx,byte [grfvarfeature]
	shl ecx,1
	add cl,[isother]
	add al,[featurevarofs+ecx]

	mov eax,[esi+eax]
	jmp short .gotval

.novar:
	stc
	ret

.externalvar:
	cmp eax,numextvars
	jae .gotval

	mov eax,[externalvars+eax*4]
	call getglobalvar

.gotval:
	mov cl,[ebx+1]		// shiftnum
	mov dh,cl
	and cl,0x1f
#ifdef RELEASE
	shr eax,cl	// we save 10 code bytes by doing this here
#endif
	clc
	ret

%define SIZE_0 byte
%define SIZE_1 word
%define SIZE_2 dword

%macro auto_size 3
	%rotate SIZEIND
	%1
%endmacro

%macro make_var_adjust 1
#ifndef RELEASE
	push ebp
	mov ebp,eax
	shr eax,cl
#endif
	auto_size {and al,[ebx+2]}, {and ax,[ebx+2]}, {and eax,[ebx+2]}
	auto_size {add ebx,3}, {add ebx,4}, {add ebx,6}

	test dh,0xc0
	jz %%gotvaladjust

	auto_size {add al,[ebx]}, {add ax,[ebx]}, {add eax,[ebx]}

	auto_size {}, {push edx}, {push edx}
	auto_size {cbw}, {cwd}, {cdq}

	auto_size {mov cl,[ebx+1]}, {mov cx,[ebx+2]}, {mov ecx,[ebx+4]}
	auto_size {cmp cl,1}, {cmp cx, BYTE 1}, {cmp ecx, BYTE 1}
	jbe %%nodiv
	auto_size {idiv cl}, {idiv cx}, {idiv ecx}
%%nodiv:
	auto_size {}, {mov ecx,edx}, {mov ecx,edx}
	auto_size {}, {pop edx}, {pop edx}
	auto_size {add ebx,2}, {add ebx,4}, {add ebx,8}

	test dh,0x40
	jnz %%gotvaladjust

	auto_size {mov al,ah}, {mov ax,cx}, {mov eax,ecx}	// get remainder

%%gotvaladjust:
#ifndef RELEASE
	cmp byte [grfdebug_current],0
	je %%novaldebug

	param_call grfdebug_output, dword "VAR ",ebp,eax

%%novaldebug:
	pop ebp
#endif
%endmacro

%macro makevaract2handler 1
	%define SIZEIND %1
	%define SIZE SIZE_%1

	add ebx,4

	call getvariationalvariable
	jc errorinvar

	make_var_adjust %1

	test dh,0x20
	jnz .nextvar
	jmp near .gotval	// could do jz .nextvar, but this is better for the BPL

.nextvar:
	push eax
	mov [variationalparameter], al
	movzx ebp,byte [ebx]
	inc ebx
	call getvariationalvariable
	jc .error_pop
	make_var_adjust %1
	mov ecx,eax
	pop eax
	call [addr(calcoperators)+ebp*4]
	test dh,0x20
	jnz .nextvar
	jmp short .gotval

.error_pop:
	pop eax
	jmp errorinvar

.gotval:
// now, before comparing, we should simulate overflowing again, but with the high
// bits being zeroed, so for ex. 0xFFFFFFF8 becomes 0xF8 and can be compared to
// other bytes in an unsigned manner

	auto_size {movzx eax,al}, {movzx eax,ax}, {}

	mov [lastcalcresult],eax	// store for next var.action 2 in chain

	mov dh,[ebx]		// number of ranges
	inc ebx

	test dh,dh
	jz .callback		// no ranges -> return as callback result

.nextrange:
	auto_size {cmp al,[ebx+2]}, {cmp ax,[ebx+2]}, {cmp eax,[ebx+2]}
	jb .toolow
	auto_size {cmp al,[ebx+3]}, {cmp ax,[ebx+4]}, {cmp eax,[ebx+6]}
	jna .gotrange

.toolow:
.toohigh:
	auto_size {add ebx,4}, {add ebx,6}, {add ebx,10}
	dec dh
	jnz .nextrange

.gotrange:
	movzx ebx,word [ebx]
.gotvalue:
	pop ebp
	pop edx
	pop esi

#if MEASUREVAR40X
	mov ecx,8*2
	mov dword [tscvar],0
	call checktsc
	or dword [tscvar],byte -1
#endif

	ret

.callback:
	movzx ebx,ax
	or bh,0x80
	bts ebx,16
	jmp .gotvalue

%endmacro

// In: ebx->param for failed 60+x vars, ->var for other vars
//	dl: size
errorinvar:
	movzx ecx,dl
.next:
	mov dh,[ebx+1]			// shift
	test dh,0xc0
	lea ebx,[ebx+2+ecx+1]		// skip var, shift, mask, (nvar or oper)
	jz .notdivmod
	lea ebx,[ebx+2*ecx]		// skip add-val and div/mod-val
.notdivmod:				// ebx -> first range or next var
	test dh,0x20
	jz .gotrange
	mov dh,[ebx]			// var
	and dh,0xe0
	cmp dh,0x60
	jne .next
	inc ebx
	jmp short .next

.gotrange:
	movzx ebx,word [ebx]
	pop ebp
	pop edx
	pop esi
	ret

getvariational:
	// find variational cargo ID from list
	// in:	ebx=variation cargo ID definition
	//	esi=struct or 0 if none
	// out:	ebx=new cargo ID sprite number
	// safe:eax ebx ecx

#if MEASUREVAR40X
	movzx ecx,byte [grffeature]
	or dword [tscvar],byte -1
	call checktsc
#endif

	push edx
	push ebp

	// first find out which size we are working with, and save it to dl
	// type & 0C: 0 = byte, 4 = word, 8 = dword
	movzx edx,byte [ebx+3]
	and edx,0x0C
	jmp [.sizehandlers+edx]

noglobal vard .sizehandlers, bytesize,wordsize,dwordsize

bytesize:
	mov dl,1
	makevaract2handler 0

wordsize:
	mov dl,2
	makevaract2handler 1

dwordsize:
	mov dl,4
	makevaract2handler 2

vard calcoperators
	dd addr(.add),addr(.sub),addr(.signed_min),addr(.signed_max),addr(.unsigned_min),addr(.unsigned_max)
	dd addr(.signed_divmod),addr(.signed_divmod),addr(.unsigned_divmod),addr(.unsigned_divmod)
	dd addr(.multiply),addr(.and),addr(.or),addr(.xor),addr(.storevar),addr(.copy),addr(.storepers)
	dd addr(.rotater),.signed_cmp,.unsigned_cmp
	dd .shiftl
	dd .unsigned_shiftr
	dd .signed_shiftr
numcalcoperators equ ($-calcoperators)/4

endvar

.add:
	add eax,ecx
	ret

.sub:
	sub eax,ecx
	ret

.and:
	and eax,ecx
	ret

.or:
	or eax,ecx
	ret

.xor:
	xor eax,ecx
	ret

.multiply:
// we can get away with a single imul without size checks becouse of two things:
// -	when multiplying two n-bit numbers, the lowest n bits of the result will be the
//	same for signed and unsigned multiplication
// -	when multiplying numbers xxxxa and yyyyb, the lowest digit of the result will
//	be a*b if it fits in a single digit

	imul eax,ecx
	ret

.make_eax_signed:
	cmp dl,2
	je .make_eax_word_signed
	ja .exit

	movsx eax,al
.exit:
	ret

.make_eax_word_signed:
	movsx eax,ax
	ret

.make_eax_unsigned:
	cmp dl,2
	je .make_eax_word_unsigned
	ja .exit

	movzx eax,al
	ret

.make_eax_word_unsigned:
	movzx eax,ax
	ret

.make_eax_ecx_signed:
	xchg ecx,eax
	call .make_eax_signed
	xchg ecx,eax
	jmp short .make_eax_signed
	
.make_eax_ecx_unsigned:
	xchg ecx,eax
	call .make_eax_unsigned
	xchg ecx,eax
	jmp short .make_eax_unsigned

.signed_min:
	call .make_eax_ecx_signed

	cmp eax,ecx
	jl .exit
	mov eax,ecx
	ret

.signed_max:
	call .make_eax_ecx_signed

	cmp eax,ecx
	jg .exit
	mov eax,ecx
	ret

.unsigned_min:
	call .make_eax_ecx_unsigned

	cmp eax,ecx
	jb .exit
	mov eax,ecx
	ret

.unsigned_max:
	call .make_eax_ecx_unsigned

	cmp eax,ecx
	ja .exit
	mov eax,ecx
	ret

.signed_divmod:
	call .make_eax_ecx_signed

	push edx
	cdq
	or ecx,ecx
	jz .no_signed_divmod
	idiv ecx
.no_signed_divmod:

	cmp ebp,6
	je .notsmod

	mov eax,edx
.notsmod:
	pop edx
	ret

.unsigned_divmod:
	call .make_eax_ecx_unsigned

	push edx
	xor edx,edx
	or ecx,ecx
	jz .no_unsigned_divmod
	div ecx
.no_unsigned_divmod:

	cmp ebp,8
	je .notunsmod

	mov eax,edx
.notunsmod:
	pop edx
	ret

.storevar:
	call .make_eax_signed
	xchg eax,ecx
	call .make_eax_unsigned
	cmp eax,NUMGRFREGISTERS
	jae .notgood
	mov [advvaraction2varbuff+eax*4], ecx
.notgood:
	// fallthrough to .copy

.copy:
	mov eax, ecx
	ret

.storepers:
	test esi,esi
	jz .badstore
	call .make_eax_signed
	xchg eax,ecx
	call .make_eax_unsigned
	xchg eax,ecx
	movzx ebp, byte [grffeature]
	jmp [writepersistentreg+ebp*4]

.badstore:
	ud2

.rotater:
	ror eax, cl
	ret

.signed_cmp:
	call .make_eax_ecx_signed
	cmp eax,ecx
	jg .cmp_above
	sete al			// 0 for less, 1 for equals
	movzx eax,al
	ret

.unsigned_cmp:
	call .make_eax_ecx_unsigned
	cmp eax,ecx
	ja .cmp_above
	sete al			// 0 for below, 1 for equals
	movzx eax,al
	ret

.cmp_above:
	mov eax,2
	ret

.shiftl:
	shl eax, cl
	ret

.unsigned_shiftr:
	call .make_eax_unsigned
	shr eax, cl
	ret

.signed_shiftr:
	call .make_eax_signed
	sar eax, cl
	ret

uvard lastcalcresult
uvarb variationalparameter

// get the "other" variable for random 83 or variational 82
// in:	esi=vehicle/station
//	ecx=grf feature
// out:	esi=other variable
// safe:ecx edx
grfcalltable getother

.gettrains:
.getrvs:
.getships:
.getplanes:
	movzx esi,word [esi+veh.engineidx]
	shl esi,vehicleshift
	add esi,[veharrayptr]
	ret

.getstations:
.getairports:
	mov esi,[esi+station.townptr]
	ret

.getcanals:
.getgeneric:
.getcargos:
.getsounds:
.getsignals:
	ret

.getbridges:
	mov esi, [esi]
	jmp short .gethouses_nopush
.gethouses:
	pusha
.gethouses_nopush:
	mov ebp,[ophandler+(3*8)]
	xor ebx,ebx
	mov bl,1
	mov eax,esi
	call dword [ebp+4]
	mov [esp+4],edi		// will be popped to esi
	popa
	ret

.getindustiles:
	movzx esi,byte [landscape2+esi]
	imul esi,industry_size
	add esi,[industryarrayptr]
	ret

.getindustries:
	mov esi,[esi+industry.townptr]
	ret

.getObjects:
	movzx esi, word [landscape3+esi*2]
	extern objectpool
	imul esi, object_size
	mov esi, dword [objectpool+esi+object.townptr]
	ret

#if MEASUREVAR40X
	// this measures the number of CPU ticks spent for calculating
	// each feature's 40+x in total, compared to the rest of the game
uvard tscvalid
uvard lasttsc,2
uvard tscvar

uvard tscdatabegin,0

#define NUMCALLBACKS 0x36
uvard numtscfeat
uvard numtsccb
uvard numticks,((NUMFEATURES+1)*2)*2
uvard numcalls,(NUMFEATURES+1)*2
uvard cbticks,NUMCALLBACKS*2
uvard varticks,NUMFEATURES*0x40*2
uvard numcb,NUMCALLBACKS
uvard numvar,NUMFEATURES*0x40

uvard tscdataend,0

// benchmarking tool, to enable recompile patches/newsprit and patches/loadsave
// with make DEFS='MEASUREVAR40X=1'
//
// in:	1) ecx=-1 to start counter
//	2) ecx=2*feature to record+isother
//	   [tscvar] grf variable being measured (-1 if none), 
//		ignores variables other than 40+x, 60+x
//	   [callback] current callback (0 if none)
// uses ecx
checktsc:
	push eax
	push ebx
	push edx

	cpu 586
	rdtsc
	cpu 386

	bts dword [tscvalid],0
	jc .wasvalid

	mov [lasttsc],eax
	mov [lasttsc+4],edx

.wasvalid:
	xchg eax,[lasttsc]
	xchg edx,[lasttsc+4]

	sub eax,[lasttsc]
	sbb edx,[lasttsc+4]

	cmp dword [tscvar],0
	jns .isvar

	sub [numticks+(ecx+1)*8],eax
	sbb [numticks+(ecx+1)*8+4],edx

	inc dword [numcalls+(ecx+1)*4]

	test ecx,ecx
	js .done

	mov ebx,[curcallback]

	sub [cbticks+ebx*8],eax
	sbb [cbticks+4+ebx*8],edx
	inc dword [numcb+ebx*4]
	jmp short .done

.isvar:
	shrd ebx,ecx,32-5
	js .done

	and ebx,byte ~0x3f	// ebx = ecx/2 * 0x40
	add ebx,[tscvar]

	sub [varticks+ebx*8],eax
	sbb [varticks+ebx*8+4],edx
	inc dword [numvar+ebx*4]

.done:
	pop edx
	pop ebx
	pop eax
	ret

var tscname, db "tsc_####.dat",0
uvard tscdumpnum

exported savevar40x
	pusha
	cmp dword [tscvalid],0
	je near .fail
	mov dword [numtscfeat],NUMFEATURES
	mov dword [numtsccb],NUMCALLBACKS
.nextnum:
	mov eax,[tscdumpnum]
	inc dword [tscdumpnum]
	cmp eax,0xffff
	ja .fail

	mov ecx,eax
	and ecx,0x0f0f
	shr eax,4
	and eax,0x0f0f

	mov edx,tscname
	mov ebx,hexdigits
	xlatb
	mov [edx+4+2],al
	mov al,ah
	xlatb
	mov [edx+4+0],al
	mov al,cl
	xlatb
	mov [edx+4+3],al
	mov al,ch
	xlatb
	mov [edx+4+1],al

	mov ax,0x3c00
	xor ecx,ecx
	CALLINT21
	jc .nextnum

	mov ebx,eax
	mov ax,0x4000
	mov edx,tscdatabegin
	mov cx,tscdataend - tscdatabegin
	CALLINT21

	mov ax,0x3e00
	CALLINT21

.fail:
	mov edi,tscvalid
	mov ecx,(tscdataend-tscvalid)/4
	xor eax,eax
	rep stosd
	popa
	ret
#endif

// get the value for a global variable
// in:	eax-> variable or function
// out:	eax: value
exported getglobalvar
	btr eax,31
	jnc .notcalculated
	jmp eax
.notcalculated:
	mov eax, [eax]
	ret

// get special variable for variational sprites
//
// in:	eax=special variable (+0x40)
//	esi=struct or 0 if none
// out:	eax=variable content
// safe:ecx
getspecialvar:
	sub eax,0x40
	movzx ecx,byte [grfvarfeature]
	cmp al,0x1f
	je .getrandomdata

	shl ecx,1
	add cl,[isother]
	cmp al,[specialvars+ecx]
	jae .done

#if MEASUREVAR40X
	push ecx
	mov ecx,8*2
	mov dword [tscvar],0
	call checktsc
	mov [tscvar],eax
	mov ecx,[esp]
#else
	cmp cl,4*2
	jb .specialvehvar	// special case because veh vars are cached
//	je .specialstatvar	// so are station variables (soon)
#endif

	mov ecx,[specialvarhandlertable+ecx*4]
	call [ecx+eax*4]

#if MEASUREVAR40X
	pop ecx
	call checktsc
	or dword [tscvar],byte -1
#endif

.done:
	ret

.specialvehvar:
	bt [cachevehvar40x],eax
	jnc .notcached
	test esi,esi
	jz .notcached

	mov ecx,[esi+veh.veh2ptr]
	mov eax,[ecx+veh2.var40x+eax*4]
	ret

.notcached:
	call [vehvarhandler+eax*4]
	ret

.getrandomdata:
	xor eax,eax
	call [getrandombits+ecx*4]
	shl eax,8
	jmp [getrandomtriggers+ecx*4]

// get special parametrized variable for variational sprites
//
// in:	eax=special variable
//	ebx->var.action 2 variable data (i.e. the bytes <var=60+eax> <param=cl>)
//	cl=parameter
//	esi->struct
// out:	eax=variable content
// safe: ecx
getspecparamvar:
	sub eax,0x60
	cmp al,0x1e
	je .grffncall
	ja .grfparam
	cmp al,0x1C
	je .persistentreg
	ja .varbuff

	mov ah,cl
	movzx ecx,byte [grfvarfeature]
	shl ecx,1
	add cl,[isother]
	cmp al,[specialparamvars+ecx]
	jae .done

	push eax
	movzx eax,al

#if MEASUREVAR40X
	push ecx
	mov ecx,8*2
	mov dword [tscvar],0
	call checktsc
	lea ecx,[eax+020]
	mov [tscvar],ecx
	mov ecx,[esp]
#endif
	mov ecx,[specialparamvarhandlertable+ecx*4]
	mov ecx,[ecx+eax*4]
	pop eax
	call ecx
#if MEASUREVAR40X
	pop ecx
	call checktsc
	or dword [tscvar],byte -1
#endif

.done:
	ret

.persistentreg:
	movzx eax, byte [grfvarfeature]
	movzx ecx,cl
	jmp [readpersistentreg+eax*4]

.varbuff:
	movzx ecx, cl
	mov eax, [advvaraction2varbuff+ecx*4]
	ret

.grfparam:
	movzx ecx,cl
	mov eax,[mostrecentspriteblock]
	cmp cl,[eax+spriteblock.numparam]
	jae .noparam
	mov eax,[eax+spriteblock.paramptr]
	mov eax,[eax+ecx*4]
	ret

.noparam:
	xor eax,eax
	ret

.grffncall:
	push ebx
	mov ebx,[curgrfsprite]
	push ebx
	movzx ebx,bx
	push edx
	push dword [isother]
	mov edx,[mostrecentspriteblock]
	mov eax,[edx+spriteblock.spritelist]
	mov ebx,[eax+(ebx-1)*4]		// ebx is one too high
	mov ebx, dword [_prespriteheader(ebx, actionfeaturedata)]			// read offset to var.action 2 copy with resolved procedure sprite numbers
	add ebx,[esp+12]
	movzx ebx,word [ebx-1]

.gotaction2:
	mov eax,[edx+spriteblock.spritelist]
	mov ebx,[eax+ebx*4]
	mov eax, dword [_prespriteheader(ebx, spritenumber)]
	mov [curgrfsprite],eax

	mov al,[ebx+3]
	sub al,0x80
	jae .validaction2			// action 2 is a valid random / variational one

	mov ebx, 0xffff 			// use 0xffff as value for invalid callback result
	jmp short .gotretvalue

.validaction2:
	call getrandomorvariational
	test bh,bh			// got callback result?
	jns .gotaction2
	and ebx,0x7fff

.gotretvalue:
	mov eax,ebx
	pop dword [isother]
	pop edx
	pop dword [curgrfsprite]
	pop ebx
	ret

// in:	ecx: register number
// out:	eax: value of register
grfcalltable readpersistentreg

.gettrains:
.getrvs:
.getships:
.getplanes:
.getstations:
.getairports:
.getcanals:
.getbridges:
.getgeneric:
.getcargos:
.getsounds:
.getsignals:
.gethouses:
.gettowns:
.getObjects:
	ud2		// not supported yet

.getindustiles:
	cmp byte [isother],0
	jnz .getindustries_nocheck
	ud2		// not supported for tiles, just for industries

extern industry2arrayptr

.getindustries:
	cmp byte [isother],0
	jnz .gettowns
.getindustries_nocheck:
	cmp ecx,GRFPERSISTENTINDUREGS
	jae .bad
	mov eax,esi
	sub eax,[industryarrayptr]
	add eax,eax

	add eax,[industry2arrayptr]
	// now eax points to the industry2 slot
	mov eax,[eax+industry2.grfpersistent+ecx*4]
	ret

.bad:
	xor eax,eax
	ret

// in:	eax: value to store
//	ecx: number of register
// out:	eax: value to store, unchanged
// safe: ebp
grfcalltable writepersistentreg

.gettrains:
.getrvs:
.getships:
.getplanes:
.getstations:
.getairports:
.getcanals:
.getbridges:
.getgeneric:
.getcargos:
.getsounds:
.getsignals:
.gethouses:
.gettowns:
.getObjects:
	ud2		// not supported yet

.getindustiles:
	cmp byte [isother],0
	jnz .getindustries_nocheck
	ud2		// not supported for tiles, just for industries

.getindustries:
	cmp byte [isother],0
	jnz .gettowns
.getindustries_nocheck:
	cmp ecx,GRFPERSISTENTINDUREGS
	jae .bad
	mov ebp,esi
	sub ebp,[industryarrayptr]
	add ebp,ebp
	add ebp,[industry2arrayptr]
	// now ebp points to the industry2 slot
	mov [ebp+industry2.grfpersistent+ecx*4],eax
.bad:
	ret

#ifndef RELEASE
proc grfdebug_output
	arg text,val1,val2

	noglobal varb .output, "XXXX ######## ########",13,10,0

	_enter
	pusha

	mov eax,[%$text]
	mov [.output],eax
	mov eax,[%$val1]
	lea edi,[.output+5]
	extern hexnibbles
	mov cl,8
	call hexnibbles
	mov eax,[%$val2]
	inc edi
	mov cl,8
	call hexnibbles

	mov ah,0x40
	mov bx,[grfdebug_active]
	mov ecx,24
	mov edx,.output
	CALLINT21

	popa
	_ret
endproc
#endif



// The following tables have two entries per feature, the first for the default thing, the second for "the other"

	// offsets into the base struc ptr to the place where the
	// variational variables start, for each feature
varb featurevarofs
	db -0x80, -0x80		// four vehicle types; the "other thing" is a vehicle as well
	db -0x80, -0x80
	db -0x80, -0x80
	db -0x80, -0x80
	db -0x80+0x10, -0x80	// stations: skip up to .platforms for the station structure; don't do this with the town struc
	db -0x80, 0		// canals don't have "other things"
	db -0x80, -0x80		// bridges (currently only have a other thing - a town struc)
	db 0, -0x80		// houses; they don't have a normal struc, but have a town struc for "the other thing"
	db 0, 0			// generic callbacks don't use action 2
	db 0, -0x80		// industry tiles are like houses, but "the other thing" is an industry struc
	db -0x80, -0x80		// industry struc; town struc
	db 0, 0			// cargos don't have structures
	db 0, 0			// sounds neither
	db -0x80+0x10, -0x80	// airports: same as stations
	db 0,0			// signals: no structures
	db 0, -0x80		// objects: current tile, northen tile
checkfeaturesize featurevarofs, 2

endvar

	// bit mask of 40+x and 60+x variables available for each feature
	// even without a structure; once for 81+x and once for 82+x
	// (all 60+x must set bit 15, which is special!)
vard varavailability
	dd 100001000b,7<<29,		100001000b,7<<29	// veh.vars 43, 48
	dd 100001000b,7<<29,		100001000b,7<<29	// veh.vars 43, 48
	dd 100001000b,7<<29,		100001000b,7<<29	// veh.vars 43, 48
	dd 100001000b,7<<29,		100001000b,7<<29	// veh.vars 43, 48
	dd 1000b,7<<29|10000000b,	0,7<<29			// station var 43 and 67, towns
	dd 0,7<<29,			0,7<<29			// canals
	dd 0,7<<29,			0,7<<29			// bridges
	dd 0,7<<29,			0,7<<29			// houses, bridges
	dd 0,7<<29,			0,7<<29			// generic variables
	dd 0,7<<29,			0,7<<29			// industry tiles, industries
	dd 0,7<<29,			0,7<<29			// industries, towns
	dd 0,7<<29,			0,7<<29			// cargos
	dd 0,7<<29,			0,7<<29			// sounds
	dd 0,7<<29,			0,7<<29			// airports
	dd 0,7<<29,			0,7<<29			// signals
	dd 101110011b,7<<29|10101b,			0,7<<29			// objects

checkfeaturesize varavailability, (4*2*2)

endvar

extern getyearbuilt
	// list of handlers for each variable
vard vehvarhandler
	dd addr(getvehnuminconsist)
	dd addr(getvehnuminrow)
	dd addr(getconsistcargo)
	dd addr(getplayerinfo)
	dd addr(getaircraftinfo)
	dd addr(getcurveinfo)
	dd addr(getmotioninfo)
	dd addr(getvehiclecargo)
	dd addr(getvehtypeflags)
	dd getyearbuilt
%ifndef PREPROCESSONLY
%assign n_vehvarhandler (addr($)-vehvarhandler)/4
%endif
endvar

vard vehparamvarhandler
	dd addr(getvehidcount)
%ifndef PREPROCESSONLY
%assign n_vehparamvarhandler (addr($)-vehparamvarhandler)/4
%endif
endvar


vard stationvarhandler
	dd addr(getplatforminfo)
	dd addr(getstationsectioninfo)
	dd addr(getstationterrain)
	dd addr(getplayerinfo)
	dd addr(getstationpbsstate)
	dd addr(gettrackcont)
	dd addr(getplatformmiddle)
	dd addr(getstationsectionmiddle)
	dd addr(getstationacceptedcargos)
	dd addr(getplatformdirinfo)
	dd addr(getstationanimframe)
%ifndef PREPROCESSONLY
%assign n_stationvarhandler (addr($)-stationvarhandler)/4
%endif
endvar

extern getstationlandslope,getotherstationid

vard stationparamvarhandler
	dd addr(getcargowaiting)
	dd addr(getcargotimesincevisit)
	dd addr(getcargorating)
	dd addr(getcargoenroutetime)
	dd addr(getcargolastvehdata)
	dd addr(getcargoacceptdata)
	dd addr(getnearbystationanimframe)
	dd getstationlandslope
	dd getotherstationid
%ifndef PREPROCESSONLY
%assign n_stationparamvarhandler (addr($)-stationparamvarhandler)/4
%endif
endvar

vard canalsvarhandler
%ifndef PREPROCESSONLY
%assign n_canalsvarhandler (addr($)-canalsvarhandler)/4
%endif
endvar

vard canalsparamvarhandler
%ifndef PREPROCESSONLY
%assign n_canalsparamvarhandler (addr($)-canalsparamvarhandler)/4
%endif
endvar

extern getbridgeage, gettileterrainbridge
vard bridgevarhandler
	dd getbridgeage
	dd gettileterrainbridge
%ifndef PREPROCESSONLY
%assign n_bridgevarhandler (addr($)-bridgevarhandler)/4
%endif
endvar

vard bridgeparamvarhandler
%ifndef PREPROCESSONLY
%assign n_bridgeparamvarhandler (addr($)-bridgeparamvarhandler)/4
%endif
endvar

extern gethouseXY
vard housesvarhandler
	dd addr(gethousebuildstate)
	dd addr(gethouseage)
	dd addr(gethousezone)
	dd addr(gettileterrain)
	dd addr(gethousecount)
	dd addr(getexpandstate)
	dd addr(gethouseanimframe)
	dd gethouseXY
%ifndef PREPROCESSONLY
%assign n_housesvarhandler (addr($)-housesvarhandler)/4
%endif
endvar

extern getotherhouseanimframe,gethouseaccepthistory,getnearesthousedist
extern getnearbyhouseidandclass,getnearbyhousegrfid
vard housesparamvarhandler
	dd addr(getotherhousecount)
	dd addr(getothernewhousecount)
	dd addr(getindustilelandslope)
	dd getotherhouseanimframe
	dd gethouseaccepthistory
	dd getnearesthousedist
	dd getnearbyhouseidandclass
	dd getnearbyhousegrfid
%ifndef PREPROCESSONLY
%assign n_housesparamvarhandler (addr($)-housesparamvarhandler)/4
%endif
endvar

vard industilesvarhandler
	dd addr(getindustileconststate)
	dd addr(gettileterrain)
	dd addr(gethousezone)
	dd addr(getindustilepos)
	dd addr(getindustileanimframe)
%ifndef PREPROCESSONLY
%assign n_industilesvarhandler (addr($)-industilesvarhandler)/4
%endif
endvar

extern getindutiletypeatoffset_tile

vard industilesparamvarhandler
	dd getindustilelandslope
	dd getotherindustileanimstage
	dd getindutiletypeatoffset_tile
%ifndef PREPROCESSONLY
%assign n_industilesparamvarhandler (addr($)-industilesparamvarhandler)/4
%endif
endvar

vard townvarhandler
	dd addr(getistownlarger)	// in newhouse.asm
	dd addr(gettownnumber)		// in newhouse.asm
%ifndef PREPROCESSONLY
%assign n_townvarhandler (addr($)-townvarhandler)/4
%endif
endvar

vard townparamvarhandler
%ifndef PREPROCESSONLY
%assign n_townparamvarhandler (addr($)-townparamvarhandler)/4
%endif
endvar

extern getlandorwaterdistance,getindustrylayoutnumber,getplayerinfo_indu,getlongbuilddate

vard industryvarhandler
	dd addr(getincargo)
	dd addr(getincargo)
	dd addr(getincargo)
	dd getlandorwaterdistance
	dd getindustrylayoutnumber
	dd getplayerinfo_indu
	dd getlongbuilddate
%ifndef PREPROCESSONLY
%assign n_industryvarhandler (addr($)-industryvarhandler)/4
%endif
endvar

extern getindustrytownzoneanddist,getindustrytowndist_euclid
extern getothertypecountanddist,getothertypecountanddist_layout

vard industryparamvarhandler
	dd getindutiletypeatoffset
	dd getindutilerandombits
	dd getindustilelandslope_industry
	dd getotherindustileanimstage_industry
	dd getothertypedistance
	dd getindustrytownzoneanddist
	dd getindustrytowndist_euclid
	dd getothertypecountanddist
	dd getothertypecountanddist_layout
%ifndef PREPROCESSONLY
%assign n_industryparamvarhandler (addr($)-industryparamvarhandler)/4
%endif

vard airportvarhandler
	dd getaircraftdestination
%ifndef PREPROCESSONLY
%assign n_airportvarhandler (addr($)-airportvarhandler)/4
%endif

vard airportparamvarhandler
%ifndef PREPROCESSONLY
	dd getaircraftvehdata
%assign n_airportparamvarhandler (addr($)-airportparamvarhandler)/4
%endif

vard signalsparamvarhandler
	dd getsigtiledata
%ifndef PREPROCESSONLY
%assign n_signalsparamvarhandler (addr($)-signalsparamvarhandler)/4
%endif

extern getObjectVar40, getObjectVar41, getObjectVar42, getObjectVar43, getObjectVar44
extern getObjectVar45, getObjectVar46, getObjectVar47, getObjectVar48, getObjectParamVar60
extern getObjectParamVar61, getObjectParamVar62, getObjectParamVar63, getObjectParamVar64

vard objectvarhandler
	dd getObjectVar40
	dd getObjectVar41
	dd getObjectVar42
	dd getObjectVar43
	dd getObjectVar44
	dd getObjectVar45
	dd getObjectVar46
	dd getObjectVar47
	dd getObjectVar48
%ifndef PREPROCESSONLY
%assign n_objectvarhandler (addr($)-objectvarhandler)/4
%endif

vard objectparamvarhandler
	dd getObjectParamVar60
	dd getObjectParamVar61
	dd getObjectParamVar62
	dd getObjectParamVar63
	dd getObjectParamVar64
%ifndef PREPROCESSONLY
%assign n_objectparamvarhandler (addr($)-objectparamvarhandler)/4
%endif

endvar

vard specialvarhandlertable
	dd vehvarhandler,vehvarhandler
	dd vehvarhandler,vehvarhandler
	dd vehvarhandler,vehvarhandler
	dd vehvarhandler,vehvarhandler
	dd stationvarhandler,townvarhandler
	dd canalsvarhandler,0
	dd bridgevarhandler, townvarhandler
	dd housesvarhandler, townvarhandler
	dd 0,0
	dd industilesvarhandler, industryvarhandler
	dd industryvarhandler,townvarhandler
	dd 0,0
	dd 0,0
	dd airportvarhandler,townvarhandler
	dd 0,0
	dd objectvarhandler, objectvarhandler		//objects
checkfeaturesize specialvarhandlertable, (4*2)

endvar

	// number of special variables defined in each feature class
vard specialvars
%ifndef PREPROCESSONLY
	db n_vehvarhandler,n_vehvarhandler
	db n_vehvarhandler,n_vehvarhandler
	db n_vehvarhandler,n_vehvarhandler
	db n_vehvarhandler,n_vehvarhandler
	db n_stationvarhandler,n_townvarhandler
	db n_canalsvarhandler,0
	db n_bridgevarhandler,n_townvarhandler
	db n_housesvarhandler,n_townvarhandler
	db 0,0
	db n_industilesvarhandler,n_industryvarhandler
	db n_industryvarhandler,n_townvarhandler
	db 0,0
	db 0,0
	db n_airportvarhandler,n_townvarhandler
	db 0,0
	db n_objectvarhandler, n_objectvarhandler	//objects
%endif

checkfeaturesize specialvars, (1*2)

endvar

vard specialparamvarhandlertable
	dd vehparamvarhandler,vehparamvarhandler
	dd vehparamvarhandler,vehparamvarhandler
	dd vehparamvarhandler,vehparamvarhandler
	dd vehparamvarhandler,vehparamvarhandler
	dd stationparamvarhandler,townparamvarhandler
	dd canalsparamvarhandler,0
	dd bridgeparamvarhandler, townparamvarhandler
	dd housesparamvarhandler, townparamvarhandler
	dd 0,0
	dd industilesparamvarhandler, industryparamvarhandler
	dd industryparamvarhandler,townparamvarhandler
	dd 0,0
	dd 0,0
	dd airportparamvarhandler,townparamvarhandler
	dd signalsparamvarhandler,0
	dd objectparamvarhandler,0			// objects
checkfeaturesize specialparamvarhandlertable, (4*2)

endvar

	// number of special variables defined in each feature class
varb specialparamvars
%ifndef PREPROCESSONLY
	db n_vehparamvarhandler,n_vehparamvarhandler
	db n_vehparamvarhandler,n_vehparamvarhandler
	db n_vehparamvarhandler,n_vehparamvarhandler
	db n_vehparamvarhandler,n_vehparamvarhandler
	db n_stationparamvarhandler,n_townparamvarhandler
	db n_canalsparamvarhandler,0
	db n_bridgeparamvarhandler,n_townparamvarhandler
	db n_housesparamvarhandler,n_townparamvarhandler
	db 0,0
	db n_industilesparamvarhandler,n_industryparamvarhandler
	db n_industryparamvarhandler,n_townparamvarhandler
	db 0,0
	db 0,0
	db n_airportparamvarhandler,n_townparamvarhandler
	db n_signalsparamvarhandler,0
	db n_objectparamvarhandler,0			// objects
%endif

checkfeaturesize specialparamvars, (1*2)

endvar

global advvaraction2varbuff
uvard advvaraction2varbuff, NUMGRFREGISTERS
global specialgrfregisters
specialgrfregisters equ advvaraction2varbuff+NUMBASEGRFREGISTERS*4
