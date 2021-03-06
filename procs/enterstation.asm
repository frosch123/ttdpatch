#include <defs.inc>
#include <frag_mac.inc>


extern patchflags


global patchenterstation

begincodefragments

codefragment oldenterstation,4
	mov ax,word [esi+veh.currorder]
	db 0x66,0xc7	// mov word ptr [esi+0ah],3

codefragment newentertrainstation
	call runindex(entertrainstation)

codefragment newenterrvstation
	call runindex(enterrvstation)

codefragment oldenterairport
	mov al,byte [esi+veh.targetairport]
	mov byte [esi+veh.laststation],al

codefragment newenterairport
	call runindex(enterairport)

codefragment oldenterdock
	mov ax,word [esi+veh.currorder]
	mov byte [esi+veh.laststation],ah

codefragment newenterdock
	call runindex(enterdock)
	setfragmentsize 7

codefragment oldpostorderupdate,-4
	or [esi+veh.currorder], ax

codefragment newpostorderupdate
	and al, 60h
	icall fifoenterstation
	setfragmentsize 8

endcodefragments

return:
	ret
patchenterstation:
	testflags gradualloading
	sbb bl,bl

	testflags feederservice
	sbb bl,0	// now bl==0 if neither gradualloading nor feederservice are on

	testflags fifoloading
	sbb bl,0	// now bl==0 if none of gradualloading,feederservice,fifoloading on
	
	test bl, bl
	jz return

	patchcode oldenterstation,newentertrainstation,1+WINTTDX,2	// trains
	patchcode oldenterstation,newenterrvstation,1,1		// truck/bus
	patchcode oldenterairport,newenterairport,1,1
	patchcode oldenterdock,newenterdock,1,1
	
	testflags fifoloading
	jnc .ret
	
	multipatchcode postorderupdate,4
.ret:
	ret


		// test for either presignals or extpresignals
		// if either is set we can have pre-signals
		// only presignals is set: only automatic setups
		// only extpresignals is set: no automatic setups
