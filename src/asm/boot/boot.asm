BITS 32                                        ; Uses 32 Bits for GRUB

; CONSTANTS
ML_MAGIC equ 0xE85250D6
ML_ARCH  equ 0x00000000
ML_LEN   equ mb2_hdr_end - mb2_hdr
ML_CHECK equ -(ML_MAGIC + ML_LEN + ML_ARCH)


section .mb2_hdr align=8                       ; Specifies to align in 8-bit cells

mb2_hdr:
  DD ML_MAGIC                                  ; Magic number 
  DD ML_ARCH                                   ; Architecture
  DD ML_LEN                                    ; Header len
  DD ML_CHECK                                  ; Checksum (Overflow of sum zero? I dont know)

; If in the future, i want graphical interface, uncomment these functions
; mb2_framebuffer:                               ; Here's a tag in GRUB      
;     dw 5                                       ; 5 = framebuffer
;     dw 1                                       ; Boolean if its required to start, 
;     DD (mb2_framebuffer_end - mb2_framebuffer) ; Header len 
;     DD 0                                       ; Width prefered. 0 = Default
;     DD 0                                       ; Height, 0 = Default
;     DD 0                                       ; BPP, 0 = Default
; mb2_framebuffer_end:

; Exit the grub tags scope
DD 0                                             ; 0 = Exit
DD 8                                             ; Size of 2 DD (4 bytes), type and size = 8 bytes
mb2_hdr_end:
