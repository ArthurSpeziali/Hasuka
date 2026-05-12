// Firmlevel kernel in Zig

// Imports
const arc = @import("core/archive.zig");
const stdout = @import("core/stdout.zig");
const debug = @import("core/debug.zig");

// Kernel main
export fn kernel_main() noreturn {
  // Welcome print
  stdout.write(
    arc.WELCOME_STR
  );
  
  // Suspend the kernel
  kernel_wait();
}

  
fn kernel_wait() noreturn {
  while (true) {
    asm volatile (
      \\ .loop:
      \\   HLT
      \\   JMP .loop
    );
  }
}
