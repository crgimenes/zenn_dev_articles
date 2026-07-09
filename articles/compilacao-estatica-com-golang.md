---
title: "Goで静的リンクバイナリをビルドする"
emoji: "📦"
type: "tech"
topics: ["go", "cgo", "linux"]
published: true
---

## Building monolithic executables

There is also a video that goes with this article, [here](https://www.youtube.com/watch?v=kdPWsCTREY8).

Go already does a good job of statically compiling almost everything, but depending on your code you may need a few extra flags to make sure your executable is completely free of dependencies.

The first step is to build your project and then inspect the binary to see whether it links against anything.

On macOS you do this with `otool` (the object file displaying tool), passing the `-L` flag, which lists the shared libraries in use:

```bash
otool -L nomedobinario
```

On Linux the equivalent command is `ldd`:

```bash
ldd nomedobinario
```

The `file` command can also hint at which shared libraries are being pulled in.

## CGO_ENABLED=0

If your binary shows no dependencies, you are done. In some cases, though, you need to disable cgo, and for that you just set the `CGO_ENABLED=0` environment variable:

```bash
CGO_ENABLED=0 go build
```

On older versions of Go, if you needed networking support you had to add the `-tags netgo` flag. It no longer causes errors, but it is no longer necessary either.

If you are linking against external libraries, you will need to pass a few flags to the linker through `-ldflags`, like this:

```bash
CGO_ENABLED=0 go build -ldflags '-extldflags "-static"'
```

And if you want to be sure everything was actually rebuilt, you can add the `-a` flag, which forces every package in use to be recompiled even if it is already up to date.

## Bonus

Since we are on the subject of build flags, we can pass two more to the linker to help shrink the final executable: `-ldflags "-s -w"`.

The `-s` flag strips debug information from the executable, and `-w` disables the generation of the DWARF (Debugging With Attributed Record Formats) data. Of course, without these you cannot debug the binary, so it may not always be what you want.

To see these and other [linker flags](https://golang.org/cmd/link), run:

```bash
go tool link --help
```

The final command ends up looking like this:

```bash
CGO_ENABLED=0 go build -a -ldflags '-extldflags "-static" -s -w'
```

[Cesar Gimenes](/pt-br/cesar-gimenes/)
