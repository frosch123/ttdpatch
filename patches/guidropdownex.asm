#include <std.inc>
#include <misc.inc>
#include <textdef.inc>
#include <human.inc>
#include <proc.inc>
#include <window.inc>
#include <imports/gui.inc>
#include <ptrvar.inc>

extern RefreshWindowArea
extern tmpbuffer1
extern ttdtexthandler, gettextwidth
extern resheight

// we sit on top a normal dropdown, so we don't need to patch ttds click handling functions
%assign DropDownExType 0x3F
%assign DropDownExID 0

%assign DropDownExMax MAXDROPDOWNEXENTRIES

// Example of usage of GenerateDropDownEx*
// ==========================================
//
// call GenerateDropDownExPrepare		// esi = window, ecx = element nr that is calling (was clicked), ch <> 0 tab mode  
//							// will result carry if a DropDownEx is already open (window bit enabled)
//							// otherwise it resets all flags to default values. 
//
// mov [DropDownExList+ecx*4], eax		// where eax is text id (or textptr) to be filled, ecx is position
//							// NOTICE: DropDownEx uses dwords per textids!  Use MAXDROPDOWNEXENTRIES 
//
// bts [DropDownExListDisabled], ecx	// will disable an entry and show it as gray, it isn't selectable...
//
// mov dword [DropDownExList+ecx*4], -1	// terminate the last entry
//
// Change any Flags and settings now, then:
//
// call GenerateDropDownEx			// open the DropDownEx window, needs:
//							// esi = window, ecx = ele, dx = selected item
//
// FLAGS: (Set to default values by GenerateDropDownExPrepare)
// ==========================================
// DropDownExFlags (word size):
//   bit 0 = change size so to have no dummy places (auto shrink) -default-
//   bit 1 = show devider between the items
//   bit 2 = use textpointers instead of the default textids
//   bit 3 = do not unactivate button on close
//
// DropDownExListItemDrawCallback (dword):
//   0 = none -default- , any other callable function ptr...
//   Function Parameters: cx = x, dx = y, ebx = id of currently drawn item
//   All registers are automatically saved/restored
//
// DropDownExListItemExtraWidth (word):
//   Width added to the item for callback drawing
//
// DropDownExListItemHeight (word)
//   Height of the item for callback drawing
//
// DropDownExListGrfPtr (dword for each item)  -- untested --
//   Set curmiscgrf for a textptr
//
//

uvarw DropDownExListItemHeight
uvarw DropDownExListItemExtraWidth
uvard DropDownExListItemDrawCallback
uvarw DropDownExMaxItemsVisible			// max 255
uvarw DropDownExFlags

uvard DropDownExList, DropDownExMax+1
uvard DropDownExListGrfPtr, DropDownExMax+1
uvarb DropDownExListDisabled, DropDownExMax/8+1


varb DropDownExElements
	db cWinElemSpriteBox
DropDownExElements.bgcolorbox:
	db cColorSchemeDarkBlue
	dw 0 
DropDownExElements.boxwidth:
	dw 1000, 0,
DropDownExElements.boxheight:
	dw 1000
DropDownExElements.flagsentries:
	dw 0
	db cWinElemSlider
DropDownExElements.bgcolorslider:
	db cColorSchemeDarkBlue
DropDownExElements.sliderx:
	dw 0, 1000, 0
DropDownExElements.sliderheight: 
	dw 1000, 0
	db cWinElemLast
endvar
%assign DropDownExMaxSliderWidth 10

struc DropDownExData
	.parentid: resw 1
	.parenttype: resb 1
	.parentele: resw 1
	.timer: resb 1
	.mousestate: resb 1
endstruc


// in:
// esi = parent window
// cx = parent ele id
// carry flag = set if the button was active already, you should surely quit your dropdown handler now
exported GenerateDropDownExPrepare
	pusha
	movzx eax, cl
	lea edi, [esi+window.activebuttons]
	
	cmp ch, 0
	je .notabs
	movzx edi, ch
	dec edi
	imul edi, 8
	add edi, dword [esi+window.data]
	
	// now [edi] = esi+window.activebuttons or tab(ch-1).activebuttons
