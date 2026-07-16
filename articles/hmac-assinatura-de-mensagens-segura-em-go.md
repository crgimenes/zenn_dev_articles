---
title: "GoでHMACによるメッセージ認証を実装する"
emoji: "🔏"
type: "tech"
topics: ["go", "security", "hmac", "api"]
published: true
---

When building APIs, it's a good idea to add an authentication header to guarantee message integrity. For example, when your server sends a request or a webhook, include an `X-Signature` header with an HMAC (Hash-based Message Authentication Code) signature.

To generate the HMAC signature, you use a secret key and the content to be signed, such as the request *body*, and send the signature in the header. It's important to make clear exactly what is being signed. I've run into problems with clients who couldn't validate the signature because they used the *body* parsed as JSON instead of the *raw body* received in the request.

Keeping the secret key safe is essential. A good practice is to use two keys: one for your communications with the client and another for the client's communications with you. The keys should also be long and random.

An HMAC signature does not replace HTTPS; it adds an extra layer of security. Another interesting option is [mTLS (mutual TLS)](https://crg.eti.br/en/post/mtls-implementando-autenticacao-mutua/), which offers stronger security. You can combine these layers to build a robust system.

Here is an example of how to use HMAC in Golang:

```golang
func HMACSign(payload, key []byte) string {
    mac := hmac.New(sha256.New, key)
    mac.Write(payload)
    return base64.StdEncoding.EncodeToString(mac.Sum(nil))
}
```

The `HMACSign` function takes the payload and the secret key and returns the signature in base64. You can send this signature in your request header.

```golang
func HMACVerify(payload, key []byte, receivedSig string) bool {
    rMac, err := base64.StdEncoding.DecodeString(receivedSig)
    if err != nil {
        return false
    }

    eMac := hmac.New(sha256.New, key)
    eMac.Write(payload)

    return hmac.Equal(eMac.Sum(nil), rMac)
}
```

The `HMACVerify` function takes the payload, the secret key, and the received signature. It returns `true` if the signature is valid and `false` otherwise.

```golang
payload := []byte("Conteúdo da mensagem a ser assinada")
key := []byte("MinhaChaveSecretaSuperSegura")

signature := HMACSign(payload, key)
fmt.Println("Assinatura:", signature)

if HMACVerify(payload, key, signature) {
    fmt.Println("Assinatura válida!")
}
```
[source code](https://crg.eti.br/en/post/hmac-assinatura-de-mensagens-segura-em-go/main.go)

With this, you add a simple extra layer of security that the client can verify.

Video with a detailed explanation (in Portuguese):

@[youtube](Yo-0TKVGsDg)
