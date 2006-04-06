// functions dealing with some new features of the new trains

#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <textdef.inc>
#include <human.inc>
#include <window.inc>
#include <veh.inc>
#include <player.inc>
#include <vehtype.inc>
#include <bitvars.inc>
#include <newvehdata.inc>
#include <ptrvar.inc>

extern newvehdata,recordtraincrash,cargobits,setmiscgrferror,specialtext1
extern trainspritemove,traintoolong,vehcallback
extern vehtypecallback
extern SplittextlinesMaxlines,articulatedvehicle,callbackflags
extern cargoamountnnamesptr,cargoid,cargounitweightsptr
extern checkcargotextcallback,checknewtrainisengine2,cleartileaftertrain
extern cleartrainsignalpath,consistcallbacks,curmiscgrf
extern currouteallowredtwoway,currscreenupdateblock,drawsplittextfn
extern drawtextfn,forcemarksignalpath,freightweightfactor,getrefitmask
extern invalidatehandle,ishumanplayer,lastrefitmask,mostrecentspriteblock
extern movetrainvehicle,newcargotypenames,newsmessagefn
extern onlycheckpath,patchflags,pbssettings,prevtrainveh
extern vehtypetextids






	// deal with shorter train vehicles (e.g. tenders)

// called when a train vehicle is leaving depot
// determine whether next vehicle is activated
//
// in:	edi=vehicle
//	dx=cur position on tile
// out:	zero flag clear if activating next vehicle
// safe:eax ecx edx
global trainleavedepot
trainleavedepot:
	mov cx,[dword esi+1]
ovar nexttrainvehthreshold, -4

	movzx eax,word [edi+veh.nextunitidx]
	cmp ax,byte -1
	je .nextnotactive

	shl eax,7
	add eax,[veharrayptr]
	test byte [eax+veh.vehstatus],1
	jnz .nextnotactive

	ret

.nextnotactive:

	mov al,[edi+veh.shortened]
	test al,al
	js .gotlength

	push edi
	call getwagonlength
	pop eax

	or al,0x80
	mov [edi+veh.shortened],al

.gotlength:
	and al,~0x80
	push cx

	// cx is either 0x801, 0x108, 0x80d or 0xd08 depending on direction
	// need to change 1=>-al, 8=>0, d=>al
	sub ch,8
	jz .goty

	mov ch,al
	jns .goty

	neg ch
.goty:
	sub cl,8
	jz .gotx

	mov cl,al
	jns .gotx

	neg cx
.gotx:
	add dx,cx
	pop cx

.isengine:
	cmp dx,cx
	ret

// called when the game needs the actual wagon length,
// either from prop. 21 or from the callback
//
// in:	on stack->vehicle
// out:	on stack: how much shorter
// uses:---
getwagonlength:
	push eax
	push esi
	mov esi,[esp+12]
	movzx eax,byte [esi+veh.vehtype]
	test byte [callbackflags+eax],2
	jz .nolengthcallback

	mov al,0x11
	call vehcallback
	mov ah,0
	jnc .isshortened

.nolengthcallback:
	movzx eax,byte [esi+veh.vehtype]
	mov al,[trainvehlength+eax]

.isshortened:
	mov [esp+12],eax
	pop esi
	pop eax
	ret

// called when a train vehicle arrives at a depot
//
// in:	edi=vehicle
// out:	set vehstatus, direction
// safe:?
global trainentersdepot
trainentersdepot:
	or word [edi+veh.vehstatus],1
	xor byte [edi+veh.direction],4
	and byte [edi+veh.shortened],0x7f
	ret

// called train has to be reversed (from button, at signal or otherwise)
//
// in:	dh=total number of vehicles in train
//	dl=0
//	esi->train engine
// out:	-
// safe:eax ecx edx ebp edi
global reversetrain,reversetrain.cantreversemessage
reversetrain:
	testflags pathbasedsignalling
	jnc near .doreverse

	call cleartileaftertrain

	push dword [esi+veh.zpos]	// push zpos and direction
	push dword [esi+veh.XY]
	push dword [esi+veh.movementstat]

	mov edi,esi
.next:
	mov ax,[edi+veh.nextunitidx]
	cmp ax,byte -1
	je .gotlast
	movzx edi,ax
	shl edi,7
	add edi,[veharrayptr]
	jmp .next

.gotlast:
	mov ax,[edi+veh.zpos]
	xor ah,4
	mov [esi+veh.zpos],ax
	mov ax,[edi+veh.XY]
	mov [esi+veh.XY],ax
	mov al,[edi+veh.movementstat]
	mov [esi+veh.movementstat],al

	mov byte [onlycheckpath],1
	call forcemarksignalpath
	jnc .couldreserve
	mov byte [currouteallowredtwoway],2	// try the best to find *any* path
	call forcemarksignalpath
