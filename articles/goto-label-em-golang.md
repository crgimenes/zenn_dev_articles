---
title: "Goのgotoとラベルを使いこなす"
emoji: "🏷️"
type: "tech"
topics: ["go", "goto", "development"]
published: true
---

The *goto* statement has a bad reputation. Back in the BASIC days programmers did not have many options, so they abused *goto* and wrote confusing code. Modern languages like Go use goto with judgment and improve code clarity.

Go lets the *break* and *continue* statements use labels. Use labels to break out of nested loops or to continue a specific loop. Using *break* or *continue* with *labels* is equivalent to using goto.

### Example of break with a label

In this example, the *break* statement exits both nested loops.

```go
label:
for coluna := 10; coluna > 0; coluna-- {
    for linha := 10; linha > 0; linha-- {
        fmt.Println(linha, coluna)
        if linha == 5 {
            break label
        }
    }
}
```

### Example of continue with a label

In this example, the *continue* statement skips the inner loop and continues the outer loop.

```go
label:
for coluna := 10; coluna > 0; coluna-- {
    for linha := 10; linha > 0; linha-- {
        fmt.Println(linha, coluna)
        if linha == 5 {
            continue label
        }
    }
}
```

### Example of goto with a label

In this example, the *goto* statement creates an infinite loop. The loop stops when the *messages* channel receives a message or when the 2 second timeout expires.

```go
func main() {
    timeout := time.After(2 * time.Second)

    messages := make(chan string)
    go func() { messages <- "ping" }()

loop:
    select {
    case <-timeout:
        fmt.Println("timeout")
        os.Exit(1)

    case m := <-messages:
        fmt.Println(m)
        goto loop
    }

}
```

### Simple example of goto with a label

In this example, the *goto* statement skips the statements in between.

```go
func main() {
    fmt.Println("1")
    goto label
    fmt.Println("2") // this line will never run
label:
    fmt.Println("3")
}
```

### Example of an error when using goto

In this example, the *goto* statement fails. It jumps over a variable declaration, which is not allowed.

```go
fmt.Println("1")
goto label
var i = 1
fmt.Println("2", i)
label:
fmt.Println("3")
```

See the examples of [using goto with Go](https://github.com/crgimenes/grupo-estudos-golang/tree/master/goto).

### Rules for using labels

The rules for using *goto*, *continue* and *break* in Go are:

- The program cannot jump outside the scope of the function.
- The program cannot jump over a variable declaration.
- The *break* statement with a label requires the statement immediately after the label to be a *for*, *switch* or *select*.
- The *continue* statement with a label requires the statement immediately after the label to be a *for*.

## Nothing wrong with goto

Assembly does not understand abstractions. The processor jumps to memory addresses. The compiler turns control structures (if, for, goto and so on) into variations of the *jmp* instruction, which is effectively a *goto*. The programmer chooses whether to use the feature, but it is there either way.

## Bonus: a goto pattern in C

In languages without defer, such as C, goto can be used to release resources before leaving a function. Instead of simply returning from the function, the programmer jumps to a label where the resources are released, and then exits.

```c
void funcao() {
    FILE *f = fopen("arquivo.txt", "r");
    if (f == NULL) {
        goto erro;
    }

    // code that uses the file

    fclose(f);
    return;

erro:
    perror("Erro ao abrir o arquivo");
    exit(1);
}
```

## Conclusion

The *goto* statement is a powerful tool. We should use it with judgment and follow good programming practices, but not hold back just because we heard goto is bad. The *goto* statement is a useful tool and should be used when needed.

Video with the explanation of this article.
@[youtube](d2Nm5tOlPTQ)
