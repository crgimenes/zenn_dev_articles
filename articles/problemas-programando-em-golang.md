---
title: "Goプログラミングでハマりやすい問題点まとめ"
emoji: "⚠️"
type: "tech"
topics: ["go", "golang", "programming"]
published: true
---

I love Go. I choose Go for many of my projects. It's simple and robust, with extensive documentation, plenty of examples, and a rich standard library focused on solving today's problems. It's without a doubt an excellent language.

However, nothing is perfect. Golang has its problems, like any other language. Some will be solved as the compiler evolves. Others, the programmer needs to watch out for. Let's look at some of the most common ones. Some of the issues mentioned here aren't exclusive to Go, but rather the result of bad code design that I've run into many times and that's worth mentioning.

## Variable Shadowing

Variable shadowing happens when a variable declaration overrides a previous declaration with the same name, for example inside an enclosing code block.

This mistake is hard to catch without help from the compiler, which can emit warnings about it. You can check your code with *go vet*. I wrote more about this in "[Variable shadowing in Golang](/pub/golang-shadow-variaveis/)".

It surprises me that the Go compiler doesn't include this check by default, since it's a well-known problem present in every C compiler I've ever used.

### defer Causing Shadowing

Any code block can cause variable shadowing, but *defer* is the main culprit. Programmers commonly write a small function to, for example, close a file. Following the recommendation to **never ignore errors** (errors should be handled, logged, or returned), they check whether the *Close* function returned an error while closing the file. This shadows the *err* variable from the outer function, because the function called by *defer* is in the same scope. Since it's rare for the *Close* function to fail, it usually returns *nil*, causing the outer function to also return *nil* instead of whatever error actually occurred.

```golang
func xyz() error {
  ...
    defer func(){
        err := f.Close()
        if err!=nil {
            fmt.Println("error closing file:", err)
        }
    }()
    ...
    return err // this error will always get overwritten
}
```

This is one more reason to always write tests for every error return path. If something should return an error and mysteriously returns *nil* instead, it might be shadowing caused by *defer*.

## Ambiguous Initialization

The *init()* function is quite useful, but it has its pitfalls. Over the years working with Go, I've run into countless ambiguous initialization issues, usually caused by things that shouldn't be in the *init* function to begin with.

To make things more confusing, you can have more than one *init* function in the same file (*imagine my shock*).

```golang
package main

import "fmt"

func init() {
    fmt.Println("init 1")
}

func init() {
    fmt.Println("init 2")
}

func main() {
    fmt.Println("main")
}
```

This code compiles and runs just fine.

```bash
$> go run main.go
init 1
init 2
main
```

In large projects with many packages, *init* can end up hiding errors or initializing things in a different order than expected.

These days, I avoid using the *init* function whenever possible. The one real justification for using it, in my opinion, is automating driver registration, for example when importing a package with *_* (underscore), like importing a database driver. After importing the *SQL* package, the driver registers itself automatically.

I prefer creating a *New* function that takes parameters and always returns, at minimum, an instance of the created object. This makes the code more flexible, easier to test, and more predictable.

## defer in a Loop

When we learn that the *defer* keyword postpones execution of a piece of code until the end of the function, programmers coming from *C* often associate that "end of the function" with "end of the code block," which is wrong. The end of a *for* block, for instance, doesn't trigger *defer*. *defer* only runs right before the function returns.

So when processing hundreds of files in a loop, opening a file and immediately calling *defer f.Close()* keeps every single file open until the function finishes.

```golang
for {
    ...
    defer func(){
        err := f.Close()
        if err!=nil {
            fmt.Println("error closing file:", err)
        }
    }()
    ...
}
return err
```

This scenario is bad and hard to debug, since the system can end up with many open files until it's done processing all of them. In infinite loops, this causes problems with the number of open file descriptors. It's just a matter of time.

On top of that, this *defer* can also shadow the error.

## Empty Interface

An [empty interface](../interface-vazia/) *interface{}* is basically a *void* pointer that accepts anything, bringing the same kinds of problems with it. You rarely need to use an empty interface. In the worst case, like parsing an unknown JSON structure, you can use *map[string]interface{}* and work with that map. It's important to always check that the interface's type is what you expect before using it.

Otherwise, you might get a *panic* when accessing the interface with the wrong type, or with *nil*.

When designing your system, avoid using the empty interface and create descriptive functions instead, like *String()*. You have no trouble imagining what that function returns just from its name.

## Wrong switch Case Order

Another mistake the compiler won't catch is using interfaces in a *switch case* that compares by type. If the broadest type is tested first among the cases, it will always match, and the remaining cases will never trigger.

I wrote more details in the tutorial "[A tricky bug with interfaces and switch case in Go](/pub/erro-na-ordem-do-switch/)".

## HTTP Timeout

By default, an HTTP call in Go has no *timeout*. If there's no response and no error, the call waits indefinitely. In environments with many *goroutines*, it's easy for some of them to get stuck, holding onto memory, and you end up not understanding why a process never finishes.

To fix this, always set a *timeout* on HTTP calls. Five seconds is plenty for any REST API.

Here's an example:

```golang
client := &http.Client{Timeout: 5 * time.Second}
```

A more elaborate approach, especially if you receive a *context* as a parameter, is:

```golang
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()
...
resp, err := http.DefaultClient.Do(request.WithContext(ctx))
```

## Goroutines

*Goroutines* make it easy to write concurrent code, but they bring their own set of problems.

### Goroutine Waiting on a Channel Forever

A *goroutine* can end up waiting on a channel that will never respond.