.couldreserve:
	mov byte [onlycheckpath],0

	pop dword [esi+veh.movementstat]
	pop dword [esi+veh.XY]
	pop dword [esi+veh.zpos]

	jnc .doreverseclear	// signal path marked without problems

	test byte [pbssettings],PBS_ALLOWUNSAFEREVERSE
	jnz .doreverseclear

	cmp byte [actionnestlevel],0
	je .cantreverse		// if we're not in an action handler, the reverse was automatic, so prevent it

	// if manual, do it anyway and hope the player knows what he's doing

.doreverseclear:
	call cleartrainsignalpath

.doreverse:
	param_call advancewagons, byte -1
	push edx

.reversenextset:
	call $
ovar exchtrainvehicles, -4

	inc dl
	dec dh
	cmp dl,dh
	jle .reversenextset

	pop edx
	param_call advancewagons, 1

.markcur:
	testflags pathbasedsignalling
	jnc .nopathsig2

	call forcemarksignalpath

.nopathsig2:
	mov byte [currouteallowredtwoway],0
	ret

.cantreverse:
	pusha

	// open the vehicle window (or flash if it's already open)
	push esi
	mov edi,esi
	movzx eax,byte [esi+veh.class]
	mov eax,[ophandler+eax*8]
	call [eax+0x18]		// mouse click handler
	pop esi

	mov ax,0x48d		// redraw status bar (just to be sure)
	mov bx,word [esi+veh.idx]
	call [invalidatehandle]

	mov dx,newstext(cantreverse)
	movzx ecx,byte [esi+veh.class]
	mov ax,[vehtypetextids+(ecx-0x10)*2]
	mov [textrefstack],ax
	movzx ax,byte [esi+veh.consistnum]

	global reversetrain.cantreverseme
.cantreversemessage:
	mov [textrefstack+2],ax
	mov ebx,0x50a00
	mov ax,[esi+veh.idx]
	mov [newsitemparam],ax
	call dword [newsmessagefn]
	popa

	// stop train
	or byte [esi+veh.vehstatus],2
	jmp .markcur

// advance a set of wagons for trains that have tenders
proc advancewagons
	arg direction

	_enter
	pusha

.nextset:
	push edx
	mov edi,esi

	mov ebx,esi
	movzx esi,word [esi+veh.nextunitidx]
	shl esi,7
	add esi,[veharrayptr]

	sub dh,1
	jbe .dontmove

.nextwagon:
	movzx edi,word [edi+veh.nextunitidx]
	shl edi,7
	add edi,[veharrayptr]
	dec dh
	jnz .nextwagon

	// now	ebx=first wagon whose length to compare with that of edi
	//	esi=first wagon in subset to move
	//	edi=last wagon in subset

	mov cl,[ebx+veh.shortened]
	and ecx,0x7f
	mov al,[edi+veh.shortened]
	and eax,0x7f
	sub ecx,eax

	imul ecx,[%$direction]
	test ecx,ecx
	jle .dontmove

	mov edx,[recordtraincrash]
	mov byte [edx],0xeb	// never record train crash
	push edx

	mov ax,-1
	xchg ax,[edi+veh.nextunitidx]	// make sure following vehicles don't move too
	push ax

.again:
	pusha
	mov eax,[prevtrainveh]
	mov [eax],ebx
	mov ah,1
	call dword [movetrainvehicle]

.isfirst:
	popa
	loop .again

	pop word [edi+veh.nextunitidx]

	pop edx
	mov byte [edx],0x73	// record train crashes again

.dontmove:
	// go to next subset
	pop edx
	sub dh,2
	jnb .nextset

	popa
	_ret
endproc advancewaggons


// show train sprite in depot or in train info window
//
// in:	cx=x pos
//	dx=y pos
// out:	cx += 14 for depot/other? or += 18 for train window
//	dx += 6
global displaytraininfosprite
displaytraininfosprite:
	add cx,14
	add dx,6

	cmp byte [esi],14	// train info window
	jne .done

	add cx,4
.done:
	ret

// called when calculating the position of the next vehicle
// in the train depot display
//
// in:	cx=old pos
//	edi=vehicle ptr
// out:	cx adjusted
//	di=nextunitidx
// safe:?
global displaytrainindepot
displaytrainindepot:
	push eax
	push edi
	call getwagonlength
	pop eax
	mov [edi+veh.shortened],al
	lea eax,[eax*3-0x1d]
	sub cx,ax
	mov di,[edi+veh.nextunitidx]
	pop eax
	ret

