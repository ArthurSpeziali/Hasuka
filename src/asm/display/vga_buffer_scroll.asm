; Scrolls VGA Buffer
; No Input, no Output
BITS 64

; Macros Here
%macro Serial 2
  PUSH rdi 
  PUSH rsi 

  MOV rdi, %1 
  MOV rsi, %2 
  CALL com_serial_write

  POP rsi 
  POP rdi
%endmacro
%macro SerialDebug 1
  PUSH rax
  PUSH rdx
  PUSH rdi 
  PUSH rsi 

  MOV rdi, %1
  CALL debug_hex
  MOV rdi, rax 
  MOV rsi, rdx 
  CALL com_serial_write

  POP rsi 
  POP rdi
  POP rdx
  POP rax
%endmacro

section .rodata
  teste db "Hello w!"

; CONSTANTS 
VGA_BFF equ 0xB8000                                  ; Memory address to write in VGA Buffer
VGA_BFF_FINAL equ VGA_BFF + (VGA_LINE-1)* VGA_COL*2  ; Result is the total bytes to the begin of 25º Line
VGA_COL equ 80                                       ; 80 Colluns and 25 lines
VGA_LINE equ 25                 
VGA_HISTORY_LIMIT equ 255


; Extern functions
extern debug_hex
extern com_serial_write

; Extern Variables 
extern vga_history_up
extern vga_history_down
extern vga_entries_up
extern vga_entries_down


section .text
; Go to down without recovery in the history, only saves
global vga_buffer_scroll_bellow
vga_buffer_scroll_bellow:
  PUSH rax                            ; Save all registers non used
  PUSH rcx 
  PUSH rdi 
  PUSH rsi
  PUSH r8

  MOV rax, VGA_BFF                    ; Move RAX to the begin of VGA Buffer Address 
  XOR rcx, rcx                        ; Zeros RCX as collums counter
  XOR r8, r8                          ; Zeros R8 as lines counter 


  CALL .add_line                      ; Calls to add the line in history
  CALL .move_line_loop                ; Calls to move up every line in the grid
  CALL .dump_line                     ; Clean the 26º line for avoid visual bugs and repeat infinitly this line for up

  ; SerialDebug [vga_history_up]
  ; SerialDebug [vga_entries_up]
  ; The history limit to the up-lines is 255, then, we need to delete de first register, and realocater the array
  MOV rax, [vga_entries_up]
  CMP rax, VGA_HISTORY_LIMIT          ; Compare if the history is full 
  JGE .history_full
  JMP done

.history_full:
  ; Decreases 1, then we have 254 entries
  MOV rax, [vga_entries_up]
  DEC rax

  MOV byte [vga_entries_up], al
  
  ; R8 as second counter 
  MOV r8, 1 
  JMP .history_loop

.history_loop:
  CMP r8, VGA_HISTORY_LIMIT-1
  JGE donediff

  JMP .history_loop_continue

.history_loop_continue:
  ; MOVSW requirements
  MOV rcx, VGA_COL                    ; Total words in a line

  ; We need to define RDI and RSI, so, we make a Offset in RAX
  ; Then, fisrt we multiply (Offset), to then add (Base)
  IMUL rax, r8, VGA_COL*2             ; RSI = R8 * (VGA_COL*2). This is the Offset, the fisrt time will be 0

  MOV rsi, vga_history_up             ; Add to RSI, the base address
  ADD rsi, rax                        ; Add to RSI, the offset

  MOV rdi, rsi                        ; Reply the value of RSI 
  SUB rdi, rax                        ; Then, back 1 line with SUB

  REP MOVSW                           ; While RCX > 0, MOVE rsi to rdi, and add 1 word to each
  
  INC r8                              ; Then add 1 to R8 
  JMP .history_loop                   ; When the task has ended (Move 1 line to 160 bytes back), return to LOOP
  
.add_line:
  ; Now, we are defining the parameters of REP MOVSW
  MOV rcx, VGA_COL                                         ; RCX is the colls counter
  MOV rsi, rax                                             ; RSI is the source of copy (VGA Buffer)
  MOV rdi, vga_history_up + (vga_entries_up * VGA_COL*2)   ; The result is the next value to write the line in the buffer

  REP MOVSW                          ; Repeat while RCX > 0, MOV RSI to RDI for single word

  ; Here, we increases +1 in the variable in the memory, using temporarly the RDI
  MOV rdi, [vga_entries_up]          ; Uses RDI as temporary registern to save the value in vga_history_up 
  INC rdi

  MOV byte [vga_entries_up], dil     ; Then, writes in the addres of the label. We use DIL because, the variable is 8-bits

  RET   