```golang
flag := make(chan string)
...
go func() {
        f := <-flag // waits for flag
        ...
}()
```

This can happen if the routine that created the *goroutine* exits before sending on the channel.

There are several solutions, such as using a *timeout*, a *context*, or sending a cancel message via *defer*.

#### Channel Timeout via *context*

This example uses *select* to receive either from the *result* channel or from *ctx.Done()* if the context gets canceled.

```golang
select {
    case <-ctx.Done():
        ...
    case result := <-ch:
        ...
}
```

The following example uses *time.After* to time out after 5 seconds without a response, avoiding an indefinite wait. Even if the *goroutine* ends up doing nothing and just exits, it's important to log the event to help identify timeout issues.

```golang
select {
   case <-time.After(5 * time.Second):
        ...
   case result := <-ch:
        ...
}
```

### Goroutines Need Time to Start

Spinning up a *goroutine* is fast, but not instantaneous. The Go runtime needs some time to start the *goroutine* and run other tasks.

When designing your code, keep in mind that right after a *goroutine* is created, it may not be running yet.

## All Channels Waiting

Channels in Go are fantastic. Communication between processes becomes simple and easy. But, like everything in life, there's a cost. Code that uses channels is harder to debug and can lead to *deadlocks*, where every single *goroutine* ends up waiting.

```golang
package main

func main() {
    m := make(chan string)
    go func(){}()
    <-m // deadlock!
}
```

This problem shows up at runtime. Fortunately, if the Go runtime detects that all goroutines are stuck, it raises a *fatal error: all goroutines are asleep - deadlock!*. That's better than the program hanging forever, but it's still bad.

## URL in the Binary

I was surprised to find out how much information the compiler stores in the binary, including the URL of every package used in the project.

Build a project that uses a package from GitHub and run:

```bash
strings nome-do-executável | grep github
```

You'll see the paths of every package used, including private repositories. This is a problem, since there's no flag to strip that information. It also exposes URLs that you might not want visible externally, making reverse engineering easier and potentially causing security issues, especially in areas like banking where URLs aren't allowed to appear in the code.

You can work around this using *go mod* with just the project name, or by compressing the binary with [UPX](https://upx.github.io). Either solution brings its own problems though, like false positives from antivirus software with UPX.

## Panic Is Too Noisy

When a *panic* happens, Go follows the Unix philosophy that "if something is going to go wrong, it should go wrong loudly." The *panic* error message is extremely detailed, making it slow to read through.

This might be a deliberate tactic to get you used to handling every possible error, avoiding panics in production.

## Dependency Management

Go's dependency management has improved a lot with *go mod*. Before that, with *vendor*, we ran into plenty of problems worth mentioning.

Most dependency problems were things we brought on ourselves. It's tempting to have packages that solve a bunch of things at once, or that get reused across different projects, and that creates all sorts of issues.

### Improving Dependencies

Let's look at how to improve your projects' dependency tree.

#### Dependencies Should Only Grow in One Direction

If you have a package in one project that turns out to be useful in another, split it out into its own separate repository. That way, you make sure the interface for interacting with the package's functionality is well defined and tested, and you can use it in both projects. Avoid pulling a package directly from one project into another, since that leads to changes that can break the second project without warning.

#### Clearly Define Code Responsibilities

To avoid constant churn, clearly define the responsibilities of each package. Invest time designing a solid, semantic interface. The goal is to keep the interface from changing too much over time, which makes it easier to maintain backward compatibility.

Whenever you change your packages, always consider backward compatibility. Other teams will get frustrated if they have to make abrupt changes to their code without good reason.

This matters even more if you maintain open source code. Imagine people all over the world using your code. You don't want to randomly break projects belonging to developers you've never met because of unplanned changes.

#### Version Your Packages

Use Git's tagging features to version your packages. This gives you better control over changes and makes it easier to use *go mod*, especially for open source code. Versioning your code is always a good idea.

## Premature Optimization and DOS

These aren't problems specific to Go, but they're still relevant.

It's fun, and relatively easy, to optimize code in Go. *Goroutines* and channels make it simple to spin up many threads and squeeze the most out of modern multi-core machines. But it's just as easy to exceed the limits of the machine, like opening hundreds of thousands of simultaneous connections and exhausting the machine's IO. (*We've done this*)

Another issue is that Go is fast. If you write a system that hits data from another API, you need to rate-limit the number of connections per second. Otherwise, you might accidentally launch a DOS attack against that very API.

## Tightly Coupled Code

While this isn't a flaw in Go itself, it's common to end up writing tightly coupled code because of the language's characteristics. It's easy to tell if your code is too coupled: difficulty writing unit tests, source files with thousands of lines, or an import list with more than 10 entries are all signs of high coupling.

This happens because Go favors structured programming, which can lead to code design problems. That said, to me, it feels closer to how computers actually work.

To avoid tight coupling, split your code into packages with well-defined responsibilities, connected through carefully designed interfaces and backed by good test coverage (*sorry if this sounds repetitive, but it matters*).

## Conclusion

Golang has problems, some serious, and since it's still a young language, it's up to us as programmers to know them and watch out for each one. We can't leave everything up to the compiler just yet. There are also design-level problems, like URLs ending up in the executable.

As the compiler and tooling evolve, I expect some of these issues to disappear. For others, I'm counting on the active community to help document the obstacles.

Of course, I haven't covered every possible mistake. Nothing can replace a creative programmer's ability to write code that's valid to the compiler but does something completely unexpected. I'll try to add new issues here as I remember or run into them.
