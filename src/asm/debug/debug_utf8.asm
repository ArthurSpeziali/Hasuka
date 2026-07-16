; Convert a full UTF-8 String, into a CP437 (Table used by VGA Buffer)
; Receives *RDI as String, RSI as String's length, and return the new String and new String length 
; *[uint8] RDI (str_ptr), uint16 RSI-16 (str_len) => *&[uint8] RAX (str_ptr), uint16 RDX-16 (str_len)

BITS 64

; Macros Here 
%macro CPtoUTF_Three 2 
  ; EBX = UTF-8 Tripple Char, AL = CP437 Char 
  ; So, we move temporally AL to the value (Even it does not bind)
  ; If bind, jump to function .write_cp437, and write the value in AL 
  ; Else, the other call to this macro will overwrite AL
  MOV al, %2
  CMP ebx, %1 
  JE .write_cp437
%endmacro 
%macro CPtoUTF 2 
  ; BX = UTF-8 Double Char, AL = CP437 Char
  ; So, we move temporally AL to the value (Even it does not bind)
  ; If bind, jump to function .write_cp437, and write the value in AL 
  ; Else, the other call to this macro will overwrite AL
  MOV al, %2                             
  CMP bx, %1                              
  JE .write_cp437
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

; Extern Data 
extern shared_string_word


section .text
global debug_utf8 
debug_utf8: 
  PUSH rbx
  PUSH rcx  

  CALL .overflow_len                           ; C-String Feature. Overflow SI if SI is zero
  
  XOR rcx, rcx                                 ; Zeros RCX = Counter of UTF-8 Chars 
  XOR rdx, rdx                                 ; Zeros RDX = Counter of CP437 Chars

  CALL loop_string                             ; Parser each char of the string
  CALL .add_zero                               ; Add a 0 Byte at final in string 

  JMP done
.overflow_len: 
  ; This function implement a C-String feature. If SI (RSI) is null (0), the it overflowed 
  ; So, it just stop, if an \0 char appears 
  ; Then, we overflow CX, and if SI == 0, then we MOVe CX to SI 
  ; RCX will be cleaned after
  XOR rcx, rcx                                 ; CX = 0
  DEC cx                                       ; CX = 0 - 1, then it overflowed to 65K +-

  CMP si, 0                                    ; If SI (Length) is zero 
  CMOVZ si, cx                                 ; MOVe CX to SI. Then SI is the max 16-bit integer has 
  RET                                          ; Finnaly, return
.add_zero: 
  ; Add an \0 byte at the final of string, ensuring of C-String is working
  MOV byte [shared_string_word + rdx], 0
  RET


loop_string:
  ; Let's pick one per one char. Putting in AL (1 Byte)
  MOV al, [rdi + rcx]                          ; RDI where the string are + RCX the char counter

  ; View if his byte is a \0 Byte. C-Style String Feature 
  CMP al, 0 
  JZ .return 

  ; The CP437 has 1 (ASCII Table) 2 and 3 bytes char in UTF-8. So we must identify it 
  ; We use a Mask to identify how bytes the char has. 
  ; 0b0xxxxxx for 1 byte, 0b110xxxxx for 2 bytes, and 0b1110xxxx for 3 bytes (In the first byte of sequence)
  
  ; Identifying one byte (ASCII Table)
  MOV bl, al                                 ; Move the char value to BL

  AND bl, 0b1000_0000                        ; Only filter the first bit
  CMP bl, 0b0000_0000                        ; Compare the masked value to: 0b0xxxxxxx 
  
  JE convert_one_byte                        ; If equal, so jump to ascii handler


  ; Identifying 2 or 3 bytes
  MOV bl, al                                 ; Move the char value to BL

  AND bl, 0b1110_0000                        ; Only filter the first 3 bits
  CMP bl, 0b1100_0000                        ; Compare the masked value to: 0b110xxxxx 
  
  JE convert_two_bytes                       ; If equal, so jump to two bytes handler
  JNE convert_three_bytes                    ; If not, just go to three bytes handler 
  ; If an 4 bytes char appear, it is interpreted has 3-bytes
.return: 
  RET

