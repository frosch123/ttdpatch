#include <std.inc>
#include <flags.inc>
#include <proc.inc>
#include <textdef.inc>
#include <house.inc>
#include <human.inc>
#include <town.inc>
#include <grf.inc>
#include <ptrvar.inc>
#include <bitvars.inc>
#include <idf.inc>
#include <objects.inc>
#include <window.inc>
#include <windowext.inc>
#include <imports/gui.inc>
#include <misc.inc>
#include <imports/dropdownex.inc>
#include <patchdata.inc>
#include <pusha.inc>
#include <player.inc>

extern failpropwithgrfconflict
extern curspriteblock
extern grfstage
extern RefreshWindowArea
extern player2array
extern numtwocolormaps

uvard objectsdataiddata,256*idf_dataid_data_size
uvard objectsdataidcount

global objectsdefandclassnames
uvard objectsdefandclassnames, 512

// idf data id management
extern idf_increaseusage
extern idf_decreaseusage
extern idf_getdataidbygameid

// objects id management
extern objectsdataidtogameid
extern objectsgameiddata
extern objectsgameidcount

// objects id management per grf
extern curgrfobjectgameids

global objectidf
vard objectidf
istruc idfsystem
	at idfsystem.dataid_dataptr, 		dd objectsdataiddata
	at idfsystem.dataid_lastnumptr,		dd objectsdataidcount
	at idfsystem.dataidtogameidptr,		dd objectsdataidtogameid
	at idfsystem.gameid_dataptr,		dd objectsgameiddata
	at idfsystem.gameid_lastnumptr,		dd objectsgameidcount
	at idfsystem.curgrfidtogameidptr,	dd curgrfobjectgameids
	at idfsystem.dataidcount,		dd NOBJECTS
	at idfsystem.gameidcount,		dd NOBJECTS
iend
endvar

// Properties for objects (gameid based)
extern objectclass				// a word id to the actuall objectclasses
extern objectnames				// a TextID
extern objectspriteblock			// to get GRF specific TextIDs
extern objectavailability
extern objectsizes
extern objectcostfactors
extern objectstartdates
extern objectenddates
extern objectflags
extern objectanimframes
extern objectanimspeeds
extern objectanimtriggers
extern objectremovalcostfactors
extern objectcallbackflags
extern objectheights

// Properties for classes of objects
extern objectclasses			// the actual defined classes
extern objectclassesnames		// the TextID for the name
extern objectclassesnamesprptr		// the spriteblockptr for this TextID
extern numobjectclasses			// how many classes we have have loaded already

// special functions to handle special object properties
//
// in:	eax=special prop-num
//	ebx=offset (first id)
//	ecx=num-info
//	edx->feature specific data offset
//	esi=>data
// out:	esi=>after data
//	carry clear if successful
//	carry set if error, then ax=error message
// safe:eax ebx ecx edx edi

uvard curobjectclass
exported setobjectclass
.nextdefine:
	push ecx
// first we define the class, if the class fails to load, we can't select the object anyway,
// so storeing and resolveing gameid isn't need either.
.loadclass:
	lodsd
	
	mov ecx,[numobjectclasses]
	mov edi,objectclasses
	test ecx, ecx
	jz .createnewclass
	repne scasd
	je .classalreadydefined
	
	cmp dword [numobjectclasses], NOBJECTSCLASSES
	jb .createnewclass 
	
.nomoreclasses:
	pop ecx
	mov al,GRM_EXTRA_OBJECTS
	jmp failpropwithgrfconflict
	
.createnewclass:
	// edi points to end of objectclasses
	mov dword [edi], eax
	inc dword [numobjectclasses]

	jmp .nocorrection
	
.classalreadydefined:
	sub edi, 4 // Points to the entry after

.nocorrection:
	sub edi, objectclasses
	shr edi, 2
	mov [curobjectclass], edi
	
// creates a new gameid:
// in: ebx = action id,  edx = feature in framework
// out: 
// carry set = error, al = code why:  0 = already defined  1 = no more gameids free
// eax = gameid
	mov edx, objectidf
	extcall idf_createnewgameid
	jnc .ok
	cmp ax, 0
	je .alreadyset
.toomany:
	pop ecx
	mov ax, GRM_EXTRA_OBJECTS
	jmp failpropwithgrfconflict
.alreadyset:
	pop ecx
	mov ax, ourtext(invalidsprite)
	stc
	ret
.ok:
	mov ecx, [curobjectclass]
	mov word [objectclass+eax*2], cx
	
	mov ecx, dword [curspriteblock]
	mov dword [objectspriteblock+eax*4],ecx

.endofthisdefine:
// Now we default all of the poperties for it
// Required properties (leaving these unset voids the object)
	mov word [objectnames+eax*2], 0
	mov byte [objectsizes+eax], 0

// Optional properties
	mov byte [objectavailability+eax], 0
	mov byte [objectcostfactors+eax], 2
	mov dword [objectstartdates+eax*4], 0
	mov dword [objectenddates+eax*4], 0
	mov word [objectflags+eax*2], 0
	mov word [objectanimframes+eax*2], -1
	mov byte [objectanimspeeds+eax], 0
	mov byte [objectanimtriggers+eax], 0
	mov byte [objectremovalcostfactors+eax], 2
	mov word [objectcallbackflags+eax*2], 0
	mov byte [objectheights+eax], -1

	pop ecx
	inc ebx
	dec ecx
	jnz .nextdefine
	
// all settings are ok
	clc
	ret

// clear the dataids for creating new game or if the game doesn't have one yet
exported clearobjectdataids
	pusha
	xor eax,eax
	mov edi,objectsdataiddata
	mov ecx,NOBJECTS*idf_dataid_data_size/4
	rep stosd
	popa
	ret

// special functions to handle station properties
//
// in:	eax=special prop-num
//	ebx=offset (objectid)
//	ecx=num-info
//	esi=>data
// out:	esi=>after data
//	carry clear if successful
//	carry set if error, then ax=error message
exported setobjectclasstexid
.nextobjectclass:
	lodsw
	movzx edx, word [objectclass+ebx*2]
	cmp ah, 0xD0
	jb .nofix
	cmp ah, 0xD3
	ja .nofix
	add ah, 0x04
.nofix:
	mov word [objectclassesnames+edx*2], ax
	mov eax, [curspriteblock]
	mov dword [objectclassesnamesprptr+edx*4], eax
	inc ebx
	loop .nextobjectclass
	clc
	ret
.fail:
	mov ax, ourtext(invalidsprite)
	stc
	ret

// Based off the specs, I believe it is meant to work more or less this way
exported setobjectbuyfactor
	lodsb
	mov byte [objectcostfactors+ebx], al
	mov byte [objectremovalcostfactors+ebx], al
	clc
	ret

// Select window
%assign win_objectgui_padding 10 

%assign win_objectgui_dropwidth 12 
%assign win_objectgui_dropheight 12
%assign win_objectgui_drop1y 20

%assign win_objectgui_previewheight 72

guiwindow win_objectgui,200,195
	guicaption cColorSchemeDarkGreen, ourtext(objectgui_title)
	guiele background,cWinElemSpriteBox,cColorSchemeDarkGreen,x,0,-x2,0,y,14,-y2,0,data,0
	// Dropdown 1
	guiele dropdown1_text,cWinElemSpriteBox,cColorSchemeGrey,x,win_objectgui_padding,-x2,win_objectgui_padding+win_objectgui_dropwidth+1,y,win_objectgui_drop1y,h,win_objectgui_dropheight,data,0
	guiele dropdown1,cWinElemTextBox,cColorSchemeGrey,-x,win_objectgui_padding+win_objectgui_dropwidth,-x2,win_objectgui_padding,y,win_objectgui_drop1y,h,win_objectgui_dropheight,data,statictext(txtetoolbox_dropdown)
	// Preview
	guiele preview,cWinElemSpriteBox,cColorSchemeGrey,x,win_objectgui_padding,-x2,win_objectgui_padding,y,40,h,win_objectgui_previewheight,data,0
	// Dropdown 2
	guiele dropdown2_text,cWinElemSpriteBox,cColorSchemeGrey,x,win_objectgui_padding,-x2,win_objectgui_padding+win_objectgui_dropwidth+1,y,40+win_objectgui_previewheight+8,h,win_objectgui_dropheight,data,0
	guiele dropdown2,cWinElemTextBox,cColorSchemeGrey,-x,win_objectgui_padding+win_objectgui_dropwidth,-x2,win_objectgui_padding,y,40+win_objectgui_previewheight+8,h,win_objectgui_dropheight,data,statictext(txtetoolbox_dropdown)
	// Build button
	guiele buildbtn, cWinElemTextBox, cColorSchemeGrey, x, win_objectgui_padding, -x2, win_objectgui_padding, -y, win_objectgui_padding+win_objectgui_dropheight, h, win_objectgui_dropheight, data, ourtext(objectbuild)
