---
title: "Neovimで行をソートして重複行を削除する"
emoji: "🔡"
type: "tech"
topics: ["lua", "neovim", "vim"]
published: true
---

Good organization makes code easier to read. Disorganized lists make it difficult to maintain a project, and they also give your code an unprofessional look.

These two functions sort and remove duplicate lines in selected text blocks in *Neovim*.

The `sort_lines` function sorts the selected lines:

```lua
function sort_lines()
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

  vim.api.nvim_buf_set_lines(
    0,
    start_line,
    end_line,
    false,
    lines
  )
end
```

The `sort_and_uniq_lines` function sorts and removes duplicate lines:

```lua
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
```

To use these functions, add the mappings below to your *Neovim* configuration file:

```lua
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

When you select a text block in visual mode and press `<Leader>s`, *Neovim* sorts the lines. If you press `<Leader>u`, *Neovim* sorts and removes duplicate lines.

I hope these functions are helpful.

## References

- [Lua](https://www.lua.org/)
- [Neovim](https://neovim.io/)
