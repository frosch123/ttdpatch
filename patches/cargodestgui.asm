#include <std.inc>
#include <dest.inc>
#include <veh.inc>
#include <station.inc>
#include <window.inc>
#include <windowext.inc>
#include <flags.inc>
#include <textdef.inc>
#include <town.inc>
#include <imports/gui.inc>

extern doresizewinfunc, stos_locationname, TrainListDrawHandlerCountTrains, ShadedWinHandler, ShadeWindowHandler.toggleshade
extern stationarray2ptr, cargodestdata, newcargotypenames, trainlistoffset, patchflags, cargodestwaitmult

global CargoPacketWin_elements._sizer_constraints

ptrvardec window2ofs

//cargo packet display window


//shamelessly stolen from tracerestrict.asm
%assign numrows 10
%assign winheight numrows*12+30
%assign buttongap 0
btn_start_end equ -buttongap-1
%define prev_btn start

%macro btndata 2-3 //name,width,follows
	%ifstr %3
	btn_%1_start equ btn_ %+ %3 %+ _end + buttongap+1
	%else
	btn_%1_start equ btn_ %+ prev_btn %+ _end + buttongap+1
	%endif
	btn_%1_end equ btn_%1_start+%2
	%xdefine prev_btn %1
	%assign winwidth btn_%1_end+1
%endmacro

//display mode ideas even more shamelessly stolen from our Comrades in OTTDland

%define btnwidths(a) x, btn_ %+ a %+ _start , x2, btn_ %+ a %+ _end, sy, 1, -y, 11, -y2, 0

btndata destination, 85
btndata full, 85
btndata nexthop, 85
btndata tree, 85
btndata packetdump, 85
btndata routing, 85
btndata sizer, 11

guiwindow CargoPacketWin, winwidth, winheight
guicaption cColorSchemeGrey, ourtext(cargopacketwintitle)	//0,1
guiwinresize cColorSchemeGrey, h,,2048, itemh,12,30, w,,2048
guiele background,cWinElemSpriteBox,cColorSchemeGrey,x,0,-x2,0,y,14,-y2,0,data,0, sy2, 1, sx2, 1		//2
guiele textcolour,cWinElemSetTextColor,0x10,x,0,x2,0,y,0,y2,0,data,0						//3
guiele textbox,cWinElemTextBox,cColorSchemeGrey,x,0,-x2,12,y,14,-y2,12,data,statictext(empty),sy2,1,sx2,1	//4
guiele slider,cWinElemSlider,cColorSchemeGrey,-x,11,-x2,1,y,14,-y2,12,data,0,sy2,1,sx,1				//5
guiele destination,cWinElemTextBox,cColorSchemeGrey,btnwidths(destination),data,ourtext(cpgui_dest)		//6
guiele full,cWinElemTextBox,cColorSchemeGrey,btnwidths(full),data,ourtext(cpgui_full)				//7
guiele nexthop,cWinElemTextBox,cColorSchemeGrey,btnwidths(nexthop),data,ourtext(cpgui_nexthop)			//8
guiele tree,cWinElemTextBox,cColorSchemeGrey,btnwidths(tree),data,ourtext(cpgui_tree)				//9
guiele packetdump,cWinElemTextBox,cColorSchemeGrey,btnwidths(packetdump),data,ourtext(cpgui_packetdump)		//A
guiele routing,cWinElemTextBox,cColorSchemeGrey,btnwidths(routing),data,ourtext(cpgui_routing)			//B
endguiwindow

exported CanDispMiscButton
	testflags cargodest
	jnc .neret
	cmp byte [esi+window.type], cWinTypeStation
	je .ret
	cmp byte [esi+window.type], cWinTypeVehicleDetails
.ret:
	ret
.neret:
	or esp, esp
	ret

exported cdestmoredetailswintoggle
	pushad

	cmp DWORD [esi+window.function], ShadedWinHandler
	jne .nounshade
	call ShadeWindowHandler.toggleshade		//window is shaded, unshade before trying to do anything to it
.nounshade:

	push DWORD [esi+window.company]
	push DWORD [esi+window.data+2]
	push DWORD [esi+window.data+6]
	push DWORD [esi+window.flags]

	cmp DWORD [esi+window.function], cdestmoredetailswinhandler
	je NEAR .revert

	push DWORD [esi+window.type]
	push DWORD [esi+window.function]
	push DWORD [esi+window.opclassoff]

	push DWORD [esi+window.width]
	push DWORD [esi+window.elemlistptr]
	bt WORD [esi+window.flags], 12
	jnc .cont
	add esp, 8
	push DWORD [esi+window2ofs+window2.origsize]
	push DWORD [esi+window2ofs+window2.origelemlist]
	call [RefreshWindowArea]
	mov ax, [esp+4]
	mov cx, [esp+6]
	call doresizewinfunc
	//recorrect for item values
	mov eax, [esi+window.type]
	mov [esp+16], eax
