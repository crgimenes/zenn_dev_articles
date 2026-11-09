---
title: "ターミナルで長いコマンドラインをエディタで編集する"
emoji: "⌨️"
type: "tech"
topics: ["terminal", "shell", "bash", "vim", "cli"]
published: true
---

I use the terminal a lot. It is amazing how the good old *command line interface* `cli` is still relevant, and still simply the fastest way to command a computer despite so many years of progress in computing.

We just haven't found a better way to enter commands yet. Over time, though, those commands have grown into what are practically small programs, sometimes several lines long, and sometimes containing things that are hard to edit, like regular expressions.

Sometimes all we want is a simple text editor feature so we can edit commands more efficiently and comfortably. The best part is that it's already there. You just have to remember a quick key combination that your favorite terminal already offers.

Watch the video for this article [here](https://www.youtube.com/watch?v=H-zi2YvrysM).

To edit long command lines more conveniently, you can use your favorite text editor. Just use the shortcut *^xe* (*hold the `control` key while pressing `x` and then `e`*).

If you want to use a different editor, set the *EDITOR* variable in the startup file of your `zsh` or `bash`. I recommend a very lightweight editor such as [vim](https://www.vim.org). Not every editor works well here, so it's worth testing and playing around a bit before deciding which one to use.

For example:

```bash
EDITOR=nano
```

Another important point is to watch out if your editor creates backup or cache files. It may be a good idea to disable that feature so it doesn't leave stray files in your temporary directory, not to mention the possibility of a security flaw and of it restoring an old command and getting in the way of your work in the terminal.

These little command line secrets are fun and useful. If you have a nice tip like this one, drop me a line on [Telegram](https://t.me/crgimenes).
