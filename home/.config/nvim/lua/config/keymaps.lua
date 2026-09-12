-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Keep the yanked/copied text in the register when pasting over a selection
vim.keymap.set("x", "p", '"_dP', { desc = "Paste without overwriting register" })
vim.keymap.set("x", "P", '"_dP', { desc = "Paste before without overwriting register" })

-- Keep the cursor centred while moving around. `n`/`N` are left alone: LazyVim
-- already remaps them (it appends `zv` to open folds), and `%` belongs to
-- matchit.
for _, lhs in ipairs({ "<C-u>", "<C-d>", "{", "}", "G", "gg", "<C-i>", "<C-o>", "*", "#" }) do
  vim.keymap.set("n", lhs, lhs .. "zz", { desc = "Centre cursor after " .. lhs })
end

-- Redo, without reaching for <C-r>
vim.keymap.set("n", "U", "<C-r>", { desc = "Redo last change" })

-- Buffer switching. LazyVim already has <S-h>/<S-l> and [b/]b; these are the
-- third alias, and the one actually in use.
--
-- Note that <Tab> and <C-i> are the same byte on a classic terminal, so this
-- mapping swallows the centred <C-i> above unless the terminal can tell them
-- apart. Ghostty can (kitty keyboard protocol); somewhere that cannot, <C-i>
-- will switch buffers instead of jumping forward.
vim.keymap.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })

-- Escape insert mode without leaving the home row
vim.keymap.set("i", "jj", "<esc>", { desc = "Exit insert mode" })
vim.keymap.set("i", "JJ", "<esc>", { desc = "Exit insert mode" })

-- Line ends in visual mode. Normal-mode L/H stay as LazyVim's buffer
-- navigation.
vim.keymap.set("v", "L", "$<left>", { desc = "Jump to end of line" })
vim.keymap.set("v", "H", "^", { desc = "Jump to beginning of line" })

-- Move the selected block, keeping it selected and reindented
vim.keymap.set("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- Clear search highlighting
vim.keymap.set("n", "<leader>no", "<cmd>noh<cr>", { desc = "Clear search highlight" })

-- Even out the splits
vim.keymap.set("n", "<leader>=", "<C-w>=", { desc = "Equalise split sizes" })

-- Spelling suggestions for the word under the cursor
vim.keymap.set("n", "<leader>ss", function()
  Snacks.picker.spelling()
end, { desc = "Spelling suggestions" })
