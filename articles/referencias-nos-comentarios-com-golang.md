---
title: "Goのコメントで識別子を参照してコードジャンプを楽にする"
emoji: "🔗"
type: "tech"
topics: ["go"]
published: true
---

A quick tip about comments in Go: include references in them. Put the element you want to reference between brackets (**[** and **]**). It works with anything that can be referenced, such as variables, constants, functions, and so on.

Here is an example:

```go
package main

import (
    "fmt"
    "time"
)

// pi representa a constante matemática Pi
const pi = 3.14159

// CalcularArea calcula a área de um círculo dado o raio.
// Utiliza a constante [pi] para o cálculo.
func CalcularArea(raio float64) float64 {
    return pi * raio * raio
}

func main() {
    raio := 5.0
    area := CalcularArea(raio)
    fmt.Printf(
        "A área do círculo com raio %.2f é %.2f\n",
        raio,
        area,
    )

    /*
        Formatos úteis:
        [time.DateTime]
        [time.Kitchen]
        [time.RFC3339Nano]
        [time.RFC3339]
    */
    fmt.Println(time.Now().Format(time.DateTime))
}
```

In Neovim, place the cursor between the brackets and press `Ctrl-]` to jump to the definition of the referenced element. To go back, press `Ctrl-t`. In VSCode, use the `Go to Definition` extension to do the same thing.

Comments and any kind of documentation often become outdated. The effort to keep them up to date is as big as the effort to maintain the code. There is an old joke that documentation is a lie waiting to happen.

The best documentation is the code itself. Good, descriptive names are better than comments.

You should not avoid writing documentation, but keep it at a manageable amount and in the places that really matter. Adding references in comments makes code navigation easier and adds usefulness and context for the reader.

Video with the demonstration:

@[youtube](ywFpjzoaj6M)

Until next time!