.cont:

	push DWORD [esi+window.x]
	movzx eax,  BYTE [esi+window.type]
	push eax

	call [DestroyWindow]

	pop ecx
	mov dx, -1
	pop eax
	mov ebx, winwidth + (winheight << 16) // width , height
	mov ebp, cdestmoredetailswinhandler
	call dword [CreateWindow]
	mov dword [esi+window.elemlistptr], CargoPacketWin_elements
	mov DWORD [esi+window.activebuttons], 1<<6
	pop DWORD [esi+window2ofs+window2.data2]		//elements
	pop DWORD [esi+window2ofs+window2.data2+4]		//sizes
	pop eax							//opclassof
	mov [esi+window2ofs+window2.data1], ax
	pop DWORD [esi+window2ofs+window2.data2+8]		//function
	pop DWORD [esi+window2ofs+window2.data2+12]		//type and item info

	pop eax
	and eax, 1<<14 | 0xFFFF<<16		//preserve stickiness and window id
	mov [esi+window.flags], eax

	pop DWORD [esi+window.data+6]
	pop DWORD [esi+window.data+2]
	pop DWORD [esi+window.company]

	mov BYTE [esi+window.itemsvisible], numrows
	mov BYTE [esi+window2ofs+window2.extactualvisible], numrows

	popad
	mov cx, -1
	ret

.revert:

	push DWORD [esi+window2ofs+window2.data2+12]		//type and item info
	push DWORD [esi+window2ofs+window2.data2]		//elements
	push DWORD [esi+window2ofs+window2.data2+4]		//sizes
	push DWORD [esi+window2ofs+window2.data2+8]		//function
	movzx eax, WORD [esi+window2ofs+window2.data1]		//opclassof
	push eax

	push DWORD [esi+window.x]
	movzx eax,  BYTE [esi+window.type]
	push eax

	call [DestroyWindow]

	pop ecx
	pop eax
	pop edx
	pop ebp
	pop ebx
	call dword [CreateWindow]
	pop DWORD [esi+window.elemlistptr]
	pop eax
	and eax, 0xFFFFFF
	mov [esi+window.type], eax

	pop eax
	and eax, 1<<14 | 0xFFFF<<16		//preserve stickiness and window id
	mov [esi+window.flags], eax

	pop DWORD [esi+window.data+6]
	pop DWORD [esi+window.data+2]
	pop DWORD [esi+window.company]
	popad
	ret

cdestmoredetailswinhandler:
 	mov esi, edi
	pushad
	mov bx, cx

	cmp dl, cWinEventClick
	je .click
	cmp dl, cWinEventRedraw
	jz .redraw
	popad
	ret

.click:
	call dword [WindowClicked] // Has this window been clicked
	js NEAR .ret

	cmp byte [rmbclicked],0 // Was it the right mouse button
	jne NEAR .ret

	movzx ecx,cl
	bt DWORD [esi+window.disabledbuttons], ecx
	jc NEAR .ret

	or cl,cl // Was the Close Window Button Pressed
	jnz .notdestroywindow // Close the Window
	popad
	jmp dword [DestroyWindow]
.notdestroywindow:

	cmp cl, 1 // Was the Title Bar clicked
	jne .notwindowtitlebarclicked
	popad
	jmp dword [WindowTitleBarClicked] // Allow moving of Window
.notwindowtitlebarclicked:
	cmp cl, 6
	jae .btn
.ret:
	popad
	ret
.btn:
	mov eax, 1
	shl eax, cl
	mov ecx, eax
	xchg [esi+window.activebuttons], eax
	cmp eax, ecx
	je .noresetscroll
	mov BYTE [esi+window.itemsoffset], 0
.noresetscroll:
	popad
	jmp [RefreshWindowArea]

.redraw:
	push edi
	push esi
	mov ecx, esi
	mov edi, textrefstack
	mov al, [esi+window.type]
	movzx esi, WORD [esi+window.id]
	mov DWORD [curstcargorttbl], 0
	cmp al, cWinTypeStation
	jne .notst
	push eax
	imul eax, esi, station_size
	add eax, [stationarray2ptr]
	mov eax, [eax+station2.cargoroutingtableptr]
	mov [curstcargorttbl], eax
	pop eax
	or esi, 0x10000
.notst:
	cmp al, cWinTypeVehicleDetails
	jne .notveh
	or esi, 0x20000
	or BYTE [ecx+window.disabledbuttons+1], (1<<3) + 1 + 2
.notveh:
	call stos_locationname
	pop esi
	pop edi
	call dword [DrawWindowElements]

	mov [scrblkupddesc], edi
	//pushad
	mov ebp, [cargodestdata]

	mov eax, [esi+window.activebuttons]
	and eax, 0x3F<<6
	test eax, 1<<0xA
	jnz NEAR packetdumpmode
	test eax, 1<<0x6
	jnz destmode
	test eax, 1<<0x7
	jnz NEAR fullmode
	test eax, 1<<0x8
	jnz NEAR nexthopmode
	test eax, 1<<0x9
	jnz NEAR treemode
	test eax, 1<<0xB
	jnz NEAR routedumpmode
	popad
	ret

uvard stsortlist, 32*0x100/4
uvard stamountlist, 32*0x100
uvard stsortlist2, 0x100/4
uvard stamountlist2, 32*0x100
uvard stflaglist, 32*0x100	//1=packets stranded, 2=is a single hop destination
uvard cargototal, 32
uvard cargorouted, 32
uvard cargounroutable, 32
uvard curstcargorttbl           //relative ptr or 0

