---
title: "GoでHTTPリクエストのタイムアウトを設定する"
emoji: "⏱️"
type: "tech"
topics: ["go", "http", "timeout", "web"]
published: true
---

By default, Go doesn't set any timeout on HTTP requests. That can lead to a range of problems and vulnerabilities — a DoS attack, for instance, can simply keep opening connections to your server and hold them open.

To fix this, create an `http.Server` instance and set the `WriteTimeout` and `ReadTimeout` fields to whatever values make sense for you.

Here's an example:

```golang
func main() {
    r := mux.NewRouter().StrictSlash(true)
    r.HandleFunc("/", mainHandler)
    ...

    srv := &http.Server{
        Handler:      r,
        Addr:         ":8000",
        WriteTimeout: 15 * time.Second,
        ReadTimeout:  15 * time.Second,
    }

    log.Println("Listen at port :8000")
    log.Fatal(srv.ListenAndServe())
}
```

This sets the default timeouts for every HTTP request.

Setting a timeout for a specific handler is trickier. One option is to create a context with a timeout and use it to keep internal calls from running too long, effectively cancelling slow database queries and other resource access.

```golang
r.Context()
ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
defer cancel()
```

Personally, I consider it good practice to pass the context down into your functions and set a timeout on it. It can save you from wasting resources when, say, a user gives up on a request before it finishes.

[Cesar Gimenes](/en/cesar-gimenes/)
