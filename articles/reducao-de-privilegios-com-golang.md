---
title: "Goプログラムの実行権限を下げてセキュリティを高める"
emoji: "🔒"
type: "tech"
topics: ["go", "security", "unix"]
published: true
---

A good practice for improving the security of a system is to drop a program's execution privileges. Ideally, a program should run with the fewest privileges possible.

On UNIX-like systems, you can change the user and group a program runs as. Let's walk through how to do that in Go.

## Checking Whether the Program Is Running as Root

First, check whether the program is running as root. This matters because we'll use system calls that require root privileges. (There are other ways to grant these privileges, but we'll cover that in another article.)

In the example below, we use `os.Getuid()` to check whether the program is running as root. If it isn't, the program exits.

```go
if os.Getuid() != 0 {
    fmt.Println("execute como root")
    return
}
```

Of course, you could do exactly the opposite — invert the condition so the program only runs when it's *not* root. But the idea here is for the program to switch to another user on its own, so let's continue.

## Checking the User and Group IDs

You can check the user and group IDs at any time with the `os.Getuid()` and `os.Getgid()` functions.

```go
fmt.Printf(
    "executando como uid: %v, gid: %v\n",
    os.Getuid(),
    os.Getgid(),
)
```

## Switching to the "nobody" User

Now let's make our program, which is running as root, switch to the *nobody* user. First, get the *nobody* user's information with the `user.Lookup` function.

```go
u, err := user.Lookup("nobody")
if err != nil {
    fmt.Println(err)
    return
}
```

With the *nobody* user's information, change the user and group IDs the program runs as using the `syscall.Setgid` and `syscall.Setuid` system calls.

```go
uid, _ := strconv.Atoi(u.Uid)
gid, _ := strconv.Atoi(u.Gid)

// Ajusta o ID do grupo
err = syscall.Setgid(gid)
if err != nil {
    fmt.Println(err)
    return
}

// Ajusta o ID do usuário
err = syscall.Setuid(uid)
if err != nil {
    fmt.Println(err)
    return
}
```

From this point on, the program runs with the privileges of the *nobody* user — that is, with minimal privileges. You can create dedicated users for each service and run each one with the privileges it needs.

**Note:** Dropping privileges is a good practice, but it doesn't prevent an attack. What it does is reduce the damage of an attack that exploits a flaw in your program.

The complete code is available on [GitHub](https://github.com/crgimenes/grupo-estudos-golang/tree/master/reducao_de_privilegios).

Demo video:

@[youtube](9HnpICpnJ-Y)

Until next time!