// find out which train vehicle the user clicked on in a depot
//
// in:	al*1d+ah=x coord within window
//	edi=first veh in consist
// out:  al=0
//	edi=0 if beyond consist
// safe: ah
global choosetrainvehindepot
choosetrainvehindepot:
	push ebx
	xchg eax,ebx
	mov al,0x1d
	mul bl
	add al,bh
	adc ah,0

.nextveh:
	push edi
	call getwagonlength
	pop ebx
	lea ebx,[ebx*3-0x1d]
	neg ebx
	sub ax,bx
	jb .foundit

	movzx edi,word [edi+veh.nextunitidx]
	cmp di,-1
	je .notfound
	shl edi,vehicleshift
	add edi,[veharrayptr]
	jmp .nextveh

.notfound:
	xor edi,edi
.foundit:
	mov al,0
	pop ebx
	ret


// calculate coords for the white rectangle around the active train vehicle
//
// in:	cx=start y
//	dx=start x
//	edi=vehicle
// out: ax=start y
//	bx=start x-how much veh is shorter
//	cx=start x
// safe:si edi bp
global showactivetrainveh
showactivetrainveh:
	mov ax,cx
	mov cx,dx
	push edi
	call getwagonlength
	pop ebx
	lea ebx,[ebx*3]
	neg ebx
	add bx,ax
	ret

uvard textstackcopy,6

// called after setting up info display for train engine
//
// in:	ebx=vehtype*vehtype_size
//	esi=>window
// out:	set textrefstack+6 to ax
// safe:eax ebx edi
global showlocoinfo
showlocoinfo:
	push esi
	mov esi,textrefstack
	mov edi,textstackcopy
	times 6 movsd
	mov [edi-2],ah		// replaced (a variation of this)

	mov edi,textrefstack

	mov eax,ebx
	mov bl,vehtype_size
	div bl
	movzx ebx,al
	mov al,[railvehhighwt+ebx]
	add [edi+5],al
	movzx eax,byte [traintecoeff+ebx]
	imul eax,10		// gravity
	movzx esi,word [edi+4]	// weight
	imul eax,esi
	shr eax,8
	mov [edi+6],ax
	pop esi
	mov eax,[textstackcopy+6]
	mov [edi+8],eax

	pusha
	mov bx,ourtext(engineinfo1)
	mov edi,[currscreenupdateblock]
	call [drawtextfn]
	popa

	add dx,3*10

	mov ax,[trainwagonpower+ebx*2]
	test ax,ax
	jz .nowagonpower

	mov [edi],ax
	mov al,[trainwagonpowerweight+ebx]
	mov [edi+2],al

	pusha
	mov bx,ourtext(wagonpower)
	mov edi,[currscreenupdateblock]
	call [drawtextfn]
	popa

	add dx,10
	mov al,-1	// one less line for misc grf text at bottom

.nowagonpower:
	add al,9	// eight/nine lines available
	movzx eax,al
	add dword [SplittextlinesMaxlines],eax
	mov eax,[textstackcopy+0x0a]
	mov [edi],eax
	mov eax,[textstackcopy+0x0e]
	mov [edi+4],eax

	shr eax,16		// capacity
	call checkrefittable
	mov [edi+8],ax

	mov eax,[textstackcopy+0x12]
	mov [edi+10],eax
	mov al,[textstackcopy+0x16]
	mov [edi+14],al

	push esi
	mov ah,0x23
	mov al,bl
	xor esi,esi
	call vehtypecallback
	mov ah,0xD4
	jnc .gotit
	mov ax,6
.gotit:
	mov [edi+15],ax
	mov eax,[mostrecentspriteblock]
	mov [curmiscgrf],eax
	pop esi
	mov bp,[esi+window.width]
	sub bp,6
	ret

global checkrefittable
checkrefittable:
	and dword [lastrefitmask],0
	test ax,ax
	jz .notrefittable	// no cargo capacity

	lea eax,[ebx+0x100000]
	push eax
	call getrefitmask
	pop eax
	test eax,eax
	jz .notrefittable
	mov ax,0x9842-6	// "(refittable)"
.notrefittable:
	add ax,6	// null string

.done:
	ret


// called after setting up info display for train wagon
//
// in:	eax=cargo type
//	ebx=vehtype
// out:  bx=textid
// safe:eax ebx edi ebp
global showwagoninfo
showwagoninfo:
	mov ebp,textrefstack
	push eax

	mov al,[railvehhighwt+ebx]
	add [ebp+5],al

	mov ax,[ebp+10]
	call checkrefittable
	mov [ebp+12],ax

	push esi
	mov ah,0x23
	mov al,bl
	xor esi,esi
	call vehtypecallback
	mov ah,0xD4
	jnc .gotit
	mov ax,6
