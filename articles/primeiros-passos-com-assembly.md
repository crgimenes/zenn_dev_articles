---
title: "アセンブリ入門：開発環境の構築と最初のブートセクタ"
emoji: "💾"
type: "tech"
topics: ["assembly", "boot"]
published: true
---

Every Thursday, a group of programmers and I get together to talk about Go in the [Go Study Group](https://github.com/crgimenes/grupo-estudos-golang). We should probably rename it *Technology Study Group*, since we end up discussing pretty much everything.

One topic that keeps coming back is assembly programming. We've talked several times about putting together demos and toy programs loaded from the boot sector, known as "boot sector games."

Besides being fun, it's a good way to teach how a computer works internally. Concepts like access speed, Lx cache, and others stay abstract in high-level languages.

The examples can't be very large, since we only have 510 bytes to work with. Our program needs to fit in that space, which is the challenge.

The limit is 510 bytes because 2 of the 512 available bytes are reserved for the boot sector signature.

## Setting up the environment

### The nasm compiler

nasm is my favorite assembler. It's cross-platform, has an active community, and uses Intel syntax.

#### Installing nasm

On Linux, most distributions ship a nasm package. It's usually a bit out of date, but I've never had issues with Debian's default version. These days I install it from source out of personal preference.

On macOS, nasm ships with Xcode. I prefer using Apple's bundled version.

On Windows, there's a pretty convenient installer.

#### Installing from source

Download the source code from the official site at https://www.nasm.us. I prefer using the stable release.

Unpack it into a directory and follow the instructions in the INSTALL file.

Basically, run the following commands:

```bash
./configure
make
sudo make install
```

Check that the install worked with `nasm --version`.

#### Installing nasm on Windows

To install on Windows, use the installer available at https://www.nasm.us/pub/nasm/releasebuilds/. Pick the version you need, for example win64, and download installer-x64.exe.

After installing, add the nasm directory to the *PATH* environment variable manually.

#### Configuring nasm in Neovim

To tell Neovim you're working with nasm, add the following to your init.vim:

```vim
"" nasm
autocmd BufNewFile,BufRead *.asm set filetype=nasm
```

### Installing qemu

qemu is a versatile emulator. Besides emulating several platforms, it has interesting features like *ncurses* mode, which redirects the emulated screen's text-mode output to the terminal. That lets you watch an emulated screen over SSH, as long as it's in text mode.

To install it, download the right version for your system from https://www.qemu.org/download/.

On Debian, install it with `apt install qemu`. On Windows, use the 64-bit installer from https://qemu.weilnetz.de/w64/.

On Windows, add the qemu directory to the *PATH* environment variable manually.

## Testing the environment

With the development environment set up, let's test it with a classic "hello world."

### Hello world

Create a file called *boot.asm* with the following content:

```assembly
org 0x7c00          ; sets the starting address
bits 16

; clear the screen
mov ax, 0x3         ; sets video mode ah=0 al=3
int 0x10            ; BIOS call

; print message
xor ax, ax          ; ax=0
mov es, ax          ; es=ax
xor dx, dx          ; dx=0
mov bp, msg         ; sets the message address
mov ax, 0x1301      ; ah=13h print string, al=1 move cursor
mov bx, 0x000A      ; bh=0 video page 0, bl=0 attributes
mov cx, [len]       ; string length
int 0x10            ; BIOS call
hlt                 ; halt

msg db 'Ola mundo!'
len dw $-msg
times 510 - ($-$$) db 0
dw 0xAA55 ; boot sector magic number
```

This is a basic boot sector example. In the first line, we set the address *0x7c00*, where the binary will be loaded into memory.

Next, we set the machine's basic word size for the assembler. Since this is the first code that runs at boot, the machine is still in *16-bit real mode*.

We use one instruction to clear the screen by adjusting the video mode, which has the side effect of clearing it.

```assembly
; clear the screen
mov ax, 0x3         ; sets video mode ah=0 al=3
int 0x10            ; BIOS call
```

Next we print the string "Ola mundo!". Printing it involves a more involved call, which I'll cover in more detail in a future post.

```assembly
; print message
xor ax, ax          ; ax=0
mov es, ax          ; es=ax
xor dx, dx          ; dx=0
mov bp, msg         ; sets the message address
mov ax, 0x1301      ; ah=13h print string, al=1 move cursor
mov bx, 0x000A      ; bh=0 video page 0, bl=0 attributes
mov cx, [len]       ; string length
int 0x10            ; BIOS call
```

After printing the message, we want the machine to stop. For that, we use the *hlt* instruction.

We define two variables: *msg* holds the message, and *len* holds its length, computed with a nasm macro.

```assembly
msg db 'Ola mundo!'
len dw $-msg
```

The boot sector signature is *0xAA55*. Those last two bytes need to sit at the very end of the boot sector. To place them correctly, we use the *times 510 - ($-$$)* macro, which pads with zeros up to byte 510, guaranteeing that *dw 0xAA55* lands in the final positions.

#### Running the example

To compile *boot.asm* with nasm, use the following command:

```bash
nasm -f bin boot.asm -o boot.bin
```

To inspect the executable, use the *hexdump* utility, which shows details like the boot sector signature's magic number at the end of the file.

```bash
hexdump boot.bin
0000000 03b8 cd00 3110 8ec0 31c0 bdd2 7c1b 01b8
0000010 bb13 000a 0e8b 7c25 10cd 4ff4 616c 6d20
0000020 6e75 6f64 0a21 0000 0000 0000 0000 0000
0000030 0000 0000 0000 0000 0000 0000 0000 0000
*
00001f0 0000 0000 0000 0000 0000 0000 0000 aa55
```

To boot it in qemu, use the following command:

```bash
qemu-system-i386 -fda boot.bin
```

If you're working on a remote machine over SSH, add the *-curses* flag:

```bash
qemu-system-i386 -curses -fda boot.bin
```

## Next steps

Finding time to write examples turns out to be harder than programming in assembly limited to 510 bytes.

Not everything will be this constrained. When the chance comes up, I plan to show off some other interesting things.

I hope you have as much fun with this as I do.
