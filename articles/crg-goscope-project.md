---
title: "GoScope — LSPに頼らずGoのシンボルを探索する軽量CLI"
emoji: "🔭"
type: "tech"
topics: ["go", "cli", "unix", "fzf"]
published: true
---

GoScope (`goscope`) is a CLI that scans a Go project starting from the current directory and lists every declared function, variable, constant, type, and function call, with file and line number. No configuration, no flags. You run it, it spits out the list.

`rgs` is the companion script. It takes the `goscope` output, pipes it into [fzf](https://github.com/junegunn/fzf), and opens the file in your editor (`$EDITOR`) at the exact line of the chosen item. If you have [bat](https://github.com/sharkdp/bat) installed, the fzf preview is colorized.

I built this because symbol navigation in editors usually depends on a running LSP, an up-to-date cache, and editor-specific integration. On large projects -- with code generation, vendored dependencies, modules with similar names -- that fails more often than it should. I wanted something dumb that ran directly, with no server and no cache, and that played well with fzf, which I already use for everything.

Build with `go build -o goscope`. Drop `goscope` and `rgs` into your `$PATH` and you're done.

Works on any Unix-like system (macOS, Linux).