destmode:
	call clearstarrays

	call destcountcommon

	xor ebx, ebx
	mov eax, cargototal
	mov ecx, 32
	call cargocountloop
	mov eax, stamountlist
	mov ecx, 32*0x100
	call cargocountloop
	call TrainListDrawHandlerCountTrains

	mov WORD [destlinetextid], ourtext(cpgui_destline)
	call commonprint
	popad
	ret

destcountcommon:
	call gettotalcargocount
	call getfirstcp
	or eax, eax
	jz .doneroutedcount
.routecountloop:
	movzx ecx, BYTE [eax+ebp+cargopacket.cargo]
	movzx edx, WORD [eax+ebp+cargopacket.amount]
	add [cargorouted+ecx*4], edx
	shl ecx, 8
	movzx ebx, BYTE [eax+ebp+cargopacket.destst]
	add ecx, ebx
	add [stamountlist+ecx*4], edx
	call getnextcp
	jnz .routecountloop
	xor ebx, ebx
.stloop:
	mov edx, [stamountlist+ebx*4]
	or edx, edx
	jz .next

	mov ecx, ebx
	and ecx, 0xFF00
	and ebx, 0x00FF
	mov DWORD [packetroutingcheck_flags], 0
	call packetroutingcheck
	imul edx, ebx, station_size
	or ebx, ecx
	movzx edx, BYTE [edx+stationarray+station.displayidx]
	mov [stsortlist+edx+ecx], bl
.next:
	inc ebx
	cmp ebx, 32<<8+0xFF
	jbe .stloop


.doneroutedcount:
	ret

treemode:
	call clearstarrays

	call destcountcommon

	mov edx, 0x80000000
	call dotreeloop
	mov ebx, edx
	sub ebx, 0x80000000
	call TrainListDrawHandlerCountTrains

	mov edx, [trainlistoffset]
	neg edx
	dec edx
	call dotreeloop

	popad
	ret

//edx=list offset
dotreeloop:
	xor edi, edi
.cargoloop:
	cmp DWORD [cargototal+edi*4], 0
	je .nextcargo
	call printheader
	cmp DWORD [cargorouted+edi*4], 0
	je .nextcargo

	push edi

	mov eax, [curstcargorttbl]
	mov ecx, [ebp+eax+routingtable.destrtptr]
	or ecx, ecx
	jz .nofarroutes
	movzx ecx, WORD [ebp+ecx+routingtableentry.lastupdated]
.nofarroutes:

	push ecx
	push DWORD 0
	push DWORD 0x03FFFFFF
	times 7 push DWORD 0xFFFFFFFF
	push eax
	push edi
	push DWORD 0
	call treerecurse
	add esp, 52

	pop edi

.nextcargo:
	inc edi
	cmp edi, 32
	jb .cargoloop
	ret

//[esp+4]=recursion level
//[esp+8]=cargo
//[esp+9]=unused (B)
//[esp+10]=flags
//[esp+12]=current station routing table
//[esp+16]=mask of usable destinations
//[esp+48]=total cost so far
//[esp+52]=date to compare oldest waiting dates to
//[esp+55]=end of function stack
//ebp=[cargodestdata]
//edx=list offset
//esi=window ptr
//c call
//trashes: eax, ebx, ecx, edi
treerecurse:
	cmp DWORD [esp+4], 16
	jae NEAR .ret
	
	movzx ecx, BYTE [esp+8]
	mov edi, [esp+12]
	
	mov eax, [ebp+edi+routingtable.nexthoprtptr]
	or eax, eax
	jz NEAR .ret
.loop:
	cmp [ebp+eax+routingtableentry.cargo], cl
	jne NEAR .next
	
	movzx ebx, BYTE [ebp+eax+routingtableentry.dest]
	bt [esp+16], ebx				//bt is intelligent enough to do: bt BYTE [esp+16+ebx>>3], ebx&7
	jnc NEAR .next
	mov bh, cl
	mov edi, [stamountlist+ebx*4]
	mov [textrefstack+6], edi
	
	mov edi, [esp+12]
	movzx ebx, bl
	or ebx, 0x10000
	mov [textrefstack+4], bx
	
	push eax
	
	mov DWORD [textrefstack+10], 0

	push DWORD [esp+4+52]
	push eax		//placeholder
	times 8 push DWORD 0
	push DWORD [eax+ebp+routingtableentry.destrttable]
	push ecx

//cost = previous cost + this hop route cost + (recursion level > 0) ? comparison date - oldest waiting : 0  
	push edi
	movzx edi, WORD [eax+ebp+routingtableentry.mindays]
	mov [textrefstack+14], edi
	mov [esp+4+40], edi

//	movzx edi, WORD [eax+ebp+routingtableentry.oldestwaiting]
//	or edi, edi
//	jz .nooldestwaiting
//	neg edi
//	add edi, [esp+4+48+4+52]	//comparison date
//.nooldestwaiting:

	movzx edi, WORD [eax+ebp+routingtableentry.dayswaiting]
	imul edi, [cargodestwaitmult]
	shr edi, 8

	mov eax, [esp+4+48+4+4]		//recursion level
	or eax, eax
	jnz .addroutewaitcost
	xor edi, edi