.move_line_loop:  
  ADD rax, VGA_COL*2                 ; Starts with 2º Line (Fisrt line is unuseless, beacause we saved to history)
  MOV rcx, VGA_COL                   ; RCX a counter of Collums
  
  MOV rsi, rax                       ; Source is RAX (Vga Buffer)
  MOV rdi, rax                       ; Destinatios is RAX, but in a previous line
  SUB rdi, VGA_COL*2                 ; 160 bytes rolls a new line. In our case, back a line

  REP MOVSW                          ; Copy the N line to N-1 line

  INC r8                             ; Increase in r8
  CMP r8, VGA_LINE                   ; Compare the second counter to VGA Lines
  JL .move_line_loop                 ; If is less, repeaat the loop
  
  RET                                ; Else, return to main function

.dump_line:
  MOV rdi, VGA_BFF + VGA_LINE*VGA_COL*2  ; The result is 0xB8FAO. The begin of 26th line
  MOV al, 0x0                            ; Zeros bytes
  MOV rcx, VGA_COL*2                     ; For all bytes in the line (80 chars * 2 bytes = 160 bytes)

  REP STOSB 
  RET 


; Go to up without recovery in the history, only saves
global vga_buffer_scroll_above
vga_buffer_scroll_above:
  PUSH rax                           ; Save all registers non used
  PUSH rcx 
  PUSH rdi 
  PUSH rsi
  PUSH r8
 
  MOV rax, VGA_BFF_FINAL             ; Move RAX to the begin of 25º Line

  XOR rcx, rcx                       ; Zeros RCX as collums counter
  XOR r8, r8                         ; Zeros R8 as lines counter

  CALL .add_line                     ; Calls to add the line in history
  CALL .move_line_loop               ; Calls to move up every line in the grid
  CALL .dump_line                    ; Clean the 26 line for avoid visual bugs and repeat infinitly this line for up

  ; The history limit to the down-lines is 255, then, we need to delete de first register, and realocater the array
  MOV rax, [vga_entries_down]
  CMP rax, VGA_HISTORY_LIMIT          ; Compare if the history is full 
  JGE .history_full

  JMP done

.history_full:
  ; Decreases 1, then we have 254 entries
  MOV rax, [vga_entries_down]
  DEC rax

  MOV byte [vga_entries_down], al
  
  ; R8 as second counter 
  MOV r8, 1 
  JMP .history_loop

.history_loop:
  CMP r8, VGA_HISTORY_LIMIT-1
  JGE done 

  JMP .history_loop_continue

.history_loop_continue:
  ; MOVSW requirements
  MOV rcx, VGA_COL                    ; Total words in a line

  ; We need to define RDI and RSI, so, we make a Offset in RAX
  ; Then, fisrt we multiply (Offset), to then add (Base)
  IMUL rax, r8, VGA_COL*2             ; RSI = R8 * (VGA_COL*2). This is the Offset, the fisrt time will be 0

  MOV rsi, vga_history_down           ; Add to RSI, the base address
  ADD rsi, rax                        ; Add to RSI, the offset

  MOV rdi, rsi                        ; Reply the value of RSI 
  SUB rdi, rax                        ; Then, back 1 line with SUB

  REP MOVSW                           ; While RCX > 0, MOVE rsi to rdi, and add 1 word to each

  INC r8                              ; Add 1 to R8 to finish the loop when nescessary
  JMP .history_loop                   ; When the task has ended (Move 1 line to 160 bytes back), return to LOOP

.add_line:
  ; Now, we are defining the parameters of REP MOVSW
  MOV rcx, VGA_COL                                             ; RCX is the colls counter
  MOV rsi, rax                                                 ; RSI is the source of copy (VGA Buffer)
  MOV rdi, vga_history_down + (vga_entries_down * VGA_COL*2)   ; The result is the next value to write the line in the buffer

  REP MOVSW                            ; Repeat while RCX > 0, MOV RSI to RDI for single word

  SerialDebug [vga_entries_up]         ; GEMINI, Here vga_entries_up is 2
  ; Here, we increases +1 in the variable in the memory, using temporarly the RDI
  MOV rdi, [vga_entries_down]          ; Uses RDI as temporary registern to save the value in vga_history_up 
  INC rdi
  MOV byte [vga_entries_down], dil     ; Then, writes in the addres of the label. We use DIL because, the variable is 8-bits
  SerialDebug [vga_entries_up]         ; GEMINI, here the vga_entries_up is 102

  ; Finally, for some reason that i don't know
  ; It's needed to replace the 25º Line for the 24º, because, if don't replace, the 24º it's ignored 
  ; I've tried everthing, but only the lazy fix resolved it
  MOV rcx, VGA_COL                   
  MOV rsi, VGA_BFF_FINAL - VGA_COL*2 
  MOV rdi, VGA_BFF_FINAL
  REP MOVSW

  RET   

