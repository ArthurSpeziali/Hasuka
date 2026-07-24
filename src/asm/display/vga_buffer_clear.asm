; Clean the the entire screen in VGA Buffer and his history 
; no input no output 

BITS 64 

; CONSTANTS
VGA_BFF equ 0xB8000                            ; VGA Memmory Address
VGA_COL equ 80                                 ; 80 VGA Collums
VGA_LINE equ 25                                ; 25 VGA Lines

; Extern Data 
; I don't think import VGA History is nescessary 
; Because, only zeros the entries is enought to resolve the task
extern vga_entries_up
extern vga_entries_down

; Macros Here 
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


; Real code
section .text
global vga_buffer_clear 
vga_buffer_clear:
  PUSH rax
  PUSH rcx 
  PUSH rdi  
  PUSH r8
  
  ; First, we clear the entire Vga Buffer Memory Space 
  MOV r8, VGA_LINE                             ; R8 is the line counter
  ; Then we define the destin (It's the VGA Space)
  MOV rdi, VGA_BFF                             
  
  CALL clear_vgabuffer                         ; Cleans the VGA Buffer Screen 
  CALL clear_history                           ; Cleans the Vga History & Entries
  
  JMP done                                     ; Then restore the registers and return to kernel

clear_vgabuffer: 
  ; Now, we use STOSB to zero each byte in Vga Space
  MOV rcx, VGA_COL                             ; We set RCX to Char Counter 
  ; Here, we write the char (00), and the color (0F) in a word 
  ; But, how we are 'breaking' a register to put in memmory, it has now endianness (Little endiannes) 
  ; So we write the less significant byte first. First the color, after the characther
  MOV ax, 0x0F00                               ; RAX (AX for 16-bit) is zero with black BG and white FG

  ; Repeat while RCX > 0, move AX to RDI
  REP STOSW
  
  DEC r8                                       ; Take 1 from R8 to continues the line-loop
  CMP r8, 0                                    ; If R8 > 0,
  JG clear_vgabuffer                           ; Repeat all 

  RET                                          ; If the loops over, back to main function

clear_history: 
  ; I'm pensative if it's so nescessary clear the real history data
  ; Because if clear only the entries, the history can't be acessed, but the content is here 
  ; For now, i only clear the entries, and new content will overlay the old (cleared) content
  MOV byte [vga_entries_up], 0
  MOV byte [vga_entries_down], 0

  ; In the future (Maybe), i zero the history
  ; But for now, i only return 
  RET


done:
  POP r8
  POP rdi 
  POP rcx
  POP rax

  RET
