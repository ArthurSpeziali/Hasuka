; Global Variables here 

; CONSTANTS
VGA_COL equ 80

; BSS Variables
; VGA Buffer
global vga_history_up 
global vga_history_down
section .bss
  vga_history_up resw 255*VGA_COL       ; Reserve 255 Lines (80 chars in each, 2 bytes per char)
  vga_history_down resw 255*VGA_COL     ; Total: 510 Lines, 255 Up + 255 Down

; Integer Variables 
; VGA Buffer
global vga_entries_up 
global vga_entries_down
section .data
  ; align 8
  vga_entries_up db 0                   ; 1 Byte = 256 numbers
  ; align 8
  vga_entries_down db 0


