; Start point to incializing the IDT table, and start IRQ/ISR's 
; no input, no output 

BITS 64

; Extern Functions
extern idt_set_entry 
extern idt_load
extern pic_controller_disable

; Macros Here 
; We use the NASM notation 'assign' to link a value in a variable multiple times (Like 'i' in a for loop)
; mut i = 0
%assign i 0
; The REP notation repeat the block X times
; So, here it's import the all Isr Stub Functions (32 in sum)
%rep 32
  extern isr_stub_%+i                          ; So, its repeat 32 times, and use 'i' to name each label
  %assign i i+1                                ; Here, 'i' is mutable, so i = i+1
%endrep

; Repeat the same, with the 16 IRQ's functions 
%assign i 0 
%rep 16
  extern irq_stub_%+i
  %assign i i+1
%endrep


; Backs to normal code 
section .text
global interrupts_init 
interrupts_init: 
  ; I finnally find the purpose of the RBP register! 
  ; It is convenally used to save RSP (But not exclusive)
  ; For exemple, here we will save the Stack Pointer (RSP)
  ; Because in other functions (who we'll call), they use RSP directly (Not POP/PUSH) with adiction and subtracion of memory 
  PUSH rbp                                     ; Saves RBP (RSP yet points to)
  MOV rbp, rsp                                 ; RBP = Pointer of begin (Or end) of the Stack

  ; We need to set each IDT Entry for every ISR Stub 
  ; It's possible to use Macros inside a function. LOL, i didn't know 
  %assign i 0
  %rep 32 
    ; Here, we uses the 'i' of the macro 'assign'. That's amazing
    MOV rdi, i                                 ; RDI as the vector number
    ; We need to use LEA here, but is the same as 'MOV rsi, isr_stub_%+i'
    LEA rsi, [isr_stub_%+i]                    ; RSI as address of handler function

    CALL idt_set_entry                         ; Finnaly, we call the idt_set_entry for each 32 ISR Stubs
    %assign i i+1                              ; i = i+1. Increase 'i' for the next iterarion
  %endrep 

  ; Now, we reprograming the PIC to not sending IRQ's to 8-15 (But in 32-47)
  CALL pic_controller_disable 
  
  ; And now, we register in the table all 16 Hardware IRQ
  %assign i 0
  %rep 16
    ; i+32 Because, we are converting the original IRQ vetor to modified
    MOV rdi, i+32                              ; RDI as the vector number
    LEA rsi, [irq_stub_%+i]                    ; RSI as address of handler function

    CALL idt_set_entry                         ; Finnaly, we call the idt_set_entry for each 32 ISR Stubs
    %assign i i+1                              ; i = i+1. Increase 'i' for the next iterarion
  %endrep 

  ; Remember Fact. The IDT Table is like (0-255):
  ; 0-31 Entries   => ISR Stubs (Exceptions) 
  ; 32-47          => IRQ Stubs (Hardware)
  ; 48-255         => Reserved (IRQ yet, but no utility)

  ; And finnaly, loads the IDT with LIDT in CPU 
  CALL idt_load                                ; Calls idt_load to load the entire 256-entries of IDT Table

  ; The most expected moment
  ; Finnaly, we set to back the Interrupts 
  ; If something went error, the moment is this
  STI                                         

  LEAVE                                        ; Alias to 'MOV rsp, rbp' & 'POP rbp'
  RET                                          ; Return to Main Kernel

