BITS 32

; CONTANTS
CODE_SEL equ 0x08                              ; Selector for code in 64-bit
DATA_SEL equ 0x10                              ; Selector for data


; Stack memory, only reserve for in the future to use
section .bss align=16

boot_stack: 
  resb 0x4000                                  ; 16 KB

boot_stack_top:


; Page Tables in  align 4K
align 4096  
pml4:
    resb 4096                                  ; Page Map Level 4 = 512 GB

align 4096
pdpt:                                          ; Page Directory Page Pointer = 1GB 
    resb 4096

align 4096                                     ; Page Directory = 2 MB
pd:
    resb 4096


; GDT
section .data align=16

gdt64:
    dq 0                                       ; Null descriptor. Intel specification

    ; Code in 64-bit
    dq 0x00209A0000000000                      ; Flags: present, executable, readable, long mode  
    ;   0x0020 = Flags (bit 53 = L bit → 1 = 64-bit code segment)
    ;   0x9A   = Acess + Type:
    ;     9 = 1001 → P=1 (present), DPL=00 (ring 0), S=1 (code/data)
    ;     A = 1010 → X=1 (executable), DC=0, R=1 (readable), A=0
    ;   0x0... = Ignore
    dq 0x0000920000000000                      ; Data

gdt64_end: 


; GDT Pointer 
gdt64_ptr:
    dw gdt64_end - gdt64 - 1                   ; Size - 1 = Intel specification
    dq gdt64                                   ; Linear address                   


; Here is the Main Code
section .text
global _start                                  ; Function Main defined in linker.ld
extern kernel_main                             ; The kernel in Assembly (To be linked)

_start: 
    ; EBX = Pointer to Multiboot Struct.
    ; EDI = In the future, will be expanded to RDI (Fist argurment in ABI)
    MOV edi, ebx
    MOV esp, boot_stack_top                    ; Mov the SP to the end of reserved region

    ; Define the EFlags = RFlags + expanded (32 flags)
    PUSH dword 0b10                               ; Define the last 2 EFlags, where the 2º flag (Left to Right) must be True (Intel specification)
    POPFD                                      ; Throws the value in stack to the EFlags direct (In 32-bits)

    ; Clear Interrupt Flags. aka: IRQs
    ; Setted beacause, if an interruption get in, it crashes, beacause we dont have the IRQ table
    CLI

    ; Paginators configuration
    XOR eax, eax                               ; Zero the EAX flag (PML4)
    MOV ecx, 1024                              ; Counter. 1024 Interations
    MOV edi, pml4                              ; PML4 address to final destin

    ; REP = Repeat until CX > 0 
    ; STOSD = Go to DI, store the value AX, increases DI + 4 (stosD -> D = DoubleWord = 4 Bytes)
    ; So, it zero 1024 * 4 Bytes
    REP STOSD                   
    
    ; Same logic to PDPT and PT
    MOV ecx, 1024 
    MOV edi, pdpt 
    REP STOSD 

    MOV ecx, 1024 
    MOV edi, pd
    REP STOSD

    ; Set the Flags to PD. Not PDT, even PML4 needs flags, beacause its uses PD. 
    ; PDPT = PD * 512, PML4 = PDPT * 512 || PD * 512 * 512
    MOV edi, pd 
    MOV eax, 0x83                              ; Or 1000_0011 in binary-flags. See all tags:
                                               ;   Bit 0  (P)    = 1 → Present (Existant page)
                                               ;   Bit 1  (R/W)  = 1 → Read/Write (Write permission)
                                               ;   Bit 2  (U/S)  = 0 → Supervisor (Only ring-o acess)
                                               ;   Bit 3  (PWT)  = 0 → Page Write-Through (Cache)
                                               ;   Bit 4  (PCD)  = 0 → Page Cache Disabled (Cache)
                                               ;   Bit 5  (A)    = 0 → Accessed (Acessed? Only CPU sets)
                                               ;   Bit 6  (D)    = 0 → Dirty (Writted? Only CPU sets)
                                               ;   Bit 7  (PS)   = 1 → Page Size = 2MB (Required)
                                               ;   Bit 8  (G)    = 0 → Global (Dont invert TLB)
                                               ;   Bits 11:9 = 000 → PAT index and reserved
                                               ;   Bits 51:12 = Fisical Address [34:12]
                                               ;   Bits 63:52 = Fisical Address [51:40]

    MOV ecx, 512                               ; 512 Entries to PDPT (2MB).


