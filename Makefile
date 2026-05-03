include config.mk

.PHONY: clean mkdir compile geniso copy debug check
all: clean mkdir compile geniso copy

build/asm/%.o: src/asm/%.asm
	@mkdir -p $(@D)
	nasm -f elf64 $< -o $@

build/zig/%.o: src/zig/%.zig 
	@mkdir -p $(@D)
	zig build-obj $< -target x86_64-freestanding -OReleaseSmall -femit-bin=$@

compile: $(ALL_OBJ)
	ld -T linker.ld -n $^ -o $(TARGET) -nostdlib -static 

geniso: 
	cp $(TARGET) iso/boot
	grub-mkrescue -o $(ISO) iso

mkdir:
	mkdir -p build/asm build/zig
  
check: clean mkdir $(ASM_OBJ)


clean:
	rm -rf $(ISO) build/*

copy: 
	cp $(ISO) /tmp/hasuka$N.iso

debug:
	@echo "$(ZIG_SRC) \n$(ZIG_OBJ)\n"
	@echo "$(ASM_SRC) \n$(ASM_OBJ)"
