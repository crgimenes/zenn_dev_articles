---
title: "ブラウザ上のKutta：同じコード、変わるフレーム予算"
emoji: "🌀"
type: "tech"
topics: ["go", "ebitengine", "webassembly", "wasm"]
published: true
---

[Kutta](/en/post/kutta/) now runs inside a browser tab. Same source as the desktop build, `GOOS=js GOARCH=wasm`, no fork, no duplicated file holding a "web" version of the solver.

[![Kutta shedding vortices at 20 degrees angle of attack](https://crg.eti.br/en/post/kutta-no-navegador/vortices.webp "Kutta shedding vortices at 20 degrees angle of attack")](https://crgimenes.itch.io/kutta)

Speed is what you pay. A solver step costs **6.1 ms under wasm against 2.3 ms native**, measured on the 360x200 grid the app runs, on an M4 Mac, same solver compiled for both targets on the same machine. Factor of 2.6.

That number decides the simulation rate. The browser environment decides the rest.

## At 60 TPS, each tick has 16.7 ms

The native build advances three solver steps per tick. That is 6.9 ms, with room left for the smoke tracers, the color field and the panels.

Three steps under wasm would take 18 ms. It overruns the tick budget before anything gets drawn, and the browser starts to stutter. So the web build advances **one** step per tick.

The flow evolves slower in wall-clock time. The physics per step is identical: same D2Q9, same BGK collision, same half-way bounce-back. Only the simulated time per second of screen is lower. Smooth and slow reads better than fast and choppy, and for a qualitative tool that costs nothing real.

The default lives in two files split by build tag, [substeps_js.go](https://github.com/crgimenes/kutta/blob/v0.0.12/substeps_js.go) and [substeps_other.go](https://github.com/crgimenes/kutta/blob/v0.0.12/substeps_other.go):

```go
//go:build js
var substeps = 1
```

```go
//go:build !js
var substeps = 3
```

It is a `var`, not a `const`, on purpose. The `-substeps` flag overrides either one without a rebuild. That knob arrived in a PR from johncohn to buy CPU headroom on slow hardware, a Raspberry Pi running Kutta as a kiosk, and it turned out to fit the browser case exactly. A flag that trades flow evolution speed for CPU headroom works the same on both sides.

## A tab cannot write to a path

Desktop Kutta uses dialogs to open and save `.afoil` scenes, imports SVG outlines from the menu and has a native menu. In a tab, opening or importing becomes drag-and-drop; saving becomes a download; the native menu is gone.

The split is a constant, not a runtime `if`:

```go
//go:build js
const onWeb = true
```

A constant so the compiler drops the branch that does not apply, instead of carrying filesystem code that will never run. Three places in the app ask about `onWeb`; the rest of the code has no idea a browser exists.

"Save" in the browser became handing bytes to the download machinery: build a `Uint8Array`, wrap it in a `Blob`, `URL.createObjectURL`, create an `<a download>`, click it from code, remove it. The whole implementation fits in [webfile_js.go](https://github.com/crgimenes/kutta/blob/v0.0.12/webfile_js.go).

Then there is the scar. In Kutta, revoking the object URL right after the click canceled a download that had not started reading yet. The file just never showed up. No error, no warning. The fix was letting the URL go stale on a 60 second timer instead.

```go
js.Global().Call("setTimeout", release, 60000)
```

Sixty seconds is a guess with slack in it. I did not find a better number and I am not going to pretend I did.

## Size

`kutta.wasm` is **17.5 MB**. Served with gzip it drops to 4.25 MB.

That is a lot. It is the whole Go runtime plus Ebitengine inside a download the visitor takes before seeing the first pixel. `-ldflags="-s -w"` strips the symbols and does not change the game. Anyone who wants small wasm does not write Go; they write C or Rust and pay elsewhere.

I will take the 4 MB. What it buys is one codebase producing builds for Windows, macOS, Linux and the browser, with the solver written once.

## What this changes about shipping

The product page runs the simulator inside itself now. No download, no installer, no "trust me and execute this .exe": [crgimenes.itch.io/kutta](https://crgimenes.itch.io/kutta) loads the wasm and the wind tunnel is right there.

The executables are still there, one file per platform, no installer. Pay what you want, zero included.

Source stays MIT at [github.com/crgimenes/kutta](https://github.com/crgimenes/kutta), and the web build is one line:

```sh
GOOS=js GOARCH=wasm go build -trimpath -ldflags="-s -w" -o web/kutta.wasm .
```