.move_line_loop:  
  STD                                ; Again, define the workflow of loop is inverted 
  SUB rax, VGA_COL*2                 ; Starts at 24º Line (Last line is unuseless, beacause we saved to history)
  MOV rcx, VGA_COL                   ; RCX a counter of Collums.
  
  MOV rsi, rax                       ; Source is RAX (Vga Buffer Final)
  MOV rdi, rax                       ; Destinatios is RAX, but in a nex line
  ADD rdi, VGA_COL*2                 ; 160 bytes rolls a new line. 

  REP MOVSW                          ; Copy the N line to N-1 line
  CLD                                ; Clear the Direction Flag, the opossite of STD
  
  INC r8                             ; Increase in r8
  CMP r8, VGA_LINE                   ; Compare them
  JL .move_line_loop                 ; If is less, repeaat the loop
  
  RET                                ; Else, return to main function

.dump_line:
  MOV rdi, VGA_BFF                       ; The begin of first line
  MOV al, 0x0                            ; Zeros bytes
  MOV rcx, VGA_COL*2                     ; For all bytes in the line (80 chars * 2 bytes = 160 bytes)

  REP STOSB 
  RET 


; Go to up with recovering in the history
global vga_buffer_scroll_up 
vga_buffer_scroll_up:
  PUSH rax                           ; Save all registers non used
  PUSH rcx 
  PUSH rdi 
  PUSH rsi
  PUSH r8

  MOV rax, [vga_entries_up]          ; Verify if has no line in history
  CMP rax, 0                           
  JE done                            ; Then, jump to end if not

  CALL vga_buffer_scroll_above       ; Scrolls up but withou restore the history. Blank line in the last line 
  CALL .pull_line                    ; Recovery in the history the 25th line, and write it

  JMP done

.pull_line:
  ; Now, we are defining the parameters of REP MOVSW
  MOV rcx, VGA_COL                                             ; RCX is the colls counter
  MOV rsi, vga_history_up + ((vga_entries_up-1) * VGA_COL*2)   ; The result is the next value to read the line in the buffer
  MOV rdi, VGA_BFF                                             ; RDI is the destiny of copy (VGA Buffer) in 1th line

  REP MOVSW                          ; Repeat while RCX > 0, MOV RSI to RDI for single word
  RET
 

; Go to down with recovering in the history 
global vga_buffer_scroll_down
vga_buffer_scroll_down:
  PUSH rax                           ; Save all registers non used
  PUSH rcx 
  PUSH rdi 
  PUSH rsi
  PUSH r8

  MOV rax, [vga_entries_down]        ; Compare if has no entries in the history
  CMP rax, 0 
  JE done                            ; If not, jump to end

  CALL vga_buffer_scroll_bellow      ; Scrolls up but withou restore the history. Blank line in the last line 
  CALL .pull_line                    ; Recovery in the history the 25th line, and write it

  JMP done

.pull_line:
  ; RAX is the entries of history (How many lines)
  MOV rax, [vga_entries_down]        
  DEC rax                            ; Decreases because we are reading, not writing              

  MOV rcx, VGA_COL                   ; RCX is the colls counter

  ; Now, we define the RSI, basicly is a multiply RAX by 160 (VGA_COL*2), this is the Offset
  ; And add the Base, that's the vga_history_down address memmory
  IMUL rsi, rax, VGA_COL*2
  ADD rsi, vga_history_down

  MOV rdi, VGA_BFF_FINAL             ; RDI is the destiny of copy (VGA Buffer) in 25th line

  REP MOVSW                          ; Repeat while RCX > 0, MOV RSI to RDI for single word
  RET


donediff:
  JMP done

done:
  POP r8
  POP rsi                            ; Restore the registers
  POP rdi 
  POP rcx 
  POP rax 

  RET                                ; Return to main kernel
