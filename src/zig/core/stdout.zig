// Write in STDout
// Imports
const arc = @import("archive.zig");

// Extern Functions in Assembly
extern fn vga_buffer_write(str_ptr: [*]const u8, str_len: usize) void;              // VGA Buffer 
extern fn vga_buffer_scroll_bellow() void;
extern fn vga_buffer_scroll_above() void;
extern fn vga_buffer_scroll_up() void;
extern fn vga_buffer_scroll_down() void;
extern fn com_serial_write(str_ptr: [*]const u8, str_len: usize) void;              // COM Serial 


// Write function
pub fn write(string: []const u8) void {
  if (arc.isCOM_OUTPUT) {
    com_serial_write(string.ptr, string.len);
  }
  else {
    vga_buffer_write(string.ptr, string.len);
  }
}

// Serial function
pub fn serial(string: []const u8) void {
  com_serial_write(string.ptr, string.len);
}

// Scroll Bellow function
pub fn scroll_bellow() void {
  vga_buffer_scroll_bellow();
}

// Scroll Above function
pub fn scroll_above() void {
  vga_buffer_scroll_above();
}

// Scroll Up function
pub fn scroll_up() void {
  vga_buffer_scroll_up();
}

// Scroll Down function
pub fn scroll_down() void {
  vga_buffer_scroll_down();
}

