 /*vector Table*/

.section .vectors, "ax"
  B _start // reset vector
  B SERVICE_UND // undefined instruction vector
  B SERVICE_SVC // software interrupt vector
  B SERVICE_ABT_INST // aborted prefetch vector
  B SERVICE_ABT_DATA // aborted data vector
  .word 0 // unused vector
  B SERVICE_IRQ // IRQ interrupt vector
  B SERVICE_FIQ // FIQ interrupt vector

.equ HEX_ADDR, 0xFF200020
.equ KEY_EDGE, 0xFF20005C //points to edge 
.equ A9_TIMER,0xFFFEC600 //points to timer


.text
.global _start
_start:                                       
        /* Set up stack pointers for IRQ */
        MOV   R1, #0b11010010
        MSR   CPSR_c, R1
        LDR   SP, =0xFFFFFFFC

        /* Change to supervisor mode*/
        MOV   R1, #0b11010011
        MSR   CPSR, R1
        LDR   SP, =0x3FFFFFFC
        
        /*Configuration*/
        BL       CONFIG_GIC      
        BL       CONFIG_KEYS 
        BL       CONFIG_A9_TIMER

        /*Configuration finished enable IRQ*/
        MOV   R0, #0b01010011
        MSR   CPSR_c, R0
        
        
        //strore the digits for A9_timerr
        //0.1s
        LDR R8, =DATA //ones digit
        LDR R9, =DATA //tens digit
        //1s
        LDR R10,=DATA
        LDR R11,=DATA

    LDR R0, =HEX_ADDR
        
LOOP:   MOV R12,#0
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
        
        B        LOOP      
        
 
/********************** Define the exception service routines *************/
SERVICE_UND:      B SERVICE_UND 
SERVICE_SVC:      B SERVICE_SVC 
SERVICE_ABT_INST: B SERVICE_ABT_INST 
SERVICE_ABT_DATA :  B SERVICE_ABT_DATA 
SERVICE_FIQ:    B SERVICE_FIQ 

/*IRQ is used*/
/*IRQ is used*/
SERVICE_IRQ:  PUSH {R0-R7, LR}
            LDR R4, =0xFFFEC100 // GIC CPU interface base address
          LDR R5, [R4, #0x0C] // read the ICCIAR in the CPU interface

FPGA_IRQ1_HANDLER:  
                CMP R5, #73 // check the interrupt ID = key?
                BEQ  KEY_ISR
                CMP R5, #29 // check the interrupt ID = timer?
                BEQ  A9_TIMER_ISR
                

EXIT_IRQ:       STR R5, [R4, #0x10] // write to the End of Interrupt Register (ICCEOIR)
                POP {R0-R7, LR}
                SUBS PC, LR, #4 // return from exception

/********************** Configure GIC ***********************************/
CONFIG_GIC: 
      /****** Distributor Register******/
      /*ICDIPTRn  [ID 73 KEY] [ID 72 Timmer] [ID 29 A9 Timer]to CPU0*/
      LDR   R0, =0xFFFED848
      LDR   R1, =0x00000101
      STR   R1, [R0]   
      LDR   R0, =0xFFFED81C 
      LDR   R1, =0x00000100
      STR   R1, [R0]  
      /*ICDISERn  [ID 73] [72] [29]enable */
      LDR   R0, =0xFFFED108
      LDR   R1, =0x00000300
      STR   R1, [R0]
      LDR   R0, =0xFFFED100
      LDR   R1, =0x20000000
      STR   R1, [R0]
      /*ICDDCR Enable */
      MOV   R1, #0x1
      LDR   R0, =0xFFFED000
      STR   R1, [R0]

      /****** CPU Interface Register******/
      /*enable interupt for all priority*/
      LDR   R0, =0xFFFEC100
      LDR   R1, =0xFF
      STR   R1, [R0, #4]
      /*ICCICR Enable*/
      MOV   R1, #0x1
      STR   R1, [R0]
      BX    LR
      
/******************************************************************************/ 
/* Configure the pushbutton KEYS to generate interrupts */
CONFIG_KEYS:                                    
              LDR    R0, =0xFF200050
              MOV   R1, #0xF
              STR   R1, [R0, #0x8 ]
              BX       LR     
              
/***********************KEY_ISR******************************************/
KEY_ISR:
      LDR R0, =0xFF200050
      LDR R1, [R0, #0xC] //read edge capture
      STR   R1, [R0, #0xC] //clear edge capture
      
      
CHECK_KEY3:
      MOV   R3, #0b1000
      ANDS  R3, R3, R1
      BNE   KEY3_PRESS
      BEQ END_KEY_ISR
      
            
KEY3_PRESS:      
            LDR R0,=RUN_STOP 
            LDR R1,[R0]
            EOR R1,#1
            STR R1,[R0] //change run stop
            B   END_KEY_ISR
            

            
END_KEY_ISR:
          B    EXIT_IRQ

 
/*****************************************************************************/
/* Configure the A9 private timer*/
 CONFIG_A9_TIMER:   
        LDR R0, =A9_TIMER
        LDR R1, =2000000 //the counting value
            STR R1, [R0]
              MOV R1,#0b111 //start counter
            STR R1,[R0,#0x8]
            BX  LR
              
/***********************A9_TIMER_ISR******************************************/
A9_TIMER_ISR:
              LDR R0, =A9_TIMER
              LDR R1, [R0, #0xC] //read timer finish
              STR   R1, [R0, #0xC] //restart timer
              LDR R0,=RUN_STOP 
              LDR R1,[R0]
              CMP R1,#1
              BLEQ  INCRE
            
END_A9_TIMER_ISR:
              B    EXIT_IRQ 


/***********************INCRE DISPLAY****************************/
INCRE:  
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
        
        BX  LR
        

RUN_STOP:               .word 0b1

DATA:               .word 0b00111111                        // '0'
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
        
  
  