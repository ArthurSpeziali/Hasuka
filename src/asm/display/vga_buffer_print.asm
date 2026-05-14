; Output print in VGA Buffer 
; Receives *RDI as String (String to print), RSI as Int (Length of String)
; *str RDI (str_ptr), uint64 RSI-16 (str_len)

BITS 64

; CONSTANTS
VGA_BFF equ 0xB8000                       ; VGA Memmory Address
VGA_COL equ 80                            ; 80 VGA Collums
VGA_LINE equ 32                           ; 32 VGA Lines

; Extern Functions 
extern vga_buffer_scroll_bellow


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



section .text
; We use here, the 16-bit version of RSI (SI)
; Because security reasons (If the users pass 0 has length in an non C-string, it don't crash)
global vga_buffer_print
vga_buffer_print:
  PUSH rcx                     
  PUSH r8 
  PUSH r9
  PUSH r10 
  PUSH r11

  ; Lets impelement a feature in string length (SI)
  ; If SI == 0, then we just stop when 0 byte appears (C Style)
  ; So, we overflow SI to the max number in 64-bit 
  ; Here, as SI is a 16-bit reg, we must use CX (Also 16-bit) from RCX
  ; XOR cx, cx                             ; Using RCX as temporally register, and zero it
  ; DEC cx                                 ; So, 0 - 1 = 184..... (Many Digits, it overflow!)
  MOV cx, 0xFF
  
  ; Then, we use CMOVx to condicional move (Like Jx, but does not jump)
  ; If SI == 0, then MOV si, cx... (After, RCX is cleaned, because it is temporally)
  CMP si, 0 
  CMOVE si, cx
 
  XOR rcx, rcx                            ; Zero RCX = Geral Counter
  XOR r11, r11                            ; Zero R11 = Char counter
  XOR r8, r8                              ; Zero R8 = Offset
  XOR r9, r9                              ; Zero R9 = Collum Cursor
  XOR r10, r10                            ; Zero R10 = Line Cursor

  ; The magic is here
  CALL loop_str                           ; Parser each char, put in your identation, intepolating breakpoints, scrolling the screen
  
  ; Finally, scrolls 1 time the screen to show the 33th line, normally, it's hidden
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
  ; In this case, R11W is the 16-bit version of R11 (W for Word)
  CMP r11w, si                            ; Checks if R11W == String Length. String limit
  JB loop_str                             ; If bellow (Unsigned operation), continues the loop
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

  CMP r10, VGA_LINE                       ; If the line cursor is bellow of 32 lines
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

  CMP al, 0x8                             ; 0x8 = 8 = \b -> Backspace
  JE delete_char                          ; If equal, jump to delete

  CMP al, 0x0                             ; 0x0 = 0 = \0 -> End of String
  JE .double_return                       ; If equal, return to main function 

  RET                                     ; Else, continue the parser
.double_return: 
  ; We want to return 2 times, so 'RET RET' does not work
  ; When we use CALL, the RIP is save in the Stack (Who is controlled by RSP)
  ; So, we can just discard that last CALL (Entry)
  ; Using 'POP register' or adding 8 in RSP (That's whats we do)
  ADD rsp, 8                              ; Discard last entry and return 
  RET


delete_char:
  INC r11                                 ; Jumps to the next char, replacing the '\n'
  MOV al, [rdi + r11]                     ; Jumps to the next char (Ignoring the \n)

  DEC rcx                                 ; So, backs 1 space in te memory, replacing the previous character 
  RET
.increase_reg:
  CMP r10, VGA_LINE 
  JGE .return 

  ; If it jumps a line, then jumps the match zero-bits value (Jumps 32 spaces, then jumps 32 words (bytes * 2))
  INC rcx                                 ; Add in RCX to continue in normal flow
  ADD r8, VGA_COL - 1                     ; Adds to R8, VGA collums minus 1
  SUB r8, r9                              ; Subtract the offset to the cursor
  RET
.return: 
  RET
  



newline_offset:
  INC r11                                 ; Jumps to the next char, replacing the '\n'
  CALL .increase_reg                      ; Just increases r8 and rcx if the line is bellow of 32 lines

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

  ; If it jumps a line, then jumps the match zero-bits value (Jumps 32 spaces, then jumps 32 words (bytes * 2))
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

  RET                                     ; Returns to the main kernel
