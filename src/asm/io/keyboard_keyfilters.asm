; A lot of KeyFilters redirecting 
; keyboard_keyfilter_vga
; Receives ASCII Code and if was Released in DI
; uint8 DIL (ascii_code) | bool DIH (released)

BITS 64 

; Extern functions 
extern vga_buffer_print

; BSS Variables
section .bss
  buffer8 resb 1                            ; Temporally buffer of 8-bits

; Macros Here
%macro DebugAny 1 
  PUSH rax 
  MOVZX rax, %1 
  Debug rax 
  POP rax
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



; Basic Key Filter, pick the key, and if valid, print in VGA Buffer
; DIL has the ASCII code, and "DIH" (Not exists) has if it was released
section .text
global keyboard_keyfilter_vga 
keyboard_keyfilter_vga:
  ; Save RSI because we will use it 
  PUSH rsi

  ; SIL will be the "DIH" register, containing the High part of DX (If released? field)
  MOV si, di                                   ; Copy DI to SI (Bot high part and low part)
  SHR si, 8                                    ; SHift to Right SI in 8 bits, to remove the low part and switch by the high part (SIL -> "SIH")

  ; Now, we handle this 2 registers (fields)
  ; If ACII is zero, dont print
  CMP dil, 0
  JE .return 
  
  ; If the key was released, dont print
  CMP sil, 1 
  JE .return

  ; Now, we configure the vga_buffer_print params (RDI, SI)
  ; To SI, we put value 1 for string length (1 char only)
  MOV rsi, 1                                   ; RSI to zero extension, but it receives as SI

  ; So, we put the value em DIL in a BSS variable in RAM, the real char
  MOV byte [buffer8], dil
  MOV rdi, buffer8                             ; RDI points to buffer8 address
  
  ; Finally, we call vga_buffer_print with the params, and return 
  CALL vga_buffer_print

  POP rsi 
  RET
.return: 
  POP rsi
  RET