.gotit:
	mov [ebp+22],ax
	mov eax,[mostrecentspriteblock]
	mov [curmiscgrf],eax
	pop esi

	pop eax

	push ebx
//	add ebx,ebx
//	add ebx,[enginepowerstable]
	imul bx,[trainspeeds+ebx*2],10
	shr bx,4
	mov [ebp+20],bx	// for later

	mov edi,eax
	shl eax,1
	add eax,[cargoamountnnamesptr]
	mov ax,[eax]
	cmp word [ebp+10],0
	jne .isok
	mov ax,0x8838	// "n/a"
.isok:
	mov bx,ourtext(wagoninfo)

	mov [ebp+8],ax
	add edi,[cargounitweightsptr]
	mov al,[edi]
	sub edi,[cargounitweightsptr]
	mul byte [ebp+10]
	shr ax,4
	add ax,[ebp+4]
	mov [ebp+6],ax

	push eax
	mov eax,[ebp+10]
	mov [ebp+12],eax
	mov eax,[ebp+6]
	mov [ebp+8],eax
	mov eax,[ebp+2]
	mov [ebp+4],eax
	mov ax,[ebp]
	mov [ebp+2],ax
	mov [ebp],bx

	mov ax,statictext(popdword)
	testmultiflags wagonspeedlimits
	jz .nolimit
	cmp word [ebp+20],0
	je .nolimit
	cmp word [ebp+20],byte -1
	je .nolimit
	mov ax,ourtext(wagonspeedlimit)
.nolimit:
	mov word [ebp+16],ax
	mov word [ebp+18],statictext(textclr_lightorange)

	mov bx,statictext(wagoninfodisplay)
	cmp word [ebp+22],6
	jne .notnoextratext
	mov bx,statictext(ident2)
.notnoextratext:
	pop eax
	pop edi
	push eax
	mov al,12
	call showvehrefittable
	pop eax

	mov bp,[esi+window.width]
	sub bp,6
	ret


// show refittable cargo types
// in:	al=number of lines to add??
//	edi=vehtype
showvehrefittable:
	push ecx

#if 0	// not needed, can just put refit list out of window
	test byte [vehmiscflags+edi],VEHMISCFLAG_NOSHOWREFIT
	jnz near .notrefittable
#endif

	movzx eax,al
	add [SplittextlinesMaxlines],eax

	mov eax,[lastrefitmask]
	test eax,eax
	jz near .notrefittable

	// first count them
	xor ecx,ecx
.countnext:
	mov edi,eax
	sub edi,1	// can't use dec because it doesn't set CF
	jc .gotcount
	and eax,edi
	inc ecx
	cmp ecx,11
	jb .countnext

.gotcount:
	push ecx
	
	// try counting the inverse
	mov eax,[lastrefitmask]
	not eax
	and eax,[cargobits]
	xor ecx,ecx

.countnextnot:
	mov edi,eax
	sub edi,1
	jc .gotnotcount
	and eax,edi
	inc ecx
	cmp ecx,11
	jb .countnextnot

.gotnotcount:
	mov al,0
	cmp ecx,1
	adc al,0

	pop edi		// count of set bits; ecx=count of clear bits
	cmp ecx,edi
	adc al,0	// al=1 for "All but ...", al=2 for "All"
	jnz .gotfinalcount

	mov ecx,edi

	cmp ecx,2
	jb .notrefittable	// just one type?

.gotfinalcount:
	imul ecx,byte -3
	add ecx,twelvecommaend+1
	mov [specialtext1],ecx

	pop ecx

	// flush text so far
	call flushtext

	push ecx
	mov bx,6
	mov word [textrefstack],statictext(special1)
	jb .notrefittable	// no room in window

	// now show refittable cargo types
	mov di,ax
	xor ecx,ecx
	mov eax,[lastrefitmask]

	cmp di,1
	jb .shownext
	ja .haveall

	not eax
	and eax,[cargobits]
	xor ecx,ecx

.shownext:
	bsf ebx,eax
	jz .haveall
	btr eax,ebx
	mov bl,[cargoid+ebx]
	mov bx,[newcargotypenames+ebx*2]
	mov word [textrefstack+2+ecx*2],bx
	inc ecx
	cmp ecx,11
	jb .shownext

	mov word [textrefstack+2+10*2],statictext(ellipsis)
	
.haveall:
	mov bx,di
	add bx,ourtext(refittableto)

