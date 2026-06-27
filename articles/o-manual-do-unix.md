---
title: "manとmandocで読み解くUNIXマニュアル"
emoji: "📖"
type: "tech"
topics: ["unix", "terminal", "man", "mandoc", "linux"]
published: true
---

On November 3, 1971, the first edition of the [Unix Programmer's Manual](https://www.bell-labs.com/usr/dmr/www/1stEdman.html) was released — what we commonly know today as the man pages.

You can download it as a PDF or PostScript from [Dennis Ritchie's page at Bell Labs](https://www.bell-labs.com/usr/dmr/www/), which Nokia keeps online for historical reasons.

It is remarkable how little UNIX commands have changed over the years. If you use Linux or BSD, you will recognize most of them right away. It is also striking how an idea this simple can be this useful.

## The pager

The *man* command relies on a pager to display the manpages, usually *more* or *less*. You can override your system's default pager by setting the *PAGER* environment variable, like this:

```bash
export PAGER="less"
```

## Adding color to the manpages

On most modern systems, *less* is the pager. We can configure it to use colors and highlight headings, keywords, parameters, lists, and so on, which makes the text easier to read.

To colorize the manpages, first make sure *less* is your pager. Then add the following variables:

```bash
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'
```

Now open any manpage and several elements of the text will be colored. You can tweak the [ANSI codes](https://en.wikipedia.org/wiki/ANSI_escape_code) to customize the colors to your taste.

## Listing the files

Many programs, such as Python, install their own manpages. To list where those files live, use *man -w*:

```bash
man -w
```

The *man* command will print the paths it searches for manpages.

## Exporting manpages to HTML

Besides *man*, another handy utility is *mandoc*, which you can use to export manpages to other formats — HTML, for example:

```bash
mandoc -Thtml -Ostyle=style.css > foo.1.html
```

### A bit of mandoc history

*mandoc* first appeared in OpenBSD 4.8, released in November 2010. That makes it fairly recent compared to the rest of the UNIX toolset.
