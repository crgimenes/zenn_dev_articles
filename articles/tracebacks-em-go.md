---
title: "Goのトレースバック：runtime.Callerでコールスタックを探る"
emoji: "🔍"
type: "tech"
topics: ["go", "golang", "runtime", "debug"]
published: true
---

Many programming languages provide some kind of "stack trace" or "backtrace". Python has the `traceback` module, C on Linux offers the `backtrace()` function in `execinfo.h` (not part of the C standard), and Java includes `Thread.dumpStack()` or `e.printStackTrace()` for exceptions.

## Stack Trace in Go

Go provides the `runtime.Caller` function to get information about the call stack. The following example prints the file, line, and function that called `info()`. Note that the argument `1` passed to `runtime.Caller` means we want information about the function that called `info()`:

```go
func info() {
    count := 1
    for {
        pc, filePath, lineNumber, ok := runtime.Caller(count)
        if !ok {
            return
        }

        funcName := runtime.FuncForPC(pc).Name()

        fmt.Printf("%d %s:%d %s\n",
            count,
            filePath,
            lineNumber,
            funcName)

        count++
    }
}
```

You can use this data in a logging system to trace the origin of an error. Go's standard `log` package already captures part of this information, but you may want to customize the output or persist the data to a database. In projects with financial transactions, for example, it's common to record each transaction with a unique end-to-end ID that follows every step of the transaction, and including some data about the program's execution makes it much easier to trace problems and run audits.

If you want to print the entire call stack, use a loop that calls `runtime.Caller` repeatedly until no more information is available. The following example illustrates this approach:

```go
func traceback() {
    i := 1
    for {
        _, file, line, ok := runtime.Caller(i)
        if !ok {
            break
        }
        fmt.Printf("File: %s, Line: %d\n", file, line)
        i++
    }
}
```

That gives you a custom "stack trace" in Go. For more details about `runtime.Caller`, see the official documentation at: https://pkg.go.dev/runtime#Caller

## runtime.CallersFrames

Another way to get more details about the program is the `runtime.CallersFrames` function, which returns an iterator for exploring the call stack. The following example prints the file, line, and function of each frame in the call stack:

```go
pcs := make([]uintptr, 10)
n := runtime.Callers(0, pcs)
pcs = pcs[:n]

frames := runtime.CallersFrames(pcs)
for {
    frame, ok := frames.Next()
    if !ok {
        break
    }
    fmt.Printf(
        "%s:%d %s\n",
        frame.File,
        frame.Line,
        frame.Function,
    )
}
```

## Log

Just for the record, you can very easily make Go's `log` print the current line and the file where it was called. Just use the `SetFlags` method of `log` when your program starts:

```go
log.SetFlags(log.LstdFlags | log.Lshortfile)
```

## -trimpath

Go stores the full path of your system's files and imported dependencies. If you compile the program on your machine, the path will reflect the local directory, possibly exposing your username and other irrelevant or sensitive information. This data can pollute your logs. To remove these paths, use the `-trimpath` flag when compiling. This way, Go reduces the exposure of sensitive details:

```bash
go build -trimpath main.go
```

## Conclusion

Getting the call stack in Go is simple and helps trace the origin of errors in large projects. This feature is a valuable tool for auditing and diagnostics. Use `runtime.Caller`, the custom traceback function, or `runtime.CallersFrames` to collect detailed information, and use flags like `-trimpath` to protect sensitive data.

Video with the code demonstration:

@[youtube](c3dwnoxjP_g)

[Cesar Gimenes](https://crg.eti.br/en/cesar-gimenes/)
