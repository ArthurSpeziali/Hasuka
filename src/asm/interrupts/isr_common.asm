; ISR Systrem for Exceptions on CPU. The 32 First IRQ error's in the 256
; Receives a vector in RDI, dont return nothing 
; uint8 RDI (vector)

BITS 64

; The isr_handler is an hipotetic function that i will developer later 
; But, it will handler the Vector 
extern isr_handler

; Macros Here 
; ISR sometimes, send an 64-bit error code 
; Then we have to push a error code who that not have error code
%macro IsrNoCode 1 
  global isr_stub_%1
  isr_stub_%1:
    PUSH qword 0                               ; For defaultism, we put 0 for don't have own code
    PUSH qword %1                              ; Here, it is too 64-bit value, in this case, own vector number
    JMP isr_common                             ; Jump to resolver
%endmacro
%macro IsrWithCode 1 
  global isr_stub_%1
  isr_stub_%1:
    PUSH qword %1                              ; In this case, it have your code error, we dont push the 0
    JMP isr_common
%endmacro

; Here the all Stub (ISR) table 
; The fisrt 32 entries in the 256 vector codes 
; We execute the all macros. Dont forget, we are in .text section
IsrNoCode 0      ; Divide by Zero
IsrNoCode 1      ; Debug
IsrNoCode 2      ; Non Maskable Interrupt
IsrNoCode 3      ; Breakpoint
IsrNoCode 4      ; Into Detected Overflow
IsrNoCode 5      ; Out of Bounds
IsrNoCode 6      ; Invalid Opcode
IsrNoCode 7      ; No Coprocessor
IsrWithCode 8    ; Double Fault
IsrNoCode 9      ; Coprocessor Segment Overrun
IsrWithCode 10   ; Bad TSS
IsrWithCode 11   ; Segment Not Present
IsrWithCode 12   ; Stack Fault
IsrWithCode 13   ; General Protection Fault
IsrWithCode 14   ; Page Fault
IsrNoCode 15     ; Unknown Interrupt
IsrNoCode 16     ; Coprocessor Fault
IsrWithCode 17   ; Alignment Check
IsrNoCode 18     ; Machine Check
IsrNoCode 19     ; SIMD Floating Point
IsrNoCode 20     ; Virtualization Exception
IsrWithCode 21   ; Control Protection Exception
IsrNoCode 22     ; Reserved
IsrNoCode 23     ; Reserved
IsrNoCode 24     ; Reserved
IsrNoCode 25     ; Reserved
IsrNoCode 26     ; Reserved
IsrNoCode 27     ; Reserved
IsrNoCode 28     ; Hypervisor Injection Exception
IsrWithCode 29   ; VMM Communication Exception
IsrWithCode 30   ; Security Exception
IsrNoCode 31     ; Reserved


; Return to real code
section .text
global isr_common 
isr_common:
  ; Now, the stack has the CPU core registers, like CS, RFLAGS, RIP etc....
  ; We need to save the geral use registers 
  PUSH rax 
  PUSH rbx 
  PUSH rcx 
  PUSH rdx
  PUSH rdi 
  PUSH rsi 
  PUSH rbp                                     ; Trully, i don't know what this register do LOL 
  PUSH r8
  PUSH r9
  PUSH r10 
  PUSH r11 
  PUSH r12 
  PUSH r13
  PUSH r14
  PUSH r15 
  
  ; Load the vector number from the stack into RDI for the handler
  ; The stack layout after pushes: [r15, r14, ..., rax, vector, error_code]
  ; There are 15 registers pushed. Vector is at [rsp + 15*8]
  MOV rdi, [rsp + 15*8]
  CALL isr_handler 

  POP r15 
  POP r14 
  POP r13
  POP r12
  POP r11
  POP r10
  POP r9
  POP r8
  POP rbp
  POP rsi
  POP rdi
  POP rdx
  POP rcx
  POP rbx
  POP RAX

  ; Now, we delete from the stack the 2 numbers were we have push'em (Error code + Vector Number) in the macros 
  ; We uses temporaly RAX to remove. This is similar to: ADD 16, rsp  
  ; The stack growth to down. If it begins at 0x1008, we PUSH four bytes, then it will be in 0x1004. And 2 qword POP's, we will be in 0x1014
  ; It will be subtract, so for real subtraction, we add.
  ADD rsp, 16                                  ; SImilar to 2x'POP rax'


  IRETQ                                       ; IRET (Or IRETQ for in Long Mode), POP the CPU core registers (CS, RFLAGS, RIP...) automaticly
