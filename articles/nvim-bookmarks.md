---
title: "Neovimでファイルをまたぐブックマーク機能を自作する"
emoji: "🔖"
type: "tech"
topics: ["neovim", "lua", "vim"]
published: true
---

I go through many files when I work, especially when debugging or tracing behaviors. I created a bookmark system in *Neovim* to quickly jump between files. This system differs from the default *Neovim* system because it focuses on marking files and lines, not just positions within the same file.

## How It Works

The system records the file path and the current line in a text file. I use the `<leader>o` key to open all marked files. I use the `<leader>m` key to mark a file. I also use the `:Clearmarks` command to clear all bookmarks when I finish a task or start a new one.

## Implementation

The `Mark_point` function writes the file path and current line to the end of a text file. It creates this file if it does not exist.

```lua
function Mark_point()
  local home = os.getenv("HOME")
  local file_marks = home .. "/marks.txt"

  local file = vim.fn.expand('%:p') -- full path
  local line = vim.fn.line('.')     -- current line number

  local mark = file .. " +" .. line

  local file_handle = io.open(file_marks, "a")
  if file_handle then
    file_handle:write(mark .. "\n")
    file_handle:close()
    print("Marked: " .. mark)
    return
  end
  print("Error opening bookmark file: " .. file_marks)
end
```

The `Open_mark` function reads the bookmark file, opens the file, and jumps to the marked line. It first goes to the beginning of the file with `gg` and then to the desired line with `G`.

```lua
function Open_mark(marks_file)
  local file = io.open(marks_file, "r")
  if not file then
    -- print("Error opening bookmark file: " .. marks_file)
    return
  end

  for line in file:lines() do
    local file_path, line_number = string.match(
        line, "^(.-)%s+%+(%d+)$")
    vim.cmd('edit ' .. file_path)
    vim.cmd('normal gg')
    vim.cmd('normal ' .. line_number .. 'G')
  end
  file:close()
end
```

I created the `Open_marks` function to open marked files in the user directory and the current directory.

```lua
function Open_marks()
  local path = os.getenv("HOME")
  local marks_file = path .. "/marks.txt"
  Open_mark(marks_file)

  path = vim.fn.getcwd()
  marks_file = path .. "/marks.txt"
  Open_mark(marks_file)
end
```

The `Clear_marks` function removes the bookmark files from the user directory and the current directory.

```lua
function Clear_marks()
  local path = os.getenv("HOME")
  local marks_file = path .. "/marks.txt"
  os.remove(marks_file)

  path = vim.fn.getcwd()
  marks_file = path .. "/marks.txt"
  os.remove(marks_file)
end
```

I set up shortcut keys and a *Neovim* command to call the functions.

```lua
vim.api.nvim_set_keymap(
  'n', '<leader>o', ':lua Open_marks()<CR>',
  { noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
  'n', '<leader>m', ':lua Mark_point()<CR>',
  { noremap = true, silent = true }
)
vim.api.nvim_command(
  'command! Clearmarks lua Clear_marks()'
)
```

## Bookmark File

I store the bookmarks in a simple text file, which makes it easy to create scripts that work with those bookmarks without having to open *Neovim*. Below is a Bash example:

```bash
#!/usr/bin/env bash

INITIAL_QUERY="${*:-}"

MARKS_FILES=("$HOME/marks.txt")
[ -f "./marks.txt" ] && \
    MARKS_FILES+=("./marks.txt")

IFS='+' read -r file_path line_number <<< "$(
    cat "${MARKS_FILES[@]}" | \
    fzf --ansi \
        --delimiter '+' \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --query "$INITIAL_QUERY"
)"

[ -n "$file_path" ] && {
    file_path=$(echo "$file_path" | xargs)
    line_number=$(echo "$line_number" | xargs)
    "$EDITOR" "$file_path" "+$line_number"
    echo "$file_path" "+$line_number"
}
```

This script reads the bookmark file, lets you select a file, and opens it in *Neovim* at the marked line. It uses `fzf` for user interaction and `bat` for file preview.

## Conclusion

I prefer small tools that perform specific tasks efficiently. They're easy to combine or modify, making my everyday workflow more productive and pleasant.

Until next time!

## References

- [Lua](https://www.lua.org/)
- [Neovim](https://neovim.io/)
- [bat on GitHub](https://github.com/sharkdp/bat)
- [fzf on GitHub](https://github.com/junegunn/fzf)
