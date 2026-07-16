; Only suspend the kernel 
; no input no output 

BITS 64 

global debug_wait
debug_wait: 
  HLT
  JMP debug_wait
