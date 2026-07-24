// Keyboard Drivers

// Extern Functions 
extern fn keyboard_driver_get_code() u8;
extern fn keyboard_driver_get_ascii(driver_code: u8) u8;
extern fn keyboard_driver_pick_key(keyfilter_id: u8) void;

// Extern Structs
const AssemblyReturn = extern struct {
  ascii: u8,
  released: u8,
};


// Functions 
// Get code from Keyboard
pub fn get_code() u8 {
  return keyboard_driver_get_code();
}

// Get ASCII code from a Keyboard Driver code 
pub fn get_ascii(driver_code: u8) u8 {
  return keyboard_driver_get_ascii(driver_code);
}

// Pick a key and pass to Key FIlter 
pub fn pick_key(keyfilter_id: u8) void {
  keyboard_driver_pick_key(keyfilter_id);
}


// Export functions
// Keyboard Layout for byte entry (One number)
export fn keyboard_layout_byte(code: u8) AssemblyReturn {
  // Keyboard Code => .{ASCII Code, Released?}
  return switch (code) {
    // Esc 
    0x01 => AssemblyReturn{.ascii = 0x87, .released = 0},
    0x81 => AssemblyReturn{.ascii = 0x31, .released = 1},
    // 1
    0x02 => AssemblyReturn{.ascii = 0x31, .released = 0},
    0x82 => AssemblyReturn{.ascii = 0x31, .released = 1},
    // 2
    0x03 => AssemblyReturn{.ascii = 0x32, .released = 0},
    0x83 => AssemblyReturn{.ascii = 0x32, .released = 1},
    // 3
    0x04 => AssemblyReturn{.ascii = 0x33, .released = 0},
    0x84 => AssemblyReturn{.ascii = 0x33, .released = 1},
    // 4
    0x05 => AssemblyReturn{.ascii = 0x34, .released = 0},
    0x85 => AssemblyReturn{.ascii = 0x34, .released = 1},
    // 5
    0x06 => AssemblyReturn{.ascii = 0x35, .released = 0},
    0x86 => AssemblyReturn{.ascii = 0x35, .released = 1},
    // 6
    0x07 => AssemblyReturn{.ascii = 0x36, .released = 0},
    0x87 => AssemblyReturn{.ascii = 0x36, .released = 1},
    // 7
    0x08 => AssemblyReturn{.ascii = 0x37, .released = 0},
    0x88 => AssemblyReturn{.ascii = 0x37, .released = 1},
    // 8
    0x09 => AssemblyReturn{.ascii = 0x38, .released = 0},
    0x89 => AssemblyReturn{.ascii = 0x38, .released = 1},
    // 9
    0x0A => AssemblyReturn{.ascii = 0x39, .released = 0},
    0x8A => AssemblyReturn{.ascii = 0x39, .released = 1},
    // 0
    0x0B => AssemblyReturn{.ascii = 0x30, .released = 0},
    0x8B => AssemblyReturn{.ascii = 0x30, .released = 1},
    // -
    0x0C => AssemblyReturn{.ascii = 0x2D, .released = 0},
    0x8C => AssemblyReturn{.ascii = 0x2D, .released = 1},
    // +
    0x0D => AssemblyReturn{.ascii = 0x2B, .released = 0},
    0x8D => AssemblyReturn{.ascii = 0x2B, .released = 1},
    // "
    0x29 => AssemblyReturn{.ascii = 0x22, .released = 0},
    0xA9 => AssemblyReturn{.ascii = 0x22, .released = 1},
    // q
    0x10 => AssemblyReturn{.ascii = 0x71, .released = 0},
    0x90 => AssemblyReturn{.ascii = 0x71, .released = 1},
    // w
    0x11 => AssemblyReturn{.ascii = 0x77, .released = 0},
    0x91 => AssemblyReturn{.ascii = 0x77, .released = 1},
    // e
    0x12 => AssemblyReturn{.ascii = 0x65, .released = 0},
    0x92 => AssemblyReturn{.ascii = 0x65, .released = 1},
    // r
    0x13 => AssemblyReturn{.ascii = 0x72, .released = 0},
    0x93 => AssemblyReturn{.ascii = 0x72, .released = 1},
    // t
    0x14 => AssemblyReturn{.ascii = 0x74, .released = 0},
    0x94 => AssemblyReturn{.ascii = 0x74, .released = 1},
    // y
    0x15 => AssemblyReturn{.ascii = 0x79, .released = 0},
    0x95 => AssemblyReturn{.ascii = 0x79, .released = 1},
    // u
    0x16 => AssemblyReturn{.ascii = 0x75, .released = 0},
    0x96 => AssemblyReturn{.ascii = 0x75, .released = 1},
    // i
    0x17 => AssemblyReturn{.ascii = 0x69, .released = 0},
    0x97 => AssemblyReturn{.ascii = 0x69, .released = 1},
    // o
    0x18 => AssemblyReturn{.ascii = 0x6F, .released = 0},
    0x98 => AssemblyReturn{.ascii = 0x6F, .released = 1},
    // p
    0x19 => AssemblyReturn{.ascii = 0x70, .released = 0},
    0x99 => AssemblyReturn{.ascii = 0x70, .released = 1},
    // [
    0x1B => AssemblyReturn{.ascii = 0x5B, .released = 0},
    0x9B => AssemblyReturn{.ascii = 0x5B, .released = 1},
    // ]
    0x2B => AssemblyReturn{.ascii = 0x5D, .released = 0},
    0xAB => AssemblyReturn{.ascii = 0x5D, .released = 1},
    // a
    0x1E => AssemblyReturn{.ascii = 0x61, .released = 0},
    0x9E => AssemblyReturn{.ascii = 0x61, .released = 1},
    // s
    0x1F => AssemblyReturn{.ascii = 0x73, .released = 0},
    0x9F => AssemblyReturn{.ascii = 0x73, .released = 1},
    // d
    0x20 => AssemblyReturn{.ascii = 0x64, .released = 0},
    0xA0 => AssemblyReturn{.ascii = 0x64, .released = 1},
    // f
    0x21 => AssemblyReturn{.ascii = 0x66, .released = 0},
    0xA1 => AssemblyReturn{.ascii = 0x66, .released = 1},
    // g
    0x22 => AssemblyReturn{.ascii = 0x67, .released = 0},
    0xA2 => AssemblyReturn{.ascii = 0x67, .released = 1},
    // h
    0x23 => AssemblyReturn{.ascii = 0x68, .released = 0},
    0xA3 => AssemblyReturn{.ascii = 0x68, .released = 1},
    // j
    0x24 => AssemblyReturn{.ascii = 0x6A, .released = 0},
    0xA4 => AssemblyReturn{.ascii = 0x6A, .released = 1},
    // k
    0x25 => AssemblyReturn{.ascii = 0x6B, .released = 0},
    0xA5 => AssemblyReturn{.ascii = 0x6B, .released = 1},
    // l
    0x26 => AssemblyReturn{.ascii = 0x6C, .released = 0},
    0xA6 => AssemblyReturn{.ascii = 0x6C, .released = 1},
    // z
    0x2C => AssemblyReturn{.ascii = 0x7A, .released = 0},
    0xAC => AssemblyReturn{.ascii = 0x7A, .released = 1},
    // x
    0x2D => AssemblyReturn{.ascii = 0x78, .released = 0},
    0xAD => AssemblyReturn{.ascii = 0x78, .released = 1},
    // c
    0x2E => AssemblyReturn{.ascii = 0x63, .released = 0},
    0xAE => AssemblyReturn{.ascii = 0x63, .released = 1},
    // v
    0x2F => AssemblyReturn{.ascii = 0x76, .released = 0},
    0xAF => AssemblyReturn{.ascii = 0x76, .released = 1},
    // b
    0x30 => AssemblyReturn{.ascii = 0x62, .released = 0},
    0xB0 => AssemblyReturn{.ascii = 0x62, .released = 1},
    // n
    0x31 => AssemblyReturn{.ascii = 0x6E, .released = 0},
    0xB1 => AssemblyReturn{.ascii = 0x6E, .released = 1},
    // m
    0x32 => AssemblyReturn{.ascii = 0x6D, .released = 0},
    0xB2 => AssemblyReturn{.ascii = 0x6D, .released = 1},
    // ,
    0x33 => AssemblyReturn{.ascii = 0x2C, .released = 0},
    0xB3 => AssemblyReturn{.ascii = 0x2C, .released = 1},
    // .
    0x34 => AssemblyReturn{.ascii = 0x2E, .released = 0},
    0xB4 => AssemblyReturn{.ascii = 0x2E, .released = 1},
    // ;
    0x35 => AssemblyReturn{.ascii = 0x3B, .released = 0},
    0xB5 => AssemblyReturn{.ascii = 0x3B, .released = 1},
    // /
    0x73 => AssemblyReturn{.ascii = 0x2F, .released = 0},
    0xF3 => AssemblyReturn{.ascii = 0x2F, .released = 1},
    // \
    0x56 => AssemblyReturn{.ascii = 0x5C, .released = 0},
    0xD6 => AssemblyReturn{.ascii = 0x5C, .released = 1},
    // F1
    0x3B => AssemblyReturn{.ascii = 0x87, .released = 0},
    0xBB => AssemblyReturn{.ascii = 0x87, .released = 1},
    // F2
    0x3C => AssemblyReturn{.ascii = 0x87, .released = 0},
    0xBC => AssemblyReturn{.ascii = 0x87, .released = 1},
    // F3
    0x3D => AssemblyReturn{.ascii = 0x87, .released = 0},
    0xBD => AssemblyReturn{.ascii = 0x87, .released = 1},
    // F4
    0x3E => AssemblyReturn{.ascii = 0x87, .released = 0},
    0xBE => AssemblyReturn{.ascii = 0x00, .released = 1},
    // F5
    0x3F => AssemblyReturn{.ascii = 0x87, .released = 0},
    0xBF => AssemblyReturn{.ascii = 0x87, .released = 1},
    // F6
    0x40 => AssemblyReturn{.ascii = 0x87, .released = 0},
    0xC0 => AssemblyReturn{.ascii = 0x87, .released = 1},
    // F7
    0x41 => AssemblyReturn{.ascii = 0x87, .released = 0},
    0xC1 => AssemblyReturn{.ascii = 0x87, .released = 1},
    // F8
    0x42 => AssemblyReturn{.ascii = 0x87, .released = 0},
    0xC2 => AssemblyReturn{.ascii = 0x87, .released = 1},
    // F9
    0x43 => AssemblyReturn{.ascii = 0x87, .released = 0},
    0xC3 => AssemblyReturn{.ascii = 0x87, .released = 1},
    // F10
    0x44 => AssemblyReturn{.ascii = 0x87, .released = 0},
    0xC4 => AssemblyReturn{.ascii = 0x87, .released = 1},
    // F11
    0x57 => AssemblyReturn{.ascii = 0x87, .released = 0},
    0xD7 => AssemblyReturn{.ascii = 0x87, .released = 1},
    // F12
    0x58 => AssemblyReturn{.ascii = 0x87, .released = 0},
    0xD8 => AssemblyReturn{.ascii = 0x87, .released = 1},
    // Backspace 
    0x0E => AssemblyReturn{.ascii = 0x08, .released = 0},
    0x8E => AssemblyReturn{.ascii = 0x08, .released = 1}, 
    // Tab 
    0x0F => AssemblyReturn{.ascii = 0x87, .released = 0},
    0x8F => AssemblyReturn{.ascii = 0x87, .released = 1},
    // Return 
    0x1C => AssemblyReturn{.ascii = 0x0A, .released = 0},
    0x9C => AssemblyReturn{.ascii = 0x0A, .released = 1},
    // Space 
    0x39 => AssemblyReturn{.ascii = 0x20, .released = 0},
    0xB9 => AssemblyReturn{.ascii = 0x20, .released = 1},
    //
    else => AssemblyReturn{.ascii = 0x00, .released = 0},
  };
}


