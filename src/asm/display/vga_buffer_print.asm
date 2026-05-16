; Output print in VGA Buffer 
; Receives *RDI as String, RSI as String's length
; *[uint8] RDI (str_ptr), uint16 RSI-16 (str_len)

BITS 64

; CONSTANTS
VGA_BFF equ 0xB8000                       ; VGA Memmory Address
VGA_COL equ 80                            ; 80 VGA Collums
VGA_LINE equ 32                           ; 32 VGA Lines

; Extern Functions 
extern vga_buffer_scroll_bellow
extern vga_controller_cursor_update

; Extern Data 
extern vga_saver_counter
extern vga_saver_offset
extern vga_saver_collum 
extern vga_saver_line

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
  PUSH rax                                ; Global Temporally Register
  PUSH rcx                                ; Global geral Counter 
  PUSH r8                                 ; Offset Counter
  PUSH r9                                 ; Collum Cursor
  PUSH r10                                ; Line Cursor
  PUSH r11                                ; Char Counter

  ; Feature to use C-String to print
  ; Basicly, if length (SI) igual 0, then put the max value (In 16-bit)
  ; Because, it only stops if reached in \0 byte interpolation (In C-Style)
  CALL .overflow_len                      

  ; This back cursor (Offset, counter, line and collum) to the last stage 
  ; In case of multiple calls of this function, it respect the the space of last print 
  ; If the first time, the variables (Picked from memory) is equal 0
  CALL .restore_cursor


  ; The magic is here
  ; Parser each char, put in your identation, intepolating breakpoints, scrolling the screen
  ; This function is a half ungly...
  CALL loop_string                           
  

  ; This function save all 4 ccursor registers for next call of this function 
  ; Inverted of .restore_cursor
  CALL .save_cursor

  ; Update the location of the cursor, were the the strings end
  CALL .update_cursor                   

  ; Finally, scrolls 1 time the screen to show the 33th line, normally, it's hidden
  ; But only if it reached in the final
  CMP r10, VGA_LINE 
  JGE .scroll

  JMP done
.overflow_len:
  ; Lets impelement a feature in string length (SI)
  ; If SI == 0, then we just stop when 0 byte appears (C Style)
  ; So, we overflow SI to the max number in 64-bit 
  ; Here, as SI is a 16-bit reg, we must use CX (Also 16-bit) from RCX
  XOR cx, cx                             ; Using RCX as temporally register, and zero it
  DEC cx                                 ; So, 0 - 1 = 184..... (Many Digits, it overflow!)
  
  ; Then, we use CMOVx to condicional move (Like Jx, but does not jump)
  ; If SI == 0, then MOV si, cx... (After, RCX is cleaned, because it is temporally)
  CMP si, 0 
  CMOVZ si, cx
  RET                                      ; Finnaly return
.restore_cursor:
  ; Restore all this registers from memory (Data Struct)
  ; Uses the 32-bit version of each register (ECX, R8D...)
  ; Because, in the memorry the variables is stored has 32-bits (To 64-bits registers)
  MOV ecx, dword [vga_saver_counter]      ; Restore RCX = Geral Counter
  MOV r8d, dword [vga_saver_offset]       ; Restore R8 = Offset
  MOV r9d, dword [vga_saver_collum]       ; Restore R9 = Collum Cursor
  MOV r10d, dword [vga_saver_line]        ; Restore R10 = Line Cursor
  
  RET
.save_cursor:
  ; Now, save the registers to the memory
  ; Save all (4 btw) registers used for controlling cursor 
  MOV dword [vga_saver_counter], ecx      ; Save RCX = Geral Counter
  MOV dword [vga_saver_offset], r8d       ; Save R8 = Offset
  MOV dword [vga_saver_collum], r9d       ; Save R9 = Collum Cursor
  MOV dword [vga_saver_line], r10d        ; Save R10 = Line Cursor .scroll:                                 

  RET
