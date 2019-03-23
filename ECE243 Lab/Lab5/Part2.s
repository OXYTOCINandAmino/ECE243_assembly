
.equ HEX_ADDR, 0xFF200020
.equ KEY_ADDR, 0xFF200050 //points to KEY
.equ KEY_EDGE, 0xFF20005C //points to edge 

.text
.global _start

_start:
		LDR R0, =HEX_ADDR
		LDR R1, =KEY_ADDR
        LDR R2, =KEY_EDGE
		LDR R8, =DATA+ //ones digit
        LDR R9, =DATA //tens digit
        
        MOV R4, #0 //R4 =1 when key pressed // R4 = 0 when key released
        MOV R5, #0 //Start =1 Stop =0
        LDR R7, =0x2 //counting value
       

        
POLL:	LDR R6, [R1]
		CMP R6, #0
        BNE START_STOP
        BEQ NO_KEY_PRESS
        
START_STOP:
		//if some key is pressed 
        CMP R4,#0 //meet a posedge
		EOREQ R5,#1
        MOV R4,#1 //R4 = 1 when key pressed
        
NO_KEY_PRESS:        
        LDR R6, [R2]
		CMP R6, #0
        //if key released
        STRNE R6, [R2] //reset edge flag
        MOVNE R4, #0
        
        CMP R5,#1
        BEQ INCRE_DISPLAY
       
        B POLL

         
INCRE_DISPLAY:
	    LDR R11,[R9] //load tens digit
        LSL R11,#8
        LDR R10,[R8] //load ones digit
        ADD R6,R10,R11
        STR R6,[R0]
        //start counting down
        SUBS R7,#1
        BEQ INCRE
        B POLL
        
INCRE:	
		LDR R7, =0x2000 //reset counting value
        CMP R10,#0b01100111 //ones =9
        LDREQ R8, =DATA //ones digit
        ADDEQ R9, #4
        ADDNE R8, #4
        
        LDR R12,=0x6767
        CMP R6,R12 //99
        LDREQ R8, =DATA //ones digit
        LDREQ R9, =DATA //tens digit
		
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
	
	
	
	
	
	
	
	