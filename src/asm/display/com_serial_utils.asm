; Utils for using the COM port (OUT and IN)
; no input no output
; -> com_serial_init & com_serial_wait

BITS 64

; Constants
COM_BASE       equ 0x3F8     ; Port Address
COM_IER        equ 0x3F9     ; Interrupt Enable Register Flag
COM_FIFO       equ 0x3FA     ; Interrupt ID / FIFO Control
COM_LCR        equ 0x3FB     ; Line Control Register 
COM_MCR        equ 0x3FC     ; Modem Control Register
COM_LSR        equ 0x3FD     ; Line Status Register 
COM_MSR        equ 0x3FE     ; Modem Status Register


global com_serial_init
com_serial_init:
  PUSH rax                     ; Saves RDX and RAX
  PUSH rdx

  ; Port Address memory = 16 Bits 
  ; Value = 8 Bits
  MOV dx, COM_IER              ; Port memmory to interuptions
  XOR al, al                   ; Zeros AL and put in port memory
  OUT dx, al                   ; OUT = Write in Port memmory, that value

  MOV dx, COM_LCR              ; LSR = Baund Rate, speed of connection
  MOV al, 1 << 7               ; We need to enable the 7º bit flag (DLAB)

  ; Baund Rate Divisor. Max divisor equal 1
  ; Because, the rule is: 155220 / divisor = we want 
  ; So, 155200 / 155200 = 1 
  ; The high port is COM_IER, the low is COM_BASE (8+8=12)
  MOV dx, COM_BASE 
  MOV al, 1                    ; Just one in low part 
  OUT dx, al

  MOV dx, COM_IER 
  MOV al, 0                    ; High part is just 0, because 1 dont overflow 8-bits
  OUT dx, al
  
  MOV dx, COM_LCR
  MOV al, 0b11                 ; Enable the 2 last bit-flags = Activate 8 bits of data
  OUT dx, al

  MOV dx, COM_FIFO             
  MOV al, 0b11000111           ; Enable these bit-flags:
                               ; 1º - Enable the FIFO 
                               ; 2º - Clean receive buffer
                               ; 3º - Clean send buffer 
                               ; 7, 8º - Enable 14-bits trigger
  OUT dx, al

  ; Enable RTS, DTR and OUT2
  ; Request to sendy, I'm ready, Enable interrupts
  MOV dx, COM_MCR
  MOV al, 0b1011                ; 1º RTS, 2º DTR, 4º OUT2
  OUT dx, al

  JMP done

global com_serial_wait
com_serial_wait:
  PUSH rdx                     ; Saves RDX and RAX 
  PUSH rax                   

  MOV dx, COM_LSR              ; Wait for byte is void
  JMP .loop

.loop:
  IN al, dx                    ; Reads the value in DX port, and register in AL
  ; TEST is a AND operator, but dont store the result, just update the flag ZF if the result is 0
  TEST al, 0x20                ; Use a mask. 0x20 = 6º bit enable. Then, verify if 6 ] bit is enable 
  JZ .loop                     ; If the 6º bit is 0, the buffer is busy, then repeat the loop until it going void 
  JNZ done

done:
  POP rax                      ; Restore RDX and RAX 
  POP rdx                     
  RET                          ; Return to main kernel