.update_cursor: 
  PUSH rdi                                ; Save registers, for don't dirty them 
  PUSH rsi 
  
  ; We need to change the X, Y of Visual Cursor with VGA Controller
  MOV rdi, r9                             ; The first argument is the counter
  MOV rsi, r10 
  CALL vga_controller_cursor_update

  POP rsi                                 ; Restore them, and return
  POP rdi 
  RET
.scroll:
  CALL vga_buffer_scroll_bellow           ; Scroll to down withou recovery
  JMP done



; String loopping
loop_string:
  ; AL = Bottom of AX, just 8-bits, same size of a string
  ; al = char
  MOV al, [rdi + r11]                     ; Point to the begin of string + each char (R11)

  ; Jumps to interpolate the string, to find breakpoints, like '\n'
  CALL inter_str                         


  ; Add the address, plus 2 bytes-cells of RCX, plus the offset
  SHL r8, 1                               ; Multiplies R8 by 2. Because, is not allowed to do that in []
  MOV byte [VGA_BFF + 2*rcx+r8],     al   ; MOV to the address 2-bytes-cells (word). The first is the character (AL)
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
  JB loop_string                          ; If bellow (Unsigned operation), continues the loop
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

  CMP r10, VGA_LINE-1                    ; If the line cursor is bellow of 32 lines
  JGE .else

  INC r10                                ; Increaes a line to Line Cursor (R10)
  RET
.else:
  SUB rcx, VGA_COL                       ; Else, Backs to the begin of line
  CALL vga_buffer_scroll_bellow          ; And Scrolls down
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
  DEC r9                                  ; For don't buggy in screen (Premature EOL)
  RET
.return: 
  RET
  
newline_offset:
  INC r11                                 ; Jumps to the next char, replacing the '\n'
  CALL .increase_reg                      ; Just increases r9 and rcx if the line is bellow of 32 lines

  MOV al, [rdi + r11]                     ; Jumps to the next char (Ignoring the \n)
  
  ; Inspect if it need to scroll the screen 
  CALL need_scroll                      
  XOR r9, r9                              ; Zeros the collum cursor, back in the begin of line

  ; We use recursion, when the next char is also '\n'
  ; If does not implemented this feature (And the next char be '\n'), so it would print the "Inavalid Code", and doesn't jump line
  CMP al, 0xA                             ; If the next char is '\n'...
  JE .recursion                           ; Uses recursion to show the next non '\n' char

  JMP newline_offset_continue             ; If not, continues the pipeline
.increase_reg:
  CMP r10, VGA_LINE-1
  JGE .return 

  ; If it jumps a line, then jumps the match zero-bits value (Jumps 32 spaces, then jumps 32 words (bytes * 2))
  INC rcx                                 ; Add in RCX to continue in normal flow 
  ADD r8, VGA_COL - 1                     ; Adds to R8, VGA collums minus 1
  SUB r8, r9                              ; Subtract the offset to the cursor
  RET
.recursion: 
  INC r10                                 ; Increases one line and jump to function (Loop)
  JMP newline_offset
.return:
  RET

newline_offset_continue:
  CMP r10, VGA_LINE-1
  JGE .return
  
  INC r10                                 ; Increase in line cursor
  RET                                     ; Return to the parser
.return: 
  RET

need_scroll:
  CMP r10, VGA_LINE-1                     ; Compare the Line Cursor to the VGA Lines
  JGE .else                               ; If its equal or greater, scroll down
  RET                                     ; Else return
.else:
  CALL vga_buffer_scroll_bellow           ; Uses external function to scrol the screen to down
  SUB rcx, r9                             ; Keep identation, don't copy of the precious item in the same line
  RET

done:
  POP r11
  POP r10 
  POP r9 
  POP r8
  POP rcx                                 
  POP rax                                 ; Restore the registers 

  RET                                     ; Returns to the main kernel
