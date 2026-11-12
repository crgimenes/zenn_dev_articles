---
title: "Goでデータ競合を検出して防ぐ"
emoji: "🏁"
type: "tech"
topics: ["go", "concurrency", "development"]
published: true
---

In [Ricardo Gomes' project, where we got a nice performance boost](https://crg.eti.br/en/pub/go-carregando-arquivos-sped-fiscal-super-rapido/), we also accidentally introduced a nice data race.

There is a video about that file [here](https://www.youtube.com/watch?v=BpCtTkJKDxU).

A data race happens when two different threads access the same variable at the same time.

But Golang has tools for everything, and while playing with this I learned about the [-race](https://golang.org/doc/articles/race_detector.html) flag. This flag makes Golang look for possible data races in your code, and it can be used with test, run, build, and install.

## Testing the Data Race Detector

Consider the following code.

```golang
package main

func main() {
    var x int

    go func() {
        x++
    }()

    x++
    println(x)
}
```

Now try running it passing the -race flag to run.

```bash
go run -race main.go
```

The output will look like this:

```bash
> $ go run -race main.go                                                                                     
1
==================
WARNING: DATA RACE
Read at 0x00c42007c000 by goroutine 5:
  main.main.func1()
      /Users/cesar/test/main.go:7 +0x3b

Previous write at 0x00c42007c000 by main goroutine:
  main.main()
      /Users/cesar/test/main.go:10 +0xa7

Goroutine 5 (running) created at:
  main.main()
      /Users/cesar/test/main.go:8 +0x7d
==================
Found 1 data race(s)
exit status 66
```

As expected, Golang raised a warning about the data race, showing the lines, the goroutines, and so on.

Now let's change the code to fix the problem. We could use channels here, but the simplest approach, and the one closest to other languages, is to lock and unlock whenever we read from or write to resources shared between threads.

Here is the fixed code:

```golang
package main

import "sync"

func main() {
    var x int
    var m sync.Mutex

    go func() {
        m.Lock()
        x++
        m.Unlock()
    }()

    m.Lock()
    x++
    println(x)
    m.Unlock()
}
```

Test it with ```golang run -race main.go``` as we did before, and you will see the warning is gone, since there is no longer any risk of a data race.

The number of static analysis tools that come *out of the box* in Go is impressive.

One last detail: this code will always print 1 for x, because the main function finishes too fast and Golang cleans up the goroutines as soon as main returns, so our goroutine never gets the chance to add anything to x. I used this example only to illustrate the point with as little code as possible.
