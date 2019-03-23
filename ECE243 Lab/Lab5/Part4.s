
.equ HEX_ADDR, 0xFF200020
.equ KEY_ADDR, 0xFF200050 //points to KEY
.equ KEY_EDGE, 0xFF20005C //points to edge 
.equ TIMER,0xFFFEC600 //points to timer

.text
.global _start

_start:
        LDR R0, =HEX_ADDR
        LDR R1, =KEY_ADDR
        LDR R2, =KEY_EDGE
        LDR R3, =TIMER
        //0.1s
        LDR R8, =DATA //ones digit
        LDR R9, =DATA //tens digit
        //1s
        LDR R10,=DATA
        LDR R11,=DATA
        
        
        MOV R4, #0 //R4 =1 when key pressed // R4 = 0 when key released
        MOV R5, #0 //Start =1 Stop =0


//this part for the timer
        LDR R7, =2000000 //the counting value
        STR R7,[R3]
        
POLL:   LDR R6, [R1]
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
        BNE STOP_COUNT
       
        B POLL

         
INCRE_DISPLAY:
        MOV R7,#0b011 //start counter
        STR R7,[R3,#0x8]
		
        MOV R12,#0
        LDR R7,[R11] //load tens digit
        LSL R7,#24
        ADD R12,r7
        
        LDR R7,[R10] //load tens digit
        LSL R7,#16
        ADD R12,r7
        
        LDR R7,[R9] //load tens digit
        LSL R7,#8
        ADD R12,r7
        
        LDR R7,[R8] //load tens digit
        ADD R12,r7
        
        STR R12,[R0]
        
        //start counting down
        LDR R7,[R3,#0xC]
        CMP R7,#1
        BEQ INCRE
        B POLL
        
INCRE:  
        STR R7,[R3,#0xC]//restart timmer
        LDR R7,=DATA
        ADD R7,#36
        
        CMP R8,R7 //9
        LDREQ R8, =DATA //ones digit
        ADDEQ R9, #4
        ADDNE R8, #4
        
        CMP R9,R7 //90
        LDREQ R9, =DATA //tens digit
        ADDEQ R10,#4
        
        CMP R10,R7//9
        LDREQ R10, =DATA //tens digit
        ADDEQ R11,#4
                
        LDR R7,=DATA
        ADD R7,#24
        CMP R11,R7//60
        LDREQ R8, =DATA 
        LDREQ R9, =DATA 
        LDREQ R10,=DATA
        LDREQ R11,=DATA
        
        B POLL
        
STOP_COUNT:
                MOV R7,#0b010 //stop counter
        STR R7,[R3,#0x8]
        B POLL


DATA:           .word 0b00111111                        // '0'
                        .word 0b00000110                        // '1'
                        .word 0b01011011                        // '2'
                        .word 0b01001111                        // '3'
                        .word 0b01100110                        // '4'
                        .word 0b01101101                        // '5'
                        .word 0b01111101                        // '6'
                        .word 0b00000111                        // '7'
                        .word 0b01111111                        // '8'
                        .word 0b01100111                        // '9'

.end
        
        
        
        
        
        
        
        