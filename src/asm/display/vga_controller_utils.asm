; Many functions to controlling the backdor of VGA Chips with IO Ports 
; Uses RDI and RSI
; -> vga_controller_max_lines & vga_controller_cursor_update

BITS 64

; CONSTANTS 
VGA_COL equ 80

; Macros here
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
; Upscaling the max lines from 25 to 25
; no input no output
global vga_controller_max_lines 
vga_controller_max_lines: 
  PUSH rax
  PUSH rbx
  PUSH rdx 

  ; We set to display 25 Lines (The max number). 
  ; I know there's way to put a 10-bits number using the 0x7 Port, but 25 is a good number to 4:3 portrait
  ; Setting the intern VGA register to Vertical size
  MOV dx, 0x3D4                              ; Port of VGA register select
  MOV al, 0x12                               ; Which VGA register we want
  OUT dx, al    
  MOV dx, 0x3D5                              ; Now, we define the data who pass 
  MOV al, 143                                ; The max number of an byte, that's 25 lines in total
  OUT dx, al                                 ; So, the calc is: (X-16)*16-1 

  JMP done                                   ; So return


; Update the cursor location using the VGA Controller 
; Uses RDI as X location (Collum), and RSI as Y (Line)
; uint16 RDI-16 (collums), uint16 RSI-16 (lines)
global vga_controller_cursor_update 
vga_controller_cursor_update:
  PUSH rax 
  PUSH rbx
  PUSH rdx 

  XOR rbx, rbx                                 ; Full clean RBX

  ; First, calculates the absolute location (The result is 16-bits in BX)
  ; The formulae is: P = Y * COLS + X
  MOV bx, si                                   ; P = Y
  IMUL bx, VGA_COL                             ; P = P * COLS
  ADD bx, di                                   ; P = P + X

  ; Using IO Ports to define the cursor location. It uses 2 Bytes (Word), in High byte and Low Byte
  ; Second, sends the high byte to IO port
  ; Port = Word (DX), Value = Byte (AL)
  MOV dx, 0x3D4                                ; We use the VGA CTRC Ports 
  MOV al, 0xE                                  ; Using the port of Cursor Location (High Byte) 
  OUT dx, al                                   ; Writes it 

  ; 0x3D4 = Command Port, 0x3D5 = Data Port
  MOV dx, 0x3D5                                ; Using Data Section of VGA CTRC
  MOV al, bh                                   ; Bh = High part (8-bits) of BX (16-bits)
  OUT dx, al                                

  ; Third, let's write the low part of result
  ; Same work 
  MOV dx, 0x3D4 
  MOV al, 0xF                                  ; Command Port of low part of Cursor Location
  OUT dx, al 

  MOV dx, 0x3D5 
  MOV al, bl                                   ; Bl = Low part (8-bits) of BX (16-bits) 
  OUT dx, al

  JMP done


done:
  POP rdx 
  POP rbx
  POP rax
  RET
