// This houses the code for 'Clone Train' feature
// This is still very basic and early code
// 
// Created By Lakie
// Auguest 2006

#include <flags.inc>
#include <misc.inc>
#include <newvehdata.inc>
#include <player.inc>
#include <ptrvar.inc>
#include <std.inc>
#include <textdef.inc>
#include <veh.inc>
#include <vehtype.inc>
#include <window.inc>

extern setmousetool, patchflags, findvehontile, errorpopup, actionhandler, addexpenses
extern traindepotwindowhandler.resizewindow, CloneTrainBuild_actionnum
extern RefreshWindowArea
extern isengine, trainplanerefitcost, newvehdata

/*

	-= Basic Idea =-
* Add a button to the train depot gui
* Button makes the mouse cursor change
* Click on a tile
* Check for vehicle
* Get vehicle engine id
* Check that the engine to clone is the players controlled company
* Check that avilable funds are enough to pay for the train consist (bl=0)
* If failed (edx=80000000), quit with error message
* If passed create the wagons for the vechile
* Then Create the engine finish the consist
* Attach the wagons in the order they were made
* End (whilest giving the player the train window) and charging the player

	-= Possible Problems =-
* Artutated Vehicles since they can be multiple parts
* Trying to store the new vehicle ids so that they may be attached in the same order
* Refitting Vehicles to have the same cargo types

	-= Possiblities =-
* Maybe adding the ablity to add it to shared orders (if clicked with ctrl key)?
* Maybe copy the same misc bits so that the graphics and cargo etc. are exactly the same

	-= Comments =-
* Might be a pain to do and take a while

*/

// Stores the location of the new depotwindow elementlist
uvard newDepotWinElemList

// Stores the location of the old depot tooltips
uvard CloneDepotToolTips

/*

	-= Fixes for the orginal Depot Window Handler =-

*/

// Handles the right click code for the depot window (to prevent crash)
global CloneDepotRightClick
CloneDepotRightClick:
	cmp cl, 7
	je .isclonetrain
	push edi
	mov edi, [CloneDepotToolTips]
	mov ax, [edi+ebx*2]
	pop edi
	ret

.isclonetrain:
	mov ax, ourtext(txtclonetooltip)
	ret

// Handles the normal click for the depot window
global CloneDepotClick
CloneDepotClick:
	cmp cl, 7
	je .isclonetrain
	cmp cl, 2
	jne .bad
	add dword [esp], 0x1B4+3
.bad:
	ret

.isclonetrain:
	bt dword [esi+window.disabledbuttons], 7 // Disabled so non-usable
	jc .disabled

	bt dword [esi+window.activebuttons], 7 // Active so skip the next part
	jc .alreadyactive

	jmp CloneDepotActiveMouseTool

.disabled:
	ret

.alreadyactive:
	push ecx
	push esi
	mov ebx, 0
	mov al, 0
	call [setmousetool]
	pop esi
	pop ecx
	ret

// Handles the disabling of the "Clone Train" Button in the Train Depot Window
global CloneDepotDisableElements
CloneDepotDisableElements:
	je .isplayer
	or dword [esi+window.disabledbuttons], 0xA8
.isplayer:
	ret

// Handles the intercepting of the window handler events
global CloneDepotWindowHandler
CloneDepotWindowHandler:
	mov bx, cx
	mov esi, edi

testmultiflags clonetrain
	jz .noclonetrain
	cmp dl, cWinEventMouseToolClick
	je near CloneTrainMain
	cmp dl, cWinEventMouseToolClose
	je near CloneDepotDeActiveMouseTool
.noclonetrain:

testmultiflags enhancegui
	jz .noresizer
	cmp dl, cWinEventResize
	je traindepotwindowhandler.resizewindow
.noresizer:

	cmp dl, cWinEventRedraw // For the orginal subroutine
	ret

// Handles a special event when a train was clicked in the depot window
global CloneDepotVehicleClick
CloneDepotVehicleClick:
	test al, al
	jl .notactive // These function fine anyway

	cmp byte [curmousetoolwintype], 0x12 // Is this depot clone train active?
	jne .notactive

	cmp edi, 0
	je .notactive

	movzx edi, word [edi+veh.engineidx] // Make it a usable number
	shl edi, 7
	add edi, [veharrayptr]

	add dword [esp], 0x65 // Jumps to a ret after doing the clone subroutine
	jmp CloneTrainMain.foundvehicle

.notactive:
	cmp al, 1
	jne .nexttype
	add dword [esp], 0x65 // Jumps to a ret
	ret

.nexttype:
	cmp al, -1
	ret

/*

	-= Mouse Tool Handlers =-

*/

// Holds a sprite table for the mouse cursor
var CloneDepotMouseSpriteTable
	dw 0x2CC, 0x1D, 0x2CD, 0x1D, 0x2CE, 0x62, 0xFFFF

// Handles the activation of the Mouse Tool
CloneDepotActiveMouseTool:
	push esi
	bts dword [esi+window.activebuttons], 7 // Active the bit (Button)

	mov dx, [esi+window.id]
	mov ah, 0x12
	mov al, 1

	mov ebx, -1 // Makes the Cursor animated
	mov esi, CloneDepotMouseSpriteTable

	call [setmousetool]
	pop esi

	call dword [RefreshWindowArea]

	ret

// Handles the deactivation of the Mouse Tool
global CloneDepotDeActiveMouseTool
CloneDepotDeActiveMouseTool:
	btr dword [esi+window.activebuttons], 7
	call dword [RefreshWindowArea]
	ret

