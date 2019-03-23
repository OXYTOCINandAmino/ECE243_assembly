          .text                   // executable code 
          .global _start                  
          //R5 longest1's //R6 longest 0's //R7 logest0101
          //R1 pass in value  //r0 return value

_start:   
          MOV     R1, #TEST_NUM   //R1 point to address to load data
          LDR     R1, [R1]		  

          BL      ONES
          MOV	  R5,R0

          BL	  ZEROS
          MOV     R6,R0

          BL	  ALTERNATIVES
          MOV     R7,R0

          BL 	  DISPLAY

END:      B       END  
              

//////////////////////////////////////////          
ONES:    // R1 pass in and R0 hold result
		  PUSH	  {R1-R12,LR}
          MOV     R0, #0          // R0 will hold the result
LOOP:     CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     END_ONES             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       LOOP     
END_ONES: POP	  {R1-R12,LR}
		  BX LR            

/////////////////////////////////////////
ZEROS:    // R1 pass in and R0 hold result
		  PUSH	  {R1-R12,LR}
          LDR	  R3,=0xffffffff
		  EOR	  R1,R1,R3
          BL	  ONES
          
END_ZEROS: POP	  {R1-R12,LR}
		  BX LR                

////////////////////////////////////////
ALTERNATIVES:  // R1 pass in and R0 hold result
		  PUSH	  {R2-R12,LR}
          LDR	  R3,=0x55555555
          EOR     R1,R1,R3 //longest 1's
          
          BL	  ONES
          MOV	  R2,R0    //logest 1's in R2
          BL	  ZEROS
          MOV	  R3,R0    //logest 0's in R3
          CMP	  R2,R3
          MOVGT   R0,R2
          MOVLE   R0,R3

END_ALTERNATIVES: POP	  {R2-R12,LR}
		          BX LR          



///////////////////////////////////////
/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */

SEG7_CODE:  PUSH 	{LR}
            MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            POP		{LR}
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment




////////////////////////////////////////
/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:    PUSH	{LR}
			LDR     R8, =0xFF200020 // base address of HEX3-HEX0
			//display R5 on HEX1-0
            MOV     R0, R5          
            BL      DIVIDE          // ones digit will be in R0; tens digit in R1
            MOV     R9, R1          
            BL      SEG7_CODE            
            MOV     R4, R0          // R4 store pattern of ones digit
            MOV     R0, R9          
            BL      SEG7_CODE       
            LSL     R0, #8          //R0 [tens digit 00000000]
            ORR     R4, R0          //R4 [tens ones]
            
            //display R6 on HEX3-2
            MOV     R0, R6          
            BL      DIVIDE          // ones digit will be in R0; tens digit in R1
            MOV     R9, R1          
            BL      SEG7_CODE            
            MOV     R10, R0          // R10 store pattern of ones digit
            MOV     R0, R9          
            BL      SEG7_CODE       
            LSL     R0, #8          //R0 [tens digit 00000000]
            ORR     R10, R0         //R10 [tens ones]
            LSL		R10,#16         //R10 [tens ones byte byte]

            ORR		R4,R10
            STR     R4, [R8]        // display the numbers from R6 and R5

            //display R7 on HEX5-4
            LDR     R8, =0xFF200030 // base address of HEX5-HEX4
            MOV     R0, R7         
            BL      DIVIDE          // ones digit will be in R0; tens digit in R1
            MOV     R9, R1          
            BL      SEG7_CODE            
            MOV     R4, R0          // R4 store pattern of ones digit
            MOV     R0, R9          
            BL      SEG7_CODE       
            LSL     R0, #8          //R0 [tens digit 00000000]
            ORR     R4, R0          //R4 [tens ones]
            STR     R4, [R8]        // display the number from R7
            POP		{LR}
            BX		LR


////////////////////////////////////////
/* r0 as input 
  ones digit will be in R0; tens digit in R1 */

DIVIDE:	    PUSH	{LR}
			MOV   	R1,#0
DIV10:	    CMP		R0,#10
            BLT     DIV_END
			SUB 	R0,#10
            ADD 	R1,#1
            B		DIV10
DIV_END:	POP		{LR}
			BX		LR

//////////////////////////////////////////
TEST_NUM: .word   0xFFFFF500

          .end    