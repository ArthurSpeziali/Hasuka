// Keyboard Drivers

// Extern Functions 
extern fn driver_keyboard_get_code() u8;

// Functions 
// Get code from Keyboard
pub fn get_code() u8 {
  return driver_keyboard_get_code();
}

