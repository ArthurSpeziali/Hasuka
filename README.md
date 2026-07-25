# HasukaOS, What is this? Is it to eat?

Hasuka is a small x86_64 Assembly-first kernel with a human-interface layer, where the low-level core runs in Assembly and Zig is used only for orchestration (e.g., dispatching and switch/case routing) without any C runtime. It focuses on a minimal, text-based system built around VGA text output and a custom “cursor breakpoints” mechanism, with serial debug helpers and a progressive interrupt bring-up using the legacy PIC (keyboard first). Advanced features like graphics, full filesystem/ disk writing, floating-point, complex protocols, extensive driver modules, portability to i386, and alternative bootloaders are deferred to keep it small and suitable for running inside a VM.

## Name: acronym, meaning, and pronunciation

The name is **“Hasuka”**, pronounced like:

***HAH-soo-kah***

 This is an acronym for: **H**askell **A**dvanced **S**ystem **U**nix **K**ernel **A**rchitecture
This doesn't make sense, but I wanted it to match [Asuka's](https://wiki.evageeks.org/Asuka_Langley_Soryu) character

### Why “H” (and why Haskell is mentioned)
The leading **“H”** comes from the original idea that this kernel would live at the intersection of **Assembly + Haskell**.
That direction got postponed: the project is focusing on a **pure Assembly kernel now**, and reserving deeper “Haskell-aligned” integration for a future stage (e.g., when the larger OS system design matures).

### Future rename
When this kernel is complete, it will likely be renamed to **AdamsKernel**.

### Etimology inspiration
The word choices and naming style are inspired directly by **Evangelion**.

---

## Goals (priority)

These are the things planned to come first (or be included early):

- **Syscall interface**: 
  - A syscall table different from Linux and other OSes
- **Own text-mode framebuffer**: 
  - Simple “framebuffer in text mode” approach
- **TUI help tool**: 
  - To create simple interfaces (focus on developer ergonomics)
- **User space programming inside the kernel**: 
  - Develop your own assembly scripts
- **Text editor inspired by VIM**: *(NOT promised)*
- **8-bit audio**: *(NOT promised)*
- **Custom network protocol**: *(NOT promised)*

---

## Non-goals (intentionally left aside)

What will be avoided or deferred to keep the kernel small and simple:

- **Graphics / GUI in general**:
  - Only text mode
- **Hard disk writing / full FS management**
  - Editing is RAM-only
- **Floating point numbers**
  - “Too broken” for my preferences, prefer other methods
- **User management / permissions**:
  - Too complex to a non-filesystem Kernel
- **Per-device driver modules**
  - Designed to run in a **VM**
- **HTTP** and anything “complex by default”:
  - I will create some simpler versions
- **Any plan to change language**: 
  - Staying on Assembly is a core constraint
- **Port to i386**:
  - I would have to change each kernel instruction, which is unfeasible.
- **Different bootloader than GRUB**
  - Comfort zone
---

## Building

```sh
$ make
```

The ISO will be created at:

- `iso/hasuka.iso`

---

## Running in QEMU (VM)

ℹ️ The ISO is less than 50MB :

```sh
$ qemu-system-x86-64 -cdrom iso/hasuka.iso
```

---

## Running on real hardware (write to USB)

⚠ Replace `/dev/sdX` with the correct device for your USB stick:

```sh
$ sudo dd if=iso/hasuka.iso of=/dev/sdX oflags=sync bs=4M status=progress
```

---
