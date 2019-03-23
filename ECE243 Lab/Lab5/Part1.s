
.equ HEX_ADDR, 0xFF200020
.equ KEY_ADDR, 0xFF200050

.text
.global _start

_start:
		LDR R0, =HEX_ADDR
		LDR R1, =KEY_ADDR
		LDR R3, =DATA
		MOV R8, #0 //if buttom released {R8=0}
		MOV R9, #0 //if clear {R9 =1}

POLL:	LDR R2, [R1]
		CMP R2, #0
		BEQ  RELEASE

		CMP R2, #1
		BEQ ZERO

		CMP R2, #2
		BEQ INCRE

		CMP R2, #4
		BEQ DECRE

		CMP R2,#8
		BEQ CLEAR
		B POLL

ZERO:	LDR R3, =DATA //set value to 0
		LDR R4, [R3]
		STR R4, [R0]	
		B POLL

INCRE:  CMP R9, #1 //if clear is called
		BEQ ZERO

	    CMP R8, #0 //check previous stage key released 
		LDREQ R4, [R3,#4]! //key released then +1
		LDRNE R4, [R3] //not released 
		STR R4, [R0]
		MOV R8, #1 
		B POLL

DECRE:  CMP R9, #1 //if clear is called
		BEQ ZERO

		CMP R8, #0 //check previous stage key released 
		LDREQ R4, [R3,#-4]! //key released then -1
		LDRNE R4, [R3] //not released 
		STR R4, [R0]
		MOV R8, #1 
		B POLL

CLEAR:  MOV R4,#0
		STRB R4, [R0] //clear the display
		MOV R9,#1
        B POLL

RELEASE: MOV R8,#0 //when released R8 = 0
		 B POLL







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

.end