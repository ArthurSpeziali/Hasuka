// Debug functions

extern fn debug_hex(hex_int: usize) AssemblyString;

// Extern Structs
const AssemblyString = extern struct {
  ptr: [*]const u8,
  len: usize
};

// Functions 

// Debug hex function
pub export fn debug(hex_int: usize) AssemblyString {
  return debug_hex(hex_int);
}


