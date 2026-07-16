// Write in STDout
// Imports
const arc = @import("archive.zig");

// Extern Functions in Assembly
extern fn vga_buffer_print([*]const u8, usize) void;                               // VGA Buffer 
extern fn vga_buffer_scroll_bellow() void;
extern fn vga_buffer_scroll_above() void;
extern fn vga_buffer_scroll_up() void;
extern fn vga_buffer_scroll_down() void;
extern fn vga_buffer_clear() void;
extern fn vga_controller_max_lines() void;                                          // VGA Controller
extern fn vga_controller_cursor_update(u16, u16) void;
extern fn com_serial_print([*]const u8, usize) void;                                // COM Serial 


// Write function
pub fn print(string: []const u8) void {
  if (arc.isCOM_OUTPUT) {
    com_serial_print(string.ptr, string.len);
  }
  else {
    vga_buffer_print(string.ptr, string.len);
  }
}

// Serial function
pub fn serial(string: []const u8) void {
  com_serial_print(string.ptr, string.len);
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

// Clean Screen function 
pub fn clear() void {
  vga_buffer_clear();
}

// Update Max Lines function
pub fn max_lines() void {
  vga_controller_max_lines();
}

// Update the current Cursor Location
pub fn update_cursor(collums: u16, lines: u16) void {
  vga_controller_cursor_update(collums, lines);
}
