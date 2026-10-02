---
title: "小さな8086 CPUエミュレータをCで書いてみた"
emoji: "🖥️"
type: "tech"
topics: ["retro", "assembly", "development"]
published: true
---

## 8086 Emulator Written in C

The first thing to make clear is that this is not a complete [emulator](https://en.wikipedia.org/wiki/Emulator). The goal is only to interpret a hello world. Of course, you can take this skeleton and expand it into a full emulator.

I was bored waiting for my friends to show up at [Campus Party](https://brasil.campus-party.org) 2016. I found the table set aside for the [hackerspace](https://en.wikipedia.org/wiki/Hackerspace) crowd and sat there waiting, but since there were no talks at that hour and nothing else I wanted to attend, I needed something to kill time.

So I came up with a challenge for myself: write an interpreter capable of running a hello world written in 16-bit assembly from the MS-DOS era. Nothing fancy, just a `flat` executable, an old [`.com`](https://en.wikipedia.org/wiki/COM_file) file.

The first step was writing the hello world itself.

---

```asm
org 100h
section .text
    mov ah, 40h
    mov bx, 1
    mov cx, 11
    mov dx, msg
    int 21h
    mov al,    1
    mov ah, 4Ch
    int 21h
section .data
    msg db "hello world"
```

---

I saved it to `test.asm` and compiled it with [NASM](https://www.nasm.us), my favorite assembler.

```bash
nasm -f bin test.asm -o test.com
```

Now that I had the binary I was going to interpret, I wrote a small [disassembler](https://en.wikipedia.org/wiki/Disassembler) just for fun.

Since I knew exactly which instructions were in the binary, I focused only on what I needed. I didn't bother adding every instruction, register, and so on, because after all it was just a way to pass the time.

---

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void decompile(const char *s, unsigned int i) {
  unsigned char v;
  unsigned char par_count;
  for (unsigned int c = 0; c < i; c++) {
    v = (unsigned char)(*(s + c));
    printf("%04xh %02x ", c, v);
    if (par_count > 0) {
      par_count--;
      printf("%02xh ", v);
    } else {
      switch (v) {
      case 0xB0:
        printf("mov al");
        par_count = 1;
        break;
      case 0xB4:
        printf("mov ah");
        par_count = 1;
        break;
      case 0xB9:
        printf("mov cx");
        par_count = 2;
        break;
      case 0xBA:
        printf("mov dx");
        par_count = 2;
        break;
      case 0xBB:
        printf("mov bx");
        par_count = 2;
        break;
      case 0xCC:
        printf("int 3");
        par_count = 0;
        break;
      case 0xCD:
        printf("int");
        par_count = 1;
        break;
      default:
        printf("%02xh", v);
        if (v >= 32) {
          printf(" \"%c\"", v);
        }
        break;
      }
    }

    printf("\r\n");
  }
}

unsigned int fsize(FILE *fd) {
  fseek(fd, 0, SEEK_END);
  unsigned int size = ftell(fd);
  fseek(fd, 0, SEEK_SET);
  return size;
}

int main(int argc, char *argv[]) {
  char memory[1024];
  FILE *fp;

  if (argc == 1) {
    printf("%s filename.com\r\n", argv[0]);
    exit(1);
  }

  memset(memory, 0, sizeof(memory));
  fp = fopen(argv[1], "rb");
  if (fp == NULL) {
    printf("Error opening file");
    return (-1);
  }

  unsigned int size = fsize(fp);

  fread(memory, size, 1, fp);
  decompile(memory, size);

  fclose(fp);
  return 0;
}
```

---

To compile it I used [gcc](https://gcc.gnu.org), but any modern **ANSI C** compiler will work:

```bash
gcc d86.c -o d86
```

To run it and see the disassembler in action, just type:

```bash
./d86 test.com
```

The result will be the following:

```
0000h b4 mov ah
0001h 40 40h
0002h bb mov bx
0003h 01 01h
0004h 00 00h
0005h b9 mov cx
0006h 0b 0bh
0007h 00 00h
0008h ba mov dx
0009h 14 14h
000ah 01 01h
000bh cd int
000ch 21 21h
000dh b0 mov al
000eh 01 01h
000fh b4 mov ah
0010h 4c 4ch
0011h cd int
0012h 21 21h
0013h 00 00h
0014h 68 68h "h"
0015h 65 65h "e"
0016h 6c 6ch "l"
0017h 6c 6ch "l"
0018h 6f 6fh "o"
0019h 20 20h " "
001ah 77 77h "w"
001bh 6f 6fh "o"
001ch 72 72h "r"
001dh 6c 6ch "l"
001eh 64 64h "d"
```

There we go, now we have every memory position of `test.com`. At this point the exercise has no real practical use beyond confirming that we're reading the file correctly and understanding each of its instructions. But it's easier to build a disassembler first and then turn it into an emulator.

Let's see what the emulator code looks like:

---

```c
#include <curses.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int print_asm;
int use_curses;
int cursor_x;
int cursor_y;
WINDOW *mainwin;

void setCursorPos(int x, int y) {
  cursor_x = x;
  cursor_y = y;
  wmove(mainwin, y, x);
  refresh();
}

void setChar(const unsigned char c) {
  mvwaddch(mainwin, cursor_y, cursor_x, c);
  refresh();
}

void init_ncurses(void) {
  if (!use_curses)
    return;

  if ((mainwin = initscr()) == NULL) {
    printf("Error initialising ncurses.\n");
    exit(1);
  }
}

void end_ncurses(void) {
  if (!use_curses)
    return;

  delwin(mainwin);
  endwin();
  refresh();
}

void run(const char *s) {
  unsigned char v;
  unsigned char par_count = 0;

  unsigned char ah;
  unsigned char al;
  int16_t cx;
  int16_t bx;
  int16_t dx;

  unsigned char lbyte;
  unsigned char hbyte;

  for (unsigned int c = 0; c < 1024; c++) {
    v = (unsigned char)(*(s + c));
    if (print_asm == 1)
      printf("%04xh %02x ", c, v);
    if (par_count > 0) {
      par_count--;
      printf("%02xh ", v);
    } else {
      switch (v) {
      case 0xB0:
        c++;
        v = (unsigned char)(*(s + c));
        al = v;
        if (print_asm == 1)
          printf("mov al, %4Xh", al);
        break;
      case 0xB4:
        c++;
        v = (unsigned char)(*(s + c));
        ah = v;
        if (print_asm == 1)
          printf("mov ah, %4Xh", ah);
        break;
      case 0xB9:
        c++;
        lbyte = (unsigned char)(*(s + c));
        c++;
        hbyte = (unsigned char)(*(s + c));
        cx = (int16_t)(hbyte << 8 | lbyte);
        if (print_asm == 1)
          printf("mov cx, %4Xh", cx);
        break;
      case 0xBA:
        c++;
        lbyte = (unsigned char)(*(s + c));
        c++;
        hbyte = (unsigned char)(*(s + c));
        dx = (int16_t)(hbyte << 8 | lbyte);
        if (print_asm == 1)
          printf("mov dx, %4Xh", dx);
        break;
      case 0xBB:
        c++;
        lbyte = (unsigned char)(*(s + c));
        c++;
        hbyte = (unsigned char)(*(s + c));
        bx = (int16_t)(hbyte << 8 | lbyte);
        if (print_asm == 1)
          printf("mov bx, %4Xh", bx);
        break;
      case 0xCC:
        printf("int 3 debug...");
        par_count = 2;
        break;
      case 0xCD:
        c++;
        v = (unsigned char)(*(s + c));
        if (print_asm == 1)
          printf("int %2Xh", v);
        if (v == 0x20) { // return to "DOS" :D
          exit(0);
        }
        if (v == 0x21) {    // DOS
          if (ah == 0x4C) { // exit program
            printf("\r\n");
            exit(al);
          }
          if (ah == 0x40) { // write to a file or device
            /*
            BX = file handle
            CX = number of bytes to write
            DS:DX -> data to write
            */

            for (int i = 0; i < cx; i++) {
              v = (unsigned char)(*(s + (dx - 0x100) + i));
              if (use_curses) {
                setChar(v);
                cursor_x++;
              } else {
                printf("%c", v);
              }
            }
          }
        }
        break;
      default:
        printf("%02xh", v);
        if (v >= 32) {
          printf(" \"%c\"", v);
        }
        break;
      }
    }

    if (print_asm == 1)
      printf("\r\n");
  }
}

size_t fsize(FILE *fd) {
  fseek(fd, 0, SEEK_END);
  size_t size = (size_t)ftell(fd); // warning ftell return signed long
  fseek(fd, 0, SEEK_SET);
  return size;
}

int main(int argc, char *argv[]) {
  char memory[1024];
  FILE *fp;

  int opt_flag;
  char *filename = 0;
  char *file = 0;
  extern char *optarg;
  extern int optind, optopt, opterr;

  print_asm = 0;
  use_curses = 0;
  cursor_y = 0;
  cursor_y = 0;

  while ((opt_flag = getopt(argc, argv, "acf")) != -1) {
    switch (opt_flag) {
    case 'a':
      print_asm = 1;
      break;
    case 'c':
      use_curses = 1;
      break;
    case 'f':
      filename = optarg;
      printf("filename is %s\n", filename);
      break;
    case ':':
      printf("-%c without filename\n", optopt);
      break;
    case '?':
      printf("unknown option %c\n", optopt);
      break;
    default:
      filename = optarg;
      printf("filename is %s\n", filename);
      break;
    }
  }

  // printf("optind = %i\n",optind);
  if (optind < argc) {
    file = argv[optind];
    // printf("filename is %s\n", file);
  }

  if (argc == 1) {
    printf("%s filename.com\r\n", argv[0]);
    exit(1);
  }

  memset(memory, 0, sizeof(memory));
  fp = fopen(file, "rb");
  if (fp == NULL) {
    printf("Error opening file %s", file);
    return (-1);
  }

  size_t size = fsize(fp);

  fread(memory, size, 1, fp);
  fclose(fp);

  init_ncurses();
  run(memory);
  end_ncurses();

  return 0;
}
```

---

You'll notice that the overall structure of the disassembler and the emulator are quite similar. The emulator has a few extra things, and I don't remember why I decided to use [Ncurses](https://en.wikipedia.org/wiki/Ncurses) — I must have been incredibly bored.

I saved the source code in a file called `r86.c`.

To compile it with `gcc`, this is the command:

```bash
gcc r86.c -o r86 -lncurses
```

Note that you need to pass the `ncurses` library to the compiler.

Now we can finally run the emulator and see whether it works with our little `test.com`. To do that, just run the following command.

```bash
./r86 test.com
```

And the result, as expected, will be

```bash
hello world
```

As expected, the emulator works. But how does it work?

When the emulator starts, it allocates 1kb of RAM, more than enough to load the test program. Obviously, for anything more serious we'd need more memory.

Next it reads the file passed on the command line and loads it into that memory. After all the initialization is done and the environment is ready, it calls the `run` function, passing our memory as a parameter.

The `run` function then interprets one instruction at a time, the same way the processor would — reading each instruction from memory and executing it. Of course, a real processor does far more complicated things than that, running microcode and much more advanced machinery.

We, on the other hand, are doing the classic emulator trick: walking through a `switch case` that interprets the instructions we care about.

It's also worth noting that this emulator isn't formal in any way. For example, the correct approach would be to simulate the RAM of a 16-bit era PC, have the instructions in our `switch case` write to the RAM segment reserved for video memory, and then have another routine display that video memory.

The way it's implemented, we simply interpret the interrupts. If the program writes directly to video memory — a very common practice for programs of that era — we just won't display anything.

We're also not interpreting any ports or anything like that, meaning there are no peripherals of any kind in this emulator.

But overall, as an exercise and a way to pass the time, it worked out well.

Some time later I started rewriting the emulator in [Golang](https://golang.org), but more important projects ended up taking my free time and I set the project aside. The only thing that's done is the loader.

---

```golang
package main

import (
    "bufio"
    "fmt"
    "io"
    "os"

    "github.com/crgimenes/goconfig"
)

type config struct {
    FileName string `cfg:"name"`
}

var memory [640000]byte

func main() {
    cfg := config{}

    goconfig.PrefixEnv = "R86"
    err := goconfig.Parse(&cfg)
    if err != nil {
        println(err.Error())
        os.Exit(1)
    }

    if cfg.FileName == "" {
        if len(os.Args) > 1 {
            cfg.FileName = os.Args[len(os.Args)-1]
        }
    }

    f, err := os.Open(cfg.FileName)
    if err != nil {
        println(err.Error())
        os.Exit(1)
    }

    defer func() {
        err = f.Close()
        if err != nil {
            println(err.Error())
            os.Exit(1)
        }
    }()

    buff := bufio.NewReader(f)

    var c byte
    var count int
    var col int

    count = 0x100
    for {

        c, err = buff.ReadByte()
        if err != nil {
            if err == io.EOF {
                break
            }
            println(err.Error())
            os.Exit(1)
        }

        memory[count] = c

        if col >= 16 || col == 0 {
            col = 0
            fmt.Printf("\n%06X ", count)
        }

        fmt.Printf("%02X ", c)
        col++
        count++
    }

    fmt.Printf("\n\n%v bytes loaded\n", count)
}
```

---

The idea was to write a more serious emulator, this time with 640k of RAM and loading the executable at address 100h. But for now it only loads the binary and then displays what was loaded into RAM.

One interesting thing to build would be an emulator that doesn't depend on any graphical environment, using standard output instead and positioning the output on screen with nothing but ANSI codes. That would be useful for running classic [BBS doors](https://en.wikipedia.org/wiki/BBS_door) like [Trade Wars](https://en.wikipedia.org/wiki/Trade_Wars) or [LORD](https://en.wikipedia.org/wiki/Legend_of_the_Red_Dragon).

Recently, at the [Golang Study Group](https://gopher.pro.br), we've been planning to build our own version of [Core Wars](https://www.corewars.org). We're still discussing whether to emulate an academic CPU like the [LC-3](https://en.wikipedia.org/wiki/LC-3), which would be interesting from an academic standpoint, whether to create something new, or whether to go with the 80x86.
