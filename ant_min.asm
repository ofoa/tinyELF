;;ant_min.asm: Copyright (C) 2026 ofoa
;;GNU GENERAL PUBLIC LICENSE
;;Version 3, 29 June 2007
;;
;;An 76 bytes x86 tiny ELF Langton's Ant Simulator on Linux
;;
;;You need a terminal with a width of 80 and a height of preferably 48 and:
;;nasm -f bin ant_min.asm -o ant_min && chmod +x ant_min && ./ant_min
;;

BITS 32

%define W 80
%define H 48

;;To simulate Langton's ant until the highway appears, at least 45 rows are needed.
;;80 * 48 = 3840 = 0xf00, so we can use "mov ch, 0xf" to set the number of characters.

%define WHITE_CHAR 'M'
%define BLACK_CHAR '_'

;;These two characters cannot be chosen arbitrarily. First, the lower 2 bits of the binary of these two chars must be
;;11 and 01 respectively for the "add al, [edi]" & movsx instructions; second, their binary must have the same parity
;;for the jnp/jp instruction; finally, the ascii of initial character will be excute as a instraction, so it cannot
;;have side effects.

        org     0x12b60000

        db      0x7F, "ELF"                                     ;e_ident

AA:
        sub     edi, esi
        add     al, [edi]

        push    eax
        mov     al, 4
exit:
        int     0x80
        pop     eax

        jmp     main_loop

        dw      0x2                                             ;e_type = 2
        dw      0x3                                             ;e_type = 3

_start:
        inc     ebx                                             ;e_version = (garbage)
        mov     ch, 0xf
        mov     eax, _start                                     ;e_entry = 0x12b60014
        dd      0x2c                                            ;e_phoff = 0x2c
        db      0x8d, 0x78                                      ;e_shoff = (garbage)
fill_char:
        push    0xb0ff5001                                      ;e_flags = (garbage)
        db      WHITE_CHAR

;;The hexadecimal of this part are 2c 00 00 00 8d 78 68 01 50 ff b0 4d,
;;00 2c -> "sub al, 0", "sub al, 0", no effect;
;;00 00 -> "add [eax], al", no effect;
;;8d 78 68 -> "lea edi, [eax + 0x68]";
;;01 50 ff -> "add [eax - 1], edx", no effect;
;;b0 4d -> mov al, 0x4d.
;;When "loop fill_char" happens, it looks like:
;;68 01 50 ff b0 -> "push 0xb0ff5001", push some direction tables onto the stack,
;;b0, ff, 50, 01 are respectively represent -80, -1, +80, +1;
;;4d -> "dec ebp", no effect.

        stosb                                                   ;e_ehsize = (garbage)
        mov     edx, 0x10020                                    ;e_phentsize = 0x20
                                        ;p_type = 1             ;e_phnum = 1
        dw      0                                               ;e_shentsize = 0
        dw      0                       ;p_offset = 0           ;e_shnum = 0
        dw      0                                               ;e_shstrndx = 0
        dw      0                       ;p_vaddr = 0x12b60000

;;"dw 0" means "add [eax], al". The loop will repeat 0xf00 times, so "add [eax], al" will repeat 0x3c00 times. When
;;executing this instruction, eax is 0x12b6004d, al is 0x4d, so the byte at [eax] in memory is increased by 0x3c00 *
;;0x4d in total, which is equivalent to nothing happening.

        mov     dh, WHITE_CHAR ^ BLACK_CHAR
        loop    fill_char               ;p_paddr = (garbage)

        sub     edi, W * H / 2 - 30     ;p_filesz = 0x0762
        xchg    eax, ecx                ;p_memsz = 0x7b373091

;;After this xchg, ecx will point to the beginning of the buffer, and eax will be 0.

main_loop:
        xor     [edi], dh
        jnp     exit                    ;p_flags = 0x34be0fc6 = 0x6

;;The xor instruction implements the conversion between WHITE_CHAR and BLACK_CHAR.
;;The jnp instruction jumps based on the parity flag result of the xor instruction; in fact, it is actually used to
;;detect overflow.
;;When an overflow occurs, the ant's position is located in the code segment. If the parity flag of that byte is odd,
;;and the ant's direction (eax) happens to be 1 (the sys call number for exit), the program can magically exit.
;;Fortunately, it works.

        movsx   esi, byte [esp + eax]   ;p_align = (garbage)

;;Thanks to the fact that we previously pushed enough direction tables onto the stack, we will definitely get the
;;correct directional offset here.

        jmp     AA
        db      0

;;The phdr starts at offset 0x2c, and ends at offset 0x4c, so we must pad a byte of 0 here. In another word, the limit
;;of this overlapping method is 76 bytes. If the phdr starts at offset 0x4, according to my test, the size will actuall
;;be larger.
