---
title: "Neovimカスタマイズ：Luaで行のソートと重複行の削除"
emoji: "🔀"
type: "tech"
topics: ["neovim", "lua", "vim"]
published: true
---

Continuing my Neovim customizations, here are two functions I use frequently: `sort_lines` and `sort_and_uniq_lines`. As the names suggest, they sort the content of the selected lines and, in the case of `sort_and_uniq_lines`, also remove duplicates.

```lua
function sort_lines()
  -- Get the start and end position of the selection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  -- Convert the position to the line index

  -- Adjust start_pos because lines in Lua start at 0
  local start_line = start_pos[2] - 1
  -- No need to adjust end_line
  local end_line = end_pos[2]

  -- Get the selected lines
  local lines = vim.api.nvim_buf_get_lines(
      0,
      start_line,
      end_line,
      false
  )

  -- Sort the lines
  table.sort(lines)

  -- Replace the original lines
  vim.api.nvim_buf_set_lines(
    0,
    start_line,
    end_line,
    false,
    lines
  )
end

function sort_and_uniq_lines()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line = start_pos[2] - 1
  local end_line = end_pos[2]

  local lines = vim.api.nvim_buf_get_lines(
    0,
    start_line,
    end_line,
    false
  )

  table.sort(lines)

  -- Remove duplicate lines
  local uniq_lines = {}
  local last_line = nil
  for _, line in ipairs(lines) do
    if line ~= last_line then
      table.insert(uniq_lines, line)
      last_line = line
    end
  end

  vim.api.nvim_buf_set_lines(
    0,
    start_line,
    end_line,
    false,
    uniq_lines
  )
end

vim.api.nvim_set_keymap(
    'v',
    '<Leader>s',
    ':lua sort_lines()<CR>',
    { noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
    'v',
    '<Leader>u',
    ':lua sort_and_uniq_lines()<CR>',
    { noremap = true, silent = true }
)
```
[sort_lines.lua](https://crg.eti.br/en/post/personalizando_neovim_ordenacao_e_remocao_de_linhas_duplicadas_com_lua/sort_lines.lua)

To use the script, just add the `sort_lines.lua` file to the `config/nvim/lua` directory and load it at the beginning of your `init.lua` file.

```lua
require "sort_lines"
```

To use these functions, press the key combinations `leader+s` or `leader+u` with the text selected in visual mode.

Sorting lists in your code, such as menus or array elements, makes them easier to read. It also adds a touch of order and cleanliness. These small actions make code more pleasant and reduce the effort needed to understand it.

As I mentioned in my [bookmark system](https://crg.eti.br/en/post/criando-sistema-de-bookmarks-no-neovim-com-lua/), these automations make Neovim powerful and customizable. Often you don't need plugins; just a bit of creativity.