.notrefittable:
	pop ecx
	ret

var twelvecommas
	times 11 db 0x80,',',' '
        db 0x80, 0
var twelvecommaend


// draw text and correct SplittextlinesMaxlines
//
// in:	registers like for DrawText
// out:	dx=Y coord below text
//	CF=1 if window is full
// uses:---
flushtext:
	pusha
	mov edi,[currscreenupdateblock]
	mov bp,[esi+window.width]
	sub bp,6
	push dword [SplittextlinesMaxlines]
	call [drawsplittextfn]
	pop dword [SplittextlinesMaxlines]
	mov ax,[esp+20]
	mov [esp+20],dx
	sub dx,ax
	mov al,dl
	aam
	movzx eax,ah
	sub [SplittextlinesMaxlines],eax
	popa
	jb .isfull
	ret

.isfull:
	or dword [SplittextlinesMaxlines],-1
	stc
	ret


// show vehicle purchase for ships and rvs
//
// in:	ebx=vehtype*vehtype_size
// out:	bx=text ID
//	edi->currscreenupdateblock
// safe:eax ebx edi
global showvehinfo,showvehinfo.callback
showvehinfo:
	mov ax,bx
	mov bl,vehtype_size
	div bl
	movzx eax,al
	or eax,0x110000

	mov bx,ourtext(rvweightpurchasewindow)
	testmultiflags rvpower
	jnz .havervpower
	mov bx,0x9008
.havervpower:
	cmp al,SHIPBASE
	jb .isrv
        mov bx,0x980a
	add eax,0x10000
.isrv:
	push eax
	call getrefitmask
	pop edi

.callback:
	movzx edi,al
	push edi
	push esi
	mov ah,0x23
	xor esi,esi
	call vehtypecallback
	pop esi
	jc .notext

	or ah,0xD4
	mov edi,[mostrecentspriteblock]
	mov [curmiscgrf],edi
	call flushtext
	mov bx,ax

.notext:
	pop edi
	mov al,10
	call showvehrefittable

	mov edi,[currscreenupdateblock]
	mov bp,[esi+window.width]
	sub bp,6
	ret


// called to show train sprite in info lists (as opposed to the main view)
//
// in:	cx,dx sprite screen X Y coordinates
//	edi->vehicle
//	stack: bx (to xchg with cursprite)
// out:	stack: ax,cx,dx
// safe:eax (after pushing)
global showvehinfosprite
showvehinfosprite:
	mov bx,[esp+4]
	xchg bx,[edi+veh.cursprite]
	mov [esp+4],ax
	pop eax		// return address
	push cx
	push dx
	push eax
	add dx,[trainspritemove]
	ret

	uvard isfreight

// called to display the current wagon load amount
//
// in:	ax=stuff for text stack
//	edi->vehicle
// out:	bx=textid
// safe:eax esi edi
global showwagonload
showwagonload:
	mov esi,textrefstack
	mov [esi+6],ax
	mov bx,0x8813

	call prepfreightstack
	mov [esi+14],eax
	ret

prepfreightstack:
	cmp byte [edi+veh.class],0x10
	jne .notfreight

	movzx eax,byte [edi+veh.cargotype]
	bt [isfreight],eax
	jnc .notfreight

	push dword [esi+veh.owner-1]
	mov byte [esp],PL_PLAYER + PL_NOTTEMP
	call ishumanplayer
	jnz .notfreight

	// make space for the (x5) textid
	mov eax,[esi+8]
	mov [esi+10],eax
	mov eax,[esi+4]
	mov [esi+6],eax
	mov eax,[esi]
	mov [esi+2],eax
	mov [esi],bx

	movzx eax,byte [freightweightfactor]

	mov bx,statictext(freightmulti)

.notfreight:
	ret

// similar as above but for the capacity
//
// in:	edi->vehicle
// out:	bx=textid
//	edi->currscreenupdateblock
// safe:eax esi
global showwagoncap
showwagoncap:
	push edi
	call showsinglecap
	pop edi

	add esi,2
	mov bx,0x013f

	call prepfreightstack
	mov [esi+8],eax
	mov edi,[currscreenupdateblock]
	ret

// same as above but for non-train vehicles
global showsinglecap
showsinglecap:
	mov esi,textrefstack
	mov eax,[esi]
	mov [esi+2],eax
	mov word [esi],statictext(ident2)

	movzx eax,byte [edi+veh.vehtype]
	push esi
	mov esi,edi
	call checkcargotextcallback
	pop esi
	mov [esi+6],ax

	mov bx,0xa01a
	mov edi,[currscreenupdateblock]
	ret