.notabs:
	btr [edi], eax
	pushf
	
	push ecx
	push esi
	mov cl, DropDownExType
	mov dx, DropDownExID
	call [FindWindow]
	test esi,esi
	jz .noold
	call [DestroyWindow]
.noold:
	pop esi
	pop ecx
	
	popf
	jc .wasactive	
	bts [edi], eax
	
	mov bx, [esi+window.id]
	mov al, [esi+window.type]
	or  al, 0x80
	mov ah, cl
	call [invalidatehandle]
	
	xor eax, eax
	mov ecx, DropDownExMax/8
	mov edi, DropDownExListDisabled
	rep stosb
	
	mov ecx, DropDownExMax
	mov edi, DropDownExListGrfPtr
	rep stosd
	
	mov word [DropDownExListItemHeight], 10
	mov word [DropDownExListItemExtraWidth], 0
	mov dword [DropDownExListItemDrawCallback], 0
	mov byte [DropDownExMaxItemsVisible], 8
	mov byte [DropDownExFlags], 1b	// set auto shrink to default
	popa
	clc
	ret
.wasactive:
	popa
	stc
	ret


// in:
// esi = window
// dx  = selected item
// cx  = calling ele number
// filled DropDownExList, DropDownExListDisabled
global GenerateDropDownEx
proc GenerateDropDownEx
	local parenttype,parentid,parentele,parentheight,newxy,itemselected,itemstotal
	
	//CALLINT3
	_enter
	pusha
	movzx ecx, cx
	mov dword [%$parentele], ecx
	mov word [%$itemselected], dx

	
	// Tab support, see DropDownMenuGetElements in wintabs.asm for general function
	mov eax, [esi+window.elemlistptr]
	cmp ch, 0 
	je .notab
	mov dh, cWinDataTabs
	extcall FindWindowData
	// edi pointer to data
	jc .notab
	movzx eax, byte [esi+window.selecteditem]	// Get the active tab
	imul eax, 4
	mov edi, dword [edi]
	mov eax, dword [edi+eax]					// Get the elemlistptr to this tab
.notab:
	movzx edi, cl
	imul edi, 0x0C
	add edi, eax

	mov al, [edi+windowbox.bgcolor]
	mov byte [DropDownExElements.bgcolorbox], al
	mov byte [DropDownExElements.bgcolorslider], al
	
	mov ax, word [esi+window.id]
	mov word [%$parentid], ax
	mov al, byte [esi+window.type]
	mov byte [%$parenttype], al
	
	mov bx, word [edi+windowbox.y2]
	add bx, word [esi+window.y]
	add bx, 1						// move window under the button
	mov word [%$newxy+2], bx
	
	mov bx, word [edi+windowbox.y2]
	sub bx, word [edi+windowbox.y1]
	mov word [%$parentheight], bx	// need to know if window doesn't fit anymore

	movzx ebx, word [edi+windowbox.x1-0x0C]
	add bx, word [esi+window.x]
	mov word [%$newxy], bx

	movzx ebx, word [edi+windowbox.x2]
	sub bx, word [edi+windowbox.x1-0x0C]
	sub bx, word [DropDownExListItemExtraWidth]

	// calculate the width of the texts, unsafe local vars!
	push ebp
	xor ebp, ebp
.nexttext:
	mov eax, dword [DropDownExList+ebp*4]
	cmp eax, -1
	je .nomoretext
	
	extern curmiscgrf
	mov edi, dword [DropDownExListGrfPtr+ebp*4]
	mov [curmiscgrf], edi
	
	bt word [DropDownExFlags], 2
	jnc .textid
	mov [specialtext1], eax
	mov eax, statictext(special1)
