---
title: "自分だけの時刻システムを作ってみた"
emoji: "🕐"
type: "tech"
topics: ["c", "tmux", "cli", "time"]
published: true
---

Measuring time is a serious task, and more complicated than it seems. Like any good nerd, I'm fascinated by the many ways of measuring and counting time. One that really catches my attention is "[decimal time](https://en.wikipedia.org/wiki/Decimal_time)".

There are several implementations of decimal time, usually dividing the day into 10 hours of 100 minutes each. Another approach is to ignore hours altogether and use only minutes as a continuous number. If you need more precision, you just use fractions of that minute, with as many decimal places as you need.

It may sound strange, but it's very easy to visualize. You get used to 1000 minutes per day quickly, and after a few days you start to notice a pattern, just like with analog clocks. In this case, the hands act as a progress bar for the day.

## Exploring Possibilities

You can go further, for example, by creating a decimal calendar with 10 months per year and 36.52422 days per month. A decimal calendar isn't all that useful, though. I don't need to calculate the winter solstice or the harvest date. For me, measuring the time within a day is enough, since most of my days are split between sleeping and sitting in front of the computer (and if you're reading this, probably yours too).

The big problem with changing something everyone is used to, like the way we measure time, is that for it to work, everyone has to get on board. Otherwise, you'll keep converting from one system to the other. No matter how good the idea is, change is hard. That's why Americans don't use the metric system in everyday life.

## Recent Attempts

The most recent attempt at a decimal clock was made by Swatch, which in 1998 created [Swatch Internet Time](https://en.wikipedia.org/wiki/Swatch_Internet_Time), with the day divided into 1000 parts called .beats, each lasting 86.40 seconds.

The idea was that there would be no time zones; everyone would use the time at the company's headquarters in Biel, Switzerland, equivalent to UTC+1. That way, if you set up a call with someone, no matter where they are on the planet, the .beats count would be the same for everyone.

Using the company's headquarters instead of UTC only complicated the math and lowered the chances of adoption, which were already extremely small.

```bash
echo '@'$(TZ=UTC+1 date +'(%-S + %-M * 60 + %-H * 3600) / 86.4'|bc)
```

## Building My Own System

Even so, the idea is interesting. Just for fun, why not build my own system?

I'll call it Individual Time (because Personal Time sounds like time spent in the bathroom).

## Let's See

- Like other implementations, the day will be divided into 1000 parts of 86.40 seconds each.
- The zero hour/time zone is defined by the user and doesn't have to be tied to geographic location. Since it's personal, you can use whatever you want as the zero hour. In my case, I'll use UTC-3.
- If, miraculously, someone wants to share the time of an event with me, they need to include their time offset. Since it's personal, it will be UTC plus or minus something, where that something can even be a fraction.
- As a symbol, instead of @, I'll use 時の (tokino), which means "of time" or "of the clock". The reason is purely aesthetic. So, for example, we have 時の500 for 12:00 PM and 時の750 for 6:00 PM.

## Implementation

Writing a program that displays the current decimal time is simple and will be fast in just about any language, but I need it to be very fast because I want the time to be shown in tmux, and if it's slow the tmux bar can end up flickering. So I decided to write it in C.

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    time_t now = time(NULL);
    struct tm *utc = gmtime(&now);

    int t = 0;
    char *format = NULL;
    char buffer[80];
    int opt;

    while ((opt = getopt(argc, argv, "t:f:")) != -1) {
        switch (opt) {
            case 't':
                t = atoi(optarg);
                continue;
            case 'f':
                format = optarg;
                continue;
            default:
                fprintf(stderr, "Usage: %s [-t timezone] [-f format]\n", argv[0]);
                return 1;
        }
    }

    if (t < -12 || t > 12) {
        fprintf(stderr, "Invalid timezone\n");
        return 1;
    } 

    // Adjust hour with timezone and normalize to [0, 23]
    int adjusted_hour = (utc->tm_hour + t + 24) % 24;

    // Calculate the beat value (Swatch Internet Time)
    int total_seconds_bmt = adjusted_hour * 3600 + utc->tm_min * 60 + utc->tm_sec;
    float beat = total_seconds_bmt / 86.4;  // 1 day = 1000 beats so 1 beat = 86.4 seconds

    if (format == NULL) {
        format = "@%06.2f\n";
    }

    printf(format, beat);

    return 0;
}
```

## Compiling

Here's an example Makefile to compile the program:

```bash
TARGET = internet_time

CC = clang
CFLAGS = -O3 \
         -march=armv8-a \
         -mtune=apple-m2 \
         -flto \
         -fomit-frame-pointer \
         -fno-unwind-tables \
         -fno-asynchronous-unwind-tables \
         -DNDEBUG

SOURCES = main.c

OBJECTS = $(SOURCES:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJECTS)
    $(CC) $(CFLAGS) -o $@ $^

%.o: %.c
    $(CC) $(CFLAGS) -c $< -o $@

clean:
    rm -f $(OBJECTS) $(TARGET)

.PHONY: all clean
```

## Usage

You can run the program from the command line as in the example below:

```bash
./internet_time -t -3
```

Or add it to your tmux.conf to display the decimal time in tmux:

```bash
set-option -ag status-right ' #[fg=white,bg=default]#(internet_time -t -3 -f "時の%%.f")'
```

To improve my Japanese pronunciation, I can also use the `say` command to speak the decimal time (on macOS):

```bash
say -v 'Kyoko (Enhanced)' `internet_time -l -f '時の%.f'`
```

## Conclusion

It's fun to think about other ways of doing things as established in our daily lives as counting the passage of time, and to experiment with the alternatives. Not to mention it's a game that never really ends. I could adopt the Julian day to go along with my decimal clock, for example. And now my tmux looks a lot more Cyberpunk.

The source code is also available on [GitHub](https://github.com/crgimenes/internet_time).
