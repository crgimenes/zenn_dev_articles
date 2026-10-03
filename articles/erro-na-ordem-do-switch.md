---
title: "Goのinterfaceとswitch文に潜む厄介なバグ"
emoji: "🐛"
type: "tech"
topics: ["go", "development"]
published: true
---

Watch the video about this bug on the [Golang Study Group](https://www.youtube.com/watch?v=v3h024EtxCU) channel (in Portuguese).

Golang is an easy language to program in, and it has few traps for the programmer. Most things that can go wrong are caught by the compiler or by one of the many static analysis tools that help keep our code *almost* bug free.

But there are situations where even those tools have a hard time warning us, because there is no way to know what the programmer expected the program to do. This usually happens when you use the more entertaining features of the language, such as *switch*, *interfaces*, *channels*, and *goroutines*.

### The switch case order bug

Here we are going to look at a bug that is really hard to spot: the order of the *cases* in a *switch* is wrong. The broadest case comes first, so the *switch* always stops there. To fix it, all you have to do is reorder the *cases*, putting the narrower ones at the top. But by then you have already burned a lot of time debugging and several liters of coffee. You need to understand how the language features work, because no compiler can catch every possible mistake an inspired programmer might make.

Take a look at the example below.

```golang
package main

import "fmt"

type comptometer interface {
    Sum(a, b int) int
}

type foo struct{}

func (_ foo) Sum(a, b int) int {
    return a + b
}

type bar struct{}

func (_ bar) Sum(a, b int) int {
    return a + b
}

//
func printType(e comptometer) {
    /*
        This switch is in the wrong order
        and will always print "comptometer
        interface", never reaching the
        other cases. Move the comptometer
        case to the end of the switch
        to fix the bug.
    */
    switch e.(type) {
    case comptometer:
        fmt.Println("comptometer interface")
    case *foo:
        fmt.Println("pointer to foo")
    case *bar:
        fmt.Println("pointer to bar")
    }
}

func main() {
    var f = &foo{}
    printType(f)
    var b = &bar{}
    printType(b)
}
```

The *switch* statement tests each case in the order they appear and jumps to the first one that matches. In the example, the *comptometer* interface always satisfies the condition, because both *structs* implement the function the interface expects.

You can see the source code for this example in our [Golang Study Group repository](https://github.com/crgimenes/grupo-estudos-golang).
