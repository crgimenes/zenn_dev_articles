---
title: "SQLiteのトリガーで処理を自動化する"
emoji: "⚡"
type: "tech"
topics: ["sqlite", "sql", "database"]
published: true
---

*SQLite* does not support *stored procedures* directly, but it does support *triggers*, which is a very useful feature for automating certain actions.

For example, automatically updating the `updated_at` field.

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_timestamp
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;
```

Now, whenever you update a record in the `users` table, the `updated_at` field will be automatically set to the current *timestamp*.

```sql
INSERT INTO users (nome) VALUES ('Teste 1');

UPDATE users SET nome = 'Teste 2' WHERE id = 1;

SELECT * FROM users;
```

This way, you can keep your data consistent without having to update the `updated_at` field by hand. *SQLite* triggers are lightweight and easy to implement, which keeps the application code simpler.
