; Output print in VGA Buffer 
; Receives *RDI as String, SI as String's length
; *[uint8] RDI (str_ptr), uint16 SI (str_len)

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
extern vga_absolute_chars

; Macros Here 
%macro DoubleReturn 0
  ; We want to return 2 times, so 'RET RET' does not work
  ; When we use CALL, the RIP is save in the Stack (Who is controlled by RSP)
  ; So, we can just discard that last CALL (Entry)
  ; Using 'POP register' or adding 8 in RSP (That's whats we do)
  ADD rsp, 8                              ; Discard last entry and return 
  RET 
%endmacro 
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
%macro Serial 2 
  extern com_serial_print
  PUSH rdi 
  PUSH rsi
  MOV rdi, %1
  MOV rsi, %2
  CALL com_serial_print
  POP rsi 
  POP rdi
%endmacro


section .text
; We use here, the 16-bit version of RSI (SI)
; Because security reasons (If the users pass 0 has length in an non C-string, it don't crash)
global vga_buffer_print
vga_buffer_print:
  PUSH rax                                ; Char byte
  PUSH rbx                                ; temporally register
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

  ; So, calls to write the byte (AL) in correct position with R8 and RCX
  CALL write_byte

  ; Revaluete the total chars in line, then move this value to memory variable 
  CALL search_byte 
  MOV byte [vga_absolute_chars], al      ; Use AL here (The max value is 80, which fits in a byte)

  INC rcx                                 ; Increases for Geral counter
  INC r11                                 ; Increases for Char Counter
  INC r9                                  ; Increases for Cursor

  ; Inspect if has overflowed the line, the jump to the next line without '\n' breakpoint
  CALL need_reset

  ; Inspect if the string is in the end, if it, then stop
  ; In this case, R11W is the 16-bit version of R11 (W for Word)
  CMP r11w, si                            ; Checks if R11W == String Length. String limit
  JB loop_string                          ; If bellow (Unsigned operation), continues the loop

  RET                                     ; Else, return to main function

write_byte:
  ; Add the address, plus 2 bytes-cells of RCX, plus the offset
  SHL r8, 1                               ; Multiplies R8 by 2. Because, is not allowed to do that in []
  MOV byte [VGA_BFF + 2*rcx+r8],     al   ; MOV to the address 2-bytes-cells (word). The first is the character (AL)
  MOV byte [VGA_BFF + 2*rcx+r8 + 1], 0xF  ; The second byte is the color. 15 = The default color.
  SHR r8, 1                               ; To return in the last state, divide by 2
  RET

read_byte: 
  ; Read the char count in RAX, and return his value in VGA Buffer also in RAX
  SHL r8, 1 
  MOV ax, word [VGA_BFF + 2*rax+r8]
  SHR r8, 1 
  RET

search_byte: 
  PUSH rdi 
  PUSH rcx
  ; Search for first 0-byte of the line, and return in RAX the char counter
  ; First, we use this formulae to evalute the begin of current line: VGA_BFF + r10 * VGA_COL
  ; We will use temporally RDI to evalute this result (RDI is an argument of SCASW)
  IMUL rdi, r10, VGA_COL
  ADD rdi, VGA_BFF 

  MOV rcx, VGA_COL                        ; Search for all characters in the line
  MOV ax, 0x0F00                          ; Search for zero byte with default color in a word (AX)

  ; Repeat while (RCX > 0 && ZF == 0), scaning single world 
  REPNE SCASW 
  ; After, we want the number of iterations. That's RCX - 1
  ; So, we move the VGA_COL (The maximum value) to RAX, then we SUBtract RAX to RCX and decrease 1 in RAX
  MOV rax, VGA_COL 
  SUB rax, rcx
  DEC rax                                 ; The result is VGA_COL - (RCX+1). This is the number of chars in line

  ; Recoverty the SCASx registers and return. The return value is in RAX
  POP rcx 
  POP rdi
  RET

trim_byte:
  ; Back N bytes to visual buffer in line. Where N is RAX 
  ; Before: "····Hello", After (RAX = 3): "·Hello"
  PUSH rdi                                ; First, save all registers 
  PUSH rsi 
  PUSH rcx 

  ; First, detect if there's any byte (And if has, how many) different to zero. Then put this value in RAX
  CALL .detect_zero_byte

  ; Loop to pull the chars in line RAX times 
  CALL .loop

  POP rcx                                 ; Restore each MOVSW/SCASW registers, then return
  POP rsi 
  POP rdi
  RET
.detect_zero_byte:
  ; 0x0F00 = Default color + 0 byte
  MOV ax, 0x0F00                          ; Which word we are searching
  MOV rcx, VGA_COL                        ; How many times we will repeat it

  ; The formulae is: RSI = R10 * VGA_COL + VGA_BFF 
  IMUL rdi, r10, VGA_COL                  ; The destiny of scan
  ADD rdi, VGA_BFF 

  ; This will stop after search the non-zero byte
  REPE SCASW                              ; While ZF = 1 and RCX > 0, compare [RDI] to AX, add 2 to RDI and decrease RCX

  ; We want now how many times we are looped. So, we use this formulae: RAX = VGA_COL - RCX - 1 
  MOV rax, VGA_COL                        
  SUB rax, rcx 
  DEC rax      

  ; If RAX is 79 (The max limit), so it will looped every byte and does not find any valid byte 
  ; So, we use non-determined value to atribute 0 in RAX if the old value was 79 
  MOV rbx, 0                              ; RBX to non-determined value 

  CMP rax, VGA_COL-1                       ; RAX == VGA_COL-1 (79)
  CMOVE rax, rbx                           ; If equal, then RAX = 0

  RET
.loop:
  CMP rax, 0                              ; If RAX = 0, the loop has over
  JZ .return 

  ; Now, we calculate the destiny address (Where line we want in VGA Buffer)
  ; The formulae is: RSI = R10 * VGA_COL + VGA_BFF 
  IMUL rdi, r10, VGA_COL 
  ADD rdi, VGA_BFF 

  ; So, the destiny is RSI - 2 (RSI minus 1 word)
  MOV rsi, rdi 
  ADD rsi, 2

  MOV rcx, VGA_COL                        ; This will repeat 80 times
  REP MOVSW                               ; So, move each word of RSI to RDI, 80 times

  DEC rax                                 ; Decrease RAX for continue the loop 
  JNZ .loop                               ; If not, then continues the loop
.return:
  RET

pull_byte:
  ; Pull the entire words in front (in line) in cursor position (VGA_COL * R10 + R9), RAX times
  ; Save registers
  PUSH rdi 
  PUSH rsi 
  PUSH rcx 
  
  ; RBX as temporally registers 
  MOV rbx, r9                             ; RBX = R9 * 2
  SHL rbx, 1

  ; Source position (Defaul postion + 2 words)
  IMUL rsi, r10, VGA_COL
  ADD rsi, rbx                            ; RSI = RBX = 2*R9 = Words until cursor
  ADD rsi, VGA_BFF
  ADD rsi, 2
  
  ; Destionaton is source - 1 word
  MOV rdi, rsi 
  SUB rdi, 2
  
  ; How many it we'll be executed (RAX)
  MOV rcx, rax 

  ; Then executed it
  REP MOVSW 

  ; Recovery registers
  POP rcx 
  POP rsi 
  POP rdi
  RET


need_reset:
  CMP r9, VGA_COL                         ; If is in the end of line (In 80th char), jump to reset_col
  JGE reset_col
  RET

reset_col:
  XOR r9, r9                              ; Zeros the Collum cursor, back in the line's begin

  MOV byte [vga_absolute_chars], 0       ; Also cleans the 'vga_absolute_chars', that representts all chars in current line

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
  ; Execute some functions that have in loop_string and it's nescessary
  ; Revaluete the total chars in line, then move this value to memory variable 
  PUSH rax 
    CALL search_byte 
    MOV byte [vga_absolute_chars], al      ; Use AL here (The max value is 80, which fits in a byte)
  POP rax

  ; Cursor breakpoints 
  ; NXT-CHAR                               
  CMP al, 0x6                             ; 0x6 = 6 = . -> Next Char 
  JE next_char                            ; If equal, move the the cursor to next char

  ; RET-CHAR
  CMP al, 0x7                             ; 0x7 = 7 = . -> Return char
  JE return_char                          ; If equal, move the cursor to previous char
  
  ; DLT-CHAR
  CMP al, 0x8                             ; 0x8 = 8 = \b -> Backspace
  JE delete_char                          ; If equal, delete the previous char

  ; ERS-CHAR                              
  CMP al, 0x9                             ; 0x9 = 9 = \d -> Delete 
  JE erase_char                           ; If equal, delte the next char


  ; NXT-LINE
  CMP al, 0xC                             ; 0xC = 12 = . -> Advance cursor 
  JE next_line                            ; If equal, move the cursor to end of line

  ; RET-LINE
  CMP al, 0xD                             ; 0xD = 13 = \r -> Return cursor
  JE return_line                          ; If equal, move the cursor to begin of line 

  ; DLT-LINE 
  CMP al, 0xE                             ; 0xE = 14 = . -> Clear Line 
  JE delete_line                          ; If equal, delete all line before cursor

  ; ERS-LINE 
  CMP al, 0xF                             ; 0xF = 15 = . -> Erase Line
  JE erase_line                           ; If equal, erase the all line after cursor

  ; Other breakpoints
  CMP al, 0xA                             ; 0xA = 10 = \n -> Newline
  JE newline_offset                       ; If equal, jump to offset

  CMP al, 0x0                             ; 0x0 = 0 = \0 -> End of String
  JE .double_return                       ; If equal, return to main function 

  RET                                     ; Else, continue the parser
.double_return:
  DoubleReturn

; Cursor breakpoints
next_char:
  ; Next char
  INC r11 
  MOV al, [rdi + r11]

  ; If the char is bellow of 32 (The breakpoints space), then use recursion to show the next valid char
  CMP al, 0x1F
  JLE .recursion 
  JG .else 
.return: 
  RET
.ghosty_bug:
  ; If both next char is 0 and our position are in limit, we decrease R9 and RCX and make a double return
  ; Because if we are in the end of line, and there's no char in linear string, what will we print in our place? 
  ; So, we just exit in this function, sending a double return with RSP manipulation

  ; If There's nothing more in linear string, 
  CMP al, 0 
  JNZ .return 

  ; And we are in end of line (Our cursor)
  CMP r9, VGA_COL-1
  JNZ .return 
  
  ; So decrease this registers 
  DEC r9 
  DEC rcx 

  ; And back to loop_string
  DoubleReturn
.recursion:
  ; Calls the main code, then jump to inter_str (Continues the loop)
  CALL .else
  JMP inter_str 
.else:
  ; So we compare the current char in line (Relative), with the total chars in line (Absolute)
  ; If we back one character, then R9 < vga_absolute_chars. Else, it's return without effect
  CMP r9b, byte [vga_absolute_chars]     ; We use R9B because it's 8-bits comparation (Register and Memory) 
  JGE .return                             ; Cancel the operation if R9 is equal (Or greater) than vga_absolute_chars

  ; Increases the Geral Counter and the Char Counter
  INC rcx 
  INC r9
  RET

return_char: 
  ; Next char
  INC r11 
  MOV al, [rdi + r11]

  ; A different Ghosty Bug Handler 
  CALL .ghosty_bug
  
  ; IF we are in the begin of line, stops
  CMP r9, 0
  JZ .return 

  ; If the char is bellow of 32 (The breakpoints space), then use recursion to show the next valid char
  CMP al, 0x1F
  JLE .recursion 
  JG .else 
.ghosty_bug:
  ; If both next char and our position are 0, we decrease R9 and RCX and make a double return
  ; Because if we are in the begin of line, and there's no char in linear string, what will we print in our place? 
  ; So, we just exit in this function, sending a double return with RSP manipulation

  ; If There's nothing more in linear string, 
  CMP al, 0 
  JNZ .return 

  ; And we are in begin of line (Our cursor)
  CMP r9, 0
  JNZ .return 
  
  ; So decrease this registers 
  DEC r9 
  DEC rcx 

  ; And back to loop_string
  DoubleReturn
.return: 
  RET
.recursion:
  ; Calls the main code, then jump to inter_str (Continues the loop)
  CALL .else
  JMP inter_str 
.else:
  ; Decrease the Geral Counter and the Char Counter
  DEC rcx 
  DEC r9
  RET

delete_char:
  INC r11                                 ; Jumps to the next char, replacing the '\b'
  MOV al, [rdi + r11]                     ; Jumps to the next char (Ignoring the \b)

  ; If in begging of line, jump to ghosty bug
  ; For Ghosty Delete char Bug, wer need to deacrease R9 if the enxt byte is 0
  CMP r9, 0
  JZ .ghosty_bug


  ; We compare the actual char with other breakpoints, if true, then inicializes an recursion, zering each \b byte in VGA Buffer 
  ; The breakpoints stops at 0x1F (31) in ASCII Table. So, if is a breakpoint (\r, \n...), it continues the loop
  CMP al, 0x1F
  JLE .recursion 
  JG .else 
.ghosty_bug: 
  ; The same bug as '\n', an ghosty character when has an 0 (Void) byte 
  ; Uses temporally RBX to move the non determined value
  MOV rbx, r9                             ; RBX = R9 - 1
  DEC rbx 

  CMP al, 0
  CMOVZ r9, rbx                           ; If AL == 0, then R9 = R9-1

  ; Same work for RCX
  MOV rbx, rcx                            ; RBX = RCX - 1
  DEC rbx 

  CMP al, 0
  CMOVZ rcx, rbx                          ; If AL == 0, then RCX = RCX-1
  RET
.recursion: 
  DEC rcx                                 ; So, backs 1 space in te memory, replacing the previous character 
  DEC r9                                  ; For don't buggy in screen (Premature EOL) 

  PUSH rax                                ; Saves the actually character
  MOV al, 0x0                             ; AL = Null Byte (Zero)
  CALL write_byte                         ; Writes byte directly in VGA Buffer 
  POP rax                                 ; Restore the char

  JMP inter_str                          ; Continues the Loop
.else:  
  DEC rcx                                 ; If the next byte is not \b, then just move the cursor (Erase the char) one time 
  DEC r9 
  RET                                     ; Then return to main function
.return: 
  RET
 
erase_char:
  ; Verify if the next VGA Buffer char is 0, if yes, then return
  MOV rax, r9                             ; Read Byte return the value to the given pos in line (In RAX)
  CALL read_byte 

  CMP al, 0                               ; If the value is 0, then exit
  JE .linear

  ; Overwrite RAX
  ; Next char
  INC r11 
  MOV al, [rdi + r11]

  ; If the next byte is a breakpoint, then uses recursion to show the next valid char
  CMP al, 0x1F
  JLE .recursion
  JG .else
.recursion:
  ; Executes the main code, then jump to inter_str (Continues the loop)
  CALL .else
  JMP inter_str 
.linear: 
  ; In linear string... we do nothing, just pass the char 
  INC r11 
  MOV al, [rdi + r11]

  CALL .ghosty_bug                        ; But if the next linear string character is 0, decrease R9 and RCX and back some chars in RAX
  RET                                     ; Just ignore all and return
.ghosty_bug: 
  ; Use RBX to non-determined value (RBX is R9 Decrease)
  MOV rbx, r9 
  DEC rbx 

  ; If the byte is 0, then R9 is RBX (R9 = R9 - 1)
  CMP al, 0 
  CMOVZ r9, rbx  

  ; Same work, but decreases RCX if nescessary
  MOV rbx, rcx 
  DEC rbx 

  CMP al, 0 
  CMOVZ rcx, rbx

  ; Now, if the next char (AL) is 0, we back one in linear string (The last valid character)
  MOVZX rbx, byte [rdi + r11 - 2]         ; We use movZX to convert 8-bits to 64-bits operants, CMOVZ just aceppt 16-bit or greater

  CMP al, 0 
  CMOVZ rax, rbx
  RET
.else:
  PUSH rax                                ; Save RAX, because we will use it 

  ; Calculate the chars in front od cursor 
  MOVZX rax, byte [vga_absolute_chars]    ; Use the value in vga_absolute_chars (Convert Byte in Quad)
  SUB rax, r9                             ; Subtract the total with the cursor 

  ; Using R9 to referencial, pull RAX bytes (Words actually) in line
  CALL pull_byte

  ; Restore and return
  POP rax 
  RET


next_line:
  ; Next char (Without this breakpoint)
  INC r11 
  MOV al, [rdi + r11]

  CMP al, 0x1F 
  JLE .recursion 
  JG .else 
.recursion:
  CALL .else 
  JMP inter_str 
.else:
  ; So, we calculate the rest of chares in line, that's vga_absolute_chars - R9 
  ; We use temporally RBX to evaluate the result of subtration 
  ; Use MOVZX to zero the higher part (And recursivily highers parts) of the quad byte (From unique byute) 
  MOVZX rbx, byte [vga_absolute_chars]
  SUB rbx, r9                            ; RBX = vga_absolute_chars - R9 = Rest chars in line 
  
  ADD r9, rbx                            ; So, R9 = R9 + (vga_absolute_chars - R9)
  ADD rcx, rbx                           ; And add to RCX the rest of chars in line

  RET                                    ; Then, return
.return: 
  RET

return_line:
  ; Back Cursor to the begin of line
  INC r11 
  MOV al, [rdi + r11]

  ; Compare the actual char with null. If it's, them jump to Ghosty Return Handler
  CMP al, 0
  JZ .ghosty_bug
  
  ; If the char is a breakpoint again, so uses recursion to find the nex valid byte
  ; The breakpoints stops at 0x1F (31) in ASCII Table. So, if is a breakpoint (\r, \n...), it continues the loop
  CMP al, 0x1F
  JLE .recursion
  JG .else
.ghosty_bug:
  ; Here, we calculate the memory addres of the target char it is
  LEA rbx, [rdi + r11]                    ; So, the target is: RDI + R11 - R9
  SUB rbx, r9
  
  MOV al, [rbx]                           ; AL = the destination of this memory address (In RBX) 

  ; So, we subtrate RCX by R9, and zeros R9 (Reset the line)
  SUB rcx, r9 
  XOR r9, r9 

  ; Them, we must ignoring the null byte (0), so we decrease each register
  DEC r9
  DEC rcx
  RET                                     ; Then return
.recursion:
  CALL .else
  JMP inter_str                        ; Backs to the interpolation string function
.else:
  ; If the next byte is not invalid (Zero byte or \r byte)
  ; Here, we subtract RCX by R9 (New chars will be placed at the begin of line)
  ; And zeros R9, so the cursor will show at the begin of line
  SUB rcx, r9 
  XOR r9, r9 
  RET 

delete_line: 
  ; Next char
  INC r11 
  MOV al, [rdi + r11]
  
  ; If in begin of line, don't continues the loop
  CMP r9, 0                               ; R9 = Char counter of the line
  JZ .return

  ; If the next byte is 0, then decrease to R9
  CALL .ghosty_bug
  
  ; If the next byte is a breakpoint, then uses recursion to show the next valid char
  CMP al, 0x1F
  JLE .recursion
  JG .else
.return: 
  RET
.ghosty_bug: 
  ; Use RBX to non-determined value (RBX is R9 Decrease)
  MOV rbx, r9 
  DEC rbx 

  ; If the byte is 0, then R9 is RBX (R9 = R9 - 1)
  CMP al, 0 
  CMOVZ r9, rbx  

  ; Same work, but decreases RCX if nescessary
  MOV rbx, rcx 
  DEC rbx 

  CMP al, 0 
  CMOVZ rcx, rbx
  RET
.recursion:
  ; Executes the main code, then jump to inter_str (Continues the loop)
  CALL .else
  JMP inter_str 
.else:
  ; Saves RAX, because we will use it in the loop
  PUSH rax

  ; Then, rolls the loop and wait for return
  CALL .decide_loop
  
  ; For last, writes the last byte in First char of line
  CALL write_byte
 
  ; If there's any 0 byte before an valid byte, then reajust and pull these 0 bytes
  CALL trim_byte

  ; If R9 = 0, then return without any effect (And restore the saved regissters)
  POP rax
  RET
.decide_loop:
  ; If the next char is null (0), then invert some operations 
  CMP al, 0
  JZ .loop_ghosty
  JNZ .loop
.loop_ghosty:
  ; We first CALL write_byte, so after decrease the registers
  ; MOVes AL (RAX) to 0 in a byte
  MOV al, 0x0
  
  ; So, writes 0 in new byte location (RCX - 1)
  CALL write_byte

  ; First, decrease R9 (By 1), it's the cursor location in line. This block infinity loop
  DEC r9 
  ; Then, decreases RCX, where the next byte will be placed (By write_byte)
  DEC rcx
  
  ; If R9 is 0, then over the loop, else, repeats
  CMP r9, 0
  JZ .return
  JNZ .loop_ghosty
.loop:
  ; We first decrease the registers, so after CALL write_byte
  ; MOVes AL (RAX) to 0 in a byte
  MOV al, 0x0

  ; First, decrease R9 (By 1), it's the cursor location in line. This block infinity loop
  DEC r9 
  ; Then, decreases RCX, where the next byte will be placed (By write_byte)
  DEC rcx

  ; So, writes 0 in new byte location (RCX - 1)
  CALL write_byte
  
  ; If R9 is 0, then over the loop, else, repeats
  CMP r9, 0
  JZ .return
  JNZ .loop

erase_line: 
  ; Check if we are in the begin in VGA BUffer 
  ; If true, so we just return 
  MOV rax, r9                             ; RAX = Cursor position 
  CALL read_byte

  CMP al, 0                               ; If the next value in buffer is null
  JE .linear                              ; Then we call the linear string function

  ; Overwrite RAX 
  ; Next Char 
  INC r11
  MOV al, [rdi + r11]

  ; Detect if the next char is a breakpoint 
  CMP al, 0x1F 
  JE .recursion 
  JNE .else 
.linear: 
  ; Next char
  INC r11 
  MOV al, [rdi + r11]

  CALL .ghosty_bug                        ; But if the next linear string character is 0, decrease R9 and RCX and back some chars in RAX
  RET                                     ; Just ignore all and return
.ghosty_bug: 
  ; Use RBX to non-determined value (RBX is R9 Decrease)
  MOV rbx, r9 
  DEC rbx 

  ; If the byte is 0, then R9 is RBX (R9 = R9 - 1)
  CMP al, 0 
  CMOVZ r9, rbx  

  ; Same work, but decreases RCX if nescessary
  MOV rbx, rcx 
  DEC rbx 

  CMP al, 0 
  CMOVZ rcx, rbx

  ; Now, if the next char (AL) is 0, we back one in linear string (The last valid character)
  MOVZX rbx, byte [rdi + r11 - 2]         ; We use movZX to convert 8-bits to 64-bits operants, CMOVZ just aceppt 16-bit or greater

  CMP al, 0 
  CMOVZ rax, rbx
  RET
.recursion:
  CALL .else 
  JMP inter_str 
.else:
  ; Save all STOcc Registers
  PUSH rax 
  PUSH rdi 
  PUSH rcx 

  ; Total of characters to be nullified (Total chars - current cursor)
  MOVZX rcx, byte [vga_absolute_chars]
  SUB rcx, r9 

  ; RBX as temporally register 
  MOV rbx, r9 
  SHL rbx, 1                              ; RBX = 2*R9

  ; Current possition in VGA Buffer
  IMUL rdi, r10, VGA_COL 
  ADD rdi, rbx                            ; RDI = RBX = 2*R9 = Total words until cursor
  ADD rdi, VGA_BFF
  
  ; Zero value with default color to STOre
  MOV ax, 0x0F00
  
  REP STOSW                               ; Start store zero value in RDI, until RCX > 0

  ; Restore the registers and return 
  POP rcx 
  POP rdi 
  POP rax  

  ; Now, if the next char is 0 in linear string, we have to decrease some registers (R9, RCX and Zeroes AL) 
  CMP r9, 0 
  JNZ .erase_bug 

  RET                                     ; Return
.erase_bug:
  ; If the next byte is null, so modify some registers
  ; Return the char 0 (For clean the current char in cursor), and decreases R9 for the erased char
  MOV al, 0
  DEC r9

  RET 


; Normal breakpoints
newline_offset:
  INC r11                                 ; Jumps to the next char, replacing the '\n'
  CALL .increase_reg                      ; Just increases r9 and rcx if the line is bellow of 32 lines

  MOV al, [rdi + r11]                     ; Jumps to the next char (Ignoring the \n)

  ; We zeros 'vga_absolute_chars', because we are starting in a new line 
  MOV byte [vga_absolute_chars], 0

  ; Inspect if it need to scroll the screen 
  CALL need_scroll                      
  XOR r9, r9                                ; Zeros the collum cursor, back in the begin of line

  ; CALL .ghosty_bug                        ; Checks if the ghosty newline bug has going

  ; We use recursion, when the next char is like a '\n' or '\b'
  ; If does not implemented this feature (And the next char be '\n'), so it would print the "Inavalid Code", and doesn't jump line
  ; The breakpoints stops at 0x1F (31) in ASCII Table. So, if is a breakpoint (\r, \n...), it continues the loop
  CMP al, 0x1F                             ; If the next char is '\n'...
  JLE .recursion                           ; Uses recursion to show the next non '\n' char
  JG .else                                 ; If not, continues the pipeline
.ghosty_bug: 
  ; Use temporally RBX, for move the non determined value (temporally)
  ; The value is RCX - 1 
  MOV rbx, rcx 
  DEC rbx
  ; If the next byte is void, deacreses one of RCX. It's a bug, that it put a space rather than ignoring it 
  ; So later, i think a better solution for this. But for while, is it
  ; I named this bug as Ghosty Newline. The pupose i've used RBX is indicates that bugs appeared
  CMP al, 0                               ; If the next byte is zero, 
  CMOVZ rcx, rbx                          ; The RCX is equal RBX (RCX - 1). So, decreases RCX if the next byte is zero 

  ; For a bug, we overflow R9 (Now, R9 is zero)
  ; So, in the next use, it increment one, resulting in absolute zero 
  ; It's nescessary, because R9 thinks RCX is in the old value (RCX + 1), adding 1 more in X in cursor

  ; Same work, mov the undertermined value to RBX, then RBX to R9 
  MOV rbx, r9 
  DEC rbx

  CMP al, 0  
  CMOVZ r9, rbx

  RET
.increase_reg:
  CMP r10, VGA_LINE-1
  JGE .return 

  ; If it jumps a line, then jumps the match zero-bits value (Jumps 32 spaces, then jumps 32 words (bytes * 2))
  INC rcx                                 ; Add in RCX to continue in normal flow 
  ADD r8, VGA_COL - 1                     ; Adds to R8, VGA collums minus 1
  SUB r8, r9                              ; Subtract the offset to the cursor
  RET
.recursion:
  CALL .else                              ; Increases one line and jump to function (Loop)
  JMP inter_str 
.else:
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
  POP rbx
  POP rax                                 ; Restore the registers 

  RET                                     ; Returns to the main kernel
