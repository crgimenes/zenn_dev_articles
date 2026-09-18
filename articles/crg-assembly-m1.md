---
title: "macOS の M1/ARM64 で始めるアセンブリ入門"
emoji: "⚙️"
type: "tech"
topics: ["assembly", "arm", "macos", "development"]
published: true
---

Here is the story. I had found a great deal on two early-90s computers still running [Zilog Z80](https://en.wikipedia.org/wiki/Zilog_Z80) processors. They weren't in perfect shape, but the price was fine.

Then a good friend, with far more common sense than me, advised me to stop wasting energy and money on old hardware. To cool down this nerd fever, he suggested I study ARM assembly instead, since it could at least be useful.

And you know what? He's right. So here I am, starting to play around with asm for ARM.

## Not a Hello World

Instead of the traditional "hello world," I went with something even simpler and potentially more useful. Many operating systems ship two extremely simple and handy commands: `true` and `false`.

These days, on modern systems, both commands are part of the shell. They are no longer separate files, but they work the same way: `true` returns *zero* and `false` returns *1*, and that return value can be read from the "$?" variable.

Naturally, the source code for `true` and `false` is identical; it only flips one bit.

### True

```asm
.global _start
.align 4

_start:
    mov     X0,  #0
    mov     X16, #1
    svc     #0x80
```

### False

```asm
.global _start
.align 4

_start:
    mov     X0,  #1
    mov     X16, #1
    svc     #0x80
```

As you can see, the two programs are nearly identical. What they do is put the return value in the *X0* register and, in the *X16* register, the function to be called — in this case function *1*, which is *exit*. Finally, we invoke *syscall* *0x80*, which runs the function.

### Makefile

```makefile
APPLICATIONS = true false
SYSLIBROOT = `xcrun -sdk macosx --show-sdk-path`

all: $(APPLICATIONS)

clean:
    rm *.o
    rm $(APPLICATIONS)

true.o: true.s
    as -o true.o true.s

true: true.o
    ld -o true true.o -lSystem -syslibroot $(SYSLIBROOT) -e _start

false.o: false.s
    as -o false.o false.s

false: false.o
    ld -o false false.o -lSystem -syslibroot $(SYSLIBROOT) -e _start
```

The biggest difference from other platforms is in the Makefile, which has to compile correctly for M1 and macOS. For example, macOS requires the executable to be linked against the System library. You can build a fully monolithic executable, but that would take a lot more work.

## Source code

Here is the source code for the examples.

- [true](https://crg.eti.br/en/post/assembly-m1/true.s)
- [false](https://crg.eti.br/en/post/assembly-m1/false.s)
- [Makefile](https://crg.eti.br/en/post/assembly-m1/Makefile)

Videos with explanation

- [YouTube](https://youtu.be/clyO5z_klrk)
- [Odysee](https://odysee.com/@crgimenes:7/ASSEMBLY-M1-ARM64:b)

## Conclusion

I'm still very much at the beginning of this experiment, but ARM is quite interesting. I expected to find it much more foreign, since the syntax is very different from the Intel assembly I'm used to. But ARM felt pretty okay — not only the M1 on macOS, but also the more modern *Raspberry Pi* models that use ARM64.

Assembly is interesting, but these days it's far less necessary than it once was. When I started programming, having at least some assembly knowledge was basically mandatory, even for simple things. But that was a different era — assembly code showed up even in magazine articles.

So yes, I'm going to play around a bit with these processors, but the goal is just to get familiar with the platform.
