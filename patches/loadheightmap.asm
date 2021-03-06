#include <std.inc>
#include <proc.inc>
#include <ptrvar.inc>

extern int21handler, gettileinfo

varb loadheightmap_filename
	db 'height.raw', 0
endvar
global loadheightmap
proc loadheightmap
	local filehandle
	
	_enter
	cmp byte [gamemode], 2
	jnz near .fail
	
	call resetland
	
	mov edx, loadheightmap_filename
	mov ax, 0x3d00
	CALLINT21
	jc near .failopen
	
	xchg eax,ebx
	mov [%$filehandle], bx
	mov ax,0x4200
	xor edx,edx
	xor ecx,ecx
	CALLINT21
	jc near .fail
	
	// In:	bx: filehandle
	// Out:	edx: file size
	extcall getfilesize
	jc near .fail
	
	cmp edx, 0x10000
	je .grayscale
	
//	cmp edx, 0x30000
//	je .24bit
	
	jmp .fail
	
.grayscale:
	xor ebx, ebx
	
.nextline:
	// read one line
	push ebx
	mov ax, 0x3F00
	mov bx, [%$filehandle]
	mov ecx, 256
	mov edx, baTempBuffer1
	CALLINT21
	pop ebx
	
	
	push ebx
	mov esi, baTempBuffer1
	mov ecx, 254	
 .next:
 	lodsb
	shr al, 4
	
	cmp bh, 1
	jb .water
	je .noheight
	
	cmp bh, 0xFE
	je .water
	
	cmp bl, 1
	jb .water
	je .noheight
	
	cmp bl, 0xFE
	je .water
	jmp short .normal
.water:
	mov al, 0x60
	jmp .normal
.noheight:
	mov al, 0x00
.normal:
	mov byte [landscape4(bx)], al
	mov byte [landscape5(bx)], 0
	mov byte [landscape1+ebx], 0
	mov byte [landscape2+ebx], 0
	mov word [landscape3+ebx*2], 0
	
	inc ebx
	dec ecx
	jnz .next
	
	pop ebx
	add ebx, 0x100
	
	cmp ebx, 0xFE00
	jb .nextline
	// now skipped whole line
	
.normalize:


	mov eax, 0x0000
.loop:
	push eax
	sub eax, 0x100
	and eax, 0xFFFF
	mov dl, [landscape4(ax,1)]	// top edge
	and dx, 0xF
	pop eax

	mov bx, dx
	
	push eax
	dec eax
	and eax, 0xFFFF
	mov dl, [landscape4(ax,1)]	// left edge
	and dx, 0xF
	pop eax

	cmp dl, bl
	jae .switch
	mov bx, dx	
.switch:

	push eax
	and eax, 0xFFFF
	mov dl, [landscape4(ax,1)]	// the tile
	and dx, 0xF
	pop eax
	
	add bx, 2
	
	cmp dx, bx
	jl .nocorrection
	dec bx
	and bl, 0xF
	and eax, 0xFFFF
	mov byte [landscape4(ax,1)], bl
 .nocorrection:
	
	inc eax
	cmp eax, (256*256)
	jl .loop
	
	
	nop
	nop
	nop

	
	mov eax, 256*256
.loop2:
	push eax
	add eax, 0x100
	and eax, 0xFFFF
	mov dl, [landscape4(ax,1)]	// bottom edge
	and dx, 0xF
	pop eax

	mov bx, dx
	
	push eax
	inc eax
	and eax, 0xFFFF
	mov dl, [landscape4(ax,1)]	// right edge
	and dx, 0xF
	pop eax

	cmp dl, bl
	jae .switch2
	mov bx, dx	
.switch2:

	push eax
	and eax, 0xFFFF
	mov dl, [landscape4(ax,1)]	// the tile
	and dx, 0xF
	pop eax
	
	add bx, 2
	
	cmp dx, bx
	jl .nocorrection2
	dec bx
	and bl, 0xF
	and eax, 0xFFFF
	mov byte [landscape4(ax,1)], bl
 .nocorrection2:
	
	dec eax
	jnz .loop2
	
.ok:
	mov ax, 0x3E00
	mov bx, [%$filehandle]
	CALLINT21
	
	extern redrawscreen
	call redrawscreen
	
	clc
	_ret
	
.fail:
	mov ax, 0x3E00
	mov bx, [%$filehandle]
	CALLINT21
	
.failopen:
	call redrawscreen
	stc
	_ret
endproc




exported resetland
	pusha
	mov ah, 0x2C
	CALLINT21
	xor ch, dl
	xor cl, dh
	mov ax, cx
	xor ch, ch
	xor al, al
	shr ax, 4
	xor cx, ax
	mov dx, cx
	
	mov ebp,[ophandler+0xC*8]
	mov ebx, 1
	call dword [ebp+4]
	mov byte [human1], 0x10
	mov byte [canrandomizelandscape], 1
	popa
	ret
