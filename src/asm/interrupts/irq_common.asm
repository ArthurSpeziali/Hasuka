; IRQ Systrem for Hardware Interrupts on CPU. Define 16 Interruptions in 256 in total
; Receives a vector in RDI, dont return
; uint8 RDI (vector)

BITS 64

; Extern Functions 
extern irq_handler 
extern pic_controller_eoi 

; Macros Here
%macro IrqStub 2
  global irq_stub_%1
  irq_stub_%1:
    ; IRQ's doesn't have an own code error, but for good practices, we push 0 in stack
    PUSH qword 0        ; Dummy error code
    PUSH qword %2       ; Vetor number
    JMP irq_common      
%endmacro

%macro Debug 1
  extern debug_hex
  extern com_serial_print
  PUSH rax
  PUSH rdx
  PUSH rdi 
  PUSH rsi

  MOV rdi, %1 
  CALL debug_hex
  MOV rdi, rax
  MOV rsi, rdx
  CALL com_serial_print

  POP rsi 
  POP rdi 
  POP rdx
  POP rax 
%endmacro


; Calls the macro to create all functions for each IRQ
;     CODE | VETOR 
IrqStub 0,  32  ; Timer
IrqStub 1,  33  ; Keyboard
IrqStub 2,  34  ; Cascade (PIC2)
IrqStub 3,  35  ; COM2
IrqStub 4,  36  ; COM1
IrqStub 5,  37  ; LPT2
IrqStub 6,  38  ; Floppy Disk
IrqStub 7,  39  ; LPT1
IrqStub 8,  40  ; CMOS Real Time Clock
IrqStub 9,  41  ; Free / ACPI
IrqStub 10, 42  ; Free / SCSI / NIC
IrqStub 11, 43  ; Free / SCSI / NIC
IrqStub 12, 44  ; PS2 Mouse
IrqStub 13, 45  ; FPU / Inter-processor
IrqStub 14, 46  ; Primary ATA Hard Disk
IrqStub 15, 47  ; Secondary ATA Hard Disk 


; Return to real code
section .text
global irq_common 
irq_common:
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
  CALL irq_handler 

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
  POP rax

  ; Before return to kernel. It does not like ISR Common.
  ; We need to advise the aPIC that the interruption is over 
  ; So, we pick the vector number in the stack to RDI 
  ; And call pic_controller_eoi passing in RDI the ORIGINAL vector number 
  ; The vector number is currently at [RSP] because we haven't popped it yet
  PUSH rdi                                    ; Save RDI before using it for EOI
  MOV rdi, [rsp + 8]                          ; Vector number (was pushed last in macro)
  SUB rdi, 32                                 ; Get original IRQ (0-15)

  CALL pic_controller_eoi                     ; Signal EOI

  POP rdi                                     ; Restore RDI
  ; Finally, discard vector and dummy error code
  ADD rsp, 16

  IRETQ                                       ; Back to to CPU (Restoring all CPU Core Registers)

