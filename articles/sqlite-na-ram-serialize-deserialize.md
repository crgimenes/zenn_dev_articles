---
title: "GoでSQLiteを完全インメモリで動かす：serialize/deserializeでスナップショットを取る"
emoji: "💾"
type: "tech"
topics: ["go", "sqlite"]
published: true
---

SQLite can run entirely in memory, without ever touching disk. And there is a little-known trick: you can take a *snapshot* of the database bytes and load them back later, with no `INSERT`, no rebuilding anything. The functions are `sqlite3_serialize` and `sqlite3_deserialize`.

I will use the `modernc.org/sqlite` driver, which is pure Go, no CGo.

```go
db, err := sql.Open("sqlite", ":memory:")
if err != nil {
	fatal(err)
}
db.SetMaxOpenConns(1)
```

The catch is in `SetMaxOpenConns(1)`. A `:memory:` database belongs to the connection that opened it. Without limiting it to one connection, the `database/sql` pool could open another one, and that one would see a different, empty database.

These functions are not part of the `database/sql` interface. We reach them through the `(*sql.Conn).Raw` escape hatch, using an interface the driver implements:

```go
type serializer interface {
	Serialize() ([]byte, error)
	Deserialize([]byte) error
}
```

The `snapshot` function returns, byte for byte, what would be the `.sqlite` file on disk. The first 16 bytes are literally `SQLite format 3\0`:

```go
func snapshot(db *sql.DB) ([]byte, error) {
	conn, err := db.Conn(context.Background())
	if err != nil {
		return nil, err
	}
	defer func() { _ = conn.Close() }()
	var buf []byte
	err = conn.Raw(func(dc any) error {
		s, ok := dc.(serializer)
		if !ok {
			return errors.New("the driver does not expose Serialize")
		}
		var serr error
		buf, serr = s.Serialize()
		return serr
	})
	return buf, err
}
```

The `restore` function does the reverse. After it runs, every table and row is back in memory.

```go
func restore(db *sql.DB, buf []byte) error {
	conn, err := db.Conn(context.Background())
	if err != nil {
		return err
	}
	defer func() { _ = conn.Close() }()
	return conn.Raw(func(dc any) error {
		s, ok := dc.(serializer)
		if !ok {
			return errors.New("the driver does not expose Deserialize")
		}
		return s.Deserialize(buf)
	})
}
```

You process everything in memory, fast and without leaving anything in plain text on disk, and when you want to persist it you save a single blob. That blob can go to disk encrypted, and then nobody reads the database without the key.

[Full source code](https://crg.eti.br/post/sqlite-na-ram-serialize-deserialize/main.go)

[Cesar Gimenes](https://crg.eti.br/en/cesar-gimenes/)
