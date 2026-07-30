---
title: "Goで作るターミナル上のプラズマエフェクト"
emoji: "🌈"
type: "tech"
topics: ["go", "terminal", "cli", "demoscene"]
published: true
---

One kind of program I've always found interesting is the *demo*: eye-catching graphical effects with code that squeezes every ounce of performance out of the machine. The plasma effect is one of my favorites, simulating a fluid in motion.

![plasma in the terminal with Go](https://crg.eti.br/en/post/efeito-plasma-no-terminal-com-golang/plasma.webp)

To create the plasma effect, I use several trigonometric functions to calculate the background color of each character, passing time as a parameter to generate the animation. The code is relatively simple, but the optimization is a bit more complex.

Computing these values continuously is very slow, and the terminal isn't very fast either. To avoid slowdowns that make the terminal output flicker, I precompute some of the calculations.

```go
func precalculateValues(r, c int) {
    preSinX = make([]float64, c)
    preCosX = make([]float64, c)
    preSinY = make([]float64, r)
    preCosY = make([]float64, r)
    preSinXY = make([][]float64, r)
    preCosXY = make([][]float64, r)

    for i := 0; i < r; i++ {
        preSinXY[i] = make([]float64, c)
        preCosXY[i] = make([]float64, c)
    }

    for x := 0; x < c; x++ {
        aX := (float64(x) / float64(c)) * math.Pi * 3
        preSinX[x] = math.Sin(aX)
        preCosX[x] = math.Cos(aX)
    }

    for y := 0; y < r; y++ {
        aY := (float64(y) / float64(r)) * math.Pi * 3
        preSinY[y] = math.Sin(aY)
        preCosY[y] = math.Cos(aY)
        for x := 0; x < c; x++ {
            aXY := ((float64(x) +
                float64(y)) / float64(c)) * math.Pi * 3
            preSinXY[y][x] = math.Sin(aXY)
            preCosXY[y][x] = math.Cos(aXY)
        }
    }
}
```

Precomputing is only part of the optimization. This code could be faster, but it's already fast enough without hurting readability.

Another optimization is precomputing the colors. For that, I use the following code:

```go
func precalculateColorStrings() {
    for i := 0; i < 256; i++ {
        colorStrings[i] = "[48;5;" + strconv.Itoa(i) + "m[38;5;0m"
    }
}
```

This way, we avoid recomputing the same *string* over and over.

Speaking of *strings*, another important optimization is sending as much data to the terminal as possible at once. For that, I use the following code, with a preallocated buffer.

```go
bufCap := 20000
buf := make([]byte, 0, bufCap)
```

This speeds up the program considerably. I left the buffer with a fixed size, but ideally its size would be calculated based on the terminal size. That's tricky, though, because it's not enough to multiply height by width; you also have to account for the size of the *strings* and escape codes. So I just created a buffer large enough.

The complete source code is in the [Go Study Group](https://github.com/crgimenes/grupo-estudos-golang/tree/master/plasma) repository.

Video of the program running:

@[youtube](gEIMDJ8gl_k)
