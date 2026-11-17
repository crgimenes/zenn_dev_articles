---
title: "Goのtimeパッケージとチャネルで定期実行する"
emoji: "⏱️"
type: "tech"
topics: ["go", "golang", "concurrency"]
published: true
---

## The time package

I am the first one to turn my nose up at the time package, mostly because of the way date formatting works, but one very interesting feature is being able to create a channel that fires every X interval, letting us run periodic actions.

There is a video of this file [here](https://www.youtube.com/watch?v=jTBtVrn-Cq8).

## Here is how it is done

First we create a channel that will fire every X interval — 300 milliseconds in this example.

```golang
timer := time.Tick(time.Duration(300) * time.Millisecond)
```

Then just consume the channel inside a loop, like below.

```golang
for {
    <-timer
    // do something periodically here
}
```

And that is it.

Let us look at a slightly more elaborate and complete example.

```golang
package main

import (
    "fmt"
    "os"
    "os/signal"
    "time"
)

func main() {

    go func() {
        sc := make(chan os.Signal, 1)
        signal.Notify(sc, os.Interrupt)
        <-sc

        fmt.Println("\nfim!")
        fmt.Print("\033[?25h")
        os.Exit(0)
    }()

    fmt.Print("\033[?25l")

    timer := time.Tick(time.Duration(300) * time.Millisecond)

    s := []rune(`◐◓◑◒`)
    i := 0
    for {
        <-timer
        fmt.Print("\r")
        fmt.Print(string(s[i]))

        i++
        if i == len(s) {
            i = 0
        }
    }
}
```

I have already covered [signal handling](https://crg.eti.br/en/pub/tratando-sinais-com-go/) and a way to use time to make a loop wait, but the approach in this article, using channels, looks far more like Go.

[Here is a much simpler version to run on the Go Playground](https://play.golang.org/p/ooNS3HC-0y)
