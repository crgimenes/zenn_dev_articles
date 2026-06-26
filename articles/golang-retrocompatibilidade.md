---
title: "Goが約束する後方互換性"
emoji: "🔄"
type: "tech"
topics: ["go", "golang", "gofix", "compatibility"]
published: true
---

When Go 1.0 was released, the team made a [commitment to backward compatibility](https://go.dev/doc/go1compat) as new versions came out.

That commitment has some interesting consequences. The code you learn doesn't go stale, and keeping the language backward compatible reinforces another important goal: simplicity and readability. A project that sat untouched for months, or even years, still compiles on the first try. I've seen this firsthand with code that *sat in a drawer* for three years.

Even with all that effort, it isn't always possible to keep absolute compatibility for so many years. Security flaws, for example, sometimes have to be reflected in the code, and small changes can creep in. For those rare cases there's the *go fix* command. And even then it's rarely needed. I only remember reaching for *go fix* once.

For instance, *go fix* replaces the old `+build` build tag with the new `go:build`. In a file, the line `// +build !windows` becomes `//go:build !windows`.

### Example

```bash
go fix ./...
luaengine/setwinsize_unix.go: fixed buildtag
luaengine/setwinsize_windows.go: fixed buildtag
term/resizeterm_unix.go: fixed buildtag
term/resizeterm_windows.go: fixed buildtag
```

## Limitations

Aside from security fixes, the compatibility is at the source level, not the binary level. So even though your code keeps compiling and behaving as expected, it may produce different binaries.

## How incompatibilities are found

The Go team does a few interesting things to keep backward compatibility. First, they maintain a list of every function exported by the standard library. When they test a new release, they compare the old list against the new one, which tells them whether anything broke.

Another interesting way compatibility gets validated is through tests. Before a new release ships, it's tested against Google's entire Go codebase, on the assumption that if compatibility breaks at Google, it will break for everyone else too.

## Keeping code extensible

Go is careful not to break the API around structs and interfaces. One nice technique, for example, is to use named fields whenever you populate a *struct*. That way, if you add new fields later, old code that uses named fields keeps compiling.

Consider the following struct:

```go
type valores struct {
    a int
    b int
}
```

The code below compiles fine.

```go
val1 := valores{a: 1, b: 2}
val2 := valores{1, 2}
```

If down the road you decide you need another field and change the *struct* like this:

```go
type valores struct {
    a int
    b int
    c int
}
```

The `val1` line keeps compiling and working as expected, but `val2` no longer compiles.

Because Go initializes values automatically, fields that aren't populated get a predictable value. Even pointers default to *nil*, which makes them easy to handle in code.

## *Fork* Go (or parts of it)

As a last resort, one way to extend the life of your program is to *fork* the parts that, for whatever reason, lost compatibility with the version you're on.

That's a somewhat drastic option, but sometimes necessary, especially if you depend on third-party libraries. The catch is that while your code keeps compiling, you won't get security updates and improvements. You take on the responsibility of maintaining that forked piece yourself.

## References

- [Go 1 and the Future of Go Programs](https://go.dev/doc/go1compat)
- [How Go Programs Keep Working](https://www.youtube.com/watch?v=v24wrd3RwGo)
- [Introducing Gofix](https://go.dev/blog/introducing-gofix)
