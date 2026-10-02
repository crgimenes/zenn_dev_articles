---
title: "BASICは今なお健在"
emoji: "🖥️"
type: "tech"
topics: ["basic", "development"]
published: true
---

While researching BASIC implementations, I found some interesting things. It's amazing that a language this old, and with this many problems, still exists. You can even find commercial compilers still under active development for it.

Yes, even though I'm a fan and love playing with BASIC for the nostalgia and the fun, there's no denying that BASIC causes more problems than it solves. (In my opinion)

Of course, an extremely simple language made sense when BASIC was born, in 1964. Machines had few resources, and the goal was a language for beginners. BASIC stands for [Beginner's All-Purpose Symbolic Instruction Code](https://en.wikipedia.org/wiki/BASIC)

![ZX Spectrum](https://crg.eti.br/assets/ZX-Spectrum.webp)

I learned BASIC on the old [TK85](https://pt.wikipedia.org/wiki/TK_85), a Brazilian clone of the famous [ZX Spectrum](https://en.wikipedia.org/wiki/ZX_Spectrum). Even today, I keep a [ZX Spectrum Next](https://www.specnext.com), an FPGA recreation that I have a lot of fun with.

## Pure BASIC

Among the commercial compilers I found, my favorite is [PureBASIC](https://www.purebasic.com). I bought a license to support the project. Beyond being BASIC, it's an impressive compiler. The generated executable is small, it compiles for the three main platforms — Windows, macOS, and Linux — and it has plenty of features.

PureBASIC uses the [fasm assembler](https://flatassembler.net) to generate the executable. If you like assembly as much as I do, that's excellent news.

On top of that, the final executable is monolithic: no libraries or interpreters to ship (unless you want to). That's a big advantage.

The PureBASIC license is lifetime. If you buy a license, you get every update for as long as the company exists. The same license works on any supported operating system.

Despite these features, I don't use PureBASIC for serious projects. The community is small, the code is closed, and even though the compiler is consistent and has been in development for decades, I worry it could disappear. I'd feel more comfortable if the compiler were open source.

## BASIC on Mobile

Another commercial compiler is [B4X](https://www.b4x.com). It has versions that compile for Android and iOS, following the idea that the same code produces executables for both platforms.

## BASIC on the Arduino

![Arduino UNO](https://crg.eti.br/assets/arduino-uno.webp)

A BASIC that makes more sense to me is [Tiny BASIC](https://en.wikipedia.org/wiki/Tiny_BASIC). It has several ports for microcontrollers, including the [ATmega328P](https://en.wikipedia.org/wiki/ATmega328) used by the [Arduino](https://www.arduino.cc).

It makes sense because it combines educational code — not necessarily efficient — and because interacting with an interpreter over serial is more fun than going through the compile, deploy, and test cycle when you're taking your first steps.

---

## Visual BASIC

I won't even get into Visual Basic and VBA. They're atrocities, but I'll leave you with one line of VB that is practically a philosophy of life.

```basic
On Error Resume Next
```
