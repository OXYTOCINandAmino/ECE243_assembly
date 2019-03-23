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
        BL    CONFIG_GIC


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

/* Configure the Interval Timer to create interrupts at 0.25 second intervals */
CONFIG_TIMER:                             
                  ... code not shown
                  BX       LR                  

/* Configure the pushbutton KEYS to generate interrupts */
CONFIG_KEYS:                                    
                  ... code not shown
                  BX       LR                  

/* Global variables */
                  .global  COUNT                           
COUNT:            .word    0x0              // used by timer
                  .global  RUN              // used by pushbutton KEYs
RUN:              .word    0x1              // initial value to increment
                                            // COUNT
                  .end                                        
