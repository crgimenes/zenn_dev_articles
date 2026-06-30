---
title: "findコマンドで特定のファイルを除外するテクニック"
emoji: "🔍"
type: "tech"
topics: ["terminal", "bash", "unix", "cli", "find"]
published: true
---

I use the `find` command a lot to search for files, both in bash scripts and on the command line.

One handy trick is to exclude certain files from the results. For example, today I needed to find every ".md" file but wanted to leave out the ones starting with an underscore, along with the file "default.md".

To do that, I put the `-not` option before the `-name` option, like in the example below.

```bash
find  . \
    -type f \
    -name '*.md' \
    -not -name '_*md' \
    -not -name 'default.md'
```

## Deleting the files

In my case I wanted to delete those files while keeping the rest of the structure intact, so I used the command below, with the single change of swapping `echo` for `rm`. Of course, I kept `echo` in the example so it stays safe for anyone who just wants to copy the command and try it out.

```bash
find  . \
    -type f \
    -name '*.md' \
    -not -name '_*md' \
    -not -name 'default.md' \
    -exec echo {} \;
```

In this example, the `-type f` option tells `find` that we only want files, not directories. Next, `-name '*.md'` asks it to match every `.md` file. The two `-not -name` options drop the files we don't want.

Finally, the `-exec echo {} \;` option runs `echo`, replacing the braces `{}` with the name of each file found.
