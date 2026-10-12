---
title: "Goで自分自身を出力するプログラム（クワイン）を実装する"
emoji: "🪞"
type: "tech"
topics: ["go"]
published: true
---

## Printing your own source code

A quine is a program that prints its own source code to standard output. The name is a tribute to the mathematician and philosopher [Willard Van Orman Quine](https://en.wikipedia.org/wiki/Willard_Van_Orman_Quine).

There are [quine](https://en.wikipedia.org/wiki/Quine_(computing)) examples written in many programming languages. Writing your own version is an interesting exercise and a nice challenge.

Keep in mind that the rule forbids simply opening your own source file and printing it — that would be cheating. Your code has to generate a copy of itself on standard output without reading it from anywhere.

Watch the video we made at the [Golang Study Group](https://www.youtube.com/watch?v=x4JLUIqC4-s).

## Implementation in Golang

The Go implementation relies on a simple trick: we use the character code for the backtick to build a string containing a single quote character, then use `print` to output the contents of the *codigo* variable wrapped in two of them. There are other approaches, but this is the easiest one to implement.

```golang
package main

func main() {
    aspa := string(96)
    print(codigo, aspa, codigo, aspa)
}

const codigo = `package main
func main() {
    aspa := string(96)
    print(codigo, aspa, codigo, aspa)
}
const codigo = `
```

Source code for the example:
[example on the Golang Playground](https://play.golang.org/p/0GI71loR7i_A)
[example in the study group repository](https://github.com/crgimenes/grupo-estudos-golang)

Even though the ability to create a copy of itself sounds like a way to build a computer virus, that is not the case here. A virus usually just reads a copy of itself from memory or from another file — it doesn't need the extra difficulty of implementing a quine. That said, I'm sure it's an interesting challenge for scripting languages, and I'm sure someone has used the idea to write a virus, if only for the challenge.

These programming exercises and challenges are very useful for anyone who wants to become a better programmer. Learning these small tricks and pushing against the edges of what your favorite programming language can do forces you to deal with situations outside your daily routine, and that leaves you better prepared for when real problems show up.