endguiwindow

svarw win_objectgui_curclass
svard win_objectgui_curobject

exported win_objectgui_create
	bts dword [esi+window.activebuttons], ebx
	call [RefreshWindowArea]
	pusha
	mov cl, cWinTypeTTDPatchWindow
	mov dx, cPatchWindowObjectGUI // window.id
	push ebx
	call dword [BringWindowToForeground]
	pop ebx
	test esi,esi
	jz .noold
	mov byte [esi+window.data], bl
	or byte [esi+window.flags], 7
	popa
	ret

.noold:
	push ebx
	mov eax, 100 + (100<<16) // x + (y << 16)
	mov ebx, win_objectgui_width + (win_objectgui_height << 16)
	mov cx, cWinTypeTTDPatchWindow		// window type
	mov dx, -1				// -1 = direct handler
	mov ebp, addr(win_objectgui_winhandler)
	call dword [CreateWindow]
	pop ebx
	mov dword [esi+window.elemlistptr], addr(win_objectgui_elements)
	mov word [esi+window.id], cPatchWindowObjectGUI // window.id
	mov byte [esi+window.data], bl
	or byte [esi+window.flags], 7
	call doesclasshaveusableobjects
	popa
	ret

win_objectgui_winhandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jz near win_objectgui_redraw
	cmp dl, cWinEventClick
	jz near win_objectgui_clickhandler
	cmp dl, cWinEventDropDownItemSelect
	jz near win_objectgui_dropdowncallback
	cmp dl, cWinEventTimer
	jz win_objectgui_timer

	cmp dl, cWinEventMouseToolClick
	je near win_objectgui_mousetoolcallback
	cmp dl, cWinEventMouseToolClose
	je near win_objectgui_setmousetool.noobject

	cmp dl, cWinEventGRFChanges
	je near win_objectgui_grfchanges
	ret
	
win_objectgui_grfchanges:
	pusha
	mov word [win_objectgui_curobject], -1
	mov word [win_objectgui_curclass], -1
	
	// To prevent possible crashes, if we have any active drop downs, we close them
	bt dword [esi+window.activebuttons], win_objectgui_elements.dropdown1_id
	jnc .nodrop1
	mov ecx, win_objectgui_elements.dropdown1_id
	extcall GenerateDropDownExPrepare
	jmp .nodrop2

.nodrop1:
	bt dword [esi+window.activebuttons], win_objectgui_elements.dropdown2_id
	jnc .nodrop2
	mov ecx, win_objectgui_elements.dropdown2_id
	extcall GenerateDropDownExPrepare

.nodrop2:
	call doesclasshaveusableobjects
	popa
	ret

win_objectgui_timer:
	mov dword [esi+window.activebuttons], 0
	
	cmp byte [esi+window.data], 0
	jne .toolbar

.ok:
	mov al,[esi]
	mov bx,[esi+window.id]
	call dword [invalidatehandle]
//	or byte [esi+window.flags], 7
	ret
	
.toolbar:
	movzx eax, byte [esi+window.data]
	mov byte [esi+window.data], 0
	mov cl, 1
	xor dx, dx
	call [FindWindow]
	btr dword [esi+window.activebuttons], eax
	jmp [RefreshWindowArea]
	
win_objectgui_redraw:
	push esi
	call dword [DrawWindowElements]	
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]
		
	push ecx
	push edx
	cmp word [win_objectgui_curclass], -1
	je .noclassselected
	
	movzx ebx, word [win_objectgui_curclass]
	mov eax, dword [objectclassesnamesprptr+ebx*4]
extern curmiscgrf
	mov [curmiscgrf], eax
	movzx eax, word [objectclassesnames+ebx*2]
	
	mov [textrefstack],eax
	mov bx,statictext(blacktext)
	add cx, win_objectgui_elements.dropdown1_text_x+2
	add dx, win_objectgui_elements.dropdown1_text_y+1
	call [drawtextfn]

.noclassselected:
	pop edx
	pop ecx

	cmp word [win_objectgui_curobject], -1
	je .noobjectselected

	movzx ebx, word [win_objectgui_curobject]
	mov eax, dword [objectspriteblock+ebx*4]
	mov [curmiscgrf], eax
	movzx eax, word [objectnames+ebx*2]

	cmp ah, 0xD0
	jb .nofix
	cmp ah, 0xD3
	ja .nofix
	add ax, 0x400

.nofix:
	mov [textrefstack],eax
	mov bx,statictext(blacktext)
	add cx, win_objectgui_elements.dropdown2_text_x+2
	add dx, win_objectgui_elements.dropdown2_text_y+1
	call [drawtextfn]

	call drawobjectproperties
	call drawobjectpreviewsprite

.noobjectselected:
	pop esi
	ret

// Draws the objects specifications
drawobjectproperties:
	push ecx
	push edx
	mov esi, [esp+0xC]
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]
	add cx, win_objectgui_padding+1
	add dx, win_objectgui_elements.dropdown2_text_y+win_objectgui_dropheight+8

	cmp byte [gamemode], 2
	je .showsize

	push edx
	push eax
	movzx ebx, word [win_objectgui_curobject]
	push ebx
	call GetObjectSize
	movzx eax, dl
	mul dh
	mov dx, ax
	mov eax, ebx
	and dword [ObjectCost], 0
	call BuildObjectCost
	mov dword [textrefstack], ebx
	pop eax
	pop edx

	push ecx
	push edx
	mov bx, ourtext(objectgui_cost)
	call [drawtextfn]
	pop edx
	pop ecx
	add dx, 12

.showsize:
	push edx
	push dword [win_objectgui_curobject]
	call GetObjectSize
	mov word [textrefstack], dx
	pop edx

	mov bx, ourtext(objectgui_size)
	call [drawtextfn]
	pop edx
	pop ecx
	ret

// Draws the objects preview sprite onto the window
// - Updated to create a drawing buffer to prevent overlap
// - Now also uses a compatible full tile drawing routine
drawobjectpreviewsprite:
	call .createbuffer
	jz .invalid

	pusha
	movzx eax, word [win_objectgui_curobject]
	mov esi, 0
	mov byte [grffeature], 0xF
	call getnewsprite
	push eax	 // Data Pointer
	push ebx	 // Sprite Availability
	push dword 3 // Construction stage (always fully built for objects)

	mov esi, [esp+0x30] // Restore window handle
	call .getcolours

	mov edi, baTempBuffer1
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]
	add cx, win_objectgui_elements.preview_x+89
	add dx, win_objectgui_elements.preview_y+33

	push ebx
	push dword 0xF
	call DrawObjectTileSelWindow
	popa

.invalid:
	ret

// Out:	z flag, clear if failed
.createbuffer:
	pusha
	mov edi, baTempBuffer1
	mov esi, [esp+0x28] // Restore window handle
	mov byte [edi], 0

	//	DX,BX = X,Y CX,BP = width,height
	mov dx, [esi+window.x]
	mov bx, [esi+window.y]
	add dx, win_objectgui_elements.preview_x+1	// So it doesn't clip the edges
	add bx, win_objectgui_elements.preview_y+1
	mov cx, win_objectgui_elements.preview_width-2
	mov bp, win_objectgui_elements.preview_height-2

extern MakeTempScrnBlockDesc
	call [MakeTempScrnBlockDesc]
	popa
	ret

// In:	esi = Window handle
// Out:	esi = Window handle
//	 bx = Recolour mapping
.getcolours:
	mov edx, 0x10	// Get the recolour to defaultly apply
	cmp byte [gamemode], 2
	je .noowner
	movzx edx, byte [human1]

.noowner:
	push edx // Owner of the window
	push dword 0 // No tile index
	push dword [win_objectgui_curobject] // Current selected object id
	call GetObjectColourMap
	ret

#if 0	// Orginial method of previewing the object
	pusha
	mov esi, [esp+0x24]
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]
	add cx, win_objectgui_elements.preview_x+89 // 59
	add dx, win_objectgui_elements.preview_y+33 // 36

	movzx eax, word [win_objectgui_curobject]
	push esi
	xor esi, esi
	mov byte [grffeature], 0xF
	call getnewsprite
	pop esi
	jc .nosprite

	inc eax
	call getobjectpreviewsprite
	call [drawspritefn]

.nosprite:
	popa
	ret

// In:	eax = pointer to the action2 data
//	ebx = sprites available
// Out:	ebx = sprite with recolour map
getobjectpreviewsprite:
	mov ebx, dword [eax]
	btr ebx, 31
	jnc .notgrfsprite

extern exscurfeature, exsspritelistext, randomfn
	mov byte [exscurfeature], 0xF
	mov byte [exsspritelistext], 1

.notgrfsprite:
	btr ebx, 30
	test bx, bx
	jns .norecolour
	call recolourobjectsprite

.norecolour:
	ret