.addroutewaitcost:
	add edi, [esp+4+48+4+48]	//total cost so far
	add [esp+4+40], edi
	add [textrefstack+14], edi

	inc eax
	pop edi
//ends

	push eax

	mov eax, [ebp+edi+routingtable.destrtptr]
	or eax, eax
	jz .doneinner
.inner:
	cmp [eax+ebp+routingtableentry.nexthop], ebx
	jne .nextinner
	cmp [eax+ebp+routingtableentry.cargo], cl
	jne .nextinner
	
	movzx edi, BYTE [eax+ebp+routingtableentry.dest]
	bt DWORD [esp+52+4+16], edi
	jnc .nextinner
	bts DWORD [esp+12], edi
	ror edi, 8
	add edi, ecx
	rol edi, 8
	mov edi, [stamountlist+edi*4]
	add [textrefstack+10], edi

.nextinner:
	mov eax, [ebp+eax+routingtableentry.next]
	or eax, eax
	jnz .inner
.doneinner:

	mov edi, [textrefstack+10]
	mov eax, [textrefstack+6]
	add eax, edi
	mov [textrefstack], eax
	or eax, eax
	jz .donecall

	inc edx
	js .doneprint
	movzx ecx, BYTE [esi+window2ofs+window2.extactualvisible]
	cmp edx, ecx
	jae .doneprint

	mov bx, ourtext(cpgui_treeline)
	mov ecx, [esp]	//recursion level+1
	shl ecx, 4
	call outlistline
.doneprint:

	or edi, edi
	jz .donecall
	call treerecurse
.donecall:
	add esp, 52

	pop eax
	movzx ecx, BYTE [esp+8]


.next:
	mov eax, [ebp+eax+routingtableentry.next]
	or eax, eax
	jnz .loop

.ret:
	ret

//ebp=[cargodestdata]
//eax=packet (unused?), Now not supplied
//ebx=destst
//ecx=cargo<<8
//edx=amount
//[packetroutingcheck_flags]=flags:	1=add cargo quantity to next hop stations' amount
//trashes: none
uvard packetroutingcheck_flags
packetroutingcheck:
	pushad
	mov esi, [curstcargorttbl]
	or esi, esi
	jz NEAR .fail

	xor edi, edi	//found count
	or ebx, 0x10000

	mov esi, [ebp+esi+routingtable.nexthoprtptr]
	or esi, esi
	jz .nonexthops
.nexthoploop:
	cmp ebx, [ebp+esi+routingtableentry.dest]
	jne .notitnh
	cmp ch, [ebp+esi+routingtableentry.cargo]
	jne .notitnh
	add cx, bx
	or BYTE [stflaglist+ecx*4], 2
	sub cx, bx
	inc edi
	test BYTE [packetroutingcheck_flags], 1
	jz .notitnh
	add cx, bx
	add [stamountlist+ecx*4], edx
	sub cx, bx
	push edx
	movzx edx, bx
	imul edx, edx, station_size
	movzx edx, BYTE [edx+stationarray+station.displayidx]
	mov [stsortlist+edx+ecx], bl
	pop edx
.notitnh:
	mov esi, [ebp+esi+routingtableentry.next]
	or esi, esi
	jnz .nexthoploop
.nonexthops:

	mov esi, [curstcargorttbl]
	mov esi, [ebp+esi+routingtable.destrtptr]
	or esi, esi
	jz .nodest
.destloop:
	cmp ebx, [ebp+esi+routingtableentry.dest]
	jne .notitd
	cmp ch, [ebp+esi+routingtableentry.cargo]
	jne .notitd
	inc edi
	test BYTE [packetroutingcheck_flags], 1
	jz .notitd
	push ebx
	push edx
	movzx ebx, WORD [ebp+esi+routingtableentry.nexthop]
	add ecx, ebx
	add [stamountlist+ecx*4], edx
	sub ecx, ebx
	imul edx, ebx, station_size
	movzx edx, BYTE [edx+stationarray+station.displayidx]
	mov [stsortlist+edx+ecx], bl
	pop edx
	pop ebx
.notitd:
	mov esi, [ebp+esi+routingtableentry.next]
	or esi, esi
	jnz .destloop
.nodest:

	or edi, edi
	jnz .ok
	//OH NOES: packet stranded
	add cx, bx
	or BYTE [stflaglist+ecx*4], 1
	movzx ecx, ch
	add [cargounroutable+ecx*4], edx
.ok:

.fail:
	popad
	ret

uvarw destlinetextid
uvarw fulllinetextid
commonprint:
	push edi
	mov edx, [trainlistoffset]
	neg edx
	dec edx
	xor edi, edi
.cargoprintloop:
	cmp DWORD [cargototal+edi*4], 0
	je NEAR .skipcargo
	call printheader

	shl edi, 8
	xor ecx, ecx

.destprintloop:
	movzx eax, BYTE [stsortlist+edi+ecx]		//eax=station id
	push ecx
	cmp al, 0xFF
	je NEAR .skipdest
	mov [textrefstack+6], ax
	add eax, edi
	push eax
	mov bx, statictext(ident)
	test BYTE [stflaglist+eax*4], 1
	jz .notbadrtdest
	mov bx, ourtext(cpgui_destunroutable)
