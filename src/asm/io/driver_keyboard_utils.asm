; Multiple functions to build the Keyboard Driver
; -> driver_keyboard_get_code
; Return in RAX

BITS 64 

; CONSTANTS 
KEYBOARD_PORT equ 0x60


section .text
; Picks the code of keyboard IRQ
; Returns in RAX 
; => uint8 RAX (code)
global driver_keyboard_get_code 
driver_keyboard_get_code: 
  IN al, KEYBOARD_PORT                         ; Reads from CPU port and store in RAX
  RET
