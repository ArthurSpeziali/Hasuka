ASM_SRC = $(shell find src/asm -name '*.asm')
ZIG_SRC = src/zig/kernel_main.zig

ASM_OBJ = $(patsubst src/%.asm,build/%.o,$(ASM_SRC))
ZIG_OBJ = build/zig/kernel_main.o

ALL_OBJ = $(ASM_OBJ) $(ZIG_OBJ)
TARGET  = build/kernel.elf
ISO     = iso/hasuka.iso

