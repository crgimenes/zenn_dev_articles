---
title: "Luaインタプリタを静的コンパイルして移植性と一貫性を確保する"
emoji: "🌙"
type: "tech"
topics: ["lua", "c", "make", "upx"]
published: true
---

Lua is my favorite language for writing small scripts and configurations. It is easy to embed in other projects and has a clean, simple syntax. It is easy to extend and a great language for configuring systems.

I recently started a project that requires the Lua interpreter to be installed. That is usually not a problem. But to have full control, I decided to compile my own statically linked version of the interpreter. This ensures that differences in the libc version or other libraries won't interfere with my system. I've run into plenty of problems with systems that failed to load because of mismatched glibc versions. Beyond the practical reasons, I believe all software should be statically compiled. The memory savings and easier updates of dynamic linking don't make up for the problems it can cause.

Compiling the Lua interpreter is very simple. Download the source code, extract it, and go to the `src` directory. Then edit the `Makefile` and add the `-static` parameter to the `MYLDFLAGS` variable. Finally, run `make` to build the interpreter.

```Makefile
MYLDFLAGS=-static
```

Besides `-static`, you can add other useful parameters, such as `-s` to strip debug symbols, `-Os` to produce a size-optimized binary, or `-Ofast` to optimize for speed — equivalent to `-O3` with extra flags that may not follow all C standards — among others.

## Bonus

Beyond compiling without debug symbols, we can use a "packer". A packer compresses the executable and decompresses it in memory at runtime. A good packer is UPX.

```bash
upx --best lua
```

Now, besides being static, the executable is also quite small.

Step-by-step video:

https://www.youtube.com/watch?v=QyAJufyWydc

[Cesar Gimenes](https://crg.eti.br/en/cesar-gimenes)
