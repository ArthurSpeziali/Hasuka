; IRQ Systrem for Hardware Interrupts on CPU. The Last 224 Interruptions in 256
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
        push qword 0        ; Dummy error code
        push qword %2       ; Número da interrupção (vetor IDT)
        jmp irq_common      ; Vai para o tratador comum
%endmacro

; -----------------------------------------------------------------------------
; Definição das 16 IRQs (Mapeadas de 32 a 47)
; -----------------------------------------------------------------------------
IRQ_STUB 0,  32  ; Timer
IRQ_STUB 1,  33  ; Keyboard
IRQ_STUB 2,  34  ; Cascade (PIC2)
IRQ_STUB 3,  35  ; COM2
IRQ_STUB 4,  36  ; COM1
IRQ_STUB 5,  37  ; LPT2
IRQ_STUB 6,  38  ; Floppy Disk
IRQ_STUB 7,  39  ; LPT1
IRQ_STUB 8,  40  ; CMOS Real Time Clock
IRQ_STUB 9,  41  ; Free / ACPI
IRQ_STUB 10, 42  ; Free / SCSI / NIC
IRQ_STUB 11, 43  ; Free / SCSI / NIC
IRQ_STUB 12, 44  ; PS2 Mouse
IRQ_STUB 13, 45  ; FPU / Inter-processor
IRQ_STUB 14, 46  ; Primary ATA Hard Disk
IRQ_STUB 15, 47  ; Secondary ATA Hard Disk
