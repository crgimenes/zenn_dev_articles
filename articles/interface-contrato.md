---
title: "Goのインターフェースを契約として使う"
emoji: "🤝"
type: "tech"
topics: ["go", "interface", "development"]
published: true
---

Watch the video for this article [here](https://www.youtube.com/watch?v=ck9rGF0tfRE).

We covered this same topic in the example list of our study group on interfaces, but that was back in the distant year of 2016, so let's build a new example showing how to use an interface as a contract. The contract lets you pass different types to a function, or accept different types through an interface, as long as they implement it — in other words, as long as they implement the functions described in the interface.

The example below is a small program that implements the `melancia` (watermelon) struct and then uses that struct both as a parameter and to initialize a variable. It works, but using concrete types this way makes the program rigid: you cannot interfere with the functions that will run, since you cannot change which function gets called.

```golang
// usando tipos concretos
package main

import (
    "fmt"
)

type melancia struct {
}

func (m melancia) nome() string {
    return "melancia"
}

func vitaminaDe(m melancia) {
    fmt.Println("vitamina de", m.nome())
}

func main() {
    var x melancia
    x = melancia{}
    nome := x.nome()
    fmt.Println(nome)

    vitaminaDe(x)
}
```

Now let's make a small change to our program: instead of using the struct directly, we'll use an interface both to declare the variable and to pass the parameter to the function.

Note the `fruta` (fruit) interface in the example below and the fact that it declares the `nome()` function. Any struct that implements this function can be used as an argument to the function, which makes the program far more flexible and lets it accept different data types.

```golang
// usando interface
package main

import (
    "fmt"
)

type fruta interface {
    nome() string
}

type melancia struct {
}

func (b melancia) nome() string {
    return "melancia"
}

func vitaminaDe(f fruta) {
    fmt.Println("vitamina de", f.nome())
}

func main() {
    var x fruta
    x = melancia{}
    nome := x.nome()
    fmt.Println(nome)

    vitaminaDe(x)
}
```

One more example, this time with two structs. Since both structs satisfy our contract, we can pass either one. This is great when you want to mock a package for tests: if you take an interface as the parameter, at test time you just swap the original struct instance for one better suited to the test.

```golang
package main

import (
    "fmt"
)

type fruta interface {
    nome() string
}

type melancia struct {
}

func (m melancia) nome() string {
    return "melancia"
}

type banana struct {
}

func (b banana) nome() string {
    return "banana"
}

func vitaminaDe(f fruta) {
    fmt.Println("vitamina de", f.nome())
}

func main() {
    var m fruta
    m = melancia{}
    nome := m.nome()
    fmt.Println(nome)

    vitaminaDe(m)

    b := banana{}
    nome = b.nome()
    fmt.Println(nome)

    vitaminaDe(b)
}
```

Finally, a small trick: did you know that if your struct implements a `String()` function, the `fmt` package will automatically use it to convert your struct instance to a string in functions like `Print`? Very handy for writing better logs.

## Useful links

- Source code for today's examples
    1. https://play.golang.org/p/7YnT6sB2PCb
    2. https://play.golang.org/p/HtM3kYwygBK
    3. https://play.golang.org/p/bpaYKqNMiOR
    4. https://play.golang.org/p/FA8t_26kwAZ
- [Our study group repository](https://github.com/crgimenes/grupo-estudos-golang)
