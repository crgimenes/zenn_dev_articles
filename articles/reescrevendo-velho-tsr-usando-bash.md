---
title: "古き良きTSRをBashで書き直す"
emoji: "⏰"
type: "tech"
topics: ["bash", "terminal", "c", "retro"]
published: true
---

When I started programming, computing was different from today. The operating system was single-tasking; only one program could run at a time. There were no modern features like protected and mapped memory. Even so, it was possible to create concurrent behavior in programs, but you had to be careful to keep any part from blocking execution. For example, there could be no loops waiting for keyboard input or very long processes. Writing a non-blocking program was tricky in languages like Clipper.

## The Art of Interrupt Hooks

Another option for simulating multitasking was to write a small program that *hooked* into a system interrupt. But what is a *hook*? Basically, you intercept an interrupt — a signal to the processor indicating that something important happened, like a clock *tick* or a key press — and redirect that signal to a function in your program. To do this, you find the address of the interrupt routine in the system table and replace it with the address of your function. At the end of your function, you call the original interrupt to keep the system working.

This made it possible to use the clock or keyboard interrupt to simulate multitasking. Your program kept running in the background without interfering with the system's main operation. It was limited, but it worked.

I still use *interrupt hooks* today, but only on microcontrollers.

## TSR: Terminate and Stay Resident

For this method to work, the program had to stay in memory after its initial execution. This was done using MS-DOS interrupt 27, which allowed creating a TSR (Terminate and Stay Resident) by specifying the program's size. Fortunately, the Turbo C header, *dos.h*, made that part easy for us.

This program puts a clock in the top-right corner of the screen. It is a TSR that uses the clock interrupt and writes directly to video memory to display the time. Operating systems are safer today, but I miss having that total control over the machine, including being able to write directly to memory and devices.

![TSR clock](https://crg.eti.br/en/post/reescrevendo-velho-tsr-usando-bash/relogio-tsr.webp)

```c
#include <dos.h>

#define COLOR 0x70  // (7 << 4) | 0  // Light Gray on Black
#define TSR_MEMORY_SIZE ((_SS + (_SP / 16)) - _psp)
#define OFFSET_INIT 140  // (0 * 80 + 70) * 2

struct dostime_t t;
char far *screen;
void interrupt (*prevtimer)();

void interrupt updatetimer() {
    unsigned int offset;
    static unsigned char last_second = 0xFF;

    _dos_gettime(&t);
    if (t.second != last_second) {
        last_second = t.second;
        offset = OFFSET_INIT;

        screen[offset++] = t.hour / 10 + '0';
        screen[offset++] = COLOR;

        screen[offset++] = t.hour % 10 + '0';
        screen[offset++] = COLOR;

        screen[offset++] = ':';
        screen[offset++] = COLOR;

        screen[offset++] = t.minute / 10 + '0';
        screen[offset++] = COLOR;

        screen[offset++] = t.minute % 10 + '0';
        screen[offset++] = COLOR;

        screen[offset++] = ':';
        screen[offset++] = COLOR;

        screen[offset++] = t.second / 10 + '0';
        screen[offset++] = COLOR;

        screen[offset++] = t.second % 10 + '0';
        screen[offset++] = COLOR;
    }
    // call the previous timer interrupt
    (*prevtimer)();
}

void main() {
    screen = (char far *)MK_FP(0xB800, 0x0000);

    disable();  // Disable interrupts

    prevtimer = getvect(8);
    setvect(8, updatetimer);

    enable();  // Enable interrupts

    keep(0, TSR_MEMORY_SIZE);
}
```
[source code](https://crg.eti.br/en/post/reescrevendo-velho-tsr-usando-bash/clocktrs.c)

## The Evolution of Operating Systems

When I wrote this TSR, there was no UNIX for PCs the way we have today with Linux and BSD. UNIX-based systems became popular later, bringing improvements in multitasking, memory management, and security.

With the arrival of Windows and the evolution toward modern operating systems, the need for TSRs dropped significantly. Today the operating system manages processes and *threads*, which gives us more safety, but we no longer have direct access.

## TSRs in Bash: A Modern Approach

The following Bash script is similar to the previous TSR, but adapted for UNIX-like systems and modern terminal emulators. Since Bash cannot access video memory directly, it uses ANSI commands to control the terminal. This includes saving the cursor position before displaying the clock and restoring it afterward, ensuring that other programs redrawing the screen do not interfere.

![Bash clock](https://crg.eti.br/en/post/reescrevendo-velho-tsr-usando-bash/relogio-bash.webp)

```bash
#!/bin/zsh

local last_second=0

display_time() {
    seconds=$(date +"%S")
    [ $seconds -eq $last_second ] && return

    local current_time=$(date +"%H:%M:")

    echo -ne "\e7\e[1;70H\e[30;47m$current_time$seconds\e[0m\e8"
}

while true; do
    display_time
    sleep 0.1
done
```
[source code](https://crg.eti.br/en/post/reescrevendo-velho-tsr-usando-bash/clock.sh)

To run the script and get the same effect as the TSR, just run it in the background:

```bash
./cloch.sh&
```

## Final Thoughts

Today we have more resources and systems that are safer and, in some ways, more flexible. Still, we can draw inspiration from techniques like *interrupt hooks* to create new and interesting things. The nostalgia of programming in more constrained environments reminds us of the creativity and ingenuity we needed back then. Maybe some of these old techniques can still be adapted or inspire innovative solutions today.

Besides that, understanding how systems worked at lower levels gives us a greater appreciation for the sophistication of modern systems. So the next time you use a simple command in the terminal, remember the layers of abstraction between your keyboard and the silicon.

Video with a detailed explanation:

@[youtube](_YGV_eNJCSw)
