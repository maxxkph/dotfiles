-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Keep the yanked/copied text in the register when pasting over a selection
vim.keymap.set("x", "p", '"_dP', { desc = "Paste without overwriting register" })
vim.keymap.set("x", "P", '"_dP', { desc = "Paste before without overwriting register" })
