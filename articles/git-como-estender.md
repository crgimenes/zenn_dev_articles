---
title: "gitを拡張する — 独自のサブコマンドを作る方法"
emoji: "🔧"
type: "tech"
topics: ["git", "shellscript", "cli"]
published: true
---

Git is an extremely flexible tool and very simple to extend and build features on. To create a command, you just need an executable named git-**command** (*git dash followed by the command name*).

Any executable on the PATH that follows this naming pattern will be called by git. To start with a simple example, let's do the traditional "hello world". Save the example below as `git-hello` in a directory on the PATH.

```bash
#!/bin/sh
w="world"
if [ $# -gt 0 ]
    then
        w=$1
fi
echo "Hello, $w"
```

Now try the command "git hello" in the terminal, and "git hello your_name".

Git prioritizes its own commands, so it's a good idea to give the command you create a good, unique name.

To help with developing extensions, git ships with a library of useful functions that you can read about in the *manpage* at `man git-sh-setup`. In fact, several git commands are just shell scripts, and various tools like "git flow" are implemented this way.

A more useful script than "hello world" is `git-page`, which opens the repository's GitHub page.

```bash
#!/bin/sh
open $(git config remote.origin.url |
    sed "s/git@\(.*\):\(.*\).git/https:\/\/\1\/\2/")
```

With this you can extend git's features a great deal, which is very handy for automating repetitive work when maintaining a repository.
