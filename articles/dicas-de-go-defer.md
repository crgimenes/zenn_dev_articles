---
title: "GoのdeferのTipsと落とし穴"
emoji: "⏳"
type: "tech"
topics: ["go", "defer", "development"]
published: true
---

Using [defer](https://blog.golang.org/defer-panic-and-recover) to postpone a command until the function returns, no matter how it returns, is an excellent idea. Imagine a function with several return points, either for errors or for a successful finish. Managing the closing of files, connections, mutexes, and other resources at each return becomes tedious and unsafe. You may forget to close a resource on some return path, and that can cause serious problems.

However, using `defer` has a cost. The runtime pushes the deferred command onto a stack, and deferring it is a few nanoseconds slower than a direct call. That is usually not a problem day to day, but if you need to squeeze the most performance out of your code, it may be worth considering.

The most common use of `defer` is releasing resources, such as closing a file. But any command can be deferred. For example, if I have a complex function that performs several tasks and cannot run in parallel on the system, I use a [mutex](https://golang.org/pkg/sync) to synchronize the code and avoid collisions. Since the function has several return points, `defer` helps guarantee that the lock is released.

```golang
m := &sync.Mutex{}
...
m.Lock()
defer m.Unlock()
```

## Watch out

Another important point is to avoid overwriting named return values with `defer`. For example, suppose you opened a file and used `defer` to make sure it gets closed.

```golang
f, err = os.Open("filename.ext")
if err != nil {
    log.Fatal(err)
}
defer f.Close()
```

The code above is simple and efficient. But if you want to handle the error from closing the file, you can do the following.

```golang
defer func() {
    err = f.Close()
    if err != nil {
        println(err.Error())
    }
}()
```
[full source code](https://crg.eti.br/en/post/dicas-de-go-defer/main.go)

At first glance everything looks fine. You properly handled the possible error from `Close`. The problem is that the *err* variable is a named return value of your function. Since the anonymous function is called at the end of the main routine, *err* will be overwritten by the return of `Close()`. So you will never get the real error from the function, and you will be left confused by not receiving the expected result or any error.

There are several ways to solve this. For example, you can use another variable instead of *err*, or simply ignore that error, since it is unlikely to be relevant. Another option is to replace the log with a panic. Keep in mind this is not a problem exclusive to `defer`. In theory, you can run into the same issue with goroutines, which can lead to [data race](https://crg.eti.br/en/post/go-previnindo-data-race/) situations.

Another common mistake with `defer` is calling it inside a loop. `Defer` pushes the given function onto a stack and runs it in reverse order, only when the function returns. If you use `defer` inside a loop, the function will be stacked many times, which can cause a stack overflow. For example:

```golang
for i := 0; i < 10; i++ {
    defer fmt.Println(i)
}
```

Despite these details to keep in mind, it is good practice to use `defer` to make sure allocated resources are released.

@[youtube](UdymPLCQ0yc)

@[youtube](GcV8wOy2irk)