// In:	esi = window pointer
// Out:	ebx = sprite plus recolour 
recolourobjectsprite:
	push edx
	push ebx

	mov edx, 0x10
	cmp byte [gamemode], 2
	je .noowner
	movzx edx, byte [human1]

.noowner:
	push edx // Owner of the window
	push dword 0 // No tile index
	push dword [win_objectgui_curobject] // Current selected object id

	call GetObjectColourMap
	shl ebx, 16
	mov bx, [esp]
	pop edx // We don't want to change ebx back
	pop edx
	ret
#endif

win_objectgui_clickhandler:
	call dword [WindowClicked]
	jns .click
	ret

.click:
	cmp cl, win_objectgui_elements.caption_close_id
	jne .notdestroy
	jmp [DestroyWindow]

.notdestroy:
	cmp cl, win_objectgui_elements.caption_id
	jne .nottilebar
	jmp dword [WindowTitleBarClicked]

.nottilebar:
	cmp cl, win_objectgui_elements.dropdown1_text_id
	je near win_objectgui_classdropdown.text
	cmp cl, win_objectgui_elements.dropdown1_id
	je near win_objectgui_classdropdown
	
	cmp cl, win_objectgui_elements.dropdown2_text_id
	je near win_objectgui_objectdropdown.text
	cmp cl, win_objectgui_elements.dropdown2_id
	je near win_objectgui_objectdropdown

	cmp cl, win_objectgui_elements.buildbtn_id
	je near win_objectgui_objectbuild

	ret
	
	
win_objectgui_classdropdown.text:
	inc cl

win_objectgui_classdropdown:
	movzx ecx, cl
	extcall GenerateDropDownExPrepare
	jnc .noolddrop
	ret

.noolddrop:
	push ecx
	xor eax,eax
	xor ebx,ebx

.loop:
	cmp al, MAXDROPDOWNEXENTRIES
	jae .done
	cmp al,[numobjectclasses]
	jae .done

	movzx ecx, word [objectclassesnames+eax*2]
	mov dword [DropDownExList+4*eax],ecx
	mov ecx, dword [objectclassesnamesprptr+eax*4]
	mov dword [DropDownExListGrfPtr+4*eax],ecx
	inc eax
	jmp .loop
	
.done:
	mov dword [DropDownExList+4*eax],-1	// terminate it
	mov byte [DropDownExMaxItemsVisible], 12
	mov word [DropDownExFlags], 11b
	
	movzx edx, word [win_objectgui_curclass]
	
	pop ecx
	extjmp GenerateDropDownEx

// Used to cache the list generated by the drop down
// (reduces issues with objects changing availability whilst open)
uvarw objectddgameidlist, MAXDROPDOWNEXENTRIES

// Notes: ids' are always >0 due to the way idf works
win_objectgui_objectdropdown.text:
	inc cl

win_objectgui_objectdropdown:
	movzx ecx, cl
	push ecx
	bt dword [esi+window.disabledbuttons], ecx
	pop ecx
	jc .ret

	extcall GenerateDropDownExPrepare
	jnc .noolddrop

.ret:
	ret

.noolddrop:
	push ecx
	push ebx
	push edx

	xor eax, eax
	xor ebx, ebx
	xor edx, edx

	// Generate our list?
	mov bx, [win_objectgui_curclass]
	mov dword [esp], -1

.loop:
	inc edx
	cmp al, MAXDROPDOWNEXENTRIES
	jae .done
	cmp edx, [objectsgameidcount]
	ja .done // First ids are always +1 against the actual count

	push edx
	push ebx
	call validobject
	jc .loop

// Works out the selected item's index [-1 if never added to list] (Lakie)
	cmp dx, word [win_objectgui_curobject]
	jne .notcur
	mov dword [esp], eax

.notcur:
	mov cx, word [objectnames+edx*2]
	cmp ch, 0xD0
	jb .nofix
	cmp ch, 0xD3
	ja .nofix
	add cx, 0x400

.nofix:
	mov dword [DropDownExList+4*eax], ecx
	mov ecx, dword [objectspriteblock+edx*4]
	mov dword [DropDownExListGrfPtr+eax*4], ecx
	mov word [objectddgameidlist+eax*2], dx
	inc eax
	jmp .loop

.done:
	mov dword [DropDownExList+4*eax],-1	// terminate it
	mov byte [DropDownExMaxItemsVisible], 12
	mov word [DropDownExFlags], 11b

	test byte [expswitches],EXP_PREVIEWDD
	jz .nopreview

	// Used for the setting up previewdd
	mov word [DropDownExListItemExtraWidth], 38
	mov word [DropDownExListItemHeight], 23
	mov byte [DropDownExMaxItemsVisible], 7
	mov dword [DropDownExListItemDrawCallback], DrawObjectDDPreview //makestationseldropdown_callback

.nopreview:
	pop edx
	pop ebx
	pop ecx
	extjmp GenerateDropDownEx

win_objectgui_dropdowncallback:
	cmp cl, win_objectgui_elements.dropdown1_id
	je .selectclass
	cmp cl, win_objectgui_elements.dropdown2_id
	je .selectobject
	ret

.selectclass:
	cmp word [win_objectgui_curclass], ax
	je .noclasschange

	mov word [win_objectgui_curclass], ax
	mov word [win_objectgui_curobject], -1
	call doesclasshaveusableobjects

.noclasschange:
	mov al,[esi]
	mov bx,[esi+window.id]
	call dword [invalidatehandle]
	jmp win_objectgui_setmousetool.noobject

.selectobject:
	push ebx
	mov bx, word [objectddgameidlist+eax*2]
	mov word [win_objectgui_curobject], bx
	pop ebx
	jmp .noclasschange

win_objectgui_objectbuild:
	bt dword [esi+window.disabledbuttons], win_objectgui_elements.buildbtn_id
	jc .disabled

	bt dword [esi+window.activebuttons], win_objectgui_elements.buildbtn_id
	jc win_objectgui_setmousetool.noobject
	jmp win_objectgui_setmousetool

.disabled:
	ret

// Functions which control the mouse tool
win_objectgui_setmousetool:
	cmp word [win_objectgui_curobject], byte -1
	je .noobject

	push esi
	mov dx, [esi+window.id]
	mov ah, cWinTypeTTDPatchWindow
	mov al, 0x1
	mov ebx, 0xFF9

extern setmousetool
	call [setmousetool]
	pop esi
	
	movzx edx, word [win_objectgui_curobject]
	movzx edx, byte [objectsizes+edx]

	mov ax, dx
	and ax, 0xF
	and dx, 0xF0
	shl ax, 4

	mov word [highlightareainnerxsize], ax
	mov word [highlightareainnerysize], dx
	mov word [highlightareaouterxsize], ax
	mov word [highlightareaouterysize], dx

	bts dword [esi+window.activebuttons], win_objectgui_elements.buildbtn_id 
	call dword [RefreshWindowArea] // Refresh the screen
	ret

// Reset the mouse tool
.noobject:
	push esi
	mov ebx, 0
	mov al, 0
	call [setmousetool]
	pop esi

	btr dword [esi+window.activebuttons], win_objectgui_elements.buildbtn_id
	call dword [RefreshWindowArea] // Refresh the screen
	ret

win_objectgui_mousetoolcallback:
	cmp byte [curmousetoolwintype], cWinTypeTTDPatchWindow // Is this depot clone vehicle active?
	jne .notactive

	movzx edx, word [win_objectgui_curobject]
	shl edx, 8

	movzx edi, word [mousetoolclicklocxy]
	rol di, 4 // Store the x, y in the ax, cx registors
	mov eax, edi
	mov ecx, edi
	rol cx, 8
	and ax, 0x0FF0
	and cx, 0x0FF0
	ror di, 4

	mov bl, 0xB
	mov word [operrormsg1], ourtext(objecterr)
	push esi
extern BuildObject_actionnum
	dopatchaction BuildObject
	pop esi

	cmp ebx, 1<<31
	je .notactive

	push esi
	mov bx, ax
	mov eax, 0x1D
	mov esi, -1
extern generatesoundeffect
	call [generatesoundeffect]
	pop esi
	call win_objectgui_setmousetool.noobject

.notactive:
	ret

// Called to workout if we have any extries for current class
// (sets the current object to the first found one if it does)
doesclasshaveusableobjects:
	push ecx
	push ebx
	call win_objectgui_setmousetool.noobject

// Check that we do have atleast one class loaded, to prevent gibberish (Lakie)
	cmp byte [numobjectclasses], 0
	je .noclasses

// We always try to select the first class (eis_os)
//	cmp word [win_objectgui_curclass], -1	
//	je .no
	
	cmp word [win_objectgui_curclass], -1	
	jne .validclass
//	cmp byte [numobjectclasses], 0
//	jbe .validclass
	mov word [win_objectgui_curclass], 0
	