.map_loop:
    MOV [edi], eax                             ; Move the Flags in the DI address in the memory 
    ADD edi, 8                                 ; Each entry = 8 Bytes. Next entry in PD
    ADD eax, 0x200000                          ; Add to AX 2MB, a entire PD

    LOOP .map_loop                             ; Executes 521 loop times. 512 * 2MB = 1GB, an entire PDPT

    MOV eax, pd                                ; Points to PD address 
    OR eax, 0b11                               ; Add Flag Present and Read/Write to PD address (0x3)

    ; Move the AX in the first byte of where PDPT point
    ; PDPT[0] = [PDPT], PDPT[1] = [PDPT + 8], PDPT[2] = [PDPT + 2*8]
    MOV [pdpt], eax

    ; Same logic por PML4 
    MOV eax, pdpt 
    OR eax, 0b11 
    MOV [pml4], eax
    
    ; The kernel will live in exact haslf of PML4, where is 256 index.
    ; The CPU reads in 64 bit. Then, 8 bytes offset (256*8)
    MOV eax, pdpt 
    OR eax, 0b11 
    MOV [pml4 + 256*8], eax



compt_mode:
    ; Activating CR3 for concluing the pagination  
    MOV eax, pml4                              ; CR3 = Page Table Base Register
    MOV cr3, eax                               ; CRx only accepts Register as origin/destin

    ; Activating PAE 
    MOV eax, cr4                               ; CR4 = Control Register 4
    ; It's nescessary activate Flag in Bit 5 (Enable PAE)
    ; 1 << 5 = 0b100000. 1 With 5 zeros, its we need to only activating Bit 5
    OR eax, 1 << 5                            
    MOV cr4, eax                               ; Again, CRx only accept registers moving. We cant use OR direct 

    ; Activating Long Mode in EFER
    ; EFER is a MSR registers 
    ; MSR Register are Super register that MOV cant interact 
    ; MSR receive a code in ECX (0xC0000080) that matchs to FSER
    ; It return in two 32-bit register a 64-bit number (DX:AX). Even in 64-Bit ASM with R registers 
    MOV ecx, 0xC0000080
    RDMSR                                      ; Put value in DX:AX 
    OR eax, 1 << 8                             ; We need to enable a 8 Bit Flag (Long Mode Compatible)
    WRMSR                                      ; Send to back DX:AX to EFER

    ; Activating Paging
    ; We finnaly will activate the pagging with virtual memory 
    ; We use the CR0 for that. Critical moment
    ; PML4 -> PDPT -> PD -> Fisical Memory 
    MOV eax, cr0 
    OR eax, 1 << 31                            ; Enable flag in 31 Bit (Pagging) 
    MOV cr0, eax                               ; If an error could appears, this is the momment
    

far_jump:
    ; We are in 32-bit in 64-bit mode. AKA Compatibily mode 
    ; To enter in 64 Bit mode, we need to enable the GDT 
    LGDT [gdt64_ptr]                           ; Load GDT
    JMP CODE_SEL:long_mode                     ; Add 0x8 (Fist segment in 64-bit) in CS, and jump 
    ; After this jump, we will enter in 64-bit full mode


BITS 64
long_mode: 
    ; We are in 64-bit Mode!!!
    ; For continue, we need to set some Segments Register to 2nd segment in GDT (16)
    ; Like the MSR registers, Segments Registers only accept other 16-bit register as argument 

    MOV ax, DATA_SEL 
    MOV ds, ax 
    MOV ss, ax
    MOV es, ax
    MOV fs, ax
    MOV gs, ax

    ; Aplying mask to RSP align in 16 bits (Flor bounce)
    AND RSP, -16                               ; RSP = 1010 0110 => 166 / 16 = 10.375
                                               ; MSK = 1111 0000 => -16 
                                               ; --- = 1010 0000 => 160 / 16 = 10
    
    ; Uses the Multiboot 2 Struct back in EDI/RDI
    MOV edi, ebx

    ; Finally, calling the kernel 
    CALL kernel_main

.hang:
    HLT                                        ; If kernels crash, it use HLT to stay in Low-mode CPU (quiet)
                                               ; We have disabled the IRQ with CLI. But, if somethings happens, there's a loop
    JMP .hang
