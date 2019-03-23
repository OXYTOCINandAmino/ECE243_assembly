/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start                  
_start:   MOV     R5,#0           //R5 holds largest 1's                          
          MOV     R1, #TEST_NUM   //R1 point to address to load data

LIST:     LDR     R3, [R1],#4     //load data into R3 and R1 point to next address
          CMP     R3, #0          //check reach end of list
          BEQ     END
          BL      ONES
          CMP     R0,R5           //if(r0 > R5)
          MOVGT   R5,r0           //r5 = r0
          B       LIST


END:      B       END  

          
ONES:    // R3 pass in and R0 hold result R2 local reg
          MOV     R0, #0          // R0 will hold the result
LOOP:     CMP     R3, #0          // loop until the data contains no more 1's
          BEQ     END_ONES             
          LSR     R2, R3, #1      // perform SHIFT, followed by AND
          AND     R3, R3, R2      
          ADD     R0, #1          // count the string length so far
          B       LOOP     
END_ONES: BX LR                  



TEST_NUM: .word   0x1,0x2,0x3,0x4,0x5,0x6,0x7,0x8,0x103fe00f,0x11,0x0 //array

          .end                            

     
     
     