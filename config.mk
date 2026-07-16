ASM_SRC = $(shell find src/asm -name '*.asm')
ZIG_SRC = $(shell find src/zig -maxdepth 1 -name '*.zig')

ASM_OBJ = $(patsubst src/%.asm,build/%.o,$(ASM_SRC))
ZIG_OBJ = $(patsubst src/%.zig,build/%.o,$(ZIG_SRC))

ALL_OBJ = $(ASM_OBJ) $(ZIG_OBJ)
TARGET  = build/kernel.elf
ISO     = iso/hasuka.iso