/*

	The Code that makes Clone Train work!

*/

// Holds the location to call for the Open Train Window subroutine
uvard CloneTrainOpenTrainWindow

// Handles the code for Clone Trains, all the calls etc
CloneTrainMain:
	movzx edi, word [mousetoolclicklocxy] // Get the tile to check
	call findvehontile // Is there a vehicle on this tile?
	jnz .foundvehicle
	ret

.foundvehicle:
	push edi
	movzx edi, word [esi+window.id]
	mov bh, [esi+window.company]

	rol di, 4
	mov ax, di
	mov cx, di
	rol cx, 8
	and ax, 0x0FF0
	and cx, 0x0FF0
	pop edi

	push esi
	mov bl, 1
	mov word [operrormsg1], ourtext(txtcloneerrortop)
	dopatchaction CloneTrainBuild
	cmp ebx, 1<<31
	je .failed

	mov edi, esi
	mov esi, [esp]
	call dword [CloneTrainOpenTrainWindow]


.failed:
	pop esi
	push ecx
	push esi
	mov ebx, 0 // Now reset the mouse tool
	mov al,  0
	call [setmousetool]
	pop esi
	pop ecx
	ret

/*

	The Actual PatchAction CloneTrain!

*/

// A few Variables to keep cloning working correctly
uvard CloneTrainCost // Stores the total cost of cloning
uvarw CloneTrainLastIdx // Stores the last created unit id

// Offsets to subroutines (so I can call them directly)
uvard CloneTrainBuyRailVehicle // <-- used to buy a new rail vehicle (changes based off newtrains)
uvard CloneTrainAttachVehicle // <-- used to attach vehicles to other vehicles
// [addexpenses] <-- use to alter the companies expenses

// Handles the actual operation of cloning the consist
// Input:	esi = Depot Window Pointer
//		edi = Vehicle Engine Pointer
// Output:	ebx = 0x80000000 if failed otherwise cost
//		esi = New consist Vehicle Engine Pointer
//		edi = Old consist Vehicle Engine Pointer
exported CloneTrainBuild
	push edi
	xchg esi, edi

	test bl, 1
	jz CloneTrainCalcOnly

	lea edi, [edi] // Blank for now

	xchg edi, esi
	pop edi
	ret

CloneTrainCalcOnly:
	mov dword [CloneTrainCost], 0 // Set this to 0 for now
	mov dword [trainplanerefitcost], 0

	mov word [operrormsg2], ourtext(txtcloneerror1) // Bad vehicle owner
	cmp bh, [esi+veh.owner]
	jne near .fail

	mov word [operrormsg2], ourtext(txtcloneerror3) // No Engine head
	cmp byte [esi+veh.subclass], 0
	jne near .fail

	mov word [operrormsg2], ourtext(txtcloneerror4) // Unknown issue with copying

.loop:
	cmp byte [esi+veh.artictype], 0xFD // Artic vehicles are already bought with there head
	jae .artic

	push ebx
	movzx bx, bh
	mov word [operrormsg2], ourtext(txtcloneerror2) // Vehicle not avilable anymore
	movzx edx, word [esi+veh.vehtype]
	imul edx, vehtype_size
	add edx, vehtypearray
	bt word [edx+vehtype.playeravail], bx
	jnc near .failebx
	pop ebx

	mov word [operrormsg2], ourtext(txtcloneerror4) // Unknown issue with copying

	push ebx
	mov dx, -1 // Contruct the vehicle (not for real though)
	movzx ebx, word [esi+veh.vehtype]
	shl bx, 8
	mov bl, 0
	push esi
	call [CloneTrainBuyRailVehicle]
	pop esi

	cmp ebx, 1<<31 // Fail or add costs
	je near .failebx
	add dword [CloneTrainCost], ebx
	pop ebx

.artic:
	push ebx // Attemps to work out refit cost
	push edx
	push eax
	xor ax, ax
	movzx ebx, word [esi+veh.vehtype]
	cmp word [esi+veh.capacity], 0
	je .nocapacity // no cargo so skip all this

	mov dl, [traincargotype+ebx] // Check if the cargo type is the same
	cmp byte [esi+veh.cargotype], dl
	je .nocapacity // If not there is a charge for the refitting which is constant

	movzx edx, byte [trainrefitcost+ebx] // Calculate the cost of this refit
	bt [isengine], ebx
	jc .engine
	imul edx, [wagonpurchasecostbase]
	jmp short .gotcost
.engine:
	imul edx, [trainpurchasecostbase]
.gotcost:
	sar edx, 2 // Fix it alittle and then store it for the end
	add dword [trainplanerefitcost], edx

.nocapacity:
	pop eax // Restore the values
	pop edx
	pop ebx

.next:
	movzx esi, word [esi+veh.nextunitidx] // Get the next id of the consist to clone
	cmp si, byte -1
	je .done
	shl esi, 7 // Move to the pointer in veh array
	add esi, [veharrayptr]
	jmp .loop

.failebx:
	pop ebx
	mov ebx, 1<<31
	pop edi
	ret

.fail:
	mov ebx, 1<<31
	pop edi
	ret

.done:
	mov ebx, [trainplanerefitcost] // Refit cost
	sar ebx, 7 // Correct the end value for refits
	add ebx, [CloneTrainCost]
	pop edi

// Hehe, for now this will stop people complaining
	mov word [operrormsg2], ourtext(txtcloneerrortmp) // Not Wrote yet
	mov ebx, 1<<31

	ret