loop_string_continue:
  ; 16-bit because it's a security limit. If commit an accident putting 0 in SI, with no \0 byte in string,
  ; It does not throw Segment Fault (65 Thousand vs 18 Quintilion characters) or worse 
  CMP cx, si                                   ; Compare RCX to RSI, but only its 16-bit version 
  JB loop_string                               ; If bellow (Lesser but unsigned), then repeat the loop 
  RET                                          ; If greater or equal the string length, just return     


convert_one_byte:
  ; AL has the acctually character 
  ; So we just write them in shared string. Because is the same the UTF8 (ASCII is universal)
  MOV byte [shared_string_word + rdx], al

  INC rdx                                      ; Pass to next CP437 (Final string) char 
  INC rcx                                      ; Pass to next UTF-8 (Base string) char
  JMP loop_string_continue                     ; So, return to loop
  
convert_two_bytes:
  ; We use BX to compare, so BL it's the next char, and BH is AL (The acctually char)
  ; Here, we 'smash' 2 bytes into one
  ; The fisrt nipples (2 hexadecimal chars) is the acctually byte (First), and the 2º nipple is the next byte 
  ; So we cam compare two bytes at once 
  MOV bh, al 
  MOV bl, [rdi + rcx + 1]

  XOR rax, rax                                 ; Cleans RAX (AL in real). It does not nescessary for now
  CALL .table_convert                          ; So, we use an extensive table to convert

  ADD rcx, 2                                   ; Next 2 characters (bytes)
  JMP loop_string_continue                     ; After, we continues to checking if there's more loop
