.define LEDR_ADDRESS 0x1000
.define SW_ADDRESS 0x3000
.define DELAY 0x8888
.define L_DELAY 0x0099

//r0: temp
//r1: 1
//r2: temp
//r3: small counter
//r4: large counter
//r5: return address
//r6: Actual Counter
//r7: pc
		mvi r1, #1
		mvi r6, #0
MAIN:	
		mvi r4, #L_DELAY
		mv r2, r7
		mvi r7, #LARGE
		
		add r6, r1
		//output actual counter
		mvi r0, #LEDR_ADDRESS
		st r6, [r0]
		
		mvi r7, #MAIN
LARGE: 	
		mvi r3, #0
		mv r5, r7
		mvi r7, #SMALL
		sub r4, r1
		mvi r0, #LARGE
		mvnc r7, r0
		add r2, r1
		add r2, r1
		mv r7, r2


SMALL:	
		mvi r0, #SW_ADDRESS
		ld r0, [r0]
		add r3, r0
		mvi r0, #SMALL
		mvnc r7, r0
		add r5, r1
		add r5, r1
		mv r7, r5
