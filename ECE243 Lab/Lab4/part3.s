          .text                   // executable code 
          .global _start                  
          //R5 longest1's //R6 longest 0's //R7 logest0101
          //R1 pass in value  //r0 return value

_start:   
          MOV     R1, #TEST_NUM   //R1 point to address to load data
          LDR     R1, [R1]           

          BL      ONES
          MOV    R5,R0

          BL     ZEROS
          MOV     R6,R0

          BL     ALTERNATIVES
          MOV     R7,R0

END:      B       END  

//////////////////////////////////////////          
ONES:    // R1 pass in and R0 hold result
            PUSH      {R1-R12,LR}
          MOV     R0, #0          // R0 will hold the result
LOOP:     CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     END_ONES             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       LOOP     
END_ONES: POP    {R1-R12,LR}
            BX LR            

/////////////////////////////////////////
ZEROS:    // R1 pass in and R0 hold result
            PUSH      {R1-R12,LR}
          LDR    R3,=0xffffffff
            EOR       R1,R1,R3
          BL     ONES
          
END_ZEROS: POP   {R1-R12,LR}
            BX LR                

////////////////////////////////////////
ALTERNATIVES:  // R1 pass in and R0 hold result
            PUSH      {R2-R12,LR}
          LDR    R3,=0x55555555
          EOR     R1,R1,R3 //longest 1's
          
          BL     ONES
          MOV    R2,R0    //logest 1's in R2
          BL     ZEROS
          MOV    R3,R0    //logest 0's in R3
          CMP    R2,R3
          MOVGT   R0,R2
          MOVLE   R0,R3

END_ALTERNATIVES: POP      {R2-R12,LR}
                    BX LR          


TEST_NUM: .word   0xFFFFF500

          .end                            

     
     
     
     