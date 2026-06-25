# tinyELF

Minimal Linux ELF experiments in x86 assembly.

This repository contains an extremely small implementation of **Langton's Ant** as a hand-crafted ELF executable.

The goal is not performance or usability, but exploring how far an x86 Linux program can be compressed by abusing ELF structure, instruction side effects, and binary layout overlap.

## Features

* Pure x86 assembly (32-bit Linux)
* No libc, no runtime
* Hand-written ELF header
* Direct Linux `int 0x80` syscalls
* ASCII terminal animation
* Simulates Langton's Ant for 10500 steps until the highway pattern appears

## Files

### `ant.asm`

Size: **87 bytes**

A more portable version.

Features:

* Works on terminals wider than the required display size
* Uses ANSI escape sequences to reposition the cursor
* Clears/redraws the screen during animation

Requirements:

* 32-bit Linux execution environment
* Terminal with ANSI escape support

---

### `ant_min.asm`

Size: **76 bytes**

The smallest version.

Trade-offs:

* Assumes an 80-column terminal
* Does not output ANSI cursor-control sequences
* Relies on terminal scrolling behavior for animation

This version prioritizes minimum executable size over portability.

## Build

Requires NASM:

```bash
nasm -f bin -o ant ant.asm
chmod +x ant

./ant
```

For the minimal version:

```bash
nasm -f bin -o ant_min ant_min.asm
chmod +x ant_min

./ant_min
```

## Technical notes

The executable is not linked normally.

The ELF file is constructed manually:

* ELF header fields are overlapped with executable instructions
* Program header fields are reused as data when possible
* Unused ELF fields become storage for code
* CPU flags and instruction side effects are reused to avoid extra instructions

The program uses only the Linux kernel interface:

```
eax = syscall number
ebx = file descriptor
ecx = buffer
edx = length

int 0x80
```

No external dependencies are required.

## Why Langton's Ant?

Langton's Ant is a simple cellular automaton:

1. On a white cell, turn right and flip the cell
2. On a black cell, turn left and flip the cell
3. Move forward

Despite simple rules, after around 10000 steps the ant creates a repeating highway pattern.

This makes it a good target for extreme size optimization:

* requires a grid
* requires state
* requires continuous output
* still has a visually recognizable result

## Size optimization techniques

Some techniques used:

* ELF header / program header overlap
* Reusing immediate values as ELF fields
* Avoiding initialization when possible
* Using stack or loader-provided memory
* Using instruction side effects as state storage
* Exploiting x86 encoding details

## Limitations

This is a sizecoding experiment, not a general-purpose program.

The executable depends on:

* 32-bit x86 Linux compatibility
* expected terminal behavior
* specific ELF loader behavior

## License

GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007
