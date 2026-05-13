// Debug functions

extern fn debug_hex(hex_int: usize) AssemblyString;
extern fn debug_wait() void;

// Extern Structs
const AssemblyString = extern struct {
  ptr: [*]const u8,
  len: usize
};


// Functions 
// Convert to hex function
pub fn convert_hex(hex_int: usize) []const u8 {
  const string: AssemblyString = debug_hex(hex_int); 

  return string.ptr[0..string.len];
}

// Wait kernel function
pub fn kernel_wait() noreturn {
  while (true) {
    debug_wait();
  }
}
