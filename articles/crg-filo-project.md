---
title: "Filo — Goに安全に組み込める最小のスクリプト言語を作った"
emoji: "🧵"
type: "tech"
topics: ["go", "lisp", "scripting", "security", "dsl"]
published: true
---

I built Filo for a problem that comes up every time I try to give end users scripting power without destroying the server.

The obvious paths are bad: the embedded language is either too weak to be useful, or too powerful to be safe. I wanted the third option -- small enough that an ordinary user can write short rules (validations, expressions, field logic), and closed enough that nothing can go down because of it.

Filo is a Lisp with minimal syntax. I picked Lisp because it's the cheapest syntax to implement and the most predictable for someone who has never programmed. `(+ 1 2)` is obvious. `(if (< age 18) "minor" "adult")` is too. There's nowhere to hide logic in syntactic ornament.

The runtime was built with explicit constraints from day one: step limit, recursion limit, timeout via `context.Context`, `recover()` around the executor. No script can cause a `panic` on the server. No file, network, or syscall access -- only the Go functions I explicitly register as builtins.

Use cases that motivated the project:

- a generic RAD-style application builder;
- a tabletop RPG platform with customizable rules;
- applications configurable by users or administrators.

The name comes from Italian *filo* ("thread"). Pronounced FEE-lo.

Full documentation, builtins, examples, and the Go integration API are in the repository.
