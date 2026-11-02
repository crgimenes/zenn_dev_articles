---
title: "Goで透明ウィンドウにDOOMの炎エフェクトを描いてみた"
emoji: "🔥"
type: "tech"
topics: ["go", "ebitengine", "gamedev", "graphics", "retro"]
published: true
---

I reimplemented the DOOM fire effect in Go, in a transparent window, using [Ebitengine](https://ebitengine.org).

The original formula is from 1993 and fits in a handful of lines: every pixel of the bottom row is a seed, the fire rises by propagating intensity to the row above, with a random horizontal offset and a color palette. It still hypnotizes.

The difference from most reimplementations is the transparent window: the fire rises over the desktop, the terminal, the open code -- whatever happens to be in the way.

```bash
export CGO_ENABLED=1
go run ./main.go
```

It was a weekend experiment, more about getting a better feel for Ebitengine and transparent windows than about the effect itself. The transparent-window piece later showed up in other projects of mine, like [Neko](https://crg.eti.br/en/projects/neko/).
