; Global Variables here 

; CONSTANTS
VGA_COL equ 80

; Memory Space
; VGA Buffer History
global vga_history_up 
global vga_history_down
; Shared String Word
global shared_string_word
section .bss
  ; VGA History
  vga_history_up resw 255*VGA_COL       ; Reserve 255 Lines (80 chars in each, 2 bytes per char)
  vga_history_down resw 255*VGA_COL     ; Total: 510 Lines, 255 Up + 255 Down
  ; Shared String 
  shared_string_word resb 0xFFFF        ; Reserve an string of 1 Word (2 Bytes) of chars (65KiB)


; Integer Variables 
; VGA Buffer History 
global vga_entries_up 
global vga_entries_down
; VGA Cursor 
global vga_saver_counter
global vga_saver_offset 
global vga_saver_collum 
global vga_saver_line
section .data
  ; VGA History
  vga_entries_up db 0                   ; 1 Byte = 256 numbers
  vga_entries_down db 0

  ; VGA Cursor
  ; All saved character are 32-bits
  vga_saver_counter dd 0                ; RCX 
  vga_saver_offset dd 0                 ; R8
  vga_saver_collum dd 0                 ; R9
  vga_saver_line dd 0                   ; R10


