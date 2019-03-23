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


.text                                       
.global  _start                          
_start:                                         
        /* Set up stack pointers for IRQ */
        MOV   R1, #0b11010010
        MSR   CPSR_c, R1
        LDR   SP, =0xFFFFFFFC

        /* Change to supervisor mode*/
        MOV   R1, #0b11010011
        MSR   CPSR, R1
        LDR   SP, =0x3FFFFFFC
        
        BL       CONFIG_GIC       // configure the ARM generic
                                  // interrupt controller
        BL       CONFIG_TIMER     // configure the Interval Timer
        BL       CONFIG_KEYS      // configure the pushbutton
                                  // KEYs port

        /*Configuration finished enable IRQ*/
        MOV   R0, #0b01010011
        MSR   CPSR_c, R0

        LDR      R5, =0xFF200000  // LEDR base address
LOOP:                                          
        LDR      R3, COUNT        // global variable
        STR      R3, [R5]         // write to the LEDR lights
        B        LOOP                


/********************** Define the exception service routines *************/
SERVICE_UND:      B SERVICE_UND 
SERVICE_SVC:      B SERVICE_SVC 
SERVICE_ABT_INST: B SERVICE_ABT_INST 
SERVICE_ABT_DATA :  B SERVICE_ABT_DATA 
SERVICE_FIQ:    B SERVICE_FIQ 

/*IRQ is used*/
SERVICE_IRQ:  PUSH {R0-R7, LR}
        LDR R4, =0xFFFEC100 // GIC CPU interface base address
        LDR R5, [R4, #0x0C] // read the ICCIAR in the CPU interface

FPGA_IRQ1_HANDLER:  
                CMP R5, #73 // check the interrupt ID = key?
                BEQ  KEY_ISR
                CMP R5, #72 // check the interrupt ID = timer?
                BEQ  TIMER_ISR

EXIT_IRQ:       STR R5, [R4, #0x10] // write to the End of Interrupt Register (ICCEOIR)
                POP {R0-R7, LR}
                SUBS PC, LR, #4 // return from exception

/********************** Configure GIC ***********************************/
CONFIG_GIC: 
      /****** Distributor Register******/
      /*ICDIPTRn  [ID 73 KEY] [ID 72 Timmer] to CPU0*/
      LDR   R0, =0xFFFED848
      LDR   R1, =0x00000101
      STR   R1, [R0]    
      /*ICDISERn  [ID 73] [72] enable */
      LDR   R0, =0xFFFED108
      LDR   R1, =0x00000300
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
/* Configure the Interval Timer to create interrupts at 0.25 second intervals */
CONFIG_TIMER:                             
              LDR    R0, =0xFF202000
              LDR    R1, =50000000 // 0.25s
              STR    R1, [R0, #0x8]
              LSR    R1, R1, #16
              STR    R1, [R0, #0xC]
              MOV    R1, #0b0111  //STAR=1 CONT=1 ITO=1
              STR    R1, [R0, #0x4]
              BX       LR                  

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
      
CHECK_KEY0:
      MOV   R3, #0b0001
      ANDS  R3, R3, R1
      BNE   KEY0_PRESS
      

CHECK_KEY1:
      MOV   R3, #0b0010
      ANDS  R3, R3, R1
      BNE   KEY1_PRESS //double rate
      
CHECK_KEY2:
      MOV   R3, #0b0100
      ANDS  R3, R3, R1
            BNE   KEY2_PRESS //half rate
      
            
KEY0_PRESS:      
            LDR R0 ,=RUN
            LDR R7 ,[R0]
            EOR R7 ,R7,#1
            STR R7 ,[R0] //RUN =!RUN
            B   END_KEY_ISR
            
KEY1_PRESS:      
            LDR    R0, =0xFF202000
            MOV    R1, #0b1010  
            STR    R1, [R0, #0x4]//STOP Timer
            
            LDR    R1, [R0, #0x8]
            LDR    R2, [R0, #0xC]
            LSL    R2, R2, #16
            ADD    R1, R1, R2 //restore the original value
            
            LSR    R1, R1, #1 //double the speed
            STR    R1, [R0, #0x8]
            LSR    R1, R1, #16
            STR    R1, [R0, #0xC]
            
            MOV    R1, #0b0111  //STAR=1 CONT=1 ITO=1
            STR    R1, [R0, #0x4]
            B      END_KEY_ISR
          
KEY2_PRESS:      
            LDR    R0, =0xFF202000
            MOV    R1, #0b1010  
            STR    R1, [R0, #0x4]//STOP Timer
            
            LDR    R1, [R0, #0x8]
            LDR    R2, [R0, #0xC]
            LSL    R2, R2, #16
            ADD    R1, R1, R2 //restore the original value
            
            LSL    R1, R1, #2 //half the speed
            STR    R1, [R0, #0x8]
            LSR    R1, R1, #16
            STR    R1, [R0, #0xC]
            
            MOV    R1, #0b0111  //STAR=1 CONT=1 ITO=1
            STR    R1, [R0, #0x4]
            B      END_KEY_ISR
            
END_KEY_ISR:
          B    EXIT_IRQ

/***********************TIMER_ISR******************************************/
TIMER_ISR:
      LDR    R0, =0xFF202000
          MOV    R1, #0
          STR    R1, [R0] //reset TO to 0
          
          LDR R0 ,=COUNT
          LDR R1 ,[R0]
          LDR R2 ,=RUN
          LDR R7 ,[R2]
          CMP R7 ,#1  //if RUN==1 {COUNT++}
          ADDEQ R1,R1,#1
          STR R1 ,[R0] 

END_TIMER_ISR:
        B    EXIT_IRQ


/* Global variables */
                  .global  COUNT                           
COUNT:            .word    0x0              // used by timer
                  .global  RUN              // used by pushbutton KEYs
RUN:              .word    0x1              // initial value to increment
                      // COUNT
                  .end        





  
  
  
  
  
  