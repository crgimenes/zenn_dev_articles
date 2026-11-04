---
title: "C言語とアセンブリで作るMS-DOS用シャットダウン＆再起動ユーティリティ"
emoji: "🔌"
type: "tech"
topics: ["development", "retro", "assembly", "c"]
published: true
---

Watch the video of this article [here](https://www.youtube.com/watch?v=GTIIId3enis).

For retrocomputing fun, I use [VirtualBox](https://www.virtualbox.org) with [MS-DOS 6.22](https://en.wikipedia.org/wiki/MS-DOS) and [DOSBox](https://www.dosbox.com). Both work very well, but the screen looks a bit better in VirtualBox, and DOSBox is faster and easier for developing and switching quickly between systems. So I use both.

In DOSBox, you can close the emulator by typing the `exit` command. That closes a command interpreter session and, if it is the last one, closes DOSBox itself. It is convenient because you do not need the mouse and it behaves more like a terminal.

In VirtualBox, you have to close the emulation by command. If the operating system were more modern, you could use the `host+u` key combination to power off via [ACPI (Advanced Configuration and Power Interface)](https://en.wikipedia.org/wiki/Advanced_Configuration_and_Power_Interface). But with DOS, VirtualBox shows an error message saying the `guest` does not support software shutdown.

I found out that the system supports [APM (Advanced Power Management)](https://en.wikipedia.org/wiki/Advanced_Power_Management), the predecessor of ACPI. You can shut down by software by calling `int 15h` and passing the parameters to power off the machine.

I put all of this together and wrote small utilities to shut down and reboot the machine. With a bit of ingenuity, I even got it to shut down by typing `exit` in DOS.

## Reboot using the BIOS

This reboot utility is simple. It does not use APM; instead, it calls `int 19h`, which makes the BIOS restart the system. The idea is not mine; I read this tip in a magazine in the early '90s. It is so simple that whenever I sit down at a DOS machine, I create the executable using debug.

### reboot.com using debug

This is the debug script that generates reboot.com. Type it exactly like this, including the blank line.

```bash
debug
a100
int 19

rcx
2
n reboot.com
w
```

That produces a `.com` executable with only 2 bytes!

Now, a more elaborate version using the NASM assembler, which generates exactly the same executable.

```assembly
;reboot using BIOS.
;nasm -f bin -o reboot.com reboot.asm

org 100h
section .text

start:  int 19h

.end
```

## Shutdown using APM

First, I wanted to check whether APM is supported. That matters because if I write a bat script, I want my executable to return a value in the `errorlevel` variable. That way I can take different actions. For example, DOSBox does not support APM, only VirtualBox does. So if I try to use this utility in DOSBox, I need to know it failed.

```asm
;check whether APM is ok
mov ax, 5300h
xor bx, bx
int 15h
jc APM_error
.
.
.
APM_error: mov  dx, msgAPMError
           mov  ah, 9
           int  21h

exitError: mov  ax, 4CFFh
           int  21h

msgAPMError db "Erro de APM ou não disponível",0
```

The code above checks for APM support. If everything is fine, the program continues. Otherwise, it jumps to the `APM_error` label, which prints an error message on screen and exits the program, setting `errorlevel` to 255.

If APM is ok, the program prepares to connect and set version 1.2 (the last revision, from 1996) and finally powers off the machine with the following snippet.

```asm
;power off the system
mov     ax, 5307h
mov     bx, 0001h
mov     cx, 0003h
int     15h
```

If you use FreeDOS, I believe it supports version 1.11, so you may need some adjustments.

## Combining reset and shutdown using C

Besides the pure assembly version, I wrote a C application combining both features: reset and shutdown. They can be selected through command line parameters. I did it just to experiment with Borland Turbo C and mix it with assembly.

```c
/*
compile com:
tcc -mt -tDc main.c
*/
#include <stdio.h>

// Verifica instalação do APM
char chkAPM() {
  asm {
    mov ax, 5300h
    xor bx, bx
    int 15h
    jc APM_error
  }
  return 0;
APM_error:
  return -1;
}

void usage() {
  printf("shutdown para DOS\n"
         "Cesar Gimenes, @crgimenes\n"
         "https://github.com/crgimenes/shutdown\n"
         "Uso:\n"
         "    -h halt requer APM\n"
         "    -r reboot (chama BIOS int 19h)\n");
}

int main(int argc, char *argv[]) {
  if (argc == 1) {
    usage();
    return 1;
  }

  if (strcmp(argv[1], "-r") == 0) {
    asm int 19h
  }

  if (chkAPM()) {
    printf("Erro de APM ou não disponível");
    return 1;
  }

  if (strcmp(argv[1], "-h") == 0) {
    asm {
      /* conecta ao APM */
      mov     ax, 5301h
      xor     bx, bx
      int     15h

      /* define versão do APM */
      mov     ax, 530Eh
      mov     cx, 0102h
      xor     bx, bx
      int     15h

      /* desligar */
      mov     ax, 5307h
      mov     bx, 0001h
      mov     cx, 0003h
      int     15h
      hlt
    }
  }

  return 0;
}
```

Finally, to make VirtualBox behave like DOSBox and close when we type the `exit` command, we can start a new session of the `command.com` interpreter at the end of `autoexec.bat` and then call the shutdown command. The downside of this approach is that it uses more RAM and keeps another instance running.

```bat
...
command
sd -h
```

I hope this is useful. The [source code and compiled versions are on GitHub](https://github.com/crgimenes/shutdown). You will notice the `.com` applications are extremely small. In fact, `reboot.com` is only 2 bytes, not kilobytes, just bytes. The largest one, `sd.com`, is only 6.4K. That happens because they are direct instructions for the processor, with no headers. The operating system just loads the file into RAM at a specific address and points the execution pointer there. But that is a topic for another day.
