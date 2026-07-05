---
title: "Gorilla sessionsを使ったGoのセッション管理"
emoji: "🍪"
type: "tech"
topics: ["go", "security", "cookie", "web"]
published: true
---

Session management is an old idea: you use cookies to hold some of the user's session data. For security, we usually store only a UUID in the cookie — as random as possible — and the server uses it to look up everything else, such as which user is logged in.

The UUID has to be as random as possible, because if someone can predict the next one, they can hijack a legitimate user's session.

Assuming the UUID is random enough, keeping the session data on the server side is always safer. It makes attacks like [session poisoning](https://en.wikipedia.org/wiki/Session_poisoning) considerably harder.

Server-side storage, however, creates a scalability problem. At minimum you have to query a microservice responsible for holding sessions, which in turn probably queries a database, and you end up with another bottleneck and a lot more complexity — even more so if you want to put a load balancer in front of it.

## AES-256

One alternative is to keep the session data in the cookie itself and encrypt it with a solid algorithm. Here we'll use [AES-256](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard).

Two things matter for this strategy to work. The first is a good key: it needs to be 32 characters and as random as possible. We'll let the `gorilla/securecookie` package generate it, which relies on `crypto/rand` under the hood. The second is to rotate the key periodically, to make brute-force attacks harder.

Needless to say, generating the key by hand is out of the question.

## What to store

Since the session data lives in the cookie itself, we have to watch its size. We need to stay under the 4096-byte limit. If, say, you store an OAuth2 *access token*, that alone eats 2048 bytes, and adding the *refresh token* costs another 512. On top of that, encryption and base64 encoding take up space too.

So be minimalist — store only what's essential.

If you need more room, it's worth looking at other storage backends for the session, such as saving to files on disk with `NewFilesystemStore` instead of `NewCookieStore`.

## Clearing sessions

There are several situations where you might want to clear the session cookie — for example, when the user logs out of the page. Another case is when something goes wrong with decryption; in that case I prefer to drop the cookie and start over.

Here's a small helper to delete a cookie:

```golang
func clearSession(w http.ResponseWriter, session string) {
    cookie := &http.Cookie{
        Name:   session,
        Value:  "",
        Path:   "/",
        MaxAge: -1,
    }
    http.SetCookie(w, cookie)
}
```

## Setting up the store

The first step is to create a place to keep the session. In our example we create a `store` variable that produces an encrypted cookie.

```golang
var store = sessions.NewCookieStore(securecookie.GenerateRandomKey(32))
```

As written, the service generates a new key every time it starts up. That can be a valid strategy, especially if you don't want to persist the key anywhere and you're fine with it changing on every release — with the minor inconvenience that your users lose their sessions whenever you deploy a new version.

Another option is to load the key from a secure system or an environment variable.

## Managing the session

To create or load a session, we use the following code inside an HTML handler.

```golang
session, err := store.Get(r, sessionName)
if err != nil {
    clearSession(w, sessionName)
    http.Redirect(w, r, "/", http.StatusTemporaryRedirect)
    //http.Error(w, err.Error(), http.StatusInternalServerError)
    return
}
```

The first line creates a `session` variable that either holds a new session or the existing one.

Then comes the usual error handling. If something goes wrong — for instance, if we can't decrypt the existing session cookie — we first clear the current cookie, since it's useless anyway, and then redirect the user to the home page or the login page to get a fresh session cookie. Alternatively, we could just return an error.

## Saving data

The session is stored in a map of interface to interface. It's not my favorite solution, but it's certainly the most flexible. We just have to be careful when reading the data back.

To save any value into the session:

```golang
session.Values["foo"] = "bar"
session.Values[42] = "The answer to life, the universe and everything"

err = session.Save(r, w)
if err != nil {
    http.Error(w, err.Error(), http.StatusInternalServerError)
    return
}
```

As the example shows, both the key and the value can be anything — letters, numbers, and so on. But it's a good idea to be careful here, and to always validate that you're reading the right type so a *panic* doesn't take the system down.

After that, call `Save` to persist the data.

## Loading the session

To read session data, we do as in the first example and use `Get` to instantiate the session variable, then read directly from the `Values` map.

```golang
a, ok := session.Values["key_name"]
if !ok {
    http.Error(w, "value not set", http.StatusInternalServerError)
    return
}
```

This is just like reading any map in Go: pass the key and take the two possible return values. The first is the stored value, if any; the second is a boolean. If that second value is `true`, the value was found; otherwise we can return an error saying the value doesn't exist.

### Watch out for interfaces in Go

The values in this map are always interfaces, so we need to *cast* them to the correct type. The catch is that if you cast to the wrong type, your system will crash with a *panic*.

Here's a small example of how to validate the type before casting.

```golang
switch a.(type) {
case string:
    w.Write([]byte(a.(string)))
default:
    http.Error(w, "value is not type string", http.StatusInternalServerError)
}
```

[Cesar Gimenes](/pt-br/cesar-gimenes/)
