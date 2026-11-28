---
title: "HTTPSへのリダイレクトとリバースプロキシ"
emoji: "🔒"
type: "tech"
topics: ["go", "https", "networking", "caddy"]
published: true
---


## Everything encrypted, no excuses

It used to be expensive and inconvenient to require encryption on HTTP servers — at the very least you had to spend some money with a certificate authority. That hasn't been true for a while now: anyone can use certificates from [letsencrypt.org](https://letsencrypt.org), they're free, easy to use, and the tooling is open source, so there's no longer any excuse for not using HTTPS on your servers.

Besides using the certificates directly, several tools and services will generate the Let's Encrypt certificate for you. That's the case with [Caddy](https://caddyserver.com): you just provide a domain name in the configuration file and it will request the certificate and handle everything transparently.

## Redirecting to HTTPS

To redirect every browser to the HTTPS port, I wrote a small service in Go that simply returns a 301 *Moved Permanently* to the user's browser, pointing to the new location by only swapping the URL scheme from HTTP to HTTPS, and leaves the rest of the work to the browser.

### Here's the Go code

```golang
package main

import (
    "log"
    "net/http"
)

func redirectToHTTPS(w http.ResponseWriter, r *http.Request) {
    redirect := "https://" + r.Host + r.RequestURI
    http.Redirect(w, r, redirect, http.StatusMovedPermanently)
    log.Print("redirect to : " + redirect)
}

func main() {
    log.Print("start redirect http->https")
    if err := http.ListenAndServe(":80", http.HandlerFunc(redirectToHTTPS)); err != nil {
        log.Fatalf("ListenAndServe error: %v", err)
    }
}
```

## Using Caddy

For a long time that was how I redirected my calls to HTTPS, but it isn't necessary anymore. With Caddy acting as server and proxy at the same time, you don't have to do anything: if it manages to generate the certificate for you automatically, it will redirect HTTP requests to HTTPS.

Caddy is also written in Go, which makes installing it as easy as any other well-written application — just compile the binary into your PATH and run it however you prefer.

I also wrote a post about how to create an [HTTPS server with Go](/pub/https-com-golang), which is no longer necessary because it's far simpler to use Caddy and write a plain server listening on a high port.

Running the server on a high port lets my user start it without worrying about permissions, which helps a lot while testing the system. Of course, if I intend to keep a system running for longer, I do it under a user dedicated to that task instead of my own. Another important point: the firewall on my machines doesn't allow any traffic other than the SSH, HTTP and HTTPS ports, so nobody can reach any service directly.

### Configuring

Caddy's configuration is quite simple. Create a file named **Caddyfile** in the directory where the Caddy executable will run.

Here's an example configuration file:

```caddyfile
example.com {
    gzip
    proxy /api localhost:8000 {
        websocket
        transparent
    }
    proxy /code localhost:8080 {
        websocket
        transparent
        without /code
    }
   root ./root
    # basicauth / user password
}
```

In this file we're configuring the domain example.com and telling Caddy to compress the protocol output with gzip. Next we set up two redirects to our internal proxy: the first sends traffic arriving at `/api` to the server running on the local machine on port 8000, keeping the `/api` string — that's how I prefer to do it these days. The second example redirects traffic to the local machine on port 8080 but strips the `/code` prefix when forwarding the request.

Then we tell Caddy that our site root is at `./root`, which in my case is very useful for serving a handful of static pages and the odd file.

After that there's a line starting with *#*, meaning it's commented out and will be ignored. If you uncomment it, though, you get *basicauth* provided by Caddy — another very handy feature for keeping some things out of the open. You can use far more sophisticated user authentication methods, but for a lot of cases basicauth is enough.

## Conclusion

There are no more excuses for not encrypting traffic to your server. It's easy to enforce that every access goes over HTTPS, and on our side there are tools that make bringing up and maintaining a secure server much easier.
