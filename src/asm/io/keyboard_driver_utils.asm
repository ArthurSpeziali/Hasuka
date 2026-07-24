; Multiple functions to build the Keyboard Driver
; -> keyboard_driver_get_code, keyboard_driver_get_ascii, keyboard_driver_pick_key
; Receive in RDI, Return in RAX

BITS 64 

; CONSTANTS 
KEYBOARD_PORT equ 0x60

; Extern functions
extern keyboard_layout_byte
extern keyboard_layout_word
extern keyboard_keyfilter_vga

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
; Picks the code of keyboard IRQ
; Returns in RAX 
; => uint8 RAX (driver_code)
global keyboard_driver_get_code 
keyboard_driver_get_code: 
  XOR rax, rax                                 ; Full cleans RAX
  
  IN al, KEYBOARD_PORT                         ; Reads from CPU port and store in RAX
  RET                                          ; Return


; Receive a driver code and return his ASCII (CP437) equivalent
; Receive in RDI, Return in RAX 
; uint8 RDI (driver_code) => uint8 RAX (ascii_code)
global keyboard_driver_get_ascii 
keyboard_driver_get_ascii:
  ; First, decide which table use, the simple (1 byte), or composed (1 word)
  ; Composed keys, like Arrows, use 0xE0 in the first byte, and the next is the real key code (Both press and release)
  CMP dil, 0xE0                                ; 0xE0 = Indicates Composed Key
  JE .composed 
  
  ; If not (The simple key), it calls keyboard_layout_byte normally
  CALL keyboard_layout_byte                    ; Return 2-element array in RAX (1º ASCII representation, 2º If its release)
  RET                                          ; Return
.composed:
  ; Discard this byte key, and pick the next 
  CALL keyboard_driver_get_code                ; Pick the next key, and stores in RAX 
  MOV rdi, rax                                 ; Uses Pipe, Output (RAX) to Input (RDI) of the next function 

  ; Finally, calls keyboard_layout_word, for the composed keys 
  CALL keyboard_layout_word
  RET                                          ; Return to main function


; Pick the last key pressed and pass to the Key Filter, RDI is the Key Filter ID
; Receive in RDI, No Return 
; uint8 RDI (keyfilter_id) 
global keyboard_driver_pick_key
keyboard_driver_pick_key:
  ; Save the registers 
  PUSH rax 
  PUSH rbx

  ; First, redirect the argument in RDI (Pointer to function) to RBX (RDI will be used)
  MOV rbx, rdi                                 ; Save the primmary RDI (Keyfilter ID) to RBX to use later
  CALL keyboard_driver_get_code                ; Get the code of last key pressed 

  ; So, move the output (RAX) to the input (RDI) of the next function 
  MOV rdi, rax 
  CALL keyboard_driver_get_ascii               ; Get from driver_code the ASCII representation 

  ; Again, uses like a 'pipe' (Output to Input)
  MOV rdi, rax 
  ; Call .lookup to return in RAX the address of memory where we will call
  MOV rax, rbx                                 ; Restore the Keyfilter in RBX to use in .lookup
  CALL .lookup                                 ; Unfortunly, we must reaprove the registers, because we use RAX not RDI (Original owner)

  ; Call the Keyfilter handler
  CALL rax                                     ; Now, call the Key Filter Function to respect ID (RDI)


  ; Restore the registers and return
  POP rbx
  POP rax
  RET
.lookup: 
  ; Find the value in RDI to match (To respective keyfilter) 
  ; VGA Keyfilter 
  MOV rbx, keyboard_keyfilter_vga              ; RBX handle temporally the Keyfilter function address

  ; Compare RAX (The ID of keyfilter) to avaliable ID
  CMP rax, 1                                   ; ID 0 => Do nothing, reserved
  CMOVE rax, rbx                               ; If equal, move RBX to RAX. Will be the function adress (Used in CALL rax)
  JE .return                                   ; And return

  JMP .double_return                           ; If not found, takes double return (Returns to main function)
.return: 
  RET
.double_return:
  ADD rsp, 8                                   ; Classic scheme to add in RSP to decrease the return order

  POP rbx                                      ; Restore registers and return
  POP rax 
  RET