// similar as above but for two capacities (planes)
//
// in:	ax=second capacity
//	edi->mail compartment
// out:	bx=textid (will be increased by one if need to show only one capacity)
//	zero flag set if only one capacity
// safe:eax esi edi
global showdoublecap
showdoublecap:
	movzx edi,word [edi+veh.engineidx]
	shl edi,7
	add edi,[veharrayptr]
	mov esi,textrefstack+4
	mov eax,[esi]
	mov [esi+4],eax
	call showsinglecap
	dec bx
	cmp word [esi+10],0
	ret

// called when buying a new rail vehicle (action handler)
//
// in:  bl=0 if checking, 1 if doing
//	ebx(8:31)=new vehtype
//	ax,cx=X,Y
// out:	ebx=cost (8000000h if error)
//	edi->new vehicle
// safe:edx esi
global newbuyrailvehicle
proc newbuyrailvehicle
	local x,y,vehtype,cost,veh,otherveh,prevveh,headtype,numheadsbase

	_enter

	mov [%$vehtype],ebx
	mov [%$x],eax
	mov [%$y],ecx
	and dword [%$cost],0
	and dword [%$veh],0

	movzx edx,bh
	call checknewtrainisengine2
	jnz .notadditionalhead

	mov dh,1

.notadditionalhead:

	// possible headtypes:
	// 00: regular engine
	// 01: add'l head
	// 81: reversed add'l head (set below)
	// 82: reversed dual head (set below)

	mov [%$headtype],dh

	push ebp
	call [oldbuyrailvehicle]
	pop ebp

	mov [%$veh],edi
	mov [%$otherveh],esi
	mov [%$cost],ebx

	cmp ebx,0x80000000
	jne .continue

	and dword [%$veh],0

.done:
	mov ebx,[%$cost]
	mov edi,[%$veh]
	and dword [articulatedvehicle],0
	mov eax,[%$x]
	mov ecx,[%$y]

	test byte [%$vehtype],1
	jz .notreally
	test edi,edi
	jz .notreally
	mov esi,edi
	call consistcallbacks
.notreally:
	_ret

.continue:
	test byte [%$vehtype],1		// no point trying to buy more since
	jz .done			// TTD can't tell the difference anyway

	mov dword [%$numheadsbase],numheads

	// do we build an articulated engine?
	movzx eax,byte [%$vehtype+1]
	test byte [traincallbackflags+eax],0x10
	jz .done

	xor esi,esi
	cmp edi,[%$otherveh]
	je .singlehead

	// we bought two vehicles, which means it must be dualheaded with multihead off
	// detach the second head for now
	mov esi,[%$otherveh]
	or word [edi+veh.nextunitidx],byte -1
	mov byte [esi+veh.artictype],0xfd
	mov eax,[%$veh]
	mov ax,[eax+veh.idx]
	mov [esi+veh.articheadidx],ax

.singlehead:
	mov [%$otherveh],esi

.next:
	test byte [%$headtype],0x80
	jnz .notreversedhead
	mov [%$prevveh],edi
.notreversedhead:
	inc dword [articulatedvehicle]
	mov esi,[%$veh]
	mov al,0x16
	call vehcallback
	jc .done

	cmp al,0xff
	jne near .addmore

	// engine is complete, set all but the first part as articulated pieces
	mov edi,[%$veh]
	mov ah,0xff	// ff means "can't be moved" and "can't attach before"
	mov al,0xfd	// fd means the same for first dualhead piece

	test byte [%$headtype],0x80
	jz .setnext

	mov esi,[%$otherveh]
	mov word [esi+veh.nextunitidx],-1
	mov al,0

	cmp byte [%$headtype],0x82
	jne .multi

	mov ah,0xfe	// fe means the same as ff plus "can't attach after"
.multi:
	mov edi,[%$prevveh]
	movzx edi,word [edi+veh.nextunitidx]
	cmp di,byte -1
	je .setdone

	shl edi,7
	add edi,[veharrayptr]
	mov [edi+veh.artictype],al
	mov ebx,[%$veh]
	mov bx,[ebx+veh.idx]
	mov [edi+veh.articheadidx],bx

.setnext:
	movzx ebx,word [edi+veh.nextunitidx]
	cmp bx,byte -1
	je .setdone

	mov edi,ebx
	shl edi,7
	add edi,[veharrayptr]
	mov [edi+veh.artictype],ah
	mov ebx,[%$veh]
	mov bx,[ebx+veh.idx]
	mov [edi+veh.articheadidx],bx
	jmp .setnext

