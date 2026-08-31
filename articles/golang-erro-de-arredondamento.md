---
title: "Goにおける丸め誤差の落とし穴"
emoji: "💰"
type: "tech"
topics: ["go", "golang", "math", "floatingpoint"]
published: true
---


When we write programs that deal with money, the ideal approach is to always use cents. That way we can use integer variables, and it's much easier to prevent errors caused by [how computers store floating-point numbers](https://en.wikipedia.org/wiki/IEEE_754).

But we don't always get to choose. When we consume third-party *APIs*, for example, best practices aren't always followed. In fact, in day-to-day work, ideal conditions are a rarity.

Not long ago I ran into a problem like this: an *API* my system needed to consume returned a *JSON* where the value field was not only a string but also a floating-point number.

So I did the simplest conversion and forgot about the floating point.

```go
vf, _ := strconv.ParseFloat(value, 64)
vi := int(vf * 100.0)
```

The problem with this small oversight is that it introduces a bug that's hard to detect, because it doesn't happen for every value. In my code, the string "1.15" after conversion ended up becoming the integer `114` when it should have become `115`.

Fortunately, the [math](https://pkg.go.dev/math) package has ready-made functions to handle this kind of rounding problem. In my case I used *math.Round* and the problem was solved.

```go
vf, _ := strconv.ParseFloat(value, 64)
vi := int(math.Round(valueFloat * 100.0))
```

Here's a more complete example.

## Example

```go
package main

import (
    "fmt"
    "math"
    "strconv"
)

func main() {
    value := "1.15"
    valueFloat, _ := strconv.ParseFloat(value, 64)

    valueCentsError := int(valueFloat * 100.0)
    valueCentsCorrect := int(math.Round(valueFloat * 100.0))

    fmt.Println("Valor original string......:", value)
    fmt.Println("Valor convertido para float:", valueFloat)
    fmt.Println("Valor em centavos (errado).:", valueCentsError)
    fmt.Println("Valor em centavos (correto):", valueCentsCorrect)

}
```

[Example code](https://crg.eti.br/en/post/golang-erro-de-arredondamento/main.go)

The parse error handling was removed to keep the example clean, but in real code never skip handling any error.

Another thing that can matter is that Go doesn't necessarily guarantee that an int will be 64 bits. The language manual says it guarantees at least 32 bits. So in some cases it can be worth using *int64*, or even *uint64* if you're sure the value will never be negative.

Here's a video with an explanation of the code.

@[youtube](L4dD1kyK1y8)
