; Output write in VGA Buffer 
; Receives *RDI as String (String to print), RSI as Int (Length of String)
; *str RDI (str_ptr), uint64 RSI (str_len)

BITS 64

; CONSTANTS
VGA_BFF equ 0xB8000                       ; VGA Memmory Address
VGA_COL equ 80                            ; 80 VGA Collums
VGA_LINE equ 25                           ; 25 VGA Lines

; Extern Functions 
extern vga_buffer_scroll_bellow

section .text
global vga_buffer_write
vga_buffer_write:
  PUSH rax                                ; Save the non-arguments registerns who i used
  PUSH rcx                     
  PUSH r8 
  PUSH r9
  PUSH r10 
  PUSH r11

  XOR rcx, rcx                            ; Zero RCX = Geral Counter
  XOR r11, r11                            ; Zero R11 = Char counter
  XOR r8, r8                              ; Zero R8 = Offset
  XOR r9, r9                              ; Zero R9 = Collum Cursor
  XOR r10, r10                            ; Zero R10 = Line Cursor

  ; The magic is here
  CALL loop_str                           ; Parser each char, put in your identation, intepolating breakpoints, and scrolling the screen
  
  ; Finally, scrolls 1 time the screen to show the 26th line, normally, it's hidden
  ; But only if it reached in the final
  CMP r10, VGA_LINE 
  JGE .scroll

  JMP done
.scroll:
  CALL vga_buffer_scroll_bellow
  JMP done

loop_str:
  ; AL = Bottom of AX, just 8-bits, same size of a string
  ; al = char
  MOV al, [rdi + r11]                     ; Point to the begin of string + each char (R11)

  ; Jumps to interpolate the string, to find breakpoints, like '\n'
  CALL inter_str                         

  ; Add the address, plus 2 bytes-cells of RCX, plus the offset
  SHL r8, 1                               ; Multiplies R8 by 2. Because, is not allowed to do that in []
  MOV byte [VGA_BFF + 2*rcx+r8],     al   ; MOV to the address 2-bytes-cells (word). The fist is the character (AL)
  MOV byte [VGA_BFF + 2*rcx+r8 + 1], 0xF  ; The second byte is the color. 15 = The default color.
  SHR r8, 1                               ; To return in the last state, divide by 2

  INC rcx                                 ; Increases for Geral counter
  INC r11                                 ; Increases for Char counter
  INC r9                                  ; Increases for Cursor

  ; Inspect if has overflowed the line, the jump to the next line without '\n' breakpoint
  CALL need_reset

  ; Inspect if the string is in the end, if it, then stop
  CMP r11, rsi                            ; Checks if RCX == String Length. String limit
  JL loop_str                             ; If less, repeat the loop
  RET                                     ; Else, return to main function

need_reset:
  CMP r9, VGA_COL                         ; If is in the end of line (In 80th char), jump to reset_col
  JGE reset_col
  RET

reset_col:
  XOR r9, r9                              ; Zeros the Collum cursor, back in the line's begin

  ; Show that we jumped one line with a friendly character '^' (94 in Ascii)
  DEC r11                                ; Goes back one character
  MOV byte [rdi + r11], 94               ; Write in region of memory where the next label will execute to find the next char (AL)

  CMP r10, VGA_LINE                       ; If the line cursor is bellow of 25 lines
  JGE .else

  INC r10                                 ; Increaes a line to Line Cursor (R10)
  RET
.else:
  SUB rcx, VGA_COL                        ; Else, Backs to the begin of line
  CALL vga_buffer_scroll_bellow             ; And Scrolls down
  RET

inter_str:
  CMP al, 0xA                             ; 0xA = 10 = \n -> Newline
  JE newline_offset                       ; If equal, jump to offset
  RET                                     ; Else, continue the parser

newline_offset:
  INC r11                                 ; Jumps to the next char, replacing the '\n'
  CALL .increase_reg                      ; Just increases r8 and rcx if the line is bellow of 25 lines

  MOV al, [rdi + r11]                     ; Jumps to the next char (Ignoring the \n)
  
  ; Inspect if it need to scroll the screen 
  CALL need_scroll                      
  XOR r9, r9                              ; Zeros the collum cursor, back in the begin of line

  CMP r10, VGA_LINE 
  JGE .return
  
  INC r10                                 ; Increase in line cursor
  RET                                     ; Return to the parser
.increase_reg:
  CMP r10, VGA_LINE 
  JGE .return 

  ; If it jumps a line, then jumps the match zero-bits value (Jumps 25 spaces, then jumps 25 words (bytes * 2))
  INC rcx                                 ; Add in RCX to continue in normal flow
  ADD r8, VGA_COL - 1                     ; Adds to R8, VGA collums minus 1
  SUB r8, r9                              ; Subtract the offset to the cursor
  RET
.return: 
  RET

need_scroll:
  CMP r10, VGA_LINE                       ; Compare the Line Cursor to the VGA Lines
  JGE .else                               ; If its equal or greater, scroll down
  RET                                     ; Else return
.else:
  CALL vga_buffer_scroll_bellow             ; Uses external function to scrol the screen to down
  SUB rcx, r9                             ; Keep identation, don't copy of the precious item in the same line
  RET

done:
  POP r11
  POP r10 
  POP r9 
  POP r8
  POP rcx                                 ; Restore the registers 
  POP rax

  RET                                     ; Returns to the main kernel
