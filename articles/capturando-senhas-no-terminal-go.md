---
title: "Goでターミナルからパスワードを安全に読み取る"
emoji: "🔑"
type: "tech"
topics: ["go", "security", "terminal", "cli"]
published: true
---

Reading a password in the terminal looks trivial, but it has two pitfalls: the password shows up on screen if you use ordinary input, and you need to make sure you're really dealing with a terminal and not a redirection. Let's solve both with the `golang.org/x/term` package.

If you read with `bufio.Scanner` or `fmt.Scanln`, every keystroke shows up on screen. That won't do for a password. `term.ReadPassword` reads straight from the terminal, without echo:

```go
fd := int(os.Stdin.Fd()) // #nosec G115 -- stdin's fd is small; the conversion is safe
fmt.Print("password: ")
pass, err := term.ReadPassword(fd)
fmt.Println() // the user's Enter doesn't emit a newline; we do it
```
[Full source code](https://crg.eti.br/en/post/capturando-senhas-no-terminal-go/main.go)

If the input comes from a *pipe*, there's no terminal to turn echo off on. It's worth refusing up front:

```go
if !term.IsTerminal(fd) {
    return "", errors.New("an interactive terminal is required for the password")
}
```

When the password is new, ask for it twice and compare. That way a typo doesn't create a secret you can never open again:

We also use `#nosec G115` to silence the security warning about using `os.Stdin.Fd()`, which is safe in this context.

To compare the passwords, you could cast them to strings, but it's better to use `bytes.Equal`, which is more efficient.
