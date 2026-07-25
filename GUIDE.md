
# Kernel / Directory Map & Calling Conventions

This guide explains the repository layout, where execution starts, what each module is responsible for, and how the key assembly/Zig functions fit together.

---

## Repository Layout (What each folder does)

### `src/zig/kernel_main.zig`
- **Role:** This is the **main kernel entry point written in Zig**.
- **Responsibility:** Orchestrates the kernel “human interface” layer and dispatches functionality using Zig conveniences:
  - switch/case dispatch on **strings** and/or **arrays**
  - simple function calling wrappers around assembly routines
- **Important note:** The kernel is still **Assembly-first**; Zig is used mainly to simplify calling and control flow.

### `src/zig/core/*`
- **Role:** Intermediate **interface modules** used by `kernel_main.zig`.
- **Responsibility:** Provide “kernel interface” building blocks (ex: parsing/dispatch logic, glue logic, TUI helpers, command routing).
- **How to think of it:** These modules are the “middle layer” between human-facing logic and the low-level assembly subsystems.

### `src/zig/drivers/*`
- **Role:** “Layout unique” driver layer.
- **Responsibility:**
  - Provides a **small set of drivers** implemented in a layout that doesn’t have parallel Assembly versions.
  - May still contain **intermediate functions** that call into Assembly routines.
- **How to think of it:** Zig-side organization for higher-level driver logic; Assembly holds the low-level primitives.

---

### `src/asm/display/*`
Low-level display and output primitives built for the kernel.

Typical responsibilities include:
- Writing to VGA text memory
- Serial debugging output
- Scrolling, cursor breakpoint behavior, and clear operations

#### `vga_buffer_print`
Prints a string into the VGA text buffer and supports “cursor breakpoints”.

#### `vga_buffer_scroll_(up/down)`
Scrolls the VGA text area while maintaining a small history model.

#### `com_serial_print`
Prints the same style string data to serial for debugging, without cursor breakpoint execution.

---

### `src/asm/interrupts/*`
- **Role:** Interrupt handling setup.
- **Responsibilities:**
  - Activate IRQ routing
  - Provide ISR stub entry points
  - Integrate with kernel IRQ/ISR handler dispatch (implemented progressively in `kernel_main.zig`)

---

### `src/asm/io/*`
- **Role:** Input/output drivers.
- **Responsibility:** Currently includes the **keyboard driver** and supporting utilities.

---

### `src/asm/boot/*`
- **Role:** Pre-kernel code.
- **Responsibility:** Runs **after GRUB / bootloader handoff and before the kernel proper** begins execution.
- **Typical tasks here:**
  - environment setup
  - initial memory/segment-related setup
  - jumping to the kernel entry

---

### `src/asm/debug/*`
- **Role:** Small debug helpers.
- **Responsibility:** Convert integers/UTF-8 and provide human-readable debug output helpers to pair with serial printing.

---

## Build/Run Stack (How the system is built & tested)

- **Bootloader:** GRUB (legacy/multiboot setup)
- **ISO creation:** `xorriso`
- **Virtualization:** `qemu-system-x86_64`
- **Architecture:** x86_64, **Legacy PIC only** for now (no APIC yet)
- **Build references:** OSDev Notes as the baseline for implementation patterns

---

## Calling & Register Conventions (My kernel ABI style)

### “All registers are saved” policy
Hasuka's stated that **every function saves registers both ways**:
- **Caller-saved and callee-saved combined:** both caller and callee preserve registers.
- Result: it is safe against accidental clobbering when calling across many boundaries.

### Practical implication for assembly
- **RDI** as “first input”
- **RSI** as “second input / pointer+length style”
- **RAX** as “return pointer or return value”
- **RDX** as “return length” (commonly used for buffers/strings)
- ... (**Other registers**) 
- **RBX** as the only register without any purpose, used ONLY for temporary data and Magic numbers, must not contain return data that will be used directly or that is maintained between function calls.


This is visible in the debug helpers, VGA/serial print, OUT/IN Porst managers and other like functions.

---

## Cursor Breakpoints Architecture (Text interface core)

Hasuka's text interface uses a custom mechanism: **“cursor breakpoints”**.

### Breakpoint ranges
- **0x00–0x1F** (0..31): reserved for **cursor control breakpoints** embedded into strings
- **0x80–0xFF**: reserved for “other keys / characters not pre-bound”

### Maximum breakpoints
- Up to **255 breakpoint codes** supported (practical limit based on encoding space).

### Semantics (examples)
These are interpreted by the VGA keyfilter / VGA printing system depending on where you apply them:

- **0x0**: terminates the string (system universal)
- **0x08**: Backspace — removes the last character
- **0x0E**: Down Arrow — example behavior includes clearing line-before-cursor and reflow rules
- **0x0A**: Enter — usually inserts newline 

### Cursor state registers
Cursor position is managed using registers stored in `data.asm`:
- **R9**: manages the active **Collum** in **coordinate system** (Cursor position *X* in VGA Buffer in current line)
- **R10**: controls the active **Line** in **coordinate system** (Cursor position *Y* in VGA Buffer in current collum)

### Text mode constraints
- Default VGA framebuffer: **80x25**
- Only **25 visible lines** by default; thus scrolling and history are needed.

---

## Framebuffer & Scroll Behavior

### Default mode
- VGA text buffer is the standard framebuffer equivalent:
  - 80 columns
  - 25 rows

### Scrolling with history
- `vga_buffer_scroll_up` and `vga_buffer_scroll_down` move the visible window.
- Each direction stores a **small history model**, so the cursor behavior and line transitions remain consistent.

---

## IRQ / ISR Handling Model (Progressive bring-up)

### Where IRQ/ISR lives
- `kernel_main.zig` contains:
  - IRQ handlers
  - ISR stubs dispatch wiring

### Current development stage
- Hasuka's implemented only the **keyboard path** so far.
- For each ISR stub that is not fully implemented:
  - it prints the stub identity to **serial**
  - then halts the kernel using hibernation (for now)

### Interrupt mode
- PIC is used (Legacy PIC)
- APIC not implemented yet

---

# Function Reference (What each function does, parameters, outputs, and entry points)

## `vga_buffer_print`  
**File:** `src/asm/display/vga_buffer_print.asm`  
**Purpose:** Write a string to the VGA text buffer while interpreting **cursor breakpoints**.

- **Inputs:**
  - **RDI:** pointer to a string (byte array)
  - **RSI:** size/length of that string
- **Behavior:**
  - Iterates through bytes
  - If it encounters breakpoint control codes, it adjusts cursor / performs actions:
    - cursor movement
    - backspace deletion
    - newline behavior
    - line-clear behaviors, etc.
  - Uses cursor state stored in `data.asm` (R9/R10-based system)
- **Return:** (None)

**Where it’s used:**
- Kernel human-interface output on VGA
- Any function that wants “real UI behavior” (not just raw output)

---

## `vga_buffer_scroll_up` / `vga_buffer_scroll_down`
**File:** `src/asm/display/vga_buffer_scroll.asm`  
**Purpose:** Move the visible VGA text window.

- **Inputs:** (None)
- **Behavior:**
  - Shifts framebuffer content up or down
  - Maintains a “history” region so that scrolling is consistent with your cursor model.
  - **Return:** (None)
---

## `com_serial_print`
**File:** `src/asm/display/com_serial_print.asm`  
**Purpose:** Print a string to the serial console for debugging.

- **Inputs:**
  - Same calling convention style as VGA:
    - **RDI:** pointer to string
    - **RSI:** length
- **Behavior:**
  - Prints characters to serial
- **Key difference from VGA:**
  - **Does NOT execute cursor breakpoints**
- **Return:** (None)

**Use case:**
- Logging in IRQ/ISR stubs
- Early kernel debugging
- Capturing logs via QEMU serial redirection

---

## `debug_hex`
**File:** `src/asm/debug_hex.asm`  
**Purpose:** Convert an integer into a **hex string** for debugging.

- **Inputs:**
  - **RDI:** integer value to convert
- **Returns:**
  - **RAX:** pointer to hex string (buffer)
  - **RDX:** size/length of the hex string
- **Behavior:**
  - Produces a hexadecimal textual representation
  - Designed to be used like:
    - call `debug_hex`
    - then call `com_serial_print` with `(RDI = RAX pointer, RSI = RDX length)`

**Where it’s used:**
- Serial debugging of numeric state (registers, counters, return codes, addresses)

---

## `debug_utf8`
**File:** `src/asm/debug_utf8.asm`  
**Purpose:** Convert a UTF-8 string into **CP437** encoding (VGA default code page).

- **Inputs:**
  - **RDI:** pointer to UTF-8 string
  - **RSI:** length (or string size) in bytes
- **Returns:**
  - **RAX:** pointer to converted CP437 byte array
  - **RDX:** length of converted array
- **Behavior:**
  - Converts UTF-8 bytes into CP437-compatible codes
  - Returns the converted buffer for printing

**Where it’s used:**
- When printing “human text” in environments that provide UTF-8 strings
- Feeding the CP437 bytes into VGA printing

---

## `$VAR`  
**File:** `src/asm/data.asm`  
**Purpose:** Central storage for globals shared by multiple assembly modules.

- **Role:**
  - Creates shared memory regions in `.data` or `.bss`
- **Access model:**
  - Many assembly functions read/write these globals to coordinate state.
- **Examples from your architecture:**
  - cursor-related state (R9/R10 system components)
  - VGA subsystem shared pointers/buffers
  - any other cross-module runtime variables

---

## `keyboard_driver_pick_key`
**File:** `src/asm/io/keyboard_driver_utils.asm`  
**Purpose:** Read the most recently pressed key from the keyboard IRQ path and pass it through keyfilter logic.

- **Inputs:**
  - **RDI:** keyfilter ID
    - **0:** keyfilter is disabled
    - **1:** **VGA Keyfilter**
      - prints directly from the VGA text buffer model
- **Precondition:**
  - You stated this is used when receiving **IRQ 33 (Keyboard)**.
  - The IRQ handler should ensure the “last key pressed” raw code is already available (likely stored via `data.asm` globals).
- **Behavior:**
  1. Take the last key code
  2. Translate to ASCII (your translation step)
  3. Send it to the keyfilter pipeline:
     - a filter can:
       - **execute and terminate**
       - or **pass to the next keyfilter**
- **Return:** (None)

---

## Keyflow Example (How pieces connect)

A typical flow during “keyboard input into UI” looks like this:

1. **IRQ 33 fires** (keyboard)
2. `kernel_main.zig` dispatches to the corresponding IRQ handler
3. The IRQ handler (or common stub) ensures the last key code is stored/available
4. `keyboard_driver_pick_key` is called with a **keyfilter ID**
5. If VGA keyfilter is selected:
   - it writes into the VGA buffer using your cursor breakpoint rules
   - cursor position updates are reflected via `data.asm` state

For debug-only observation, serial logging uses:
- `com_serial_print`
- optionally `debug_hex` and `debug_utf8` to turn internal state into readable text.

---

## Notes on What to Implement Next (within this guide’s scope)

This guide is set up so new functions can be documented using the same template:
- File
- Purpose
- Inputs (RDI/RSI…)
- Returns (RAX/RDX…)
- Behavior & side effects
- Key consumers (which Zig module or IRQ path uses it)
