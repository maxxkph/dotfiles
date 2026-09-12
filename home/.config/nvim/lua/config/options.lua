-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.conceallevel = 0 -- show raw markdown syntax instead of inline rendering
vim.opt.smoothscroll = false
vim.opt.spell = false
vim.g.snacks_animate = false

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    local light = vim.o.background == "light"
    -- mellow (dark) values, and their maxx-mellow-dawn (light) counterparts
    local indent = light and "#e2ded9" or "#262628"
    local scope = light and "#cec9c1" or "#313134"
    local line_nr = light and "#a8a3b0" or "#6c6874"
    local diff_text = light and "#48454f" or "#c9c7cd"
    local add_bg = light and "#d7e8dc" or "#1a2e22"
    local del_bg = light and "#f0d9e0" or "#2e1a22"

    vim.api.nvim_set_hl(0, "SnacksIndent", { fg = indent })
    vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = scope })
    vim.api.nvim_set_hl(0, "SnacksDiffContext", { link = "Normal" })
    vim.api.nvim_set_hl(0, "SnacksDiffContextLineNr", { fg = line_nr })
    -- Readable git diff: subtle tint + main text fg (syntax colors were unreadable on tinted bg)
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = add_bg, fg = diff_text })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = del_bg, fg = diff_text })
    vim.api.nvim_set_hl(0, "DiffChange", { link = "Normal" })
    vim.api.nvim_set_hl(0, "SnacksDiffAdd", { bg = add_bg, fg = diff_text })
    vim.api.nvim_set_hl(0, "SnacksDiffDelete", { bg = del_bg, fg = diff_text })
    vim.api.nvim_set_hl(0, "SnacksDiffAddLineNr", { bg = add_bg, fg = line_nr })
    vim.api.nvim_set_hl(0, "SnacksDiffDeleteLineNr", { bg = del_bg, fg = line_nr })
  end,
})