.notbadrtdest:
	inc edx
	js .donedestprint
	movzx ecx, BYTE [esi+window2ofs+window2.extactualvisible]
	cmp edx, ecx
	jae .donedestprint
	mov cx, [destlinetextid]
	mov [textrefstack], cx
	mov eax, [stamountlist+eax*4]
	mov [textrefstack+2], eax
	mov cx, 15
	call outlistline
.donedestprint:
	pop ecx			//dest st id & cargo

	//full mode
	cmp WORD [fulllinetextid], 0
	je .skipfullsourceloop
	movzx eax, BYTE [esi+window2ofs+window2.extactualvisible]
	dec eax
	cmp edx, eax
	jge .skipfullsourceloop

	push ecx

	push edx
	call fullsourceloop
	pop edx
	xor ecx, ecx
.sourceprintloop:
	movzx eax, BYTE [stsortlist2+ecx]		//eax=station id
	push ecx
	cmp al, 0xFF
	je .skipsource
	inc edx
	js .skipsource
	movzx ecx, BYTE [esi+window2ofs+window2.extactualvisible]
	cmp edx, ecx
	jae .skipsource
	mov cx, [fulllinetextid]
	mov [textrefstack], cx
	mov [textrefstack+6], ax
	mov eax, [stamountlist2+eax*4]
	mov [textrefstack+2], eax
	movzx eax, BYTE [esp+4]
	mov [textrefstack+8], ax
	mov cx, 30
	call outlistline
.skipsource:
	pop ecx
	inc ecx
	cmp ecx, 0x100
	jb .sourceprintloop

	add esp, 4

.skipfullsourceloop:
	//full mode ends

.skipdest:
	pop ecx
	inc ecx
	cmp ecx, 0x100
	jb .destprintloop

	shr edi, 8

.skipcargo:
	inc edi
	cmp edi, 32
	jb .cargoprintloop

	pop edi
	ret

cargocountloop:
	cmp DWORD [eax], 0
	jz .noinc
	inc ebx
.noinc:
	add eax, 4
	loop cargocountloop
	ret

fullmode:
	call clearstarrays

	call destcountcommon

	xor ebx, ebx
	mov eax, cargototal
	mov ecx, 32
	call cargocountloop

	mov eax, stamountlist
	xor ecx, ecx
.sourceloop:
	cmp DWORD [eax+ecx*4], 0
	je .sourcenext
	inc ebx
	push ecx
	push eax
	call fullsourceloop
	mov eax, stamountlist2
	mov ecx, 0x100
	call cargocountloop
	pop eax
	pop ecx

.sourcenext:
	inc ecx
	cmp ecx, 32*0x100
	jb .sourceloop

	call TrainListDrawHandlerCountTrains

	mov WORD [destlinetextid], ourtext(cpgui_destline)
	mov WORD [fulllinetextid], ourtext(cpgui_sourceline)
	call commonprint
	mov WORD [fulllinetextid], 0
	popad
	ret

printheader:	
	inc edx
	js .skipheader
	movzx ecx, BYTE [esi+window2ofs+window2.extactualvisible]
	cmp edx, ecx
	jae .skipheader
	mov bx, ourtext(cpgui_cargosum)
	mov eax, [cargounroutable+edi*4]
	or eax, eax
	jz .noextra
	cmp DWORD [curstcargorttbl], 0
	je .noextra
	mov bx, ourtext(cpgui_cargosum_extra)
.noextra:
	mov [textrefstack+14], eax
	mov cx, [newcargotypenames+edi*2]
	mov [textrefstack], cx
	mov ecx, [cargototal+edi*4]
	mov [textrefstack+2], ecx
	mov eax, [cargorouted+edi*4]
	mov [textrefstack+6], eax
	sub ecx, eax
	mov [textrefstack+10], ecx
	xor ecx, ecx
	call outlistline
.skipheader:
	ret

//cl=destination station id
//ch=cargo
//ebp=[cargodestdata]
//trashes eax, ecx, edx
//fills stamountlist2 and stsortlist2
fullsourceloop:
	call clearst2arrays
	push ebx
	call getfirstcp
	or eax, eax
	jz .doneroutedcount
.routecountloop:
	cmp ch, [eax+ebp+cargopacket.cargo]
	jne .sourcenext
	cmp cl, [eax+ebp+cargopacket.destst]
	jne .sourcenext
	//weed out packets not to the destination in question
	movzx edx, WORD [eax+ebp+cargopacket.amount]
	movzx ebx, BYTE [eax+ebp+cargopacket.sourcest]
	add [stamountlist2+ebx*4], edx
	imul edx, ebx, station_size
	movzx edx, BYTE [edx+stationarray+station.displayidx]
	mov [stsortlist2+edx], bl
.sourcenext:
	call getnextcp
	jnz .routecountloop
.doneroutedcount:
	pop ebx
	ret

nexthopmode:
	call clearstarrays
	call clearst2arrays


	call gettotalcargocount
	call getfirstcp
	or eax, eax
	jz .doneroutedcount