.validclass:
	mov bx, [win_objectgui_curclass]

// We should probably check if this current object is still valid first (Lakie)
// (Because the gui may be openned later when the object is no-longer valid)
	cmp word [win_objectgui_curobject], -1
	je .noobject

	mov cx, [win_objectgui_curobject]
	push ebx
	push ecx
	call validobject
	jnc .skip

.noobject:
	push eax
	xor ecx, ecx
	xor eax, eax

.loop:
	inc ecx
	cmp ecx, [objectsgameidcount]
	ja .done

	push ecx
	push ebx
	call validobject
	jc .loop

	inc al

.done:
	cmp al, 0
	pop eax
	je .no

	mov word [win_objectgui_curobject], cx

.skip:
	pop ebx
	pop ecx
	btr dword [esi+window.disabledbuttons], win_objectgui_elements.dropdown2_id
	btr dword [esi+window.disabledbuttons], win_objectgui_elements.buildbtn_id
	ret

.noclasses:
	mov word [win_objectgui_curclass], -1
	
.no:
	pop ebx
	pop ecx
	mov word [win_objectgui_curobject], -1
	bts dword [esi+window.disabledbuttons], win_objectgui_elements.dropdown2_id
	bts dword [esi+window.disabledbuttons], win_objectgui_elements.buildbtn_id
	ret
#if 0
// We can use cWinEventGRFChanges for this (eis_os)
.external:
	push ecx // called upon newgrf change to update the window
	push edx
	push esi
	mov cl, cWinTypeTTDPatchWindow
	mov dx, cPatchWindowObjectGUI
	call [FindWindow]
	jz .notopen
	call doesclasshaveusableobjects

.notopen:
	pop esi
	pop edx
	pop ecx
	ret
#endif

// ************************************ Object Pool Functions *************************************

global objectpoolclear
objectpoolclear:
	pusha
	mov edi, objectpool		// first, fill it with zeroes
	xor eax, eax
	mov ecx, NACTIVEOBJECTS*(object_size/4)
	rep stosd
	popa
	ret
	
// ********************************** Externs for the code below **********************************

extern CheckForVehiclesInTheWay
extern actionhandler
extern gettileinfo
extern miscgrfvar
extern callback_extrainfo
extern curcallback
extern grffeature
extern getnewsprite
extern randomfn
extern processtileaction2
extern addgroundsprite
extern addsprite
extern objectpool_ptr
extern displayfoundation

extern redrawtile
extern curplayerctrlkey
extern invalidatetile
extern getyear4fromdate
extern reduceyeartoword
extern deftwocolormaps

// *************************************** Helper functions ***************************************

// Validates if a object is 'available' for use
// Out:	carry = set if not valid for usage
global validobject
proc validobject
	arg gameid, classid
	_enter

	push eax
	push ebx
	push ecx
	movzx ecx, word [%$classid]
	movzx ebx, word [%$gameid]

	cmp cx, byte -1
	je .noclass

	cmp word [objectclass+ebx*2], cx
	jne near .fail

.noclass:
	cmp word [objectnames+ebx*2], 0
	je near .fail

	mov word [operrormsg2], ourtext(objecterr_noaction3)
	cmp dword [objectsgameiddata+ebx*idf_gameid_data_size+idf_gameid_data.act3info], 0
	je near .fail

	mov word [operrormsg2], ourtext(objecterr_wrongclimate)
	movzx ax, byte [climate]
	bt word [objectavailability+ebx], ax
	jnc near .fail

	mov word [operrormsg2], ourtext(objecterr_wronggamemode)
	test word [objectflags+ebx*2], OF_SCENERIOEDITOR
	jz .notScenerioOnly
	cmp byte [gamemode], 2
	jne near .fail

.notScenerioOnly:
	test word [objectflags+ebx*2], OF_NEEDSOWNER
	jz .notGameplayOnly
	cmp byte [gamemode], 1
	jne .fail

.notGameplayOnly:
	movzx eax, word [currentdate]
	add eax, 701265
	add eax,[landscape3+ttdpatchdata.daysadd]

	mov ecx, dword [objectstartdates+ebx*4]
	cmp ecx, 701265
	jbe .skipstart // jump if carry or zero
	
	mov word [operrormsg2], ourtext(objecterr_tooearly)
	cmp eax, ecx
	jb .writeyear

.skipstart:
	add ecx, 365 // Add roughly a year
	cmp dword [objectenddates+ebx*4], ecx
	jbe .skipend

	mov ecx, dword [objectenddates+ebx*4]
	cmp ecx, 701265
	jbe .skipend

	mov word [operrormsg2], ourtext(objecterr_toolate)
	cmp eax, ecx
	ja .writeyear

.skipend:
	pop ecx
	pop ebx
	pop eax
	clc
	_ret

.writeyear:
	xchg eax, ecx
	call GetObjectYear
	mov dword [textrefstack+0], eax

.fail:
	pop ecx
	pop ebx
	pop eax
	stc
	_ret
endproc

// In:	eax = days since year 0
// Out:	eax = year from year 0
GetObjectYear:
	push edx
	call getyear4fromdate

	// Calculate the ~3 years part
	sub edx, 366 // First year is always a leppia year
	jc .done
	inc eax

	sub edx, 365 // Second year
	jc .done
	inc eax

	sub edx, 365 // Third year (last one)
	jc .done
	inc eax

.done:
	pop edx
	ret

// Out:	carry = error because of bad game id
//	edx = tiles to loop
proc GetObjectSize
	arg gameid

	_enter
	mov word [operrormsg2], ourtext(objecterr_invalidsize)
	movzx edx, word [%$gameid]
	test edx, edx
	je .default

	movzx dx, byte [objectsizes+edx] // Get the object size and store
	shl dx, 4
	shr dl, 4
	and dx, 0xF0F
	jz .default

	clc
	_ret

.default:
	mov dx, 0xF0F
	stc
	_ret
endproc

// In:	edx = number of tiles X and Y to loop
//	bh = object owner
//	edi = origin tile
// Out:	carry = set on error
//	edx = tile count
proc LoopTiles
	arg checkfn, actualfn, id, poolid
	slocal tilecount

	_enter
	push ecx
	push edx
	push edi
	and dword [%$tilecount], 0
	xor ecx, ecx

.nexty:
	and cl, 0xF0
	push edx
	push edi

.nextx:
	push eax
	push edx
	movzx eax, word [%$id]
	movzx edx, word [%$poolid]

	call [%$checkfn]
	jc .skipTile

	call [%$actualfn]
	jc .failpop
	inc byte [%$tilecount]

.skipTile:
	pop edx
	pop eax

	lea edi, [edi+1]
	inc cl
	dec dl
	jnz .nextx

	pop edi
	pop edx
	lea edi, [edi+256]
	add cl, 0x10
	dec dh
	jnz .nexty

	pop edi
	pop edx
	pop ecx
	mov edx, [%$tilecount]
	clc
	_ret

.failpop:
	pop edx // Inner
	pop eax
	pop edi // Y
	pop edx
	pop edi // X
	pop edx
	pop ecx
	mov edx, 0
	stc
	_ret
endproc

// In:	edi = tile
RedrawObjectTile:
	pusha
	mov esi, edi
	call redrawtile
	popa
	clc
	ret

// In:	eax = game id
//	ecx = pool id
//	edi = object origin
SetObjectPoolEntry:
	cmp edi, 0
	je .noOrigin

	push eax
	push ecx
	push ebx
	imul ecx, object_size
	mov word [objectpool+ecx+object.origin], di

	push eax // Get and store the date since year 0
	movzx eax, word [currentdate]
	add eax, 701265
	add eax, [landscape3+ttdpatchdata.daysadd]
	call GetObjectYear
	call reduceyeartoword
	mov word [objectpool+ecx+object.buildyear], ax
	pop eax

	mov bx, word [objectflags+eax*2]
	mov word [objectpool+ecx+object.flags], bx
	mov bx, [objectsgameiddata+eax*idf_gameid_data_size+idf_gameid_data.dataid]
	mov word [objectpool+ecx+object.dataid], bx

	cmp byte [gamemode], 2
	jne .companyowned
	call [randomfn]
	mov byte [objectpool+ecx+object.colour], al

.companyowned:
	pop ebx
	pop ecx
	pop eax
	ret

.noOrigin:
	pusha
	mov edi, objectpool		// Set the entry to be wiped
	imul ecx, object_size
	add edi, ecx

	xor eax, eax
	mov ecx, (object_size / 4)	// Wipe one entry (always aligned to dwords)
	rep stosd
	popa
	ret

