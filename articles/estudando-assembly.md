---
title: "なぜ今アセンブリを学ぶのか — より良いプログラマーになるために"
emoji: "⚙️"
type: "tech"
topics: ["assembly", "development", "programming"]
published: true
---

When I started programming, back in the 8-bit era, learning a bit of assembly was unavoidable. The machines were far simpler than today's computers, and we often didn't even have a compiler at hand. Instead, we typed small chunks of opcodes directly in hexadecimal.

This was incredibly useful for working around the limitations of the BASIC that served both as a programming language and as the operating system (burned straight into the machine's ROM).

Back then, every computing magazine came with code examples and often entire programs.

*"If you know assembly, every program is open source."*

As microcomputers evolved into 16-bit machines, things got more interesting, though they were still far less powerful than what we have today. Even though we already had excellent compilers and interpreters for several languages, many programs and even entire operating systems were still written in assembly, simply so they could run in such a limited environment.

Processors like the 80286 and later the 80386 brought a big leap: it was now possible to have mapped memory and protected mode, a feature that had been exclusive to large computers and was now available on home machines.

Even so, it took a good while before operating systems showed up that actually took advantage of protected mode. It's hard to explain what it was like to program in an era when your program had access to absolutely any part of the machine.

Without protected mode, your program could do whatever it wanted: it could change any bit in RAM, it could alter the interrupt table, and while your program was running it was king. No other program could take control unless yours allowed it.

Of course, if your program crashed, the only thing you could do was restart the machine.

With modern operating systems running in protected mode, you can no longer access the hardware directly. You always have to go through the kernel. This makes systems much safer, but it also takes away a lot of the fun and control we used to have.

The machines are far more powerful and the compilers far smarter, and you no longer need to drop down to assembly every time you want to do something more interesting.

## Assembly Today

Why study assembly when machines are so powerful and we no longer have the control we once did?

- Understanding how computers work. Knowing how the system works under the hood makes your systems more efficient, and efficient systems cost less money, even if you program in a high-level language and all your software lives "in the cloud." Knowing assembly also helps with debugging, making it easier to understand bugs in your code even when you work in high-level languages.

- Forensics, security, and reverse engineering. This is a growing field that needs professionals who can analyze pieces of software and find potential security flaws, as well as determine whether a piece of software is malicious.

- Firmware development. Modern microcontrollers make it much easier and cheaper to build projects that used to be far too expensive. On top of that, it's increasingly simple to add new features, such as WiFi connectivity by just plugging in a module. But for all of this, someone has to write and test the software, and since microcontrollers are quite limited, assembly is often needed, whether to develop critical sections or to debug errors.

- Optimization for performance, size, and so on. Good performance means better competitiveness, whether by cutting infrastructure costs, making the user interface smoother, or making power consumption more efficient. Knowing how the machine works and how to take advantage of its capabilities will help you build a better product, even if you don't develop directly in assembly but understand what your compiler is doing and how to get a great result out of it.

- Still on optimization and performance, there's a whole misguided culture that optimization is the root of all evil and so on. This gets used as an excuse to write bad software, and bad software dies the moment something better comes along. A clear example is what happened with Windows CE. Before the iPhone showed up, Windows dominated handhelds and had plenty of features: a text editor, a spreadsheet, and more. But it was slow. When the iPhone arrived, it had none of that. There was no App Store, no applications, nothing, but the system was fast, making the user experience much more pleasant. Windows CE never recovered, even though it had dominated the market. All it took was a more efficient competitor.

- On optimizing for size, the strongest argument today for investing in more efficient software is that if your software is too large, whether it's an app or even a web page, there's a good chance your potential customer gives up because they don't have a good connection and your software simply took too long to download.

- Because you're a massive hacker and can't stand not knowing how things work bit by bit. This is without a doubt the most fun reason to learn assembly.

Note that often you don't even need to program directly in assembly to benefit from knowing it. You've learned how computers work at the hardware level, and that lets you write better software even in other languages. After all, no matter which language you choose, once it passes through all the layers of the operating system, virtualization, and so on, your code still has to be executed by the hardware.

## Assembly, Assembler, and Machine Language

Here I've used "assembly" to cover a whole concept. For example, when I typed directly in hexadecimal back on the 8-bit computers, that wasn't actually assembly; we were typing directly in machine language. I explain a bit more about this in the post [Assembly, Assembler, and Machine Language](https://crg.eti.br/en/post/assembly-assembler-e-linguagem-de-maquina/).

## Where to Start

The hardest part of getting started with any programming language is setting up the development environment. With assembly there's an extra layer of complexity: you have to decide which platform you'll study, because assembly is so close to the hardware and the operating system that each platform has its own specific setup, and it would be impossible to cover them all. Still, I've written a few posts that can help.

- [First steps with assembly](https://crg.eti.br/en/post/primeiros-passos-com-assembly/)
- [16-bit Assembly on macOS with NASM and DOSBox](https://crg.eti.br/en/post/assembly-16bits-nasm-dosbox/)
- [Assembly on macOS M1/ARM64](https://crg.eti.br/en/post/assembly-m1/)
