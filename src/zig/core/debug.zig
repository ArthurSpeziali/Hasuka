// Debug functions

extern fn debug_hex(usize) AssemblyString;
extern fn debug_wait() void;
extern fn debug_utf8([*]const u8, usize) AssemblyString;

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

// Convert UTF8 to CP437 
pub fn convert_utf8(string: []const u8) []const u8 {
  const format_string: AssemblyString = debug_utf8(string.ptr, string.len);

  return format_string.ptr[0..format_string.len];
}
