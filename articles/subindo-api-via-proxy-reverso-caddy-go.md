---
title: "CaddyのリバースプロキシでGo製APIを公開する"
emoji: "🔀"
type: "tech"
topics: ["go", "caddy", "supervisor"]
published: true
---

A friend asked me for an example of how to deploy an API behind a reverse proxy using Go. Here is a short walkthrough.

First, set up a server and register its IP with your DNS provider. Assign the IP to a name so you can create an HTTPS certificate for the machine.

Configure the machine's firewall and open only ports 22 (SSH), 80 (HTTP), and 443 (HTTPS).

## Caddy

I use the Caddy HTTP server. It is practical and creates HTTPS certificates automatically. By default, it redirects HTTP requests to HTTPS.

To install Caddy on your operating system, follow the instructions at [https://caddyserver.com/docs/install](https://caddyserver.com/docs/install).

After installing, edit the `/etc/caddy/Caddyfile` file and add the following configuration:

```caddy
example.com {
    # Define a file to store the server log
    log {
        output file /var/log/caddy/example.com.log
    }

    # Configure the server to serve static pages
    root * /var/www/html
    file_server

    # Redirect calls that start with the /api endpoint
    route /api* {
        reverse_proxy 127.0.0.1:8080
    }
}
```

Caddy will take the domain configured in place of *example.com*, query the DNS server to verify that it matches the server's IP, and create the TLS certificates for you.

This configuration assumes you want to serve static files. If you prefer to have the Go code serve the root of the server, remove the root path settings and change the route as in the following example:

```caddy
route /* {
    reverse_proxy 127.0.0.1:8080
}
```

## API

For this example, we will create a simple HTML server. It will listen on port 8080 and respond with "Hello, world!" to requests.

```go
package main

import (
    "io"
    "net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
    io.WriteString(w, "Hello, world!")
}

func main() {
    http.HandleFunc("/", handler)
    err := http.ListenAndServe(":8080", nil)
    if err != nil {
        panic(err)
    }
}
```

This code only serves to demonstrate that port forwarding through a reverse proxy with Caddy works.

## tmux

[tmux](https://github.com/tmux/tmux) is available in every Linux distribution. Like GNU Screen, we can use it to keep a server running during tests, even if the connection drops. Using tmux for production services is not a good practice. However, during debugging, examining the output on screen helps a lot. If you are not familiar with tmux, it is worth learning about the tool.

## Supervisor

For production, a great way to manage your service is with *supervisor*.

To install it on Debian or Ubuntu, use the command:

```bash
apt-get install supervisor
```

Then create an *api.conf* file in the `/etc/supervisor/conf.d/` directory. (The path may vary depending on the Linux distribution.)

This is a simple example of a configuration file to start our service:

```
[program:api]
command=/path/api
directory=/path
autostart=true
```

Supervisor will use the `/path/api` executable to start the service. You can add more settings, such as automatically restarting on error or redirecting logs.

After creating the configuration file, reload supervisor with:

```bash
supervisorctl reread # reload the configuration
supervisorctl update # apply the changes
```

You can check the state of your service with the following command:

```bash
supervisorctl status api
```

To start the service, use:

```bash
supervisorctl start api
```

And to stop the service, use:

```bash
supervisorctl stop api
```

There are many other commands. Use `man supervisorctl` to learn more about them.

## Conclusion

This is a simplified overview of how to deploy an application written in Go in a controlled way, with TLS certificates and room to grow without sacrificing simplicity. As your system grows, you will probably add more services and routes to Caddy, but it will not get more complicated.

This approach lets you run the service as a regular user on a high port. Caddy takes care of the reverse proxy and TLS certificates. Supervisor takes care of the service in production.

Eventually, you may need workers for asynchronous tasks. For that, use `crontab` and small executables. It will be easy to maintain.