.textid:

	mov edi, tmpbuffer1
	pusha
	call [ttdtexthandler]
	popa
	mov esi, edi
	push ebx
	mov word [currentfont], 0
	call [gettextwidth]
	pop ebx
	cmp cx, bx
	jl .okay
	movzx ebx, cx
.okay:
	inc ebp
	jmp .nexttext
.nomoretext:
	mov ecx, ebp

	pop ebp
	// unsafe local vars end

	// how many items do we have?
	mov dword [%$itemstotal], ecx

	bt word [DropDownExFlags], 0
	jnc .noautoshrink
	cmp cl, byte [DropDownExMaxItemsVisible]
	jae .noautoshrink
	// test if the shrink would be to small...
	mov byte [DropDownExMaxItemsVisible], 2
	cmp cl, 2
	jb .noautoshrink
	mov byte [DropDownExMaxItemsVisible], cl
.noautoshrink:

	// calculate the height of the window
	movzx eax, word [DropDownExListItemHeight]
	movzx ecx, byte [DropDownExMaxItemsVisible]
	
	// change for devider
	mov byte [DropDownExElements], cWinElemSpriteBox
	mov word [DropDownExElements.flagsentries], 0
	bt word [DropDownExFlags], 1
	jnc .nodivider
	mov byte [DropDownExElements], cWinElemTiledBox
 	mov byte [DropDownExElements.flagsentries], 1
	//mov cl, byte [DropDownExMaxItemsVisible]
	mov byte [DropDownExElements.flagsentries+1], cl
	add eax, 2
.nodivider:
	imul ax, cx
	// change the elements list
	// ebx = width
	// eax = height
	
	bt word [DropDownExFlags], 1
	jc .divider
	add eax, 4	// pixels for borders
.divider:

	add ebx, 6	// pixels for borders and some space at the text
	add bx, word [DropDownExListItemExtraWidth]
	// now we know the full width, move window x to right place
#if 0
	sub word [%$newxy], bx
#endif

	mov word [DropDownExElements.boxwidth], bx
	mov word [DropDownExElements.boxheight], ax
	mov word [DropDownExElements.sliderheight], ax
	inc ebx
	mov word [DropDownExElements.sliderx], bx
	add ebx, DropDownExMaxSliderWidth
	mov word [DropDownExElements.sliderx+2], bx
	


	// end change of element list

	// create window sizes
	inc eax
	inc ebx
	
	// fix position if it's not well
	mov cx, ax	// does it end below the visible area? (the status bar takes 12 pixels)
	add cx, word [%$newxy+2]
	mov dx,[resheight]
	sub dx, 12	// status bar 
	cmp cx,dx
	jl .heightok
	
	mov dx, word [%$newxy+2]
	sub dx, ax
	sub dx, word [%$parentheight]
	mov word [%$newxy+2], dx
.heightok:

	// merge sizes
	shl eax, 16
	or ebx, eax	
	// ebx = width , height
	mov eax, dword [%$newxy]
	
	push ebp
	mov ebp, addr(GenerateDropDownEx_winhandler)
	mov cx, DropDownExType	// window type
	mov dx, -1				// -1 = direct handler
	call dword [CreateWindow]
	pop ebp
	mov word [esi+window.id], DropDownExID
	mov dword [esi+window.elemlistptr], addr(DropDownExElements)
	mov word [esi+window.flags], 0
	
	
	mov cl, byte [%$parenttype]
	mov byte [esi+window.data+DropDownExData.parenttype], cl
	mov dx, word [%$parentid]
	mov word [esi+window.data+DropDownExData.parentid], dx
	mov ecx, dword [%$parentele]
	mov word [esi+window.data+DropDownExData.parentele], cx
	
	
	mov dx, word [%$itemselected]
	mov word [esi+window.selecteditem], dx
	mov dx, word [%$itemstotal]
	mov byte [esi+window.itemstotal], dl
	mov dl, [DropDownExMaxItemsVisible]
	mov byte [esi+window.itemsvisible], dl
	
	// set to old position to old selected item
	mov ax, [esi+window.selecteditem]
	xor dl, dl
	or ax, ax
	js .nodefsel
	mov byte [esi+window.itemsoffset], al
	add al, [esi+window.itemsvisible]
	cmp al, [esi+window.itemstotal]
	jbe .itemokay
	mov byte [esi+window.itemsoffset], 0
	mov dl, [esi+window.itemstotal]
	sub dl, [esi+window.itemsvisible]
	jna .itemokay
