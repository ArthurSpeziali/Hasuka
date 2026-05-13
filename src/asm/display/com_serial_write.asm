; Output print in COM Serial
; Receives *RDI as String (String to print), RSI as Int (Length of String)
; *str RDI (str_ptr), uint64 RSI (str_len)

BITS 64

; CONSTANTS
COM_BASE       equ 0x3F8             ; Port Address

global com_serial_print
com_serial_print:
  PUSH rax                           ; Store the registers non used
  PUSH rcx 
  PUSH rdx      

  XOR rcx, rcx                       ; Zeros RCX
  JMP loop_str 

loop_str: 
  MOV al, [rdi+rcx]                  ; Store the char in AL
  MOV dx, COM_BASE                   ; Mov dx (16-bit) to the port addres to print
  OUT dx, al                         ; Write in serial the char

  INC rcx                            ; Next char
  JMP compare                        ; Compare if reachs in the end of string

compare: 
  CMP rcx, rsi

  JGE done
  JNE loop_str

done:
  MOV al, 10                         ; Print '\n' (10 in ascii) in the final to mark the end of line 
  OUT dx, al

  POP rdx                            ; Restore the non used registers 
  POP rcx 
  POP rax

  RET                               ; Return to main Kernel
