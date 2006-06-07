//
// plane motion patches
//

#include <std.inc>
#include <veh.inc>

extern GetCallBack36

//
// called when plane moves
//
// in:	edi=vehicle ptr
// out:
// safe:eax,ebx,ecx,edx,esi,ebp
global moveplane
moveplane:
	cmp byte [edi+veh.subclass],2
	jna .realplane
	ret	// don't move shadows and rotors directly

.realplane:
	mov esi,edi
	call isplaneinflight
	sbb ecx,ecx
	and ecx,0
ovar .factor, -1, $,moveplane
	jz .once

	test byte [esi+veh.vehstatus],1<<7
	jz .domove

	// crashed plane, just process once
.once:
	mov cl,1

.domove:
	push ecx
	call $
ovar .doit, -4, $, moveplane
	pop ecx
	loop .domove
	ret



//
// find effective plane speed
//
// in:	ax=plane speed after acceleration
//	bx=top speed
//	esi=vehicle ptr
//	flags from test[esi+veh.vehstatus],0x40
// out:	bx=effective top speed for motion
// safe:eax ebx
global planebreakdownspeed
planebreakdownspeed:
	cmp word [esi+veh.speedlimit], 0
	jne .dontSetSpeedLimit
	mov word [esi+veh.speedlimit], bx
.dontSetSpeedLimit:
	push eax
	movzx ax, byte [esi+veh.movementstat]
	cmp al, byte [esi+veh.prevmovementstat]
	jne .movementHasChanged
	pop eax
	jmp .testBreakdown

.movementHasChanged:
	mov byte [esi+veh.prevmovementstat], al
	push ecx
	mov cx, bx
	mov ah, 0xC //speeeeed
	mov al, byte [esi+veh.vehtype]	//vehicles are only 0-255
	call GetCallBack36
	pop ecx
	mov word [esi+veh.speedlimit], ax
	pop eax

.testBreakdown:
	test word [esi+veh.vehstatus],0x40
	jz .updateCurrentSpeed

.brokendown:
	// normally TTD just limits the speed to 27 = 216 mph
	// now we make that 5/8 of the top speed
	push eax
	movzx eax, word [esi+veh.maxspeed]
	lea eax,[eax*5]
	shr eax,3
	cmp ax, word [esi+veh.speedlimit]
	jge .finishBreakDown
	mov word [esi+veh.speedlimit], ax
.finishBreakDown:
	pop eax

.updateCurrentSpeed:
	cmp ax, word [esi+veh.speed]
	je .noChange
	mov bx, word [esi+veh.speedlimit]
	cmp ax, bx
	je .noChange
	mov ax, word [esi+veh.speed]
	cmp ax, bx
	jbe .incSpeed //is speed equal or below limit? just continue
.decrement:
	dec ax
	cmp ax, bx
	jae .noChange
	mov ax, bx
	retn
.incSpeed:
	inc ax //put it back to the speed it should be.
	cmp ax, bx
	jbe .noChange
	mov ax, bx
.noChange:
	ret


//
// decide whether plane is in air or on runway accelerating/decelarating
//
// in:	esi=vehicle ptr
// out:	carry set if in flight
// uses:--
global isplaneinflight
isplaneinflight:
	push eax
	test byte [esi+veh.vehstatus],$80
	jnz .notinflight
	// in flight only if veh.aircraftop is 7..9 or >= 13
	mov al,[esi+veh.aircraftop]
	cmp al,7
	jb .notinflight
	cmp al,10
	jb .onrunway
	cmp al,13
	jb .notinflight
	cmp al,18	// 18:always in flight
	je .inflight

.onrunway:
	mov al,[esi+veh.movementstat]
		// not in flight unless movementstat is 13, 15, or 21+
		// for 13 and 21 only when facing in direction of runway
	cmp al,13
	jb .notinflight
	je .checkdirection

	cmp al,15
	je .checkdirection

	cmp al,21
	ja .inflight
	jb .notinflight

.checkdirection:
	cmp byte [esi+veh.direction],1
	je .inflight

.notinflight:
	clc
	pop eax
	ret

.inflight:
	stc
	pop eax
	ret
