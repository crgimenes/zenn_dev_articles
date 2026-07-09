---
title: "GlazeでCGOなしのGoデスクトップWebViewを作る"
emoji: "🪟"
type: "tech"
topics: ["go", "purego", "webview", "ffi", "cgo"]
published: true
---

Opening an HTML window from Go almost always charges a toll in C.

Either you turn on cgo and drag a C toolchain into the project, or someone embeds a compiled `.dll`/`.so`/`.dylib` in the binary and extracts it to disk on the first run. Both work. And both take away exactly what I like about the ecosystem: the `go build` that cross-compiles to three operating systems without a second thought, the reproducible build, the `go install` that just runs for whoever cloned the repo. That's the first thing to go the moment C enters the picture.

**Glaze** started out doing the second option. It was a fork of `go-webview`: it embedded the compiled C++ library from [webview/webview](https://github.com/webview/webview), extracted the blob into a temporary directory, and loaded it from there. It even did a BLAKE2b-256 check of the extracted file against the embedded bytes, so nobody could swap the library on disk between extraction and load. It worked. But that's a lot of ceremony just to open a window: one binary blob per platform, generated in a CI job, extracted at runtime, plus a hash to validate a file I had just written myself.

The turning point was to stop loading a library of my own and start calling the WebView the operating system already ships. macOS comes with WKWebView. Windows 10/11 ships the WebView2 runtime. On Linux it's a system WebKitGTK, which you declare as a dependency instead of packaging. In none of these cases does the native library need to travel inside the binary. It's already on the machine.

What was missing was a way to talk to it without cgo. That's where [purego](https://github.com/ebitengine/purego) comes in.

## purego is FFI without cgo

The idea behind purego is to open a shared library at runtime and call a C function directly, with no `import "C"` and no C compiler in the path. On Linux and macOS it's `dlopen`/`dlsym` under the hood:

```go
lib, _ := purego.Dlopen("libwebkitgtk-6.0.so.4", purego.RTLD_NOW|purego.RTLD_GLOBAL)

var webkitWebViewNew func() uintptr
purego.RegisterLibFunc(&webkitWebViewNew, lib, "webkit_web_view_new")
```

After that, `webkitWebViewNew()` is an ordinary Go function that calls the C symbol. No compilation stage, no headers.

On Windows there's no `Dlopen` -- you resolve the symbols with `LoadLibrary` and `GetProcAddress` and register them the same way. For a C callback that calls back into Go there's `NewCallback`, which on Windows delegates to the standard library's `syscall.NewCallback` and gets the stdcall convention right. And for macOS there's the `objc` package, which talks to the Objective-C runtime: register a class, create a Go method that AppKit calls back, blocks, structs passed by value. You can build an `NSWindow` with a `WKWebView` inside it entirely in Go.

## Every system has its own curse

It isn't free. You trade a binary blob for reimplementing the backend on each system, and each one charges its own price.

macOS was the cleanest. Cocoa via `objc`, the delegates registered as Go classes, the autorelease pool managed by hand. Tedious, but straightforward.

Linux is pure C ABI, the terrain where purego shines. The annoying detail is versioning. The original webview picks GTK3 or GTK4 at compile time; at runtime you don't get that luxury. So Glaze detects which stack is installed -- `libwebkitgtk-6.0` (GTK4) or `libwebkit2gtk-4.1`/`4.0` (GTK3) -- and switches the calls, because the arity of some functions changed between the two versions.

Windows was hell. WebView2 isn't a plain C API, it's COM. You call a method by index in a vtable of pointers, implement the callback interfaces on this side (a vtable built in Go with `QueryInterface`/`AddRef`/`Release`/`Invoke`), and on top of that you manage the ref-count of an object the garbage collector knows nothing about. And to keep the "zero DLL" promise without embedding `WebView2Loader.dll`, Glaze reimplements the loader's discovery: it finds the runtime DLL through the Windows registry and calls an internal Edge export to create the environment. That's what the official loader does under the hood. The price is that this export is internal and undocumented, and Microsoft could rename or remove it. If it disappears, you get a clear error instead of an ugly crash.

One rule runs through all three backends: **no Go pointer crosses over to C**. The engine is identified by an integer id kept in a map on the Go side, and what goes to C is only the integer. A Go pointer in C's hands is an invitation for the GC to move the memory out from under it.

## The test bench is CI

There's a thoroughly unglamorous detail: I develop on macOS. Linux and Windows I had no way to run by hand. And ABI bugs don't show up in cross-compilation -- it compiles beautifully and breaks at runtime.

So the test bench became containers and CI: GitHub Actions running all three systems (macOS, Windows, Linux on both GTK3 and GTK4, amd64 and arm64), plus an adversarial review of the COM code before spending CI cycles on Windows. That's how it surfaced, for instance, that `g_signal_handlers_disconnect_by_data` isn't an exported symbol, it's a GObject macro -- an undefined symbol that only blows up at runtime, inside a container. Or that passing a `RECT` by value to WebView2 works on amd64 and breaks on arm64, because the 16-byte struct goes by reference on one and packed into two registers on the other.

## What's left

In the end, what remains is what I wanted from the start:

- `CGO_ENABLED=0` everywhere;
- cross-compile to all three systems straight from `go build`, with no C toolchain;
- a binary that carries no native library with it;
- `go install github.com/crgimenes/glaze` working for whoever cloned the repo, no ritual.

What you start depending on instead is the runtime being present: nothing extra on macOS, a WebKitGTK on Linux, the Edge WebView2 Runtime on Windows (which already ships on 10/11). It's an honest trade: a system dependency declared out in the open instead of a dependency embedded and disguised.

Glaze no longer "uses" webview/webview at runtime. It became a port: the same idea, rewritten in pure Go on top of purego, without a single byte of C++ in the binary. Trading one compiled blob for three hand-written backends is more work, and it was. But what comes out of `go build` now speaks COM on Windows, objc on macOS, and GTK on Linux, without an `import "C"` anywhere.

[Glaze on GitHub](https://github.com/crgimenes/glaze)
