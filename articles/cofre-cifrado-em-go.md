---
title: "Goで作る暗号化ボールト：SQLiteをRAMに置き、ディスクには暗号化Blobだけを残す"
emoji: "🔐"
type: "tech"
topics: ["go", "security", "sqlite", "encryption"]
published: true
---

Let's put together the three previous pieces:

- [terminal password input](https://crg.eti.br/en/post/capturando-senhas-no-terminal-go/)
- [encryption at rest](https://crg.eti.br/en/post/criptografia-at-rest-com-a-stdlib-go/)
- [SQLite snapshot](https://crg.eti.br/en/post/sqlite-na-ram-serialize-deserialize/)

A SQLite database that lives in RAM and, on disk, exists only as an encrypted blob.

The database runs in `:memory:`.
On exit, we take a *snapshot* of the database bytes, encrypt it with the password, and write it out.
On startup, we read the blob, decrypt it with the password, and *deserialize* it back into RAM.

Data protection here depends on the strength of the password and on the encryption algorithm (AES-GCM, in this case). You have to be careful with the size of the database, because dumping, encrypting, and writing everything at once can be slow. But it works very well for storing sensitive data like API keys, tokens, and so on.

The main flow decides between opening an existing vault or creating a new one:

```go
exists := fileExists(*vault)
pass, err := askPassphrase(!exists) // a new vault asks for confirmation
if err != nil {
	fatal(err)
}

db, _ := sql.Open("sqlite", ":memory:")
db.SetMaxOpenConns(1)
mustExec(db, `PRAGMA temp_store=MEMORY;`)

if exists {
	blob, _, err := readVault(*vault, pass)
	if err != nil {
		fatal(err) // wrong password or tampered: abort WITHOUT overwriting
	}
	restore(db, blob)
	list(db)
	return
}
// first time: create, serialize, encrypt and seal
```

Two important points:

- Never overwrite on a wrong password: if `decrypt` fails, we abort before writing anything.
- Atomic writes: write to a temporary file and rename, so a crash mid-write doesn't leave a half-written vault behind.

```go
func seal(db *sql.DB, path, pass string) error {
	plain, err := snapshot(db)
	if err != nil {
		return err
	}
	blob, err := encrypt(pass, plain)
	if err != nil {
		return err
	}
	tmp, err := os.CreateTemp("", ".vault-*")
	if err != nil {
		return err
	}
	tmpName := tmp.Name()
	if _, werr := tmp.Write(blob); werr != nil {
		_ = tmp.Close()
		_ = os.Remove(tmpName)
		return werr
	}
	if cerr := tmp.Close(); cerr != nil {
		_ = os.Remove(tmpName)
		return cerr
	}
	if cerr := os.Chmod(tmpName, 0o600); cerr != nil {
		_ = os.Remove(tmpName)
		return cerr
	}
	return os.Rename(tmpName, path)
}
```

To test it:

```sh
go run .                      # create, ask for the password twice, seal
file vault.blob               # not a SQLite file
hexdump -C vault.blob | head  # nothing readable
go run .                      # ask for the password, open and list
```

This protects the database contents *at rest*: without the password, the file is just noise, and any tampering is detected by GCM.

Of course, the data is only protected on disk; this does not protect against an attacker who can read the process memory.

[full source code](https://crg.eti.br/post/cofre-cifrado-em-go/main.go)

[Cesar Gimenes](https://crg.eti.br/en/cesar-gimenes/)
