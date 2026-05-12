; Reprograming the aPIC to dont overlay the IRQ to ISR (0-32)
; Uses RDI
; -> pic_controller_disable &

BITS 64

; CONSTANTS
; There's two main chips in aPIC, the Slave and the Master
; Both with Data and Commmand port
MASTER_COMMAND equ 0x20
MASTER_DATA equ 0x21 
SLAVE_COMMAND equ 0xA0 
SLAVE_DATA equ 0xA1
; ICW = Inicializition Commands Words
; ICW is for PIC 8086 rules
; Has 4 words (Inicializition, Vetor, Flags, Slave?)
ICW_1         equ 0x11                         ; Inicializition Variable
ICW_2_MASTER  equ 0x20                         ; IDT Vetor for Master and Slave  
ICW_2_SLAVE   equ 0x28 
ICW_3_MASTER  equ 0x4                          ; The ID of pin Master to Slave (0 if has no SLave pin)
ICW_3_SLAVE   equ 0x2                           
ICW_4         equ 0x1                          ; Flags config. In this case, we just need the first bit
; Finnaly, this constant indicates the end of interrupt (EOI)
PIC_EOI equ 0x20


section .text
; Disable the classic PIC 8086 chip
global pic_controller_disable
pic_controller_disable: 
  PUSH rax 

  MOV al, ICW_1                                ; Inicializition for now
  OUT MASTER_COMMAND, al                       ; We use the COMMAND, not DATA
  OUT SLAVE_COMMAND, al

  MOV al, ICW_2_MASTER                         ; Catch vetors from IDT
  OUT MASTER_DATA, al
  MOV al, ICW_2_SLAVE 
  OUT SLAVE_DATA, al

  MOV al, ICW_3_MASTER                         ; Register the slaves pins to respective master pins
  OUT MASTER_DATA, al 
  MOV al, ICW_3_SLAVE 
  OUT SLAVE_DATA, al

  MOV al, ICW_4                                ; Bit Flags: 0b1000000. We just use the first bit
  OUT MASTER_DATA, al                          ; It's show to aPIC that we use now the PIC 8086
  OUT SLAVE_DATA, al

  MOV al, 0x00                                 ; This is a mask (0 = enabled), enabling all IRQs
  OUT MASTER_DATA, al 
  OUT SLAVE_DATA, al 


  POP rax
  RET                                          ; Then return


; Sends to PIC that the interrupt has over 
; Receives RDI as the original vector number of the IRQ 
; uint8 RDI (original_vector)
global pic_controller_eoi 
pic_controller_eoi: 
  MOV al, PIC_EOI                              ; Move to AL the EOI code (To use in Slave/Master pin)

  CMP rdi, 8                                   ; If vector is lesser than 8 
  JL .master_only                              ; Only calls Master PIN
  JGE .slave_master                            ; If greater, then calls first the Slave, then the Master
.master_only: 
  OUT MASTER_COMMAND, al 
  RET                                          ; In the final, return in the two ways
.slave_master: 
  OUT SLAVE_COMMAND, al 
  JMP .master_only

