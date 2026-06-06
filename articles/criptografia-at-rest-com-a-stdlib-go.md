---
title: "Goの標準ライブラリだけで保存データを暗号化する：PBKDF2とAES-256-GCM"
emoji: "🔐"
type: "tech"
topics: ["go", "security", "encryption"]
published: true
---

I want to store a piece of data on disk so that, even if the file leaks, it is only readable with the password and any tampering is detected.

To do this we protect the data by encrypting it "at rest", which basically means the data is protected while it sits on disk and can only be accessed by whoever has the right password.

You can do this with the standard library alone:
- PBKDF2 to derive the key from the password
- AES-256-GCM to encrypt and authenticate.

Since Go 1.24 `crypto/pbkdf2` ships in the stdlib, so there's no external dependency.

The password doesn't become the key directly. It goes through PBKDF2 with a random *salt* and a high iteration count, which makes a brute-force attack expensive. AES-GCM is an authenticated mode: it encrypts and produces an integrity *tag*. If someone edits the file, verification fails.

The final file has this layout, where the salt travels along with it (it isn't a secret, it just needs to be unique) and the `magic` goes in as additional data (AAD), so it's authenticated too:

```
magic | salt(16) | nonce(12) | ciphertext+tag
```

The key comes out of the password and turns into an AES-256-GCM:

```go
const (
	saltLen = 16
	keyLen  = 32      // AES-256
	iter    = 600_000 // PBKDF2 iterations
)

func newGCM(pass string, salt []byte) (cipher.AEAD, error) {
	key, err := pbkdf2.Key(
        sha256.New,
        pass,
        salt,
        iter,
        keyLen)
	if err != nil {
		return nil, err
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	return cipher.NewGCM(block)
}
```

Encrypting means generating a random salt and nonce and assembling the blob:

```go
func encrypt(pass string, plain []byte) ([]byte, error) {
	salt := make([]byte, saltLen)
	if _, err := rand.Read(salt); err != nil {
		return nil, err
	}
	gcm, err := newGCM(pass, salt)
	if err != nil {
		return nil, err
	}
	nonce := make([]byte, gcm.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		return nil, err
	}
	ct := gcm.Seal(nil, nonce, plain, []byte(magic))

	out := append([]byte(magic), salt...)
	out = append(out, nonce...)
	return append(out, ct...), nil
}
```

`gcm.Open` fails if the password is wrong or if the file was altered.
Both cases return the same error, and that's on purpose:

```go
func decrypt(pass string, blob []byte) ([]byte, error) {
	if len(blob) < len(magic)+saltLen+12 || string(blob[:len(magic)]) != magic {
		return nil, fmt.Errorf("invalid format")
	}
	p := blob[len(magic):]
	salt, rest := p[:saltLen], p[saltLen:]
	gcm, err := newGCM(pass, salt)
	if err != nil {
		return nil, err
	}
	ns := gcm.NonceSize()
	if len(rest) < ns {
		return nil, fmt.Errorf("invalid format")
	}
	nonce, ct := rest[:ns], rest[ns:]
	pt, err := gcm.Open(nil, nonce, ct, []byte(magic))
	if err != nil {
		return nil, fmt.Errorf("wrong password (or tampered file)")
	}
	return pt, nil
}
```

To test it:

```sh
export PASSWORD="my secret password"
go run . encrypt "sensitive data" > vault.bin
hexdump -C vault.bin
go run . decrypt < vault.bin
```

`hexdump -C` shows nothing but noise after the magic.

With `crypto/pbkdf2` + `crypto/aes` + `crypto/cipher` you encrypt data "at rest" with zero dependencies.

[full source code](https://crg.eti.br/post/criptografia-at-rest-com-a-stdlib-go/main.go)

[Cesar Gimenes](https://crg.eti.br/en/cesar-gimenes/)