.routecountloop:
	movzx ecx, BYTE [eax+ebp+cargopacket.cargo]
	movzx edx, WORD [eax+ebp+cargopacket.amount]
	add [cargorouted+ecx*4], edx
	shl ecx, 8
	movzx ebx, BYTE [eax+ebp+cargopacket.destst]
	add ecx, ebx
	add [stamountlist2+ecx*4], edx
	call getnextcp
	jnz .routecountloop
	xor ebx, ebx
.stloop:
	mov edx, [stamountlist2+ebx*4]
	or edx, edx
	jz .next

	mov ecx, ebx
	and ecx, 0xFF00
	and ebx, 0x00FF
	mov DWORD [packetroutingcheck_flags], 1
	call packetroutingcheck
	or ebx, ecx
.next:
	inc ebx
	cmp ebx, 32<<8+0xFF
	jbe .stloop
.doneroutedcount:

	xor ebx, ebx
	mov eax, cargototal
	mov ecx, 32
	call cargocountloop
	mov eax, stamountlist
	mov ecx, 32*0x100
	call cargocountloop
	call TrainListDrawHandlerCountTrains

	mov WORD [destlinetextid], ourtext(cpgui_nexthopline)
	call commonprint
	popad
	ret

packetdumpmode:
	xor ebx, ebx
	call getfirstcp
	or eax, eax
	jz .nomultiveh
.packetcountloop:
	inc ebx
	call getnextcp
	jnz .packetcountloop
	//dec ebx

.nomultiveh:
	inc ebx
	call TrainListDrawHandlerCountTrains

	call getfirstcp
	or eax, eax
	jz NEAR .done
	mov edi, eax

	mov ax, [esi+window.x]
	mov cx, [esi+window.width]
	add cx, ax
	mov [cpguirightedge], cx
	add ax, 4
	mov dx, [esi+window.y]
	add dx, 18

	mov bx, ourtext(cpgui_pd_amount)
	mov cx, 30
	call outtablevalue
	mov bx, ourtext(cpgui_pd_cargo)
	mov cx, 75
	call outtablevalue
	mov bx, ourtext(cpgui_pd_source)
	mov cx, 100
	call outtablevalue
	mov bx, ourtext(cpgui_pd_dest)
	call outtablevalue
	mov bx, ourtext(cpgui_pd_lastst)
	call outtablevalue
	mov bx, ourtext(cpgui_pd_startdate)
	mov cx, 90
	call outtablevalue
	mov bx, ourtext(cpgui_pd_laststopdate)
	call outtablevalue
	mov bx, ourtext(cpgui_pd_ttl)
	mov cx, 50
	call outtablevalue
	mov bx, ourtext(cpgui_pd_flags)
	mov cx, 75
	call outtablevalue

	mov edx, 1

	mov eax, edi
	or eax, eax
	jz NEAR .done
	mov ecx, [trainlistoffset]
	jecxz .draw
.skiploop:
	call getnextcp
	jz NEAR .done
	loop .skiploop
.draw:
	mov edi, eax
.drawloop:
	call outtableline
	mov eax, edi
	call getnextcp
	jz .done
	mov edi, eax
	cmp dl, [esi+window2ofs+window2.extactualvisible]
	jb .drawloop
.done:
	popad
	ret

uvard scrblkupddesc
uvarw cpguirightedge

outtableline:				//ebp=[cargodestdata]
					//edx=vertical position
					//edi=cargo packet
					//trashes: ecx, eax
	push edx
	mov ax, [esi+window.x]
	mov cx, [esi+window.width]
	//sub cx, 15
	add cx, ax
	mov [cpguirightedge], cx
	add ax, 4
	shl edx, 2
	lea edx, [edx+edx*2+18]
	add dx, [esi+window.y]

	mov bx, statictext(printword)
	mov cx, [ebp+edi+cargopacket.amount]
	mov [textrefstack], cx
	mov cx, 30
	call outtablevalue

	movzx ebx, BYTE [edi+ebp+cargopacket.cargo]
	mov bx, [newcargotypenames+ebx*2]
	mov cx, 75
	call outtablevalue

	mov bx, statictext(outstation)
	movzx cx, BYTE [ebp+edi+cargopacket.sourcest]
	mov [textrefstack], cx
	mov cx, 100
	call outtablevalue

	movzx cx, BYTE [ebp+edi+cargopacket.destst]
	mov [textrefstack], cx
	mov cx, 100
	call outtablevalue

//	cmp BYTE [esi+window.type], cWinTypeStation
//	jne .ok
//	movzx cx, BYTE [ebp+edi+cargopacket.sourcest]
//	cmp cx, [esi+window.id]
//	je .nodisp
//.ok:
	movzx cx, BYTE [ebp+edi+cargopacket.lastboardedst]
	mov [textrefstack], cx
	mov cx, 100
	call outtablevalue
//.nodisp:

	mov bx, statictext(printdate)
	mov cx, [ebp+edi+cargopacket.dateleft]
	mov [textrefstack], cx
	or cx, cx
	jnz .lu_ok
	mov bx, statictext(empty)
