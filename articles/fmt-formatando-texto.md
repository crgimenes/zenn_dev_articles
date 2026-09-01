---
title: "fmtコマンド：シンプルで高速なテキスト整形ユーティリティ"
emoji: "📝"
type: "tech"
topics: ["terminal", "unix"]
published: true
---

The `fmt` utility is a simple, fast text formatter. Its purpose is to format text files or strings received via stdin so that lines don't exceed the maximum number of characters per line defined by the user.

It was originally intended to be used together with the mail utility, but it can be useful alongside other programs such as vim, for example.

The main parameters are:

- `-w`, which sets the desired number of characters per line.
- `-t`, which sets the tab width.

There are several other useful parameters; check your system's *manpage* to learn more.

## Examples

Reading text directly from a file:

```bash
fmt -t 4 -w 80 file.txt
```

Formatting text inside vim, receiving it via stdin and returning it via stdout:

```vim
:%!fmt
```

The `%` character tells vim to redirect all lines to fmt.

---

It's fairly simple to recreate the fmt utility with other UNIX utilities, at a slight performance cost.

```sh
#!/bin/sh 
sed '1i \
    .ll 72 \
    .na \
    .hy 0 \
    .pl 1' $* | nroff
```

## Warning

One thing to watch out for is that on some systems the name `fmt` was used for a disk formatting utility, so make sure you know what the command does on your system before testing it.

## Origin

The command `fmt` first appeared in *BSD3* in *1978*. That version was discontinued, and the version we use today was completely rewritten and appeared in *FreeBSD 4.4* in *1993*.

## Contributors

- Kurt Shoens
- Liz Allen
- Gareth McCaughan

## References

- UNIX manpages
- O'Reilly Unix Power Tools, 3rd Edition

## Videos with examples

- [YouTube](https://youtu.be/Yo0riwUgwo4)
- [Odysee](https://odysee.com/@crgimenes:7/comando-fmt-unix:1)
