---
title: "Goのプラグイン機能の使い方と制約"
emoji: "🔌"
type: "tech"
topics: ["go", "plugin", "cgo", "development"]
published: true
---

Plugins are one of the few nearly forgotten features in Go, and frankly, I advise against using them. Unlike other features of the language, plugins only work on Linux, BSD, and macOS. Because they are built on `dlopen`, you cannot unload or replace a plugin once it has been loaded. On top of that, you need CGO, which brings complications of its own.

Despite the problems, plugins are an interesting feature and can be useful in some cases, such as loading a module dynamically.

Before compiling the plugin, you need to enable CGO.

```bash
export CGO_ENABLED=1
```

A plugin is written just like any other code we are used to. See the example below.

```golang
package main

import "fmt"

func Hello() error {
    fmt.Println("hello, plugins!")
    return nil
}
```
[source code](https://crg.eti.br/pub/go-plugins/hello.go)

Create a project as usual, but do not name it *plugin* — that causes a compilation error.

To compile a plugin, use the `-buildmode=plugin` flag.

```bash
go build -buildmode=plugin
```

This produces a *hello.so* file containing the functions a main program can load.

If you want the plugin to have a name other than *hello.so*, use the *-o* flag, as in the example:

```bash
go build -buildmode=plugin -o novonome.so
```

To use a plugin, first load the file.

```golang
var p *plugin.Plugin
var err error

p, err = plugin.Open("./hello/hello.so")
if err != nil {
    fmt.Println(err)
    return
}
```

Then look up the function inside the plugin file.

```golang
var s plugin.Symbol

s, err = p.Lookup("Hello")
if err != nil {
    fmt.Println(err)
    return
}
```

The variable *s* is an interface. Convert it to the same signature as the *Hello* function that came from the plugin. Create a variable with the same name as the function so you can call it directly.

```golang
Hello := s.(func() error)
```

Now you can call *Hello* normally, like any other function in your code.

```golang
err = Hello()
if err != nil {
    fmt.Println(err)
    return
}
```
[source code](https://crg.eti.br/pub/go-plugins/main.go)

Plugins can be useful for building less monolithic systems. That said, this does not seem as relevant today as it once was. The lack of support for other platforms, the CGO requirement, and the impossibility of unloading plugins all make the feature less appealing.

Video explaining the code:

@[youtube](z0g7fLNmxrk)
