;;ant.asm: Copyright (C) 2026 ofoa
;;GNU GENERAL PUBLIC LICENSE
;;Version 3, 29 June 2007
;;
;;An 87 bytes x86 tiny ELF Langton's Ant Simulator on Linux
;;
;;You need a terminal that is no smaller than 80*48 and:
;;nasm -f bin ant.asm -o ant && chmod +x ant && clear && ./ant
;;

BITS 32

%define W 80
%define H 47

;;To simulate Langton's ant until the highway appears, at least 45 rows are needed.

%define DIRECTION_TABLE 0x74affe4f

%define WHITE_CHAR 'M'
%define BLACK_CHAR '_'

;;These two characters cannot be chosen arbitrarily. First, the lower 2 bits of the binary of these two chars must be
;;11 and 01 respectively for the "add al, [edi]" & movsx instructions; second, their binary must have the same parity
;;for the jnp/jp instruction; finally, the ASCII code of the background character needs to be able to fall near the
;;offset where the push instruction might be located. Considering all the above conditions, these two characters are the
;;pair with the greatest distinguishability that I could find.

;;The underscore character can be changed to a single quote character, which is also nice. However, changing the M
;;character requires adjusting the position of the push instruction.


        org     0xaa0ab000

        db      0x7F, "EL"                                      ;e_ident
AA:
        inc     esi     ;'F'

        push    eax
        mov     al, 4
exit:
        int     0x80
        pop     eax

        xor     [edi], dh
        jnp     short exit

;;The xor instruction implements the conversion between WHITE_CHAR and BLACK_CHAR.
;;The jnp instruction jumps based on the parity flag result of the xor instruction; in fact, it is actually used to
;;detect overflow.
;;When an overflow occurs, the ant's position is located in the code segment. If the parity flag of that byte is odd,
;;and the ant's direction (eax) happens to be 1 (the sys call number for exit), the program can magically exit.
;;Fortunately, it works.

        jmp     short main_loop

        dw      0x2                                             ;e_type = 2
        dw      0x3                                             ;e_machine = 3

_start:
        inc     ebx                                             ;e_version = (garbage)
        mov     dh, BLACK_CHAR ^ WHITE_CHAR

        mov     eax, _start                                     ;e_entry = 0xaa0ab014
        dd      0x2c                                            ;e_phoff = 0x2c

;;"mov eax, _start" provides the address of _start for e_entry and make "add [eax], al" (0x00) not cause SEGFAULT. This
;;can save the space of jmp.
;;2c 00 00 00 are "sub al,0x0" and "add [eax], al", which are harmless.

        lea     edi, [eax + buf - _start]                       ;e_shoff = (garbage)
fill_char:
        mov     cl, W - 1                                       ;e_flags = (garbage)
        mov     al, WHITE_CHAR
        rep     stosb                                           ;e_ehsize = (garbage)

        enter   0x20, 1                                         ;e_phentsize = 0x20
                                        ;p_type = 1             ;e_phnum = 1

;;This enter instruction is only meant to set ELF information, not to create a stack frame.

        add     [eax], al                                       ;e_shentsize = 0
        add     [eax], al               ;p_offset = 0           ;e_shnum = 0
        add     [eax], al                                       ;e_shstrndx = 0
        add     [eax], al               ;p_vaddr = 0xaa0ab000

;;Now, the higher 24 bits of eax are 0xaa0ab0, and al is 'M' or 0x4d, so eax is 0xaa0ab04d, which point to 0x74 in
;;DIRECTION_TABLE. So we actrually let "add [eax], al" (0x00) modify the code to serve as a counter.

;;0x74 + 47(height) * 0x4d(ascii of M) == 0, this is why the program outputs 47 lines.

;;This direction table should originally be 0x01b0ff50, but in order to loop 47 times, one byte need to be 0x74 and when
;;the loop ends, its value will be 0. So, we need an instruction that contains 0x00. I chose a character from the
;;DIRECTION_TABLE to play this role. 0 and 1 are very similar, so we can use inc esi to add one to all the direction
;;numbers in the table, and we:

;;%define DIRECTION_TABLE 0x74affe4f

;;When we use it, it will be 0x00affe4f

        mov     al, 0xa
        stosb
        jnz     short fill_char         ;p_paddr = (garbage)

        sub     edi, W * H / 2 + 8      ;p_filesz = 0x0760
        mov     al, ANSI_CSI_H - $$     ;p_memsz = 0x019154b0
        xchg    eax, ecx

main_loop:
        add     edi, esi                ;p_flags = 0x240702f7 = 0x7
        add     al, [edi]
        and     al, 0b11                ;p_align = (garbage)
        push    DIRECTION_TABLE
        movsx   esi, byte [esp + eax]
        jmp     short AA

;;The lower two bits of al indicate the direction of the ant, and edi indicates the position of the ant.

ANSI_CSI_H:
        db      0x1b, 0x5b, 0x48
buf:
