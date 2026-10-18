---
title: "GoのContextでHTTPミドルウェア間のデータを受け渡す"
emoji: "🔗"
type: "tech"
topics: ["go"]
published: true
---

Watch the video for this article [here](https://www.youtube.com/watch?v=Xyj-dQvfvq0).

## Passing data between middleware

We have already seen [how HTTP middleware works](https://www.youtube.com/watch?v=aQGRh7ECgwg), so now let's look at how to pass information from one middleware to the next. This is used, for example, to hand a user's credentials to the next middleware, or any other information collected in one middleware that you want to forward.

First, let's write an example that shows as clearly as possible when the middleware run. This matters a lot, because misunderstanding the execution order is an incredible source of bugs. In the example below we print a message to the terminal every time a middleware is pushed and popped. And it's worth stressing: this happens in the same order in which they were registered.

```golang
package main

import (
    "fmt"
    "net/http"

    "github.com/gorilla/mux"
    "github.com/urfave/negroni"
)

func handleMain(w http.ResponseWriter, r *http.Request) {
    _, err := w.Write([]byte("{\"value\":42}\n"))
    if err != nil {
        fmt.Println("error handleMain", err)
    }
}

func middleware1() negroni.Handler {
    fmt.Println("carregando middleware 1")
    return negroni.HandlerFunc(func(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
        fmt.Println("empilhando middleware 1")
        next(w, r)
        fmt.Println("desempilhando middleware 1")
    })
}

func middleware2() negroni.Handler {
    fmt.Println("carregando middleware 2")
    return negroni.HandlerFunc(func(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
        fmt.Println("empilhando middleware 2")
        next(w, r)
        fmt.Println("desempilhando middleware 2")
    })
}

func middleware3() negroni.Handler {
    fmt.Println("carregando middleware 3")
    return negroni.HandlerFunc(func(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
        fmt.Println("empilhando middleware 3")
        next(w, r)
        fmt.Println("desempilhando middleware 3")
    })
}

func main() {
    n := negroni.Classic()
    n.Use(middleware1())
    n.Use(middleware2())
    n.Use(middleware3())
    fmt.Println("-=-=-=-=-=-=-=-=-=-=-=-=-=-")
    r := mux.NewRouter().StrictSlash(true)
    n.UseHandler(r)

    r.HandleFunc("/", handleMain).Methods("GET")

    fmt.Println("main listen at :8080")
    err := http.ListenAndServe(":8080", n)
    if err != nil {
        fmt.Println(err)
    }
}
```

The canonical way to pass information along while an HTTP request is being processed is with context. See the example below.

```golang
package main

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http"

    "github.com/gorilla/mux"
    "github.com/urfave/negroni"
)

type key int

const (
    dataKey key = iota
)

type data struct {
    ValueA string `json:"value_a"`
    ValueB int    `json:"value_b"`
}

func setContextData(r *http.Request, d *data) (ro *http.Request) {
    ctx := r.Context()
    ctx = context.WithValue(ctx, dataKey, d)
    ro = r.WithContext(ctx)
    return
}

func getContextData(r *http.Request) (d data) {
    d = *r.Context().Value(dataKey).(*data)
    return
}

func middleware1() negroni.Handler {
    return negroni.HandlerFunc(func(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
        d := data{
            ValueA: "valor A",
            ValueB: 42,
        }
        r = setContextData(r, &d)
        next(w, r)
    })
}

func middleware2() negroni.Handler {
    return negroni.HandlerFunc(func(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
        d := getContextData(r)
        d.ValueA += "A"
        r = setContextData(r, &d)
        next(w, r)
    })
}

func middleware3() negroni.Handler {
    return negroni.HandlerFunc(func(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
        d := getContextData(r)
        d.ValueA += "A"
        r = setContextData(r, &d)
        next(w, r)
    })
}

func handleMain(w http.ResponseWriter, r *http.Request) {
    d := getContextData(r)
    j, err := json.MarshalIndent(d, "", "\t")
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    _, err = w.Write(j)
    if err != nil {
        fmt.Println(err)
    }
}

func main() {
    n := negroni.Classic()
    n.Use(middleware1())
    n.Use(middleware2())
    n.Use(middleware3())

    r := mux.NewRouter().StrictSlash(true)
    n.UseHandler(r)

    r.HandleFunc("/", handleMain).Methods("GET")

    fmt.Println("main listen at :8080")
    err := http.ListenAndServe(":8080", n)
    if err != nil {
        fmt.Println(err)
    }
}
```

There are many more examples in the repository of our [Go study group](https://github.com/crgimenes/grupo-estudos-golang). It's worth a look, and contributions are welcome — we always need help keeping the material complete and up to date.
