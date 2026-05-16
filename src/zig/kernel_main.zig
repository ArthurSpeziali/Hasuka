// Firmlevel kernel in Zig

// Imports
const arc = @import("core/archive.zig");
const stdout = @import("core/stdout.zig");
const debug = @import("core/debug.zig");

const kbd = @import("drivers/keyboard.zig");

// Extern Functions 
extern fn interrupts_init() void;


// Kernel main
export fn kernel_main() noreturn {
  // Activate the interrupts 
  interrupts_init();

  // Setting up the max VGA Lines to 32 
  stdout.max_lines();

  // Clear the VGA Screen
  stdout.clear();

  // Welcome print
  stdout.print(
    arc.WELCOME_STR
  );

  debug.convert_utf8("Ç");

  // Suspend the kernel
  debug.kernel_wait();
}


// HANDLERS
// Function for handling error stubs (ISR) and success stubs (IRQ)
export fn isr_handler(vector: usize) void {
  switch (vector) {
      0  => stdout.serial("Division by Zero!"),
      1  => stdout.serial("Debug Exception!"),
      2  => stdout.serial("Non-Maskable Interrupt!"),
      3  => stdout.serial("Breakpoint!"),
      4  => stdout.serial("Overflow!"),
      5  => stdout.serial("Bound Range Exceeded!"),
      6  => stdout.serial("Invalid Opcode!"),
      7  => stdout.serial("Device Not Available!"),
      8  => stdout.serial("Double Fault!"),
      9  => stdout.serial("Coprocessor Segment Overrun!"),
      10 => stdout.serial("Invalid TSS!"),
      11 => stdout.serial("Segment Not Present!"),
      12 => stdout.serial("Stack-Segment Fault!"),
      13 => stdout.serial("General Protection Fault!"),
      14 => stdout.serial("Page Fault!"),
      15 => stdout.serial("Reserved!"),
      16 => stdout.serial("x87 Floating-Point Exception!"),
      17 => stdout.serial("Alignment Check!"),
      18 => stdout.serial("Machine Check!"),
      19 => stdout.serial("SIMD Floating-Point Exception!"),
      20 => stdout.serial("Virtualization Exception!"),
      21 => stdout.serial("Control Protection Exception!"),
      28 => stdout.serial("Hypervisor Injection Exception!"),
      29 => stdout.serial("VMM Communication Exception!"),
      30 => stdout.serial("Security Exception!"),
      22...27, 31 => stdout.serial("Reserved!"),
      else => stdout.serial("Unknown Interrupt!")
  }

  debug.kernel_wait();
}

export fn irq_handler(vector: usize) void {
  switch (vector) {
    33 => {
      // _ = kbd.get_code();
      stdout.serial("Keyboard?");
    },
    else => {}
  }
}

