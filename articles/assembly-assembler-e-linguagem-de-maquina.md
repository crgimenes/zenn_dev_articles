---
title: "アセンブリ・アセンブラ・機械語の違いを整理する"
emoji: "⚙️"
type: "tech"
topics: ["assembly", "development"]
published: true
---

## They Are Different Things

There are three different but related concepts that people often confuse. Let's clarify each one.

### Assembly

Assembly is a programming language made up of simple mnemonics. It maps directly to the instructions of the platform you're targeting. When you write Assembly, you know exactly what the processor is doing, and you get access to resources that higher-level languages may not expose. Assembly is a low-level language, meaning it sits close to the hardware.

### Assembler

The assembler is the program that reads a file of Assembly mnemonics and turns them into machine language. It plays the same role a compiler does.

### Machine Language

Machine language is the only language the processor can actually interpret. It is made up entirely of codes, which makes it unreadable to humans. With practice, you can recognize some hexadecimal codes and match them to their Assembly mnemonics. For example, on the [8086](https://en.wikipedia.org/wiki/Intel_8086) platform, the `NOP` instruction is `0x90` and `0xCD` is the code that calls an interrupt. On the [Z80](https://en.wikipedia.org/wiki/Zilog_Z80) platform, `NOP` is `0x00`.

## Examples

### Hello World in 16-bit DOS x86

```asm
ORG 100h
section .text
    MOV AH, 40h
    MOV BX, 1
    MOV CX, 11
    MOV DX, msg
    INT 21h
    MOV AL, 1
    MOV AH, 4Ch
    INT 21h
section .data
    msg db "hello world"
```

### The Same Program After the Assembler

```
B4 40 BB 01 00 B9 0B 00 BA 14 01 CD 21 B0 01 B4
4C CD 21 00 68 65 6C 6C 6F 20 77 6F 72 6C 64
```

## Where Assembly Still Matters

Back in the day, Assembly was the only option short of typing machine codes by hand. Things have changed, but Assembly is still an important language and shows up inside the implementation of many modern ones.

It is used to reach hardware cryptographic instructions, or to squeeze out maximum speed in critical paths — for instance, context switching in modern languages such as Go.

Learning Assembly means understanding how a computer works on the inside. Any programmer who takes the craft seriously should pick it up at some point.

## The Machine Itself

A good way to really understand how the components of a computer fit together is to write an emulator. It doesn't have to be complete — a small interpreter that reads and runs binaries, simulating a CPU and a bit of RAM, is enough.

I wrote a [simple 8086 emulator](https://crg.eti.br/en/pub/assembly-emulador-8086/) with teaching in mind. If you have questions about the idea or how it works, let me know.
