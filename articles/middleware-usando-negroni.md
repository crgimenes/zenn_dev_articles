---
title: "GoでHTTPミドルウェアを書く——標準ライブラリとNegroniの2通り"
emoji: "🧅"
type: "tech"
topics: ["go", "http", "middleware", "negroni"]
published: true
---

You can watch the video version of this article [here](https://www.youtube.com/watch?v=aQGRh7ECgwg).

HTTP [middleware](https://en.wikipedia.org/wiki/Middleware) is very useful for avoiding duplicated code when your application has several endpoints — for example, when you want to make sure the user's credentials have been verified, or that the content has been compressed, and so on.

The most important thing to keep in mind is that each middleware runs in the order it was registered. So you can have a middleware responsible for setting up the environment, such as opening the database or preparing session handling, that runs before the middleware validating the user's credentials.

## Using the standard library

```golang
package main

import (
    "fmt"
    "log"
    "net/http"
)

func handleMain(w http.ResponseWriter, r *http.Request) {
    _, err := w.Write([]byte("{\"value\":42}\n"))
    if err != nil {
        fmt.Println("error handleMain", err)
    }
}

func handleHealthcheck(w http.ResponseWriter, r *http.Request) {
    _, err := w.Write([]byte("{\"status\":\"ok\"}\n"))
    if err != nil {
        fmt.Println("error handleHealthcheck", err)
    }
}

func applicationJSON(h http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        h.ServeHTTP(w, r)
    }
}

func basicAuth(h http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {

        if r.URL.Path == "/healthcheck" {
            h.ServeHTTP(w, r)
            return
        }

        user, pass, ok := r.BasicAuth()
        if !ok || user != "admin" || pass != "admin" {
            w.WriteHeader(http.StatusUnauthorized)
            fmt.Fprintln(w, `{"error": "Unauthorized"}`)
            return
        }

        w.Header().Set("WWW-Authenticate", `Basic realm="Restricted"`)
        h.ServeHTTP(w, r)
    }
}

func main() {
    http.HandleFunc("/", applicationJSON(basicAuth(handleMain)))
    http.HandleFunc("/healthcheck", applicationJSON(handleHealthcheck))

    fmt.Println("main listen at :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

In this example we have two endpoints and a middleware that sets the `Content-Type` header to `application/json` on every HTTP request, so we no longer have to worry about it. No matter how many endpoints our application has, all of them will carry that same header — which means we avoid duplicating this code all over our program.

## Using Negroni and gorilla/mux

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

func handleHealthcheck(w http.ResponseWriter, r *http.Request) {
    _, err := w.Write([]byte("{\"status\":\"ok\"}\n"))
    if err != nil {
        fmt.Println("error handleHealthcheck", err)
    }
}

func applicationJSON() negroni.Handler {
    return negroni.HandlerFunc(func(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
        w.Header().Set("Content-Type", "application/json")
        next(w, r)
    })
}

func basicAuth() negroni.Handler {
    return negroni.HandlerFunc(func(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
        if r.URL.Path == "/healthcheck" {
            next(w, r)
            return
        }

        user, pass, ok := r.BasicAuth()
        if !ok || user != "admin" || pass != "admin" {
            w.WriteHeader(http.StatusUnauthorized)
            fmt.Fprintln(w, `{"error": "Unauthorized"}`)
            return
        }

        w.Header().Set("WWW-Authenticate", `Basic realm="Restricted"`)
        next(w, r)
    })
}

func main() {
    n := negroni.Classic()
    n.Use(applicationJSON())
    n.Use(basicAuth())

    r := mux.NewRouter().StrictSlash(true)
    n.UseHandler(r)

    r.HandleFunc("/", handleMain).Methods("GET")
    r.HandleFunc("/healthcheck", handleHealthcheck).Methods("GET")

    fmt.Println("main listen at :8080")
    err := http.ListenAndServe(":8080", n)
    if err != nil {
        fmt.Println(err)
    }
}
```

Here is the same example, now using the classic [Negroni](https://github.com/urfave/negroni) and [Gorilla mux](https://github.com/gorilla/mux) pairing. There are a few more examples in our [Golang study group](https://github.com/crgimenes/grupo-estudos-golang) repository.
