---
title: "macOSでNASMとDOSBoxを使って16ビットアセンブリで遊ぶ"
emoji: "🕹️"
type: "tech"
topics: ["assembly", "nasm", "dosbox", "macos", "retro"]
published: true
---

## Messing around with assembly

Watch the video of this article [here](https://www.youtube.com/watch?v=Q1jNzLugyz8).

Playing with assembly is fun. With asm alone you have full control of the machine and of every aspect of your program. Nothing is hidden, and the computer will do exactly what you told it to do (not necessarily what you want).

These days assembly is a hobby for me. I'm not working on anything so low level that it really requires going down to asm, but as NERD entertainment there's nothing like it. Recently I found my old quick reference guides for the [BIOS](https://en.wikipedia.org/wiki/BIOS) and [MS-DOS](https://en.wikipedia.org/wiki/MS-DOS) interrupts.

I'm not interested in assembly for modern machines. I want to play with 16 bits and the [80x86](https://en.wikipedia.org/wiki/X86) line of processors, up to the [i386](https://en.wikipedia.org/wiki/Intel_80386) at most, building completely flat .com files. The idea is to relive the old days when computers were magic boxes full of things to discover.

## Development environment

So I put together a small development environment to play with: [NASM](https://www.nasm.us) as the assembler and [DOSBox](https://www.dosbox.com) to run the programs. The emulator is necessary because modern operating systems run in protected mode and it's impossible to run a .com directly.

Of course a lot has evolved from the 16-bit era until today, and current tools are fantastic. I have no problem using modern tools — after all, why not make the fun even more fun?

For example, [Visual Studio Code](https://code.visualstudio.com) has a good assembly plugin. Using an emulator instead of a real machine means I don't have to reboot the machine when it hangs because of some programming error... yes, without protected memory you can lock up the whole system by accident.

To get started, I wrote a small program that changes the machine's font. I intend to expand it to the other letters simply because drawing bitmaps is fun.

## Source code

```asm
    org 100h
section .text

start:  
    mov    bp,font    ; aponta para fonte
    mov    cx,1       ; mudar 1 bitmap
    mov    dx,0041h   ; A 41h = 65 = A na
                      ; tabela ASCII
    mov bx,1000h      ; bh = 16 bl = 00. 
        ; 16 bytes/char, bloco de RAM 00
    mov ax,1100h      ; serviço 11h muda a fonte
    int 10h           ; interrupção 10h
    mov ax,4C00h      ; serviço 04h do MS-DOS, 
                      ; termina o programa 
    int 21h           ; int 21h MS-DOS

section .data
font:    
        db    00000000b       ; 1
        db    01111100b       ; 2
        db    11111110b       ; 3
        db    11000010b       ; 4
        db    11000010b       ; 5
        db    11000010b       ; 6
        db    11000010b       ; 7
        db    11111110b       ; 8
        db    11000010b       ; 9
        db    11000010b       ; 10
        db    11000010b       ; 11
        db    11000010b       ; 12
        db    11000010b       ; 13
        db    11000010b       ; 14
        db    00000000b       ; 15
        db    00000000b       ; 16

.end
```

To compile it, just run the following:

```bash
nasm -f bin -o font.com font.asm
```