// In:	edi = tile
//	edx = pool id
//	bh = object owner
// Out:	carry = set if not an object tile
IsObjectTile:
	push ebx
	mov bl, byte [landscape4(di, 1)]
	and bl, 0xF0
	cmp bl, 0xA0
	pop ebx
	jne .isNotObjectTile

	cmp byte [landscape5(di, 1)], NOBJECTTYPE
	jne .isNotObjectTile	// Right class wrong type...

	cmp byte [landscape1+edi], bh
	jne .isNotObjectTile	// Atleast not one we own...

	cmp dx, [landscape3+edi*2]
	jne .isNotObjectTile	// It is an object tile but it
				// doesn't belong to this object...

	clc
	ret

.isNotObjectTile:
	stc
	ret

// Out: bx as the recolour map
proc GetObjectColourMap
	arg owner, tile, gameid

	_enter
	push eax
	push ecx
	push edx

	cmp dword [%$tile], 0
	je near .gui
	
	movzx edx, word [%$tile]
	movzx edx, word [landscape3+edx*2]
	imul edx, object_size
	mov dword [%$tile], edx

	movzx edx, word [%$gameid]
	cmp byte [%$owner], 0x10
	jb .owned

	mov eax, dword [%$tile]
	movzx ax, byte [objectpool+eax+object.colour]
	mov cx, ax
	and ax, 0x0F
	and cx, 0xF0

	jmp .hascolours

.owned:
	movzx eax, byte [%$owner]
	call GetOwnerColours

.hascolours:
	test edx, edx // No game id, so only 1cc is possible
	jz .onecc

	cmp byte dword [numtwocolormaps+1], 1 // No 2cc maps loaded so we can only do 1cc
	jb .onecc

	mov edx, [%$tile]
	test word [objectpool+edx+object.flags], OF_TWOCC
	jnz .twocc

.onecc:
	mov bx, ax
	add bx, 775
	pop edx
	pop ecx
	pop eax
	_ret

.twocc:
	mov bx, ax
	or bx, cx
	add bx, [deftwocolormaps]
	pop edx
	pop ecx
	pop eax
	_ret

.gui:
	movzx edx, word [%$gameid]
	mov eax, 0x00 // Dark Blue
	mov ecx, 0x10 // Pale Green

	cmp byte [gamemode], 2
	je .guichecks

	movzx eax, byte [%$owner]
	call GetOwnerColours

.guichecks:
	cmp byte [numtwocolormaps+1], 1 // No 2cc maps loaded so we can only do 1cc
	jb .onecc

	test word [objectflags+edx*2], OF_TWOCC // We only have the grf raw data of flags for the gui
	jnz .twocc
	jmp .onecc
endproc

// In:	eax - owner
// Out:	al - first colour [lower nibble]
//		cl - second colour [upper bibble] (same as first if no second colour defined) 
GetOwnerColours:
	push edx
	mov ecx, eax
	mov edx, eax

	imul edx, player2_size
	add edx, dword [player2array]
	movzx eax, byte [companycolors+eax]
	movzx ecx, byte [edx+player2.col2]

	bt dword [edx+player2.colschemes], 0 // Have standard second colour?
	jc .hascolour
	mov ecx, eax

.hascolour:
	shl ecx, 4
	pop edx
	ret

// **************************************** Object Creation ***************************************

uvard ObjectCost
uvard ObjectLayout
uvarb ObjectWater

// Create Object function
// Input:	edi - tile index (word)
//		edx - object data id (word) (from bit 8)
// Output:	ebx - 0x80000000 if fail, cost if sucessful
exported BuildObject
	push eax
	push ecx
	push edx
	mov byte [currentexpensetype], expenses_construction
	and dword [ObjectCost], 0

	mov eax, edx			// Move our game id to a more perminant home
	shr eax, 8

	mov word [operrormsg2], ourtext(cheatinvalidparm)
	or eax, eax
	jz near .fail
	cmp eax, [objectsgameidcount]
	ja near .fail

	push eax
	push dword -1
	call validobject
	jc near .fail

	call GetObjectLayout		// Result is in ObjectLayout
	call GetObjectPoolEntry		// Can we create an instance of an object?
	jc .fail

	push eax
	call GetObjectSize
	jc .fail

	push edx
	push dword CheckObjectLayout	// Functions and values for check tile
	push dword CheckObjectTile
	push eax
	push ecx
	call LoopTiles
	jc .failpop

	test bl, 1
	jz .check

	pop edx
	mov bh, [curplayer]
	push dword CheckObjectLayout	// Functions and values for create tile
	push dword CreateObjectTile
	push eax
	push ecx
	call LoopTiles
	call SetObjectPoolEntry

	mov dword [ObjectLayout], -1 // Return and clear the selected layout
	pop edx
	pop ecx
	pop eax
	ret

.failpop:
	pop edx

.fail:
	mov dword [ObjectLayout], -1 // Return error and clear the selected layout
	mov ebx, 1<<31
	pop edx
	pop ecx
	pop eax
	ret

.check:
	call BuildObjectCost
	pop edx
	pop edx
	pop ecx
	pop eax
	ret

// In:	eax = game id
//	edx = tile count
// Out:	ebx = cost
BuildObjectCost:
	push eax
	push edx
	mov ebx, 2 // Our base factor
	test ax, ax
	jz .nogrf
	movzx ebx, byte [objectcostfactors+eax] // Get the grf factor

.nogrf:
	// multiple it by the number of tiles
	imul ebx, edx

	// multiple it the base factor
	mov edx, dword [costs+0x8A]
	imul ebx, edx

	add ebx, dword [ObjectCost] // Add the cost of clearing the tiles below
	pop edx
	pop eax
	ret

// In:	eax = game id
GetObjectLayout:
	push esi		// Currently no layout structure exists so this is a place holder
	mov dword [ObjectLayout], -1
	pop esi
	ret

// Out:	carry = set if cannot find entry
//	ecx = pool id
GetObjectPoolEntry:
	push eax
	mov word [operrormsg2], ourtext(objecterr_poolfull)
	xor eax, eax
	xor ecx, ecx
	
.next:
	cmp word [objectpool+eax+object.origin], 0
	je .done
	add eax, object_size
	inc ecx
	cmp ecx, NACTIVEOBJECTS
	jb .next

	pop eax
	stc
	ret

.done:
	pop eax
	clc
	ret
	
// In:	edi = tile
// Out:	carry = set if not an object tile
CheckObjectLayout:
	clc			// Currently no layout structure exists so this is a place holder
	ret

// In:	edi = tile
//	eax = game id
//	cl = tile offset
// Out:	carry = set if not an object tile
CheckObjectTile:
	push ecx
	push eax
	call [CheckForVehiclesInTheWay]
	jnz near .fail

	rol di, 4		// Store the x, y in the ax, cx registors
	mov eax, edi
	mov ecx, edi
	rol cx, 8
	and ax, 0x0FF0
	and cx, 0x0FF0
	ror di, 4

	pusha
	call [gettileinfo]
	mov dword [miscgrfvar], edi
	popa

	push ecx
	push eax
	mov eax, [esp+0x8]
	mov ecx, [esp+0xC]
	call CheckObjectSlope
	pop eax
	pop ecx
	jnz .fail
	
	pusha
	mov ebx, [esp+0x20]	// get our game id
	mov dl, byte [landscape4(di, 1)]	// We check water slightly differently
	and dl, 0xF0
	cmp dl, 0x60
	je .water

.usual:
// Allows the grf to prevent an object being constructd on land (Lakie)
	mov word [operrormsg2], ourtext(objecterr_cantbuildonland)
	test word [objectflags+ebx*2], OF_NOBUILDLAND
	jnz .failpop

	mov esi, 0		// Clear Tile
	call BuildObjectFlags
	call [actionhandler]
	cmp ebx, 1<<31
	je .failpop

	add dword [ObjectCost], ebx
	popa
	pop eax
	pop ecx
	clc
	ret

.failpop:
	popa

.fail:
	pop eax
	pop ecx
	stc
	ret

.water:
// Checks water tiles allowing flat water tiles and 'river rapids' (Lakie)
//   Additionally also removes the cost of clearing the water.
	mov dh, byte [landscape5(di, 1)]
	test word [objectflags+ebx*2], OF_BUILDWATER	// Can we build on water
	jz .usual

	cmp dh, 3	// River Rapids (valid due to slopes not allowed on map edge)
	je .donepop
	cmp dh, 0	// Flat water tile
	jne .usual

	mov esi, 0		// Check to see if we can clear the water tile
	mov bl, 2		// (mainly to check if we are trying to replace map edge tiles)
	call [actionhandler]
	cmp ebx, 1<<31
	je .failpop

.donepop:
	popa
	pop eax
	pop ecx
	clc
	ret

// In:	ebx = game id
// Out: ebx = action flags
BuildObjectFlags:
	push eax
	xchg ebx, eax
	mov ebx, 0xA
	test word [objectflags+eax*2], OF_BUILDWATER
	jz .nowater
	and bl, ~8

.nowater:
	pop eax
	ret

// In:	eax = game id
//	di = slope information
//	cl = offset from northen corner
// Out:	zero flag = set for not allowed
global CheckObjectSlope
CheckObjectSlope:
	push eax
	push ecx
	push edi
	push esi
	mov word [operrormsg2], 0x1000
	mov edi, dword [miscgrfvar]

	test di, 0x10
	jnz .fail

	test word [objectcallbackflags+eax*2], OC_SLOPECHECK
	jz .default

	xor esi, esi
	movzx ecx, cl
	mov dword [callback_extrainfo], ecx

	mov word [curcallback],0x157
	mov byte [grffeature], 0xF
	call getnewsprite
	mov dword [curcallback],0
	mov dword [miscgrfvar], 0
	jc .default

	test ax, ax
	pop esi
	pop edi
	pop ecx
	pop eax
	ret

.default:
	test di, di

.fail:
	pop esi
	pop edi
	pop ecx
	pop eax
	ret

// In:	edi = tile
//	edx = pool id
//	eax = game id
//	bh = object owner
CreateObjectTile:
	pusha
	movzx cx, byte [landscape4(di, 1)]
	and cl, 0xF0
	cmp cl, 0x60
	jne .notwater
	cmp byte [landscape5(di, 1)], 0x1
	je .notwater

// Stores the water bits of the water tile we are being built on (Lakie)
	mov ch, byte [landscape3+edi*2]
	or ch, 4

.notwater:
	mov byte [ObjectWater], ch

	rol di, 4		// Store the x, y in the ax, cx registors
	mov eax, edi
	mov ecx, eax
	rol cx, 8
	and ax, 0x0FF0
	and cx, 0x0FF0
	ror di, 4
	mov esi, 0
	call [actionhandler]
	call [invalidatetile]
	popa

	// Landscape 1 = owner (0x10 for no owner)
	// Landscape 2 = tile offset from origin (northen tile)
	// Landscape 3 = pool id
	// Landscape 4 = Class A and hieght
	// Landscape 5 = newObject Type (NOBJECTTYPE)
	// Landscape 6 = Random bits

	mov byte [landscape1+edi], bh
	mov byte [landscape2+edi], cl
	mov word [landscape3+edi*2], dx
	and byte [landscape4(di, 1)], 0xF
	or byte [landscape4(di, 1)], 0xA0
	mov byte [landscape5(di, 1)], NOBJECTTYPE

	push eax
	call [randomfn]
	mov byte [landscape6+edi], al

	mov al, byte [ObjectWater]
	mov byte [landscape7+edi], al
	pop eax

	push eax
	push edx
	mov edx, objectidf
	call idf_increaseusage
	pop edx
	pop eax

	cmp cl, 0
	ja .notfirst

	test word [objectflags+eax*2], OF_ANIMATED
	jnz .hasanimation
.notfirst:
	ret

.hasanimation:
	push ebp
	push ebx
	push edi
	mov ebp, [ophandler+0xA0]
	mov ebx, 2
	call [ebp+4]
	pop edi
	pop ebx
	pop ebp
	ret

// **************************************** Object Removal ****************************************
// Removal of newgrf objects (Hooks owned land)
// Input:	edi - tile coordinates
uvard ObjectClearTile

global RemoveObject, RemoveObject.origfn
RemoveObject:
	mov word [operrormsg2], 0x013B
	cmp byte [landscape5(di, 1)], NOBJECTTYPE
	je .ObjectTile
	stc
	ret

// Both the new and old functions need this
.clearTile:
	call [ObjectClearTile]
	ret

// Remove new objects
.ObjectTile:
	push eax
	push ecx
	push edx
	movzx ecx, word [landscape3+edi*2]
	imul ecx, object_size
	cmp word [objectpool+ecx+object.origin], 0
	je .ud2

	mov bh, [landscape1+edi]
	cmp bh, [curplayer]
	je .companyowned

	cmp bh, 0x10
	jne .companyfail

.companyowned:
	call RemoveObjectFlags
	jc .fail
	movzx eax, word [objectpool+ecx+object.dataid]

	push dword [objectsdataidtogameid+eax*2]
	call GetObjectSize

	push edi
	push ebp
	movzx ebp, word [landscape3+edi*2]
	movzx edi, word [objectpool+ecx+object.origin]
	push ebp

	push dword IsObjectTile		// Functions and values for check tile
	push dword RemoveObjectTile
	push eax
	push ebp
	call LoopTiles

	pop ecx
	pop ebp
	pop edi
	movzx eax, word [objectsdataidtogameid+eax*2]

	cmp edx, 0	// We shouldn't really get 0 unless there has been an error
	je .ud2

	test bl, 1
	jz .check

	push edi
	xor edi, edi
	call SetObjectPoolEntry
	pop edi

	pop edx
	pop ecx
	pop eax
	clc
	ret

.check:
	call RemoveObjectCost
	pop edx
	pop ecx
	pop eax
	clc
	ret
.ud2:
	ud2 // Forced crash upon corrupt object pool entry

.fail:
	pop edx
	pop ecx
	pop eax
	mov ebx, 1<<31
	clc
	ret

.companyfail:
	pop edx
	pop ecx
	pop eax
	stc
	ret

// In:	ecx = pool id
//	bl = action code
// Out: carry = set if error
RemoveObjectFlags:
	cmp byte [curplayer], 0x11
	je .fail
	
	cmp byte [gamemode], 2 // Objects are always removeable in the scenerio editor
	je .done

	test word [objectpool+ecx+object.flags], OF_ANYREMOVE
	jnz .done

	test word [objectpool+ecx+object.flags], OF_UNREMOVALABLE
	jnz .unremovable

	mov word [operrormsg2], 0x5800
	test bl, 2
	jnz .fail

.done:
	clc
	ret

.unremovable:
	mov word [operrormsg2], 0x013B
	cmp byte [curplayerctrlkey], 1
	jz .done

.fail:
	stc
	ret

// In:	eax = data id
//	cl = Tile Number
//	edx = pool id
//	edi = tile
RemoveObjectTile:
	pusha
	mov cl, byte [landscape7+edi]
	mov byte [ObjectWater], cl

	rol di, 4 // Store the x, y in the ax, cx registors
	mov eax, edi
	mov ecx, edi
	rol cx, 8
	and ax, 0x0FF0
	and cx, 0x0FF0
	ror di, 4
	call RemoveObject.clearTile
	popa

	test bl, 1
	jnz .remove

	clc
	ret

.remove:
	call RedrawObjectTile // Force the game to redraw the tile

	push esi
	push ebx
	push edx
	mov edx, objectidf
	call idf_decreaseusage // Requires an action3 structure
	pop edx
	pop ebx

	cmp cl, 0
	ja .normaltile

	imul edx, object_size
	test word [objectpool+edx+object.flags], OF_ANIMATED
	jz .normaltile

	push ebx
	push ebp
	push edi
	mov ebp, [ophandler+0xA0]
	mov ebx, 3
	call [ebp+4]
	pop edi
	pop ebp
	pop ebx

.normaltile:
	test byte [ObjectWater], 4
	jz .wasntwater

// Restore the water tile originally under the object (Lakie)
	pusha
	rol di, 4 // Store the x, y in the ax, cx registors
	mov eax, edi
	mov ecx, edi
	rol cx, 8
	and ax, 0x0FF0
	and cx, 0x0FF0
	ror di, 4
	
	movzx edi, byte [ObjectWater]
	and di, ~4
	jnz .notsea
	mov byte [curplayerctrlkey], 1 // Overrides canal/rivers on sea level

.notsea:
	shr di, 1 // 1 = river, 0 = canal

extern actionmakewater_actionnum
	mov esi, actionmakewater_actionnum
	mov bx, 1
	call [actionhandler]
	popa

.wasntwater:
	pop esi
	clc
	ret

// In:	eax = game id
//	ecx = pool id
//	edx = number of tiles
// Out:	ebx = cost
RemoveObjectCost:
	push eax
	push edx
	push ebx
	imul ecx, object_size
	mov ebx, 2 // Our fallback base factor

	test ax, ax
	jz .nogrf
	movzx ebx, byte [objectremovalcostfactors+eax]

.nogrf:
	// multiple it by the number of tiles
	imul ebx, edx

	// multiple it the base factor
	mov edx, [costs+0x8A]
	imul ebx, edx

	// Unmovable flag (if we get here we know ctrl is pressed)
	test word [objectpool+ecx+object.flags], OF_UNREMOVALABLE
	jz .removable
	imul ebx, 25

.removable:
	// Removal as income flag
	test word [objectpool+ecx+object.flags], OF_REMOVALINCOME
	jz .normal
	shr ebx, 1
	neg ebx

.normal:
	pop edx
	pop edx
	pop eax
	ret

// **************************************** Object Drawing ****************************************

global DrawObject
DrawObject:
	cmp dh, NOBJECTTYPE
	je .newObject

	movzx ebp, byte [landscape1+ebp]
	movzx ebp, byte [companycolors+ebp]
	clc
	ret

