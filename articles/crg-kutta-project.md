---
title: "Goで作る小さな風洞「Kutta」"
emoji: "🌀"
type: "tech"
topics: ["go", "ebitengine", "simulation", "physics"]
published: true
---

You can explain lift with a diagram and an equation. It rarely sticks. Watch a wake peel off the back of a wing while you turn the angle of attack, and it sticks immediately. That gap is the whole reason **Kutta** exists.

It is a small 2D wind tunnel written in Go, rendered with [Ebitengine](https://ebitengine.org), running as a single desktop app.

[![Kutta running](https://crg.eti.br/en/post/kutta/kutta.webp "Kutta running")](https://github.com/crgimenes/kutta)

The idea never grew past the first sketch: stream air past an airfoil and make the flow visible. Change the angle of attack and the field reacts. Toggle between speed, vorticity and a pressure-like field. Draw your own shape. Cut a wing into a wing and a flap, animate the flap, and watch the wake go unstable when the geometry or the angle gets greedy.

It is a toy, and I mean that as praise. Small enough to poke at, grounded enough to teach something.

It ships with NACA 4- and 5-digit generation, so you type `2412`, `0012` or `23012` and get the shape with nothing loaded from disk. There is also a `neko` airfoil. It flies like a brick. That is the point.

## Qualitative, not validated CFD

This is the part I want to be loud about: Kutta is **not** a validated CFD tool.

It runs in lattice units, not physical ones. It gets the shape of the flow right (stagnation at the nose, the wake, suction over the top, separation as the angle climbs) and the numbers wrong on purpose. Use it for intuition, for teaching, for aeromodeling curiosity, for a demo that looks good on a projector. Do not use it to size a real wing.

That line is drawn deliberately. I trust a tool that is honest about what it is more than one that pretends to be more.

## How it works

The solver is a 2D Lattice-Boltzmann method, D2Q9 with BGK collision. A free stream enters from the left; the body is a no-slip wall done with half-way bounce-back; the forces come from integrating pressure over the body faces. So it catches form drag and lift, but not everything. Skin friction is ignored, which means drag reads low. A known limitation, not a hidden bug.

The code splits into a few packages that carry no rendering weight and test headlessly: `lbm` is the solver, `foil` generates the NACA shapes, `scene` and `sceneio` hold the editable scenes, `viz` does the color maps and the smoke tracers. On top sits the app: the Ebitengine loop, the editor, input and menus. There is also a snapshot tool that renders the fields straight to PNG, which is how I sanity-check the physics without opening a window.

## The editor

Kutta has a small shape editor. Draw a closed shape, drag vertices, pull a Bézier handle to curve an edge. Cut and rejoin shapes, which is what lets you split one airfoil into two: a wing and a flap that each keep the real profile.

Then there is an animation mode: scrub a timeline, drop keyframes, animate the pose of each part while the flow keeps running underneath. Scenes save as `.afoil`, a small textual s-expression format. I like formats you can open, read, diff and commit without a special tool.

## Why Go

Go is not the language people reach for when they want a visual toy, and that is half of why I keep using it for them. For Kutta it buys fast builds, cross-compilation without drama, readable code, and enough speed for a real-time qualitative sim. Ebitengine handles the window and the loop. What comes out is an ordinary desktop app: download one executable and run it.

There is a second, quieter reason. An open source project that produces an image, a sound or an animation is far easier to share than a library that only makes sense after you read its API. It does not make the visual project better. It makes it legible to someone who has three seconds and a scroll wheel. Kutta is a library-shaped idea wearing something you can watch.

## Running it

Prebuilt binaries and a Homebrew cask are on the repo. From source it is the usual:

```sh
go run .
```

On Linux, Ebitengine wants the usual Cgo/OpenGL/audio dev packages; macOS and Windows need nothing extra.

Kutta is MIT licensed: [github.com/crgimenes/kutta](https://github.com/crgimenes/kutta). If small visual tools in Go are your thing, a star tells me which experiments are worth feeding.