.setdone:
	// if it's supposed to be dualheaded, add the second head
	movzx esi,byte [%$vehtype+1]
	add esi,[%$numheadsbase]
	test byte [esi],1
	jz .done

	mov al,[%$headtype]
	test al,al
	jnz .done

	add al,0x81
	xor al,3
	mov [%$headtype],al
	and dword [articulatedvehicle],0
	mov esi,[%$otherveh]
	test esi,esi
	jnz .haveotherveh
	push edi
	mov ebx,[%$vehtype]
	or bl,8		// don't attach to anything
	mov eax,[%$x]
	mov ecx,[%$y]
	push ebp
	call [oldbuyrailvehicle]
	pop ebp
	mov esi,edi
	mov [%$otherveh],edi
	pop edi
	cmp ebx,0x80000000
	je .done
.haveotherveh:
	mov bx,[esi+veh.idx]
	mov [edi+veh.nextunitidx],bx	// attach second head again
	mov edi,esi
	jmp .next

.addmore:
	push eax
	and al,0x7f
	xor ebx,ebx
	mov bh,al
	mov bl,9
	mov eax,[%$x]
	mov ecx,[%$y]
	push ebp
	call [oldbuyrailvehicle]
	pop ebp
	pop eax

	cmp ebx,0x80000000
	je .done

	// attach to engine
	mov byte [edi+veh.currorderidx],0	// in case any left-over was in there
	mov byte [edi+veh.subclass],2
	mov edx,[%$veh]
	mov dx,[edx+veh.idx]
	mov [edi+veh.engineidx],dx
	and dword [edi+veh.value],0

	// regular and multihead: attach edi to prevveh
	// reversed dual head: detach prevveh from prevprevveh and attach to edi
	//	(e.g. for 5, before 0->2->3->4->1 then 0->2->3->5->4->1)
	cmp byte [%$headtype],0x80
	jb .notbackwards

	mov esi,[%$prevveh]		// esi->4, edi->5
	mov dx,[esi+veh.nextunitidx]	// dx=1
	mov [edi+veh.nextunitidx],dx	// now 0->2->3->4(->1), 5->1
	mov dx,[edi+veh.idx]		// dx=5
	mov [esi+veh.nextunitidx],dx	// now 0->2->3->4->5->1
	jmp short .checkreverse

.notbackwards:
	mov esi,[%$prevveh]
	mov dx,[edi+veh.idx]
	mov [esi+veh.nextunitidx],dx

.checkreverse:
	mov ah,[%$headtype]
	and ah,0x80
	xor al,ah
	xor al,0x80
	js .next	// does not need to be reversed

	movzx esi,al

	mov al,[edi+veh.spritetype]
	cmp al,0xfd
	jae .hasotherengine

	// add 1 to spritetype for regular engines, and add 2 for
	// dualhead engines and new graphics engines

	add esi,[%$numheadsbase]
	test byte [esi],1
	jz short .hasnootherengine

.hasotherengine:
	add al,1

.hasnootherengine:
	add al,1
	mov [edi+veh.spritetype],al
	jmp .next
endproc


uvard oldbuyrailvehicle

global newsellrailengine
newsellrailengine:
	and dword [lastdetachedveh],0
	jmp [oldsellrailengine]

uvard oldsellrailengine
uvard lastdetachedveh

	// called when detaching a vehicle from unattached wagons
	//
	// in:	eax=veh.nextunitidx
	// out:	carry and eax->vehicle if is next vehicle
	//	no carry and ax=following veh.nextunitidx otherwise
	// safe:eax ebx cx edi
global nextfirstwagon
nextfirstwagon:
	shl eax,7
	add eax,[veharrayptr]
	cmp byte [eax+veh.currorderidx],0xfe
	jb .done

	mov ax,[eax+veh.nextunitidx]

.done:
	ret

	// called when the orientation of an articulated loco has to be reversed
	// as a result of (not) holding Ctrl when moving it in the depot
	//
	// in:	edi->first artic.piece
	//	esi->second artic.piece
	// out:	edi->new first artic.piece
	// safe:eax ebx edx esi
global reversearticulatedloco
reversearticulatedloco:
	ret
#if 0
	// this doesn't work yet
	mov ax,[edi+veh.idx]
	movzx edx,word [edi+veh.engineidx]
.findbefore:
	shl edx,7
	add edx,[veharrayptr]
	cmp ax,[edx+veh.nextunitidx]
	je .gotbefore
	cmp ax,[edx+veh.idx]
	je .none
	movzx edx,word [edx+veh.nextunitidx]
	cmp dx,byte -1
	jne .findbefore
.none:
	xor edx,edx