// Keyboard Layout for word entry (Two numbers)
export fn keyboard_layout_word(code: u8) AssemblyReturn {
  // Keyboard Code => .{ASCII Code, Released?}
  return switch (code) {
    // Home 
    0x47 => AssemblyReturn{.ascii = 0x0D, .released = 0},
    0xC7 => AssemblyReturn{.ascii = 0x0D, .released = 1},
    // End
    0x4F => AssemblyReturn{.ascii = 0x0C, .released = 0},
    0xCF => AssemblyReturn{.ascii = 0x0C, .released = 1},
    // Up 
    0x48 => AssemblyReturn{.ascii = 0x0F, .released = 0},
    0xC8 => AssemblyReturn{.ascii = 0x0F, .released = 1},
    // Down 
    0x50 => AssemblyReturn{.ascii = 0x0E, .released = 0},
    0xD0 => AssemblyReturn{.ascii = 0x0E, .released = 1},
    // Left 
    0x4B => AssemblyReturn{.ascii = 0x07, .released = 0},
    0xCB => AssemblyReturn{.ascii = 0x07, .released = 1},
    // Right 
    0x4D => AssemblyReturn{.ascii = 0x06, .released = 0},
    0xCD => AssemblyReturn{.ascii = 0x06, .released = 1}, 
    // Delete 
    0x53 => AssemblyReturn{.ascii = 0x09, .released = 0},
    0xD3 => AssemblyReturn{.ascii = 0x09, .released = 1},
    // 
    else => AssemblyReturn{.ascii = 0x00, .released = 0}
  }; 
}
