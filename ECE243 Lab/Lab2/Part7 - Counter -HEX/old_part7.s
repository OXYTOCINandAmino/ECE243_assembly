.define LEDR_ADDRESS 0x1000
.define SW_ADDRESS 0x3000
.define DELAY 0x8888
.define L_DELAY 0x0099
.define HEX_ADDRESS 0x2000

		mvi r1, #1				// r1 for increment e.g. add rX,r1 : rx=(rX)+1
		mvi r6, #0				// reset actual counter to 0
		mv	r5, r7				// backup return address
		mvi	r7, #BLANK			// call subroutine to blank the HEX displays
MAIN:	
		mvi r4, #L_DELAY		// get the "large delay time"
		mv r2, r7				// backup return address
		mvi r7, #LARGE			// call subroutine LARGE to count up to the "large delay time"
		
		add r6, r1				// actual counter increment 1
		
		mvi r0, #LEDR_ADDRESS	// r0 stores LEDR address
		st r6, [r0]				// store value in r6 (actual counter) onto LEDR
		
		//hex0
		mv r0, r6				// r0 stores the actual counter
		mv	r5, r7				// backup return address 
		mvi	r7, #DIV10			// call subroutine to divide r0 by 10. remainder will be stored in r0
		
		mvi	r4, #HEX_ADDRESS	// r4 stores HEX0 address
		mvi	r3, #DATA			// get the hex pattern address
		add	r3, r0				// correct the hex pattern address accoding to r0
		ld	r0, [r3]			// load the corresponding hex pattern onto r0
		st	r0, [r4]			// store r0(the corresponding hex pattern) onto the HEX
		
		//hex1
		mv r0, r2
		mv	r5, r7				
		mvi	r7, #DIV10	
		
		mvi	r4, #HEX_ADDRESS	// r4 stores HEX0 address
		add r4, r1				// correct address to HEX1
		mvi	r3, #DATA
		add	r3, r0
		ld	r0, [r3]
		st	r0, [r4]
		
		//hex2
		mv r0, r2
		mv	r5, r7				
		mvi	r7, #DIV10	
		
		mvi	r4, #HEX_ADDRESS	// r4 stores HEX0 address
		add r4, r1				// correct address to HEX1
		add r4, r1				// correct address to HEX2
		mvi	r3, #DATA
		add	r3, r0
		ld	r0, [r3]
		st	r0, [r4]
		
		//hex3
		mv r0, r2
		mv	r5, r7				
		mvi	r7, #DIV10	
		
		mvi	r4, #HEX_ADDRESS	// r4 stores HEX0 address
		add r4, r1				// correct address to HEX1
		add r4, r1				// correct address to HEX2
		add r4, r1				// correct address to HEX3
		mvi	r3, #DATA
		add	r3, r0
		ld	r0, [r3]
		st	r0, [r4]
		
		//hex4
		mv r0, r2
		mv	r5, r7				
		mvi	r7, #DIV10	
		
		mvi	r4, #HEX_ADDRESS	// r4 stores HEX0 address
		add r4, r1				// correct address to HEX1
		add r4, r1				// correct address to HEX2
		add r4, r1				// correct address to HEX3
		add r4, r1				// correct address to HEX4
		mvi	r3, #DATA
		add	r3, r0
		ld	r0, [r3]
		st	r0, [r4]
		
		mvi r7, #MAIN			//go to the next loop
		
DIV10:  mvi r2, #0
		mvi r3, #RETDIV 
DLOOP: 	mvi r4, #9
		sub r4, r0
		mvnc r7, r3 
INC: 	add r2, r1 
		mvi r4, #10
		sub r0, r4 
		mvi r7, #DLOOP 
RETDIV: add r5, r1 
		add r5, r1
		mv r7, r5 
		
LARGE: 	
		mvi r3, #DELAY	// get the "small delay time"
		mv r5, r7		// backup return address
		mvi r7, #SMALL	// call subroutine LARGE to count up to the "large delay time"
		sub r4, r1		// "large delay time" - 1
		mvi r0, #LARGE	// store address of subroutine LARGE onto r0
		mvnc r7, r0		// if ("large delay time" - 1) != 0, call subroutine LARGE
		add r2, r1		// adjust return address
		add r2, r1		// adjust return address
		mv r7, r2		// return back 


SMALL:	
		mvi r0, #SW_ADDRESS	// store SW_ADDRESS onto r0
		ld r0, [r0]		// load the counting speed from the switches
		sub r3, r0		// subtract the speed
		mvi r0, #SMALL	// store address of subroutine SMALL onto r0
		mvnc r7, r0		// if ("large delay time" - speed) != 0, call subroutine LARGE
		add r5, r1		// adjust return address
		add r5, r1		// adjust return address
		mv r7, r5		// return back 


BLANK:
			mvi	r0, #0				// used for clearing
			mvi	r2, #HEX_ADDRESS	// point to HEX displays
			st		r0, [r2]				// clear HEX0
			add	r2, r1
			st		r0, [r2]				// clear HEX1
			add	r2, r1
			st		r0, [r2]				// clear HEX2
			add	r2, r1
			st		r0, [r2]				// clear HEX3
			add	r2, r1
			st		r0, [r2]				// clear HEX4
			add	r2, r1
			st		r0, [r2]				// clear HEX5

			add	r5, r1
			add	r5, r1
			mv		r7, r5				// return from subroutine


DATA:		.word 0b00111111			// '0'
			.word 0b00000110			// '1'
			.word 0b01011011			// '2'
			.word 0b01001111			// '3'
			.word 0b01100110			// '4'
			.word 0b01101101			// '5'
			.word 0b01111101			// '6'
			.word 0b00000111			// '7'
			.word 0b01111111			// '8'
			.word 0b01100111			// '9'