.gotbefore:
	mov si,-2
	movzx eax,word [edi+veh.idx]
.storenext:
	push si
	mov esi,eax
	shl esi,7
	add esi,[veharrayptr]
	cmp byte [esi+veh.currorderidx],0xfe
	jb .storedall
	movzx eax,word [esi+veh.nextunitidx]
	cmp ax,byte -1
	jne .storenext

.storedall:
	mov ecx,eax
	mov esi,edx
	test edx,edx
	jnz .restorenext
	pop di
	movzx edi,di
	shl edi,7
	add edi,[veharrayptr]
	mov esi,edi

.restorenext:
	pop ax
	cmp ax,byte -2
	je .done

	mov [esi+veh.nextunitidx],ax
	movzx esi,ax
	shl esi,7
	add esi,[veharrayptr]

	mov al,[esi+veh.spritetype]
	cmp al,0xfd
	jae .type2

	test al,1
	jz .type2

	xor al,3

.type2:
	xor al,2
	mov [esi+veh.spritetype],al
	jmp .restorenext

.done:
	mov [esi+veh.nextunitidx],cx
	test edx,edx
	jz .gotnothingbefore
	movzx edi,word [edx+veh.nextunitidx]
	shl edi,7
	add edi,[veharrayptr]
.gotnothingbefore:
	mov al,[edi+veh.currorderidx]
	xchg al,[esi+veh.currorderidx]
	mov [edi+veh.currorderidx],al

	mov al,[edi+veh.subclass]
	xchg al,[esi+veh.subclass]
	mov [edi+veh.subclass],al
	ret
#endif

	// called when checking train length when attaching wagons
	//
	// in:	al=number of vehicles in train so far
	// out:	comparison of al with maxlen-1
	// safe:eax esi edi
global limittrainlength
limittrainlength:
//	testflags manualconvert		// traintoolong now needs to be called
//	jnc .nomanucvt			// always (because of callback)

	call traintoolong
	jbe .nomanucvt
	ret

.nomanucvt:
	mov word [operrormsg2],0x8819	// Train too long
	push PL_DEFAULT
	call ishumanplayer
	je .human

	movzx esi,byte [curplayer]
	imul esi,player_size
	add esi,[playerarrayptr]
	mov ah,[esi+0x327]	// train station length
	add ah,ah
	dec ah
	cmp al,ah
	ret

.human:
	testflags mammothtrains
	jc .mammoth

	cmp al,9
	ret

.mammoth:
	cmp al,126
	ret


// show the sprite for one line in the train details window
//
// in:	edi->vehicle
// out:
// safe:
global showtraindetailssprite
showtraindetailssprite:
	mov al,0
	mov ebx,edi

.nextone:
	add al,1
	movzx ebx,word [ebx+veh.nextunitidx]
	cmp bx,byte -1
	je .lastone
	shl ebx,7
	add ebx,[veharrayptr]
	cmp byte [ebx+veh.currorderidx],0xfe
	jae .nextone

.lastone:
	jmp $+0x1000
ovar fnshowtrainsprites,-4

// find the vehicle to display in the train details window
// in:	edi->vehicle
// out:	sign flag if display vehicle
// safe:ebx
global findtraindetailveh
findtraindetailveh:
	cmp byte [edi+veh.subclass],2
	jb .gotit
	cmp byte [edi+veh.currorderidx],0xfe
.gotit:
	jnc .returnsf

	sbb al,0
	jns .returnsf

	cmp al,-6
	ret

.returnsf:
	or bl,0x80
	ret

// count number of slots to show in train details window
// in:	edi->vehicle
//	cl=current count
// out:	di=veh.nextunitidx
//	cl=new count
// safe:eax
global counttrainslots
counttrainslots:
	cmp byte [edi+veh.subclass],2
	jb .gotit
	cmp byte [edi+veh.currorderidx],0xfe
.gotit:
	adc cl,0
	mov di,[edi+veh.nextunitidx]
	ret


// check whether vehicle can be started/stopped
// in:	edx->vehicle
//	eax,ebx,ecx etc like for DoAction
// out:	CF=0 ZF=0 possible
//	CF=0 ZF=1 possible, but don't do it
//	CF=1 not possible, other error
// safe:ebx edx esi edi
global startstopveh
startstopveh:
	mov esi,edx
	push eax
	mov al,0x31
	call vehcallback
	cmc
	jnc .isfine

	cmp al,0xff
	je .isfine
	call setmiscgrferror
	stc

.isfine:
	pop eax
	jc .done

	test bl,1
	jz .done

	xor byte [edx+veh.vehstatus],2	// overwritten

.done:
	ret
