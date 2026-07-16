; Debug a integer as a string
; Receives RDI as a Integer, and return in RAX the pointer to ASCII format
; uint64 RDI (hex_int) => *string RAX (ptr), uint64 RDX (len)

BITS 64

; BSS variables 
section .bss 
  hex_ascii resb 18                  ; Reserve 18 bytes. 2 for the hex prefix (0x) and 16 for each nipple/char

section .text
global debug_hex
debug_hex: 
  ; Saves all to restore later
  PUSH rcx                           ; Geral counter
  PUSH rdi
  PUSH r8                            ; Left-Zero Flag

  XOR rcx, rcx
  XOR rdx, rdx                       ; Char counter as return
  MOV r8, 1                          ; Enable R8, because its the FLAG to left-zero

  ; 8 because, the register is 64-bits 
  ; Each byte (8-bits) has 2 Nipples
  ; Nipple = 1 char of hexadecimal (0xF)
  ; 64 bits (register) / 8 bits (2 nipples) = 8 bits 
  MOV rcx, 8

  ; ROL = Rotate left X bits
  ; Like to SHL, but the value that will be discard, jumps to the other side (Like Pacman)
  ; Then, no value is discard, just realocate in the register
  ROL rdi, 8                         ; Rools RDI for left in 8 bits. Then, the first byte is the last byte.

  ; Writes in the string the HEX prefix: 0x...
  MOV byte [hex_ascii], 48              ; 48 = '0' in ascii
  MOV byte [hex_ascii+1], 120           ; 120 = 'x' in ascii

  ADD rdx, 2                         ; Add 2 char count

  JMP loop_hex

loop_hex:
  MOV al, dil                        ; DIL = the lowest part in RDI (Bellow of EDI and DI), then AL receives 1 byte (2 Nipples/Chars)
  MOV ah, al                         ; AH = First Nipple (Char), AL Second Nipple (Char)

  AND ah, 0b1111_0000                ; Uses a mask to pick only first nipple 
  AND al, 0b0000_1111                ; Again, the mask to pick only second nipple 
  SHR ah, 4                          ; Replace the last 0 by the char itself. Basicly, divides by 16 (Base integer) 

  JMP compare_high

compare_high:
  CMP ah, 0x9                        ; Compare if the 1º nipple is an number or a letter. 0-9 number, A-F (10-15) letter
  JG .letter
  JLE .number

.letter:
  ADD ah, 55                         ; Number to add for convert a letter in hex to respective ascii
  JMP compare_low 

.number: 
  ADD ah, 48                         ; Number to add for convert a integer to respective ascii
  JMP compare_low


compare_low:
  CMP al, 0x9 
  JG .letter 
  JLE .number 

.letter:
  ADD al, 55
  JMP discard_left_zero

.number:
  ADD al, 48
  JMP discard_left_zero


; Write the Nipples in Serial
loop_hex_continue:
  XOR r8, r8                         ; Disable left-zero flag

  ; Write AH and AL
  MOV byte [hex_ascii+rdx], ah 
  MOV byte [hex_ascii+rdx+1], al
  
  ADD rdx, 2
  JMP loop_hex_final

loop_hex_final:
  ROL rdi, 8                    ; Next 2 characters (2*4=8)
  LOOP loop_hex                 ; LOOP, deacrese RCX until stop
  JMP done                      ; If the loop over, jump to the final      


; Checks if there's zero at left, and discard them
discard_left_zero:
  CMP ah, 48                         ; 48 not 0, because it is in Ascii format, '0' in Ascii is 48.
  JE .compare_low 
  JNE loop_hex_continue

.compare_low:
  CMP al, 48
  JE compare_left_zero
  JNE loop_hex_continue

compare_left_zero:
  CMP r8, 1                          ; Checks if in the left zero flag is enabled
  JE loop_hex_final
  JNE loop_hex_continue


done:  
  MOV rax, hex_ascii                 ; Then, return the pointer to the begin of hex string as 1º Return
  ; RDX = Return the length of string as 2º Return

  POP r8
  POP rdi
  POP rcx 

  RET                                ; Return to main Kernel