.nodefsel:
	mov [esi+window.itemsoffset], dl
.itemokay:
		
	// enable mouse tracking
	mov byte [esi+window.data+DropDownExData.timer], 0
	mov byte [esi+window.data+DropDownExData.mousestate], 1
	popa
	_ret
endproc

GenerateDropDownEx_close:
	push esi
	mov edi, esi
	push edi
	mov cl, byte [edi+window.data+DropDownExData.parenttype]
	mov dx, word [edi+window.data+DropDownExData.parentid]
	call [FindWindow]
	pop edi
	test esi,esi
	jz .parentnotfound
	
	push ecx
	movzx ecx, word [edi+window.data+DropDownExData.parentele]
	
	lea eax, [esi+window.activebuttons]
	cmp ch, 0
	je .notabs
	movzx eax, ch
	dec eax
	imul eax, 8
	add eax, dword [esi+window.data]
	
	// now [eax] = esi+window.activebuttons or tab(ch-1).activebuttons
.notabs:
	movzx ecx, cl
	test BYTE [DropDownExFlags], 8
	jnz .noclearbtnactivation
	btr [eax], ecx
.noclearbtnactivation:

	mov bx, word [edi+window.data+DropDownExData.parentid]
	mov al, byte [edi+window.data+DropDownExData.parenttype]
	or al, 0x80
	mov ah, cl
	call [invalidatehandle]
	pop ecx
.parentnotfound:
	pop esi
	ret
	
GenerateDropDownEx_winhandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jz near GenerateDropDownEx_redraw
	cmp dl, cWinEventClick
	jz near GenerateDropDownEx_clickhandler
	cmp dl, cWinEventClose
	jz GenerateDropDownEx_close
	cmp dl, cWinEventGRFChanges
	jz GenerateDropDownEx_close
	cmp dl, cWinEventUITick
	jz GenerateDropDownEx_uitick
	ret
	
	
GenerateDropDownEx_uitick:
	pusha
	mov ax,0x8000
	call [WindowClicked]	// release up/down scroll arrows
	popa
	
	push esi
	mov cl, byte [esi+window.data+DropDownExData.parenttype]
	mov dx, word [esi+window.data+DropDownExData.parentid]
	call [FindWindow]
	mov edi, esi
	pop esi
	test edi,edi
	jz .closewindow		// our parent isn't there anymore
	
	cmp byte [esi+window.data+DropDownExData.timer], 0
	jz .checkmousedrag
	dec byte [esi+window.data+DropDownExData.timer]
	jnz .checkmousedrag
	
	push esi
	// generate drop down event
	mov dl, cWinEventDropDownItemSelect
	movzx eax, word [esi+window.selecteditem]
	movzx ecx, word [esi+window.data+DropDownExData.parentele]
	extcall GuiSendEventEDI
	pop esi
.closewindow:
	jmp [DestroyWindow]
	
.checkmousedrag:
	cmp byte [esi+window.data+DropDownExData.mousestate], 0
	jz .done
	cmp byte [lmbstate], 0
	jnz .mousepressed
	mov byte [esi+window.data+DropDownExData.mousestate], 0
	mov ax, [mousecursorscrx]
	mov bx, [mousecursorscry]
	call GenerateDropDownEx_clickhandler
	// we have [esi+window.data+DropDownExData.timer], 4 but maybe should be 2
	ret
