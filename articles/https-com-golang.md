---
title: "GoとLet's EncryptでHTTPSサーバーを構築する"
emoji: "🔒"
type: "tech"
topics: ["go", "https", "tls", "letsencrypt", "linux"]
published: true
---

## Generating the keys with letsencrypt.org

As I mentioned in the post about [redirecting everything to HTTPS](https://crg.eti.br/en/post/redirect-to-https/), every communication between client and server needs to be encrypted, and with [letsencrypt.org](https://letsencrypt.org) that can be done at no cost, with open source code and plenty of documentation, which in my view leaves no excuse for not using HTTPS.

One important caveat is that there may be legal reasons to prefer another certificate authority. For example, if I'm not mistaken, to have legal weight in Brazil the authority has to be Brazilian. Of course that only matters if you plan to sue someone; I'm only interested in the security.

Enough talk, lets encrypt! :)

## Install certbot

You'll need to run these commands on the server that answers for your domain, and you'll also need root access to install the certificate and the dependencies.

First, download certbot from GitHub.

```bash
git clone https://github.com/certbot/certbot
```

We'll use certbot both to create the certificates and to renew them when needed, so move the certbot directory wherever you find most convenient. For the purposes of this tutorial I left the directory at */root/certbot*.

Enter the certbot directory ("*cd certbot*") and let's install the dependencies. My server runs Debian, but the system works with all the popular Linux distributions.

Installing the dependencies is a step you can safely skip — certbot will check them for you when issuing the certificates — but I like to know everything is fine before moving on.

## Installing dependencies

```bash
./certbot-auto --os-packages-only
```

Accept the installation of the required packages and let's continue.

## Generating and installing the certificates

If anything is listening on port 80, you need to shut it down; the certificate generator will use that port.

Then just run the following command, making the appropriate substitutions:

```
./certbot-auto certonly --standalone --email voce@exemplo.com.br -d exemplo.com.br
```

Accept the letsencrypt.org terms and in a few moments the certificates will be generated and already in the appropriate directories. Certbot will tell you which directories those are, but it will probably be something like */etc/letsencrypt/live/exemplo.com.br/*

## Preparing the renewal scripts

Certificates need to be renewed from time to time, and you can easily automate that with cron.

Here's an example command to put in cron:

```bash
/root/certbot/certbot-auto renew --standalone \
--pre-hook "/root/redirect/stop.sh" \
--post-hook "/root/redirect/start.sh"
```

The scripts in the pre-hook and post-hook parameters are very simple. In my case stop.sh just runs *killall redirectToHTTPS* to take down my little redirector, and start.sh simply brings it back up. That way port 80 is free for certbot to use.

I recommend setting cron to run this line twice a day during low-traffic hours. If it isn't time to renew yet, don't worry — certbot simply won't do anything, not even run the pre/post hook scripts.

## Now let's finally get to the Go code

```golang
package main

import (
    "io"
    "net/http"
    "log"
)

// remember to replace the domain name with the correct one :D
const fullchain = "/etc/letsencrypt/live/exemplo.com.br/fullchain.pem"
const privkey = "/etc/letsencrypt/live/exemplo.com.br/privkey.pem"

func helloHandle(w http.ResponseWriter, req *http.Request) {
    io.WriteString(w, "Olá Mundo HTTPS!\n")
}

func main() {
    http.HandleFunc("/", helloHandle)

    err := http.ListenAndServeTLS(":443", fullchain, privkey, nil)
    if err != nil {
        log.Fatal("ListenAndServeTLS: ", err)
    }
}
```

That's all there is to it. Pretty simple, right?

Of course you can make your server much more sophisticated. For example, in your HTTP handler you can add a line to send an HSTS header and tell browsers they should use HTTP Strict Transport Security.

```golang
w.Header().Add("Strict-Transport-Security", "max-age=63072000; includeSubDomains")
```

There's an excellent article on other changes you can make, written by [Peter Lambert at blog.bracelab.com](https://blog.bracebin.com/achieving-perfect-ssl-labs-score-with-go)

## Bonus

### Creating your own certificates

Let's say you don't want to use a certificate authority or anything like that — you just want asynchronous key certificates to install on your system for local testing.

To generate those certificates, use the following commands:

```bash
openssl ecparam -genkey -name secp384r1 -out server.key
openssl req -new -x509 -sha256 -key server.key -out server.pem -days 3650
```

That will produce the server.key and server.pem files, and to use them in our example you just change the constants like this:

```golang
const fullchain = "server.pem"
const privkey = "server.key"
```

## Important

Remember that security is not a command or a program, it's a process everyone has to be involved in. In this post I used several commands without detailing every parameter. Don't stop reading here: read the openssl manpage and find out what each parameter we used does, read other sources and learn as much as you can. Knowledge is the only effective weapon for making systems secure.