.table_convert:
  CPtoUTF 0xC387, 0x80                         ; Ç
  CPtoUTF 0xC3BC, 0x81                         ; ü
  CPtoUTF 0xC3A9, 0x82                         ; é
  CPtoUTF 0xC3A2, 0x83                         ; â
  CPtoUTF 0xC3A4, 0x84                         ; ä
  CPtoUTF 0xC3A0, 0x85                         ; à
  CPtoUTF 0xC3A5, 0x86                         ; å
  CPtoUTF 0xC3A7, 0x87                         ; ç
  CPtoUTF 0xC3AA, 0x88                         ; ê
  CPtoUTF 0xC3AB, 0x89                         ; ë
  CPtoUTF 0xC3A8, 0x8A                         ; è
  CPtoUTF 0xC3AF, 0x8B                         ; ï
  CPtoUTF 0xC3AE, 0x8C                         ; î
  CPtoUTF 0xC3AC, 0x8D                         ; ì
  CPtoUTF 0xC384, 0x8E                         ; Ä
  CPtoUTF 0xC385, 0x8F                         ; Å
  CPtoUTF 0xC389, 0x90                         ; É
  CPtoUTF 0xC3A6, 0x91                         ; æ
  CPtoUTF 0xC386, 0x92                         ; Æ
  CPtoUTF 0xC3B4, 0x93                         ; ô
  CPtoUTF 0xC3B6, 0x94                         ; ö
  CPtoUTF 0xC3B2, 0x95                         ; ò
  CPtoUTF 0xC3BB, 0x96                         ; û
  CPtoUTF 0xC3B9, 0x97                         ; ù
  CPtoUTF 0xC3BF, 0x98                         ; ÿ
  CPtoUTF 0xC396, 0x99                         ; Ö
  CPtoUTF 0xC39C, 0x9A                         ; Ü
  CPtoUTF 0xC2A2, 0x9B                         ; ¢
  CPtoUTF 0xC2A3, 0x9C                         ; £
  CPtoUTF 0xC2A5, 0x9D                         ; ¥
  CPtoUTF 0xC692, 0x9F                         ; ƒ
  CPtoUTF 0xC3A1, 0xA0                         ; á
  CPtoUTF 0xC3AD, 0xA1                         ; í
  CPtoUTF 0xC3B3, 0xA2                         ; ó
  CPtoUTF 0xC3BA, 0xA3                         ; ú
  CPtoUTF 0xC3B1, 0xA4                         ; ñ
  CPtoUTF 0xC391, 0xA5                         ; Ñ
  CPtoUTF 0xC2AA, 0xA6                         ; ª
  CPtoUTF 0xC2BA, 0xA7                         ; º
  CPtoUTF 0xC2BF, 0xA8                         ; ¿
  CPtoUTF 0xC2AC, 0xAA                         ; ¬
  CPtoUTF 0xC2BD, 0xAB                         ; ½
  CPtoUTF 0xC2BC, 0xAC                         ; ¼
  CPtoUTF 0xC2A1, 0xAD                         ; ¡
  CPtoUTF 0xC2AB, 0xAE                         ; «
  CPtoUTF 0xC2BB, 0xAF                         ; »
  CPtoUTF 0xC381, 0xB5                         ; Á
  CPtoUTF 0xC382, 0xB6                         ; Â
  CPtoUTF 0xC380, 0xB7                         ; À
  CPtoUTF 0xC2A9, 0xB8                         ; ©
  CPtoUTF 0xC2A2, 0xBD                         ; ¢
  CPtoUTF 0xC2A5, 0xBE                         ; ¥
  CPtoUTF 0xC3A3, 0xC6                         ; ã
  CPtoUTF 0xC383, 0xC7                         ; Ã
  CPtoUTF 0xC2A4, 0xCF                         ; ¤
  CPtoUTF 0xC3B0, 0xD0                         ; ð
  CPtoUTF 0xC390, 0xD1                         ; Ð
  CPtoUTF 0xC38A, 0xD2                         ; Ê
  CPtoUTF 0xC38B, 0xD3                         ; Ë
  CPtoUTF 0xC388, 0xD4                         ; È
  CPtoUTF 0xC4B1, 0xD5                         ; ı
  CPtoUTF 0xC38D, 0xD6                         ; Í
  CPtoUTF 0xC38E, 0xD7                         ; Î
  CPtoUTF 0xC38F, 0xD8                         ; Ï
  CPtoUTF 0xC2A6, 0xDD                         ; ¦
  CPtoUTF 0xC38C, 0xDE                         ; Ì
  CPtoUTF 0xC393, 0xE0                         ; Ó
  CPtoUTF 0xC39F, 0xE1                         ; ß
  CPtoUTF 0xC394, 0xE2                         ; Ô
  CPtoUTF 0xC392, 0xE3                         ; Ò
  CPtoUTF 0xC3B5, 0xE4                         ; õ
  CPtoUTF 0xC395, 0xE5                         ; Õ
  CPtoUTF 0xC2B5, 0xE6                         ; µ
  CPtoUTF 0xC3BE, 0xE7                         ; þ
  CPtoUTF 0xC39E, 0xE8                         ; Þ
  CPtoUTF 0xC39A, 0xE9                         ; Ú
  CPtoUTF 0xC39B, 0xEA                         ; Û
  CPtoUTF 0xC399, 0xEB                         ; Ù
  CPtoUTF 0xC3BD, 0xEC                         ; ý
  CPtoUTF 0xC39D, 0xED                         ; Ý
  CPtoUTF 0xC2AF, 0xEE                         ; ¯
  CPtoUTF 0xC2B4, 0xEF                         ; ´
  CPtoUTF 0xC2B1, 0xF1                         ; ±
  CPtoUTF 0xC2BE, 0xF3                         ; ¾
  CPtoUTF 0xC2B6, 0xF4                         ; ¶
  CPtoUTF 0xC2A7, 0xF5                         ; §
  CPtoUTF 0xC3B7, 0xF6                         ; ÷
  CPtoUTF 0xC2B8, 0xF7                         ; ¸
  CPtoUTF 0xC2B0, 0xF8                         ; °
  CPtoUTF 0xC2A8, 0xF9                         ; ¨
  CPtoUTF 0xC2B7, 0xFA                         ; ·
  CPtoUTF 0xC2B9, 0xFB                         ; ¹
  CPtoUTF 0xC2B3, 0xFC                         ; ³
  CPtoUTF 0xC2B2, 0xFD                         ; ²
  CPtoUTF 0xC2A0, 0xFF                         ;  

  RET                                          ; Else, if no one matching, return and don't write this unknow char
.write_cp437: 
  MOV byte [shared_string_word + rdx], al      ; Writes the CP437 char in a shared string 

  INC rdx                                      ; Increases one byte in only CP437 counter
  RET                                          ; Then returns, we find it