.fallbackpop:
	pop ebp
	pop ebx
	pop edx
	pop ecx
	pop eax

.fallback:
	push ebp
	call DrawObjectFoundations
	call GetObjectColourMapWrapper
	shl ebp, 16

	push ebp
	mov bx, 1420
	call .fallback_ground
	pop ebx

	or al, 8
	or cl, 8
	mov di, 1
	mov si, di
	mov dh, 0xA
	mov bx, 4790 + 0x8000
	call [addsprite]
	pop ebp
	popa
	stc
	ret

// Because of foundations, we need to draw our ground tile differently
.fallback_ground:
	mov ebp, dword [esp+8]
	test bp, bp
	jnz .fallback_found

	call [addgroundsprite]
	ret

.fallback_found:
	push edx
	mov ax,31
	mov cx,1
extern addrelsprite
	call [addrelsprite]
	pop edx
	ret

.newObject:
	pusha
	xchg edi, ebp
	cmp dword [objectpool_ptr], 0
	je .fallback

	movzx esi, word [landscape3+edi*2]
	imul esi, object_size
	cmp word [objectpool+esi+object.origin], 0
	je .fallback	// invalid pool (should be crash)?

	movzx esi, word [objectpool+esi+object.dataid]
	movzx esi, word [objectsdataidtogameid+esi*2]
	test esi, esi
	jz .fallback	// No grf loaded

	push edx
	call DrawObjectFoundations.gameid
	pop edx

	push esi
	push edi
	push eax
	push ecx
	push edx
	push ebx
	push ebp

	mov eax, esi
	mov esi, ebx
	mov byte [grffeature], 0xF
	call getnewsprite
	
	push eax	// dataptr for processtileaction2
	push ebx	// spritesavail for processtileaction2
	push dword 3	// conststate for processtileaction2

	push ebx
	mov ebx, [esp+0x14]
	call GetObjectColourMapWrapper
	pop ebx

	push ebp	// defcolor for processtileaction2

	movzx eax, word [esp+0x20]
	movzx ecx, word [esp+0x1C]
	mov edx, [esp+0x18]
	mov edi, [esp+0x10]

	push dword 0xF		// grffeature for processtileaction2
	call processtileaction2

	pop ebp
	pop ebx
	pop edx
	pop ecx
	pop eax
	pop edi
	pop esi

// Replaces the ground sprite with water showing correct canal / river bits (Lakie)
	xchg esi, edi // Were we built upon water
	test byte [landscape7+esi], 4
	jz .nowater

	movzx edi, word [landscape3+esi*2] // Should we draw water
	imul edi, object_size
	test word [objectpool+edi+object.flags], OF_DRAWWATER
	jz .nowater

	call [gettileinfoshort]
	movzx bp, byte [landscape7+esi]
extern Class6DrawLandCanalsOrRiversOrSeeWaterL3.ebp
	call Class6DrawLandCanalsOrRiversOrSeeWaterL3.ebp

.nowater:
	popa
	stc
	ret

// In:	ebx = tile
//	ebp = raised flags
// Out:	carry = set if foundations
DrawObjectFoundations.gameid:
	push edi
	movzx edi, word [landscape3+ebx*2]
	imul edi, object_size
	test word [objectpool+edi+object.flags], OF_NOFOUNDATIONS
	pop edi
	jnz DrawObjectFoundations.override

DrawObjectFoundations:
	test bp, bp
	jz .nofondations

	add dl, 8
	call displayfoundation
	ret

.override:
	xor bp, bp

.nofondations:
	ret

// In:	ebx = tile
// Out:	ebp = colour / recolour map
GetObjectColourMapWrapper:
	push ebx
	push edx

	movzx edx, byte [landscape1+ebx]
	movzx ebp, word [landscape3+ebx*2]
	imul ebp, object_size
	movzx ebp, word [objectpool+ebp+object.dataid]
	movzx ebp, byte [objectsdataidtogameid+ebp*2]

	push edx // Object owner
	push ebx // Tile index
	push ebp // Object game id

	call GetObjectColourMap
	mov bp, bx
	pop edx
	pop ebx
	ret

// Used to increment the animation of the object
global ClassAAnimationHandler
ClassAAnimationHandler:
	test word  [animcounter], 3
	jnz .finish

	cmp byte [landscape5(bx, 1)], NOBJECTTYPE
	jne .notobject

	push ebp
	push ebx
	movzx ebp, word [landscape3+ebx*2]
	push ebp
	imul ebp, object_size
	mov al, byte [objectpool+ebp+object.animation]
	inc al
	mov byte [objectpool+ebp+object.animation], al

	push edx
	movzx edx, word [objectpool+ebp+object.dataid]
	push dword [objectsdataidtogameid+edx*2]
	call GetObjectSize

	push edi
	mov bh, [landscape1+ebx]
	movzx edi, word [objectpool+ebp+object.origin]
	mov ebp, [esp+8]
	push dword IsObjectTile
	push dword RedrawObjectTile
	push dword 0 // Unused by the sub functions
	push ebp
	call LoopTiles
	pop ebp
	pop edi
	pop edx
	pop ebx
	pop ebp

.finish:
	ret

// Not an object tile so purge it from the animated tile list
.notobject:
	push ebx
	push ebp
	push edi
	mov edi, ebx
	mov ebp, [ophandler+0xA0]
	mov ebx, 3
	call [ebp+4]
	pop edi
	pop ebp
	pop ebx
	ret

// In:	 cx, dx = x, y
//	ebx = dropdown item index
DrawObjectDDPreview:
	inc ecx
	call .createview
	jz .invalid

	pusha
	mov edi, baTempBuffer1
	mov word [edi+scrnblockdesc.zoom], 1
	shl word [edi+scrnblockdesc.x], 1
	shl word [edi+scrnblockdesc.y], 1
	shl word [edi+scrnblockdesc.width], 1
	shl word [edi+scrnblockdesc.height], 1

	movzx eax, word [objectddgameidlist+ebx*2]
	mov ebp, eax
	mov esi, 0
	mov byte [grffeature], 0xF
	call getnewsprite
	push eax	 // Data Pointer
	push ebx	 // Sprite Availability
	push dword 3 // Construction stage (always fully built for objects)

	add cx, 16
	add dx, 8
	shl cx, 1
	shl dx, 1

	call .getcolours
	push ebx
	push dword 0xF
	call DrawObjectTileSelWindow
	popa

.invalid:
	ret

.createview:
	pusha
	mov edi, baTempBuffer1
	mov byte [edi], 0
	//	DX,BX = X,Y CX,BP = width,height
	mov ebx, edx
	mov edx, ecx
	mov cx, 64/2
	mov bp, 46/2

	call [MakeTempScrnBlockDesc]
	popa
	ret

.getcolours:
	push edx
	mov edx, 0x10	// Get the recolour to defaultly apply
	cmp byte [gamemode], 2
	je .noowner
	movzx edx, byte [human1]

.noowner:
	push edx // Owner of the window
	push dword 0 // No tile index
	push dword ebp // Current selected object id
	call GetObjectColourMap
	pop edx
	ret

// ************************************ Object Preview Drawing ************************************
extern drawspritefn, exscurfeature, exsspritelistext
global DrawObjectTileSelWindow

uvarw DrawPreviewLastX
uvarw DrawPreviewLastY

// Draws a object tile in a temporary buffer, [also house or industry tiles in theory]. (Lakie)
// - This is going to mainly be a stripped down and simplified clone of processtileaction2
// In:	 cx = x
//	 dx = y
//	edi = Sprite Block
//	(On the stack in this order)
//	- Data Pointer
//	- Sprite Availablity
//	- Construction State
//	- Defualt Recolour
//	- Grf Feature
proc DrawObjectTileSelWindow
	arg dataptr, spritesavail, conststate, defcolor, grffeature
	slocal numsprites, byte

	_enter

	mov esi, dword [%$dataptr]
	
	mov bl, [esi] // Num sprites / type of action2
	mov byte [%$numsprites], bl
	inc esi

	call .getsprite
	jz .noground

	pusha	// Draw the ground tile
	call [drawspritefn]
	popa

.noground:
	cmp byte [%$numsprites], 0
	ja .newformat

	call .getsprite
	jz .done

	pusha
	movzx ax, byte [esi] // x
	movzx cx, byte [esi+1] // y
	mov dl, 0 // z
	call .topixels
	mov bx, cx
	
	mov ecx, dword [esp+_pusha.ecx]
	mov edx, dword [esp+_pusha.edx]
	add cx, ax
	add dx, bx
	mov ebx, dword [esp+_pusha.ebx]
	
	// Draw the upper tile part
	call [drawspritefn]
	popa

.done:
	_ret

.error:
	ud2
	_ret