.mousepressed:
	mov ax, [mousecursorscrx]
	mov bx, [mousecursorscry]
	call GenerateDropDownEx_clickhandler
	mov byte [esi+window.data+DropDownExData.timer], 0	// undo click handler
.done:
	ret
	
GenerateDropDownEx_redraw:
	call dword [DrawWindowElements]
	mov cx, [esi+window.x]
	add cx, 1
	mov dx, [esi+window.y]
	inc dx
	bt word [DropDownExFlags], 1
	jc .divider
	inc dx
.divider:

	mov edi, [currscreenupdateblock]
	movzx ebx, byte [esi+window.itemsoffset]
	movzx ebp, byte [esi+window.itemsvisible]
	add ebp, ebx

.start:
	cmp word [DropDownExList+ebx*4], -1
	je near .done
	cmp ebp, ebx
	je near .done
	
	cmp word [DropDownExList+ebx*4], 0
	je near .next
		
	mov al, 0x10	//cTextColorBlack
	cmp bx, [esi+window.selecteditem]
	jne .notelected
.selected:
	mov al, 0x0C	//cTextColorWhite
	pusha
	add cx, 1
	mov eax, ecx
	mov ecx, edx
	mov ebx, eax
	add bx, word [esi+window.width]
	sub ebx, 5+DropDownExMaxSliderWidth
    add dx, word [DropDownExListItemHeight]
	dec edx
	xor ebp, ebp
	call [fillrectangle]
	popa
.notelected:

	pusha
	cmp dword [DropDownExListItemDrawCallback], 0
	je .nocallback
	pusha
	call [DropDownExListItemDrawCallback]
	popa
.nocallback:
	add cx, 2
	add cx, word [DropDownExListItemExtraWidth]
	mov bp, word [DropDownExListItemHeight]
	sub bp, 10
	shr bp, 1
	add dx, bp
	
	extern curmiscgrf
	mov esi, [DropDownExListGrfPtr+ebx*4]
	mov [curmiscgrf], esi
	
	movzx ebx, word [DropDownExList+ebx*4]
	bt word [DropDownExFlags], 2
	jnc .textid
	mov [specialtext1], ebx
	mov ebx, statictext(special1)
.textid:
	call [drawtextfn]
	popa
	
	bt [DropDownExListDisabled], ebx
	jnc .notdisabled
.disabled:
	pusha
	mov eax, ecx
	mov ecx, edx
	mov ebx, eax
	add bx, word [esi+window.width]
	sub ebx, 5+DropDownExMaxSliderWidth
    add dx, word [DropDownExListItemHeight]
	dec edx
	movzx ebp, byte [DropDownExElements.bgcolorbox]
	movzx bp, byte [colorschememap+5+ebp*8]
	or bp, 0x8000
	call [fillrectangle]
	popa
.notdisabled:
.next:
 	add dx, word [DropDownExListItemHeight]
	bt word [DropDownExFlags], 1
	jnc .nodivider
	add dx, 2
.nodivider:
	inc ebx
	cmp ebx, ebp
	jne near .start
.done:
	ret
	
GenerateDropDownEx_clickhandler:
	call dword [WindowClicked]
	jns .click
	ret
.click:
	cmp cl, 0
	jne .done
	sub	bx, [esi+window.y]
	sub bx, 2
	js .done
	mov ax, bx
	mov bx, word [DropDownExListItemHeight]
	bt word [DropDownExFlags], 1
	jnc .nodivider
	add bx, 2
.nodivider:	
//can we have a overflow here?
	div bl
	movzx eax, al
	add al, [esi+window.itemsoffset]
	cmp al, [esi+window.itemstotal]
	jnb .nonselect
	bt [DropDownExListDisabled], eax
	jc .nonselect
	mov word [esi+window.selecteditem], ax
	mov byte [esi+window.data+DropDownExData.timer], 4
.nonselect:
	call [RefreshWindowArea]
.done:
	ret
