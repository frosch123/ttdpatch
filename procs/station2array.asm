#include <defs.inc>
#include <frag_mac.inc>
#include <station.inc>
#include <bitvars.inc>
#include <patchproc.inc>

patchproc fifoloading,generalfixes,newcargos,irrstations,patchstation2array

extern malloccrit,miscmodsflags,patchflags,stationarray2ofst
extern stationarray2ptr

begincodefragments

codefragment oldsetupstationstruct_2
	mov byte [esi+station.exclusive],0

codefragment newsetupstationstruct_2
	icall setupstation2
	setfragmentsize 7

codefragment oldsetupoilfield
	mov byte [esi+station.facilities],0x18

codefragment newsetupoilfield
	icall setupoilfield
	setfragmentsize 7

endcodefragments

patchstation2array:
	xor ebx,ebx
	testflags generalfixes
	jnc .nogenfix
	test dword [miscmodsflags],MISCMODS_NOEXTENDSTATIONRANGE
	jz .doit
.nogenfix:
	testflags fifoloading
	jc .doit
	testflags stationsize
	jc .doit
	testflags newcargos
	jnc .dontdoit
.doit:
	inc ebx
	push dword numstations*station2_size
	call malloccrit
	pop edi
	mov [stationarray2ptr], edi
	add edi, numstations*station2_size
	extern stationarray2endptr
	mov [stationarray2endptr], edi
	sub edi, numstations*station2_size
	sub edi, [stationarrayptr]
	mov [stationarray2ofst], edi

.dontdoit:
	patchcode oldsetupstationstruct_2,newsetupstationstruct_2,1,1,,{test ebx,ebx},nz
	patchcode oldsetupoilfield,newsetupoilfield,1,1,,{test ebx,ebx},nz

	ret