convert_three_bytes: 
  ; We use EBX to compare the three bytes (The acctualy byte, the next byte, and the next-next byte)
  ; Here, we 'smash' 3 bytes into one
  
  XOR ebx, ebx                                 ; We clean the variable
  MOVZX ebx, al                                ; So, we move the first byte to EBX. Zering the rest of bits (8 to 32 bits)
  ; Here, we push the AL inside EBX 16 bits higher 
  ; So, we define the higher part of EBX, the low part is BX
  ; Before: 0b...00000000_00000000_0001010 
  ; After : 0b...00001010_00000000_0000000
  SHL ebx, 16                                   
  
  ; The higher part of BX (BH) is the next char
  MOV bh, [rdi + rcx + 1]
  ; The low part of BX (BL) is the next-next char
  MOV bl, [rdi + rcx + 2]
  ; So, we have 3 bytes in EBX, 1 in EBX-Higher (In second Byte), and 2 in BX (1 in BH and 1 in BL)
  ; We The fisrt byte in EBX is null (Because we have cleaned), so, we can discard the left 0 
  ; That's allow to compare only 6 nipples (3 bytes) of a hexadecimal integer. Like 0x123456

  XOR rax, rax                                 ; Cleans RAX (AL in real). It does not nescessary for now
  CALL .table_convert                          ; So, we use an extensive table to convert

  ADD rcx, 3                                   ; Next 3 characters (bytes)
  JMP loop_string_continue                     ; After, we continues to checking if there's more loop
.table_convert: 
  CPtoUTF_Three 0xE296A0, 0xFE                 ; ■
  CPtoUTF_Three 0xE28097, 0xF2                 ; ‗
  CPtoUTF_Three 0xE289A1, 0xF0                 ; ≡
  CPtoUTF_Three 0xE29680, 0xDF                 ; ▀
  CPtoUTF_Three 0xE29498, 0xD9                 ; ┘
  CPtoUTF_Three 0xE2948C, 0xDA                 ; ┌
  CPtoUTF_Three 0xE29688, 0xDB                 ; █
  CPtoUTF_Three 0xE29684, 0xDC                 ; ▄
  CPtoUTF_Three 0xE2959A, 0xC8                 ; ╚
  CPtoUTF_Three 0xE29594, 0xC9                 ; ╔
  CPtoUTF_Three 0xE295A9, 0xCA                 ; ╩
  CPtoUTF_Three 0xE295A6, 0xCB                 ; ╦
  CPtoUTF_Three 0xE295A0, 0xCC                 ; ╠
  CPtoUTF_Three 0xE29590, 0xCD                 ; ═
  CPtoUTF_Three 0xE295AC, 0xCE                 ; ╬
  CPtoUTF_Three 0xE29490, 0xBF                 ; ┐
  CPtoUTF_Three 0xE29494, 0xC0                 ; └
  CPtoUTF_Three 0xE294B4, 0xC1                 ; ┴
  CPtoUTF_Three 0xE294AC, 0xC2                 ; ┬
  CPtoUTF_Three 0xE2949C, 0xC3                 ; ├
  CPtoUTF_Three 0xE29480, 0xC4                 ; ─
  CPtoUTF_Three 0xE294BC, 0xC5                 ; ┼
  CPtoUTF_Three 0xE295A3, 0xB9                 ; ╣
  CPtoUTF_Three 0xE29591, 0xBA                 ; ║
  CPtoUTF_Three 0xE29597, 0xBB                 ; ╗
  CPtoUTF_Three 0xE2959D, 0xBC                 ; ╝
  CPtoUTF_Three 0xE29691, 0xB0                 ; ░
  CPtoUTF_Three 0xE29692, 0xB1                 ; ▒
  CPtoUTF_Three 0xE29693, 0xB2                 ; ▓
  CPtoUTF_Three 0xE29482, 0xB3                 ; │
  CPtoUTF_Three 0xE294A4, 0xB4                 ; ┤
  CPtoUTF_Three 0xE28C90, 0xA9                 ; ⌐
  CPtoUTF_Three 0xE282A7, 0x9E                 ; ₧
  RET
.write_cp437:
  MOV byte [shared_string_word + rdx], al 
  INC rdx                                      ; Increases one byte in only CP437 counter
  RET                                          ; Then returns, we find it

done: 
  ; Ensuring the returning is correct for 2 returns (RAX for string and RDX for length)
  MOV rax, shared_string_word                  ; RAX as a pointer to string (Shared)
  ; RDX is just setted as string length 

  POP rcx
  POP rbx
  RET