.lu_ok:
	mov cx, 90
	call outtablevalue

	mov bx, statictext(printdate)
	mov cx, [ebp+edi+cargopacket.datearrcurloc]
	mov [textrefstack], cx
	mov cx, 90
	call outtablevalue

	mov bx, statictext(printbyte)
	movzx cx, BYTE [ebp+edi+cargopacket.ttl]
	mov [textrefstack], cx
	mov cx, 50
	call outtablevalue

	mov bx, statictext(printhexword)
	mov cx, [ebp+edi+cargopacket.flags]
	mov [textrefstack], cx
	mov cx, 75
	call outtablevalue

	pop edx
	inc edx
	ret

routedumpmode:
	xor ebx, ebx
	call getfirstroute
	jz .noroutes
.routecountloop:
	inc ebx
	call getnextroute
	jnz .routecountloop
.noroutes:
	inc ebx
	call TrainListDrawHandlerCountTrains


	mov ax, [esi+window.x]
	mov cx, [esi+window.width]
	add cx, ax
	mov [cpguirightedge], cx
	add ax, 4
	mov dx, [esi+window.y]
	add dx, 18

	mov bx, ourtext(cpgui_pd_cargo)
	mov cx, 75
	call outtablevalue
	mov cx, 100
	mov bx, ourtext(cpgui_pd_dest)
	call outtablevalue
	mov bx, ourtext(cpgui_rd_via)
	call outtablevalue
	mov bx, ourtext(cpgui_rd_days)
	mov cx, 50
	call outtablevalue
	mov bx, ourtext(cpgui_rd_lastupdate)
	mov cx, 90
	call outtablevalue
	mov bx, ourtext(cpgui_rd_oldestwaiting)
	call outtablevalue
	mov bx, ourtext(cpgui_pd_flags)
	mov cx, 50
	call outtablevalue

	mov edx, 1

	call getfirstroute
	jz NEAR .done
	mov ecx, [trainlistoffset]
	jecxz .draw
.skiploop:
	call getnextroute
	jz NEAR .done
	loop .skiploop
.draw:

.drawloop:
	call outroutetableline
	call getnextroute
	jz .done
	cmp dl, [esi+window2ofs+window2.extactualvisible]
	jb .drawloop
.done:
	popad
	ret

uvarb getfirstroute_flag
getfirstroute:	//sets zf on fail
	mov BYTE [getfirstroute_flag], 0
	mov edi, [curstcargorttbl]
	or edi, edi
	jz .end
	mov edi, [ebp+edi+routingtable.nexthoprtptr]
	or edi, edi
	jnz .end
	mov BYTE [getfirstroute_flag], 1
	mov edi, [curstcargorttbl]
	mov edi, [ebp+edi+routingtable.destrtptr]
	or edi, edi
.end:
	ret

getnextroute:
	or edi, edi
	jz .trynext
	mov edi, [ebp+edi+routingtableentry.next]
	or edi, edi
	jz .trynext
.ret:
	ret
.trynext:
	cmp BYTE [getfirstroute_flag], 1
	je .ret
	mov edi, [curstcargorttbl]
	mov edi, [ebp+edi+routingtable.destrtptr]
	mov BYTE [getfirstroute_flag], 1
	or edi, edi
	ret

outroutetableline:				//ebp=[cargodestdata]
					//edx=vertical position
					//edi=cargo packet
					//trashes: ecx, eax
	push edx
	mov ax, [esi+window.x]
	mov cx, [esi+window.width]
	//sub cx, 15
	add cx, ax
	mov [cpguirightedge], cx
	add ax, 4
	shl edx, 2
	lea edx, [edx+edx*2+18]
	add dx, [esi+window.y]

	movzx ebx, BYTE [edi+ebp+routingtableentry.cargo]
	mov bx, [newcargotypenames+ebx*2]
	mov cx, 75
	call outtablevalue

	mov bx, statictext(ident)
	pushad
	mov esi, [ebp+edi+routingtableentry.dest]
	mov edi, textrefstack
	call stos_locationname
	popad
	mov cx, 100
	call outtablevalue

	mov bx, statictext(ident)
	pushad
	mov esi, [ebp+edi+routingtableentry.nexthop]
	mov edi, textrefstack
	call stos_locationname
	popad
	mov cx, 100
	call outtablevalue

	mov bx, statictext(printword)
	mov cx, [ebp+edi+routingtableentry.mindays]
	mov [textrefstack], cx
	mov cx, 50
	call outtablevalue

	mov bx, statictext(printdate)
	mov cx, [ebp+edi+routingtableentry.lastupdated]
	mov [textrefstack], cx
	mov cx, 90
	call outtablevalue

	mov bx, statictext(printword)
	mov cx, [ebp+edi+routingtableentry.dayswaiting]
	mov [textrefstack], cx
	or cx, cx
	jnz .lu_ok
	mov bx, statictext(empty)
.lu_ok:
	mov cx, 90
	call outtablevalue

	mov bx, statictext(printhexbyte)
	movzx cx, BYTE [ebp+edi+routingtableentry.flags]
	mov [textrefstack], cx
	mov cx, 50
	call outtablevalue

	pop edx
	inc edx
	ret

