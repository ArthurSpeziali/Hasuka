; Interruptor Descriptor Table Set EWntry
; Receives RDI as the number of interruption, RSI as the address memory of the handler Function. No Return 
; uint8 RDI (vector), *void RSI (handler)
BITS 64

; CONSTANTS
ALL_VECTORS equ 256                           ; The total of differents IRQ's (One for Keyboard, other for Seg Fault etc...)
CODE_SEL equ 0x08                              ; Selector for code in 64-bit


; Define a Struct in NASM (128-bits in total)
; GDT Table Structe (Gate struct):
struc InterruptorTable 
  .address_low  resw 1                        ; Bits 0-15  => [MEMORY] Handler Function Address (First 16-bits)
  .selector     resw 1                        ; Bits 16-31 => [INT] GDT Selector (Default 0x08, we set in boot_shim)
  .ist          resb 1                        ; Bits 32-39 => [BOOL] If we want to use IST, we dont (Default 0)
  .flags        resb 1                        ; Bits 40-47 => [FLAG] The flags struct is:
                                              ;   Type (0-3)   -> Gate 0b1111 || Interrupt 0b1110 
                                              ;   Reserved (4) -> 0b0
                                              ;   DPL (5-6)    -> 0b0 
                                              ;   Present (7)  -> 0b1 
                                              ;   # Gate Type don't save the registers before, and Interrupt type save him,
                                              ;   # Reserved is aways 0 
                                              ;   # DPL is the max level of the ring that the instruction can be acessed, 0 = Security 
                                              ;   # Present define if the struct is a vector valid for the CPU, 1 to valid them
  .address_mid  resw 1                        ; Bits 48-63 => [MEMORY] The rest of Handler Function (First 32-bits)
  .address_high resd 1                        ; Bits 64-95 => [MEMORY] The final of Handler Function (Total 64-bits)
  .reserved     resd 1                        ; Bits 96-128=> [NULL] Reserved area
endstruc

; Lets reserve the all entries each using the table
section .data 
  ; Times = NASM conviniation. Repeat N times the X instruction
  ; Here, We reserve 256 (All vector) * 16 (Table size) Bytes with value 0
  idt_entries:                                  ; The real tables is here
    Times ALL_VECTORS*InterruptorTable_size DB 0                  
  
  ; The CPU requires a 2 field table
  ; The first 2 bytes is the size of tables in the total 
  ; The last 8 bytes is the address of real table
  idt_ptr:                                  ; The pointer for the real table
    dw (ALL_VECTORS * InterruptorTable_size)-1  ; Total value of all interruptions, minus 1 (Base limit)
    dq idt_entries


; Return to code 
section .text
; Set a especific IRQ Vector
global idt_set_entry
idt_set_entry:
  PUSH rax

  ; We need to write in the correct memorry the table, so: 
  ; idt_entries + (vector * 16), Where vector is the number of irq (RDI) 
  ; And 16 the number of bytes of the table (InterruptorTable)
  MOV rax, rdi 
  SHL rax, 4                                             ; 2^4 = 16
  ADD rax, idt_entries                                   ; RAX it's now the m,emory address of the table
  
  ; Now, we go to fill each field in the table 
  MOV word [rax + InterruptorTable.address_low], si      ; Fisrt part of Handle Address 
  MOV word [rax + InterruptorTable.selector], CODE_SEL   ; GDT Selector 
  MOV byte [rax + InterruptorTable.ist], 0               ; IST disabled 
  MOV byte [rax + InterruptorTable.flags], 0b10001110    ; Basicly: 0b1_____00__0________1110 -> 
                                                         ;          Present DPL Reserved Type
  ; We go to shiftR RSI to deslocate the 16-bits from HIGH to LOW
  ; And return to original state of RSI
  PUSH rsi                                               ; Save state of RSI
  SHR rsi, 16                                            ; Discard the last 16-bits, and realocate
  MOV word [rax + InterruptorTable.address_mid], si      ; Second part of Handler Address. The HIGH 16-bit of ESI 

  SHR rsi, 16                                            ; Again, discard the used 16-bits 
  MOV dword [rax + InterruptorTable.address_high], esi   ; Final part of Handler Adddress. Use 32-bits now
  POP rsi                                                ; So, back to original value of RSI. We have used completely it 

  MOV dword [rax + InterruptorTable.reserved], 0         ; Null value, reserved area
  
  POP rax                                                ; Restore saved registers, and return
  RET
  

; Load the IDT, a too smaller function to keep in outer file 
global idt_load 
idt_load:
  ; LIDT is a special instruction, to evaluate the value to the special register IDTR 
  ; IDTR is a 10-byte register, only avaliable for LIDT (Write) and SIDT (Read) 
  ; We have to pass a 10 byte value, not the memory address
  LIDT [idt_ptr]                               ; Finnaly, load the IDT with the register IDTR. So, return
  RET
