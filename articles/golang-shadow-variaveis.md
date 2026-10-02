---
title: "Goの変数シャドーイングをgo vetで検出する"
emoji: "🔍"
type: "tech"
topics: ["go", "govet", "staticanalysis"]
published: true
---

Go is an easy language to work with, and it helps you avoid a lot of common mistakes.

But one mistake that's easy to make in Go, and that the compiler still doesn't warn you about, is variable shadowing.

Shadowing happens when you declare a variable in one block and then declare it again, with the same name, in a nested block.

You then change the value of the variable believing you're updating the one from the outer block, but you're actually only changing the variable in the current block.

## Example

In the example below, the variable *x* is declared in the main block, but right after that, inside the *if* block, we use *:=* to declare the variable *err*, which causes *x* to be recreated in that block.

When the *if* block ends, that variable stops existing, and the previous instance of *x* becomes valid again.

```golang
package main

import "fmt"

var a = 1

func ret10() (int, error) {
    return 10, nil
}

func main() {
    x := 1
    if a == 1 {
        x, err := ret10()
        if err != nil {
            fmt.Println(err)
            return
        }
        fmt.Println("x =", x)
    }
    fmt.Println("x =", x)
}
```

As a result, the first *fmt.Println* prints *x = 10*, and the second prints *x = 1*.

Bugs like this are hard to debug, because everything looks normal at first glance.

## Experimental Detection

It's still experimental, but there's already a way to detect variable shadowing using the *go vet* tooling.

### Installing the Tool

The first step is installing the *go vet* tool that will help us look for "shadowed" variables in our code.

Use the following command:

```bash
go install golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow
```

Note that it's important to have the *go/bin* directory in your *PATH*.

### Looking for Shadowing

Then just run the following command in your project's directory.

```bash
go vet -vettool=$(which shadow)
```

For our example, the output will be:

```bash
./main.go:14:3: declaration of "x" shadows declaration at line 12
```

Now we know exactly where the shadowing is happening, which makes the problem much easier to fix.

*go vet* also sets the *errorlevel* (or *$?* in UNIX terms), so you can automate this check in CI tools or even a Makefile to stop the build from continuing.

### Tests

It goes without saying that tests help a lot in catching you off guard with variable shadowing.

It would be simple to write tests to make sure your function behaves as expected.

Even without *go vet*, it might take a while to figure out why the tests are failing, and it might make you scratch your head a few times, but at least you won't find out about the problem in production — *guess who didn't have test coverage in that situation*...

## Another Kind of Shadowing

Since variables and functions carry the same weight in Go, it's possible to shadow a function with a variable.

This isn't a huge problem, because the compiler will throw an error if you try to use a function that's been overridden by a variable, but it's still an inconvenience.

Take the following example:

```golang
package main

import "fmt"

func main() {
    len := 10 // shadows the builtin len() function
    fmt.Printf("len = %v\n", len)
}
```

In this example, the variable *len* is shadowing the runtime's *len* function. If we try to use that function anywhere else in our code, the compiler will throw an error.
