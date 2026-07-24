
extern fn com_serial_print(str_ptr: [*]const u8, str_len: usize) void;


// Default Boolean Constants
pub const isCOM_OUTPUT: bool = false;


// Public Constants in the Kernel
pub const WELCOME_STR: []const u8 =
    \\=========================================----------------
    \\|  Welcome! You're in Hasuka System.    | / Version: \ |
    \\|       The Sky is your Dreams!         | \ 0.1.1    / |
    \\=========================================----------------
    \\             
    \\
;


