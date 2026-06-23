---
title: "SQLを書きながらテスト・デバッグできるツール「LQS」"
emoji: "🧪"
type: "tech"
topics: ["go", "sql", "lua", "neovim"]
published: true
---

It's very common to need to embed SQL code strings in the source of other languages. The problem is that SQL is an interpreted language, so it can contain errors that we only notice at runtime.

## Testing SQL

LQS was created to work together with Neovim and allow you to test SQL while editing, without having to copy and paste into another file or SQL client.

- **Test SQL with embedded metadata:**
  Insert configurations directly in your SQL script, such as the connection string, JSON output option, or even an extra query to generate parameters.
  Example:
  ```sql
  -- DB: sqlite://:memory:
  -- JSON: TRUE
  SELECT sqlite_version();
  ```

- **Integrate Lua scripts:**
  Need dynamic parameters? Insert Lua code right into your script. The Lua return replaces the placeholders in your query.
  Example:
  ```sql
  -- DB: $ENV_DB_CONNECTION_STRING
  -- LUA: return 42, "Alice", 1.99
  SELECT * FROM test
  WHERE id = $1 AND user = $2 AND value < $3;
  ```

- **Run an auxiliary query for parameters:**
  Use the `-- SQL:` line to run a query and use its results as arguments, whether for Lua or for the main query.
  ```sql
  -- DB: sqlite://:memory:
  -- SQL: SELECT 10, "Bob"
  -- LUA: print(arg[1], arg[2])   -- return arg[1], arg[2]
  SELECT * FROM users WHERE id = $1 AND name = $2;
  ```

- **JSON output:**
  With the `-- JSON: TRUE` parameter, you can format the output in JSON, making it easier to integrate with other tools or APIs.

## Integration with Neovim

Integration with Neovim is simple—just one function. It allows you to select part of your SQL script in the editor and, with a quick command, run the query and view the result in a new buffer. This automation makes development much more fluid. If an error occurs, the error message will be displayed.

In [lqs.lua](https://github.com/crgimenes/LQS/blob/trunk/lqs.lua), you'll find an example of how to create a custom command in Neovim to capture the selection, save it to a temporary file, and automatically run LQS.

## How It Works

LQS reads the SQL file and processes each line to extract parameters:

- **Connection configuration:** The `-- DB:` line defines the database.
- **Lua script:** The `-- LUA:` line allows you to include Lua code, potentially continuing across multiple lines with the backslash (`\`).
- **Dynamic parameters via SQL:** The `-- SQL:` line executes a query to provide parameters that can be used by both the Lua script and the main query.
- **Output format:** The `-- JSON:` parameter defines whether the result will be in JSON or a more human-readable format.

## Conclusion

If you work with embedded SQL or need to test queries quickly, give LQS a try. It allows you to catch SQL errors as you edit your code and can also serve as a handy form of documentation, a simple approach to literate programming.

And yes, LQS is SQL spelled backwards. We shouldn't let programmers name things.

---

*References:*
- [Lua 5.4 Reference Manual](https://www.lua.org/manual/5.4/)
- [Go Database/sql Package](https://pkg.go.dev/database/sql)
- [Source Code](https://github.com/crgimenes/lqs)

Demonstration video:

@[youtube](8_I6bKp5LkY)
