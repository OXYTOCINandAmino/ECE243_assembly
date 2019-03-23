.define LEDR_ADDRESS 0x1000
.define SW_ADDRESS 0x3000
.define DELAY 0x8888
.define L_DELAY 0x0099

//r0: temp
//r1: 1
//r2: return address
//r3: small counter
//r4: large counter
//r5: return address
//r6: Actual Counter
//r7: pc
		mvi r1, #1                  // r1 for increment e.g. add rX,r1 : rx=(rX)+1
		mvi r6, #0              // reset actual counter to 0
MAIN:	
		mvi r4, #L_DELAY       // get the "large delay time"
		mv r2, r7              // backup return address
		mvi r7, #LARGE         // call subroutine LARGE to count up to the "large delay time"
		
		add r6, r1              // actual counter increment 1

		//output actual counter
		mvi r0, #LEDR_ADDRESS   // r0 stores LEDR address
		st r6, [r0]             // store value in r6 (actual counter) onto LEDR
		
		mvi r7, #MAIN          //go to the next loop
LARGE: 	
		mvi r3, #DELAY          // get the "small delay time"
		mv r5, r7               // backup return address
		mvi r7, #SMALL          // call subroutine LARGE to count up to the "large delay time"
		sub r4, r1              // "large delay time" - 1
		mvi r0, #LARGE          // store address of subroutine LARGE onto r0
		mvnc r7, r0             // if ("large delay time" - 1) != 0, call subroutine LARGE
		add r2, r1              // adjust return address
		add r2, r1              // adjust return address
		mv r7, r2               // return back


SMALL:	
		mvi r0, #SW_ADDRESS     // store SW_ADDRESS onto r0
		ld r0, [r0]             // load the counting speed from the switches
		sub r3, r0              // subtract the speed
		mvi r0, #SMALL          // store address of subroutine SMALL onto r0
		mvnc r7, r0             // if ("large delay time" - speed) != 0, call subroutine LARGE
		add r5, r1              // adjust return address
		add r5, r1              // adjust return address
		mv r7, r5               // return back
