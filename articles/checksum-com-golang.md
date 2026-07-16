---
title: "GoでFNV-1aを使いメッセージの整合性チェックを高速化する"
emoji: "⚡"
type: "tech"
topics: ["go", "security", "hash", "performance"]
published: true
---

In the article [HMAC (Hash-based Message Authentication Code)](https://crg.eti.br/en/post/hmac-assinatura-de-mensagens-segura-em-go/), we saw how that technique ensures a message was not altered in transit and confirms the validity of the signature.

However, while secure, that process is slow and resource-intensive. When we only need to verify message integrity without validating a signature, we can use a faster hash function. For that, we will use the FNV-1a (Fowler-Noll-Vo) algorithm, known for its speed and low collision rate.

First, let's create a hash *pool* to avoid allocating memory on every call to the hash function. This reduces pressure on the *garbage collector*.

```golang
var (
    hashPool = sync.Pool{
        New: func() interface{} {
            return fnv.New32a()
        },
    }
)
```

To manage the hash *pool*, we will create two functions: one to get a hash from the *pool* and another to return it.

```golang
func getHash() hash.Hash32 {
    return hashPool.Get().(hash.Hash32)
}

func putHash(h hash.Hash32) {
    hashPool.Put(h)
}
```

Now, let's create a function to compute the message checksum. This function gets a hash from the *pool*, computes the checksum, and returns the hash to the *pool*.

```golang
func checksum(data []byte) uint32 {
    hash := getHash()
    defer putHash(hash)
    hash.Reset()
    _, _ = hash.Write(data)
    return hash.Sum32()
}
```
[complete source code](https://crg.eti.br/en/post/checksum-com-golang/main.go)

From now on, we can use the `checksum` function to compute the message hash. This approach is much faster than *HMAC* and ideal for systems like a message *broker*, which needs to handle a large flow of information.

This approach does not verify the authenticity of the message, only its integrity. In many cases, though, that is enough. Security can be ensured by other means, such as a secure *TLS* connection.

Video explaining the code:

@[youtube](zTDaOv7ysOo)
