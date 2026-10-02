---
title: "GoでクライアントとサーバーのIPアドレスを取得する"
emoji: "🌐"
type: "tech"
topics: ["go", "network", "ipv6"]
published: true
---

I recently ran into an interesting problem: I needed to stand up a small REST service to manage some hardware, all without human intervention and with multiple network interfaces involved.

At some point my system has to bring up an auxiliary service and tell the client which IP and port to connect to. Normally you'd handle this with a config file somewhere, but one requirement was that I couldn't assume my own IP, since it could come from any of the network interfaces, and making all of that configurable would get too complex.

The solution was to automate the whole process inside my own code. To do that I needed to know both my IP and the client's, so I'd know which network to respond on, and so on.

Since Go has a solid net package, I also wanted to support IPv6 while I was at it. That's not hard, you just have to be careful to use what Go gives you instead of assuming the IP and port format.

## Handling the IP

The net package has two unexported functions, so I copied them into my code to help parse the result.

The *last* function extracts the last part of a string given a separator. Here we use it to extract the *zone* from IPv6 addresses; the zone is usually the network interface name.

```golang
func last(s string, b byte) int {
    i := len(s)
    for i--; i >= 0; i-- {
        if s[i] == b {
            break
        }
    }
    return i
}
```

The *splitHostZone* function returns the host and the zone separately; if there's no zone, it comes back as an empty string. I need this because when I put the IP and port back together, I don't want to include the zone.

```golang
func splitHostZone(s string) (host, zone string) {
    // The ipv6 scoped addressing zone identifier starts after the
    // last percent sign.
    if i := last(s, '%'); i > 0 {
        host, zone = s[:i], s[i+1:]
        return
    }
    host = s
    return
}
```

## Getting the server's IP

There are several ways to find the server's IP, but the simplest, "Go-style" one I found was pulling the address that's placed in the request context.

```golang
adr := r.Context().Value(http.LocalAddrContextKey)
serverAddr, serverPort, err := net.SplitHostPort(
    fmt.Sprintf("%v", adr))
if err != nil {
    fmt.Println(err)
    return
}
serverIP, serverZone := splitHostZone(serverAddr)
```

Getting the client's IP is easier, since it already comes with the request, so we just handle the return value the same way as before.

```golang
clientAddr, clientPort, err := net.SplitHostPort(r.RemoteAddr)
if err != nil {
    fmt.Println(err)
    return
}
clientIP, clientZone := splitHostZone(clientAddr)
```

Here's a [gist with the example code](https://gist.github.com/crgimenes/752efa64ef36d94569a694bf940a7b03).

This code works well for my case, where everything happens inside an internal network, but it doesn't work if there's a proxy in the middle. It wouldn't be too hard to add proxy support using headers like *X-ProxyUser-Ip*, but that's beyond what I need right now.
