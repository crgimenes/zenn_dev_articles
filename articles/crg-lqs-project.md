---
title: "lqs: メタデータを埋め込んで.sqlファイルをそのまま実行するGo製CLI"
emoji: "🧪"
type: "tech"
topics: ["go", "sql", "sqlite", "postgresql", "cli"]
published: true
---

`lqs` is a small Go CLI for testing and debugging SQL commands with embedded metadata and, optionally, Lua scripts.

The idea came from a concrete annoyance: every time I wanted to validate a query in PostgreSQL or SQLite, I'd open `psql` or `sqlite3`, copy, paste, test, tweak, copy again. With parameterized queries it got worse, because each client handles `$1`, `?`, and `:name` differently.

The fix was to treat the `.sql` file as a small executable script. At the top of the file you put metadata in comments:

```sql
#!./lqs
-- DB: sqlite://:memory:
-- JSON: TRUE
SELECT sqlite_version();
```

`-- DB:` sets the connection. `-- JSON: TRUE` prints the result as JSON. `-- LUA:` lets a Lua script produce placeholder values. `-- SQL:` lets another query feed those placeholders. Combining the three, you can test parameterized queries without ever leaving the file.

CGo-free. Uses only the standard library and pure Go drivers. Compiles on any supported platform.

There's also a [Neovim integration](https://github.com/crgimenes/lqs/blob/main/lqs.lua) that takes a visual selection, writes it to a temp file, runs `lqs`, and shows the output. I use it a lot.