.newformat:
	// First loop the extended ground sprites
	// - There isn't much difference between this and .normal/.shared, the
	//     main difference is ground sprites do not support the x, y offsets.
	cmp byte [esi+6], 0x80
	jne .normal

	call .getsprite
	jz .error
	btr ebx, 30
	add esi, 3

	pusha	// Draw the extra ground tile
	call [drawspritefn]
	popa
	dec byte [%$numsprites]
	jnz .newformat
	_ret

.normal:
	// Handles the rest of the action2, both the 'boxes' and 'relatives'
	call .getsprite
	jz .error
	btr ebx, 30

	pusha
	cmp byte [esi+2], 0x80
	je .shared
	
	// Get the landscape offsets and convert them to pixel offsets
	movzx ax, byte [esi] // x
	movzx cx, byte [esi+1] // y
	mov dl, byte [esi+2] // z
	call .topixels
	mov bx, cx

	mov ecx, dword [esp+_pusha.ecx]
	mov edx, dword [esp+_pusha.edx]
	add cx, ax
	add dx, bx

	// To provide almost correct functionality for 'relatives'
	mov word [DrawPreviewLastX], ax
	mov word [DrawPreviewLastY], dx

	mov ebx, dword [esp+_pusha.ebx]
	add dword [esp+_pusha.esi], 6
	jmp .offsets
	
.shared:
	// Already pixel offsets so no adjustment needed
	movzx cx, byte [esi]
	movzx dx, byte [esi+1]
	add cx, word [DrawPreviewLastX]
	add dx, word [DrawPreviewLastY]
	add dword [esp+_pusha.esi], 3

.offsets:
	call [drawspritefn]
	popa
	dec byte [%$numsprites]
	jnz .normal
	_ret

// In:	esi = Pointer to Action2 (Sprite raw)
// Out:	ebx = Sprite (with recolour)
//	z flag = set means sprite valid
.getsprite:
	mov ebx, dword [esi]
	add esi, 4
	btr ebx, 31
	jnc .ttdsprite

	// Grf (house / industry) sprites need adjusting according to construction
	push edx
	mov edx, dword [%$spritesavail]
	shl edx, 2
	add edx, [%$conststate]
	movzx edx, byte [.spriteoffsets+edx]
	add ebx, edx

	mov dl, [%$grffeature]	// Something to do with GRM apparently
	mov [exscurfeature], dl
	mov byte [exsspritelistext], 1
	pop edx

.ttdsprite:
	test bx, bx
	jns .norecolor

	rol ebx, 16	// Tests for a specified recolour mapping
	test bx, 0x3fff
	jnz .goodrecolor
	or bx, [%$defcolor]

.goodrecolor:
	ror ebx,16
	
.norecolor:
	test ebx, ebx
	_ret 0 // Preserve stack frame

// In:	ax, cx, dl = landscape x, y, z
// Out:	ax, cx = pixel x, y
.topixels:
	xor dh, dh
	mov bx, ax
	neg ax
	add ax, cx
	add cx, bx
	shl ax, 1
	sub cx, dx
	_ret 0
endproc

.spriteoffsets:
	db 0,0,0,0
	db 0,0,0,1
	db 0,1,1,2
	db 0,1,2,3

// ************************************ Periodic Tile Proc ****************************************
global ClassAPeriodicHandler
ClassAPeriodicHandler:
	cmp byte [landscape1+ebx], 0 // Only operate on the first tile (prevent over redraw)
	jne .done

	pusha
	xchg edi, ebx
	mov bh, byte [landscape1+edi]
	movzx ebp, word [landscape3+edi*2]

	push ebp
	imul ebp, object_size
	movzx esi, word [objectpool+ebp+object.dataid]
	movzx esi, word [objectsdataidtogameid+esi*2]
	pop ebp
	test esi, esi	// Do we have a valid gameid?
	jz .donepop

	push esi
	call GetObjectSize	// Result in dx

	push IsObjectTile
	push RedrawObjectTile
	push esi
	push ebp
	call LoopTiles	// Mark all the object tiles as dirty

.donepop:
	popa

.done:
	ret

// ****************************************** Query Tile ******************************************
global QueryObject

// In:	 ax = Statue string
//	 cl = Tile class
//	edi = Tile index (xy)
// Out:	ax = String to use
//	ecx= TextRefStack Values
QueryObject:
	cmp cl, 2
	je .done

	mov ax, 0x5805	// Original owned land
	cmp cl, 5
	jne .done

	// New objects
	push esi
	xor ecx, ecx
	movzx esi, word [landscape3+edi*2]
	imul esi, object_size
	movzx esi, word [objectpool+esi+object.dataid]
	movzx esi, word [objectsdataidtogameid+esi*2]
	
	test esi, esi	// No grf loaded, so fallback to company owned land
	jz .donepop

	mov ax, ourtext(objectquery)	// Store the text id and its value to use
	mov ecx, dword [objectspriteblock+esi*4]
extern curlandinfogrf
	mov dword [curlandinfogrf], ecx
	
	mov cx, word [objectnames+esi*2]
	call .fixtextid

// It's not gartentuee'd that the class and object textids come from the same grf
//   but this commented code would give the ablity to show both
//	shl ecx, 16
//	
//	movzx esi, word [objectclass+esi*2]
//	mov cx, word [objectclassesnames+esi*2]
//	call .fixtextid

.donepop:
	pop esi

.done:
	ret

.fixtextid:
	cmp ch, 0xD0
	jb .nofix
	cmp ch, 0xD3
	ja .nofix
	add ch, 0x04

.nofix:
	ret

// **************************************** Newgrf Vars *******************************************
extern gettileterrain, gettileinfoshort

// Var:	40, Relative Position
// Out:	eax = 00yxYYXX
exported getObjectVar40
	test esi, esi
	jz .gui

	movzx eax, byte [landscape2+esi]
	shl eax, 16

	mov al, byte [landscape2+esi]
	shl ax, 4
	shr al, 4
	ret

.gui:
	mov eax, 0xFF0F0F
	ret

// Var:	41, Tile Type
// Out:	0000sstt (tt - same as var 43 houses, ss - slope data)
exported getObjectVar41
	test esi, esi
	jz .gui

	pusha
	call [gettileinfoshort] // First we get the tile information
	shl di, 8

	call gettileterrain // And we add the terrain information
	movzx ax, al
	or ax, di

	movzx eax, ax
	mov dword [esp+_pusha.eax], eax // Since getTileInfo changes most registors pusha was needed.
	popa
	ret

.gui:
	xor eax, eax
	ret

// Var 42, Construction Date
// Out: dddddddd (year since year 0)
exported getObjectVar42
	test esi, esi
	jz .gui

	movzx eax, word [landscape3+esi*2]
	imul eax, object_size
	movzx eax, word [objectpool+eax+object.buildyear]
	imul eax, 365	// Rough fix until the object pool update
	ret

.gui:
	movzx eax, word [currentdate]
	add eax, 701265
	add eax, [landscape3+ttdpatchdata.daysadd]
	ret

// Var 43, Colour and Animation stage
// Out:	0000CCAA - Colour (no owner) and Animation Counter
exported getObjectVar43
	test esi, esi
	jz .gui

	push ecx
	movzx ecx, word [landscape3+esi*2]
	imul ecx, object_size
	movzx eax, byte [objectpool+ecx+object.animation]
	mov ah, byte [objectpool+ecx+object.colour]

	cmp byte [landscape1+esi], 0x10
	jae .noowner

	push eax
	movzx eax, byte [landscape1+esi]
	call GetOwnerColours

	or cl, al
	pop eax
	mov ah, cl

.noowner:
	pop ecx
	ret

.gui:
	xor eax, eax
	ret

// Var 44, Object Owner
// Out:	000000AA - Owner id (0x10 if unowned)
exported getObjectVar44
	movzx eax, byte [landscape1+esi] // Too easy?
	ret

// Should I use the same method as var65 or just use the reftown it was built with?
// Var45, Get distance of closest town
// Out:	?
exported getObjectVar45
	xor eax, eax
	ret

// Var46, Get euclidean distance of closest town
// Out:	?
exported getObjectVar46
	xor eax, eax
	ret


// For the below "ParamVar" functions, ah = parameter from grf

// Var60, Get object id at offset from tile
// Out:	?
exported getObjectParamVar60
	xor eax, eax
	ret

// Var61, Get random bits at offset from tile
// Out:	000000RR - Random Bits from tile (given tile is of same object)
exported getObjectParamVar61
	xor eax, eax
	ret

// Var62, Land info at offset from tile
// Out:	?
exported getObjectParamVar62
	xor eax, eax
	ret

// Var63, Get animation counter at offset from tile
// Out:	000000AA - Animation Counter from tile (given tile is of same object)
exported getObjectParamVar63
	xor eax, eax
	ret

// Var64, Count of object type and closest object distance
// Out:	?
exported getObjectParamVar64
	xor eax, eax
	ret