outtablevalue:				//dx=vertical
					//ax=horizontal
					//bx=text id
					//cx=width
	add ax, cx
	cmp ax, [cpguirightedge]
	ja .done
	pushad
	sub ax, cx
	mov cx, ax
	mov al, 0x10
	mov edi, [scrblkupddesc]
	call [drawtextfn]
	popad
.done:
	ret

outlistline:				//edx=vertical position
					//cx=indent
					//bx=textid
					//trashes: eax, ecx
	push edx
	mov ax, [esi+window.x]
	mov WORD [cpguirightedge], 0xFFFF
	add ax, 4
	add ax, cx
	shl edx, 2
	lea edx, [edx+edx*2+18]
	add dx, [esi+window.y]
	xor cx, cx
	call outtablevalue
	pop edx
	ret

uvard cpguicurvehid
getfirstcp:				//expects ebp=[cargodestdata]
					//returns packet in eax
	mov al, [esi+window.type]
	cmp al, cWinTypeVehicleDetails
	je .veh
	cmp al, cWinTypeStation
	je .st
.bad:
	xor eax, eax
.ret:
	ret
.veh:
	movzx eax, WORD [esi+window.id]
	mov [cpguicurvehid], eax
	mov eax, [cargodestgamedata.vehcplist+ebp+eax*4]
	or eax, eax
	jz getnextcp
	test BYTE [eax+ebp+cargopacket.flags], 2	//not a cargo packet
	jnz getnextcp
	ret
.st:
	movzx eax, WORD [esi+window.id]
	cmp eax, 250
	jae .bad
	imul eax, eax, station_size
	add eax, [stationarray2ptr]
	mov eax, [eax+station2.cargoroutingtableptr]
	or eax, eax
	jz .ret
	mov eax, [eax+ebp+routingtable.cargopacketsfront]
	ret

getnextcp:	//nz=continue, new packet in eax
		//z=no next packet, eax=0
	or eax, eax
	jz .test
.next:
	mov eax, [ebp+eax+cargopacket.nextptr]
	or eax, eax
	jz .test
	test BYTE [eax+ebp+cargopacket.flags], 2	//not a cargo packet
	jnz .next
	or eax, eax
	ret
.zret:
	xor eax, eax
	ret
.test:
	cmp BYTE [esi+window.type], cWinTypeVehicleDetails
	jne .zret
.testnext:
	mov eax, [cpguicurvehid]
	cmp eax, 0xFFFF
	je .zret
	shl eax, vehicleshift
	add eax, [veharrayptr]
	movzx eax, WORD [eax+veh.nextunitidx]
	mov [cpguicurvehid], eax
	cmp eax, 0xFFFF
	je .zret
	mov eax, [cargodestgamedata.vehcplist+ebp+eax*4]
	or eax, eax
	jz .testnext
	ret

gettotalcargocount:	//trashes: none
	cmp BYTE [esi+window.type], cWinTypeVehicleDetails
	je .veh
	cmp BYTE [esi+window.type], cWinTypeStation
	je .st
	ret
.veh:
	pushad
	movzx eax, WORD [esi+window.id]
.nextveh:
	shl eax, vehicleshift
	add eax, [veharrayptr]
	movzx ecx, BYTE [eax+veh.cargotype]
	movzx edx, WORD [eax+veh.currentload]
	add [cargototal+ecx*4], edx
	movzx eax, WORD [eax+veh.nextunitidx]
	cmp eax, 0xFFFF
	jne .nextveh
	popad
	ret
.st:
	pushad
	movzx eax, WORD [esi+window.id]
	imul eax, eax, station_size
	lea esi, [eax+stationarray+station.cargos]
	xor ecx, ecx
	mov ebp, 0xFFF
	testflags newcargos
	jnc .stloop
	mov ebp, 0x7FFF
	add eax, [stationarray2ptr]
	add eax, station2.cargos+stationcargo2.type
.stloop:
	mov ebx, ecx
	testflags newcargos
	jnc .nonewcargos
	movzx ebx, BYTE [eax]
	add eax, stationcargo2_size
	cmp bl, 0xFF
	je .skip
.nonewcargos:
	movzx edx, WORD [esi+stationcargo.amount]
	and edx, ebp
	add [cargototal+ebx*4], edx
.skip:
	inc ecx
	add esi, stationcargo_size
	cmp ecx, 12
	jb .stloop
	popad
	ret

clearstarrays:
	mov edi, stsortlist
	mov ecx, 32*0x100/4
	cld
	or eax, BYTE -1
	rep stosd
	mov edi, stamountlist
	mov ecx, 32*0x100
	xor eax, eax
	rep stosd
	mov edi, stflaglist
	mov ecx, 32*0x100
	xor eax, eax
	rep stosd
	mov edi, cargototal
	mov ecx, 32
	xor eax, eax
	rep stosd
	mov edi, cargorouted
	mov ecx, 32
	xor eax, eax
	rep stosd
	mov edi, cargounroutable
	mov ecx, 32
	xor eax, eax
	rep stosd
	ret

clearst2arrays:
	pushad
	mov edi, stsortlist2
	mov ecx, 0x100/4
	cld
	or eax, BYTE -1
	rep stosd
	mov edi, stamountlist2
	mov ecx, 32*0x100
	xor eax, eax
	rep stosd
	popad
	ret
