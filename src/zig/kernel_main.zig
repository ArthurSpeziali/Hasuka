// Firmlevel kernel in Zig

// Imports
const arc = @import("archive.zig");
const stdout = @import("core/stdout.zig");
const debug = @import("core/debug.zig");


// Kernel main
export fn kernel_main() noreturn {
  // Welcome print
  stdout.write(
    arc.WELCOME_STR.ptr,
    arc.WELCOME_STR.len
  );
 
  stdout.scroll_above();
  // stdout.scroll_bellow();

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
