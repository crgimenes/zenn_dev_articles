---
title: "tr で文字を置換する — Unix の小さな定番ツール"
emoji: "🔤"
type: "tech"
topics: ["unix", "terminal", "bash", "cli"]
published: true
---

This is a simple and very useful utility. Basically, `tr` filters strings one character at a time, and when used correctly it is even UTF-8 compatible.

Character filtering is defined by the parameters, and to make things easier you can use character *classes*, for example `[:upper:]` for all uppercase letters or `[:cntrl:]` for all control characters.

## Parameters

The parameters I use most are the following:

- `-d` *delete* to remove characters.
- `-s` *squeeze*, which is quite handy for collapsing sequences of repeated characters.

## Examples

Converts uppercase to lowercase, but fails with UTF-8 characters.

```bash
echo ÁÉÍÓÚ | tr 'A-Z' 'a-z'
```

Same as the previous example, converting from uppercase to lowercase, but this time it doesn't fail with UTF-8 characters.

```bash
echo ÁÉÍÓÚ | tr '[:upper:]' '[:lower:]'
```

Replaces line breaks with spaces.

```bash
echo "teste1\nteste2" | tr '\n' ' '
```

Strips everything from the string, leaving only the digits.

```bash
echo "O numero de telefone é (11) 12345-6789" | tr -cd '[:digit:]'
```

Removes all control characters, leaving only the plain text.

```bash
tr -d '[:cntrl:]'
```

Takes the contents of the PATH environment variable and breaks the paths one per line.

```bash
echo $PATH | tr  ':' '\n'
```

Removes repeated characters.

```bash
echo teste        teste  | tr -s ''
```

Rot13, probably the weakest encryption in the universe, but still fun.

```bash
tr a-z n-za-m
```

## Portability

tr has been rewritten many times for different platforms, and some parameters and behaviors that exist in certain versions don't exist in others. If you're concerned about the portability of your scripts, try to stick to the parameters defined by *POSIX*.

## Origins

I believe the first release of the `tr` utility was in the *1973* version of *Unix Time-Sharing System 4*.

## Authors

- Douglas McIlroy (doug)

## References

- UNIX manpages
- A Research UNIX Reader: Annotated Excerpts from the Programmer's Manual, 1971-1986

## Videos with examples

- [YouTube](https://youtu.be/rBSgawLwNuo)
- [Odysee](https://odysee.com/@crgimenes:7/utilitário-tr-unix:e)
