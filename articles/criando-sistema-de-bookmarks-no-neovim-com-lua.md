---
title: "LuaでNeovimにブックマーク機能を自作する"
emoji: "🔖"
type: "tech"
topics: ["neovim", "lua", "vim", "productivity"]
published: true
---

Continuing our series of articles aimed at reducing the cognitive effort involved in programming tasks, here is my small bookmark script for Neovim.

Neovim is incredibly customizable. Without having to build full plugins, you can add a lot of functionality with just a few Lua functions.

In my day-to-day work, I often need to return to the same files to fix and test problems. Opening those files directly at the right line, without wasting time navigating, is essential.

To solve this, I built a set of Lua functions that make up my bookmark system. It saves the bookmarks in a marks.txt file, following a specific format that I use in other scripts: one column with the full path and file name, and another with the line number.

You can also create bookmarks specific to the project you're working on, but I rarely use that feature.

```lua
function Mark_point()
  local home = os.getenv("HOME")
  local file_marks = home .. "/marks.txt"

  local file = vim.fn.expand('%:p') -- caminho completo
  local line = vim.fn.line('.')     -- número da linha atual

  local mark = file .. " +" .. line

  local file_handle = io.open(file_marks, "a")
  if file_handle then
    file_handle:write(mark .. "\n")
    file_handle:close()
    print("Marked: " .. mark)
    return
  end
  print("Erro ao abrir o arquivo de marcação: " .. file_marks)
end

function Open_mark(marks_file)
  local file = io.open(marks_file, "r")
  if not file then
    -- print("Erro ao abrir o arquivo de marcação: " .. marks_file)
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

function Open_marks()
  local path = os.getenv("HOME")
  local marks_file = path .. "/marks.txt"
  Open_mark(marks_file)

  path = vim.fn.getcwd()
  marks_file = path .. "/marks.txt"
  Open_mark(marks_file)
end

function Clear_marks()
  local path = os.getenv("HOME")
  local marks_file = path .. "/marks.txt"
  os.remove(marks_file)

  path = vim.fn.getcwd()
  marks_file = path .. "/marks.txt"
  os.remove(marks_file)
end

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
*[bookmark.lua](https://crg.eti.br/en/post/criando-sistema-de-bookmarks-no-neovim-com-lua/bookmark.lua)*

To use the script, just drop the *bookmark.lua* file into the *config/nvim/lua* directory and load it at the start of your *init.lua* file.

```lua
require "bookmark"
```

The script adds two shortcuts:

- leader+m: adds the current file and line to the bookmarks
- leader+o: opens all bookmarked files

The script also adds the Clearmarks command, which clears all bookmarks.

I usually use this script as follows: while analyzing some code or discussing an approach, I mark the important spots. That way I can quickly jump back to those sections, which makes it easier to resume discussions about implementations or to fix bugs.

Once a problem is solved, I delete the bookmarks; I don't keep them around for long. If I need them for a longer project, I simply copy the marks.txt file into my notes.

Alongside the Lua script, I also have a Bash script to open the bookmarks straight from the terminal.

```bash
#!/usr/bin/env bash

MARKS_FILE="$HOME/marks.txt"

[[ ! -f "$MARKS_FILE" ]] && {
    echo "Arquivo de marcações não encontrado: $MARKS_FILE"
    exit 1
}

NVIM_COMMANDS=""

while IFS= read -r line; do
    [[ "$line" =~ ^(.+)\ \+([0-9]+)$ ]] && {
        file="${BASH_REMATCH[1]}"
        lineno="${BASH_REMATCH[2]}"
        NVIM_COMMANDS="$NVIM_COMMANDS +:edit $file +$lineno"
        continue
    }
    echo "Formato inválido na linha: $line"
done < "$MARKS_FILE"

[[ -n "$NVIM_COMMANDS" ]] && {
    nvim $NVIM_COMMANDS
    exit $?
}
echo "Nenhuma marcação válida encontrada para abrir."
exit 1
```
*[open_marks](https://crg.eti.br/en/post/criando-sistema-de-bookmarks-no-neovim-com-lua/open_marks.sh)*

I rarely use this script, since it's more common for me to open Neovim and quickly hit leader+o, but it's handy to have the option of automating how the bookmarks are opened.

I have several small automations like this one in Neovim. Being able to write Lua functions and bind them to events, such as keyboard shortcuts or saving files, makes the editor extremely pleasant to use. In future articles, I'll share more about these automations.
