-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.conceallevel = 0 -- show raw markdown syntax instead of inline rendering
vim.opt.smoothscroll = false
vim.opt.spell = false
vim.g.snacks_animate = false

-- Snacks indent guides and the git-diff highlights, derived from whatever
-- colorscheme is active instead of from a hardcoded light/dark pair. Every
-- value comes out of a group the theme defines itself, so this follows the
-- maxx-mellow <-> maxx-mellow-dawn swap and works on any other theme too.

-- Indent guides sit between the editor background and the gutter grey.
-- 0.30 / 0.57 reproduce the previously hand-picked values to within a shade
-- in both flavours.
local INDENT_MIX = 0.30
local SCOPE_MIX = 0.57

-- How far the add/delete accent is mixed into the editor background. The diff
-- tint is always computed this way rather than taken from the theme's own
-- DiffAdd/DiffDelete background: some themes (mellow, for one) set that to the
-- accent at full strength, which is what made diff text unreadable in the first
-- place. 0.20 is not arbitrary — oldworld's own diff backgrounds are exactly
-- its accents at 0.20, in both flavours.
local DIFF_MIX = 0.20

local palette = require("config.palette")
local hl, pick, blend = palette.hl, palette.pick, palette.blend

-- Note that no group read here is a group written below. That keeps this
-- idempotent: re-running it without a colorscheme reload cannot feed its own
-- output back in and drift.
local function apply_theme_highlights()
  local normal = hl("Normal")
  -- Nothing to derive from on a theme without an explicit Normal (terminal
  -- default background); leave every group as the theme left it.
  if not (normal and normal.fg and normal.bg) then
    return
  end
  local fg, bg = normal.fg, normal.bg

  local gutter = pick("fg", { "LineNr", "NonText", "Comment" }, fg)
  local indent = blend(gutter, bg, INDENT_MIX)
  local scope = blend(gutter, bg, SCOPE_MIX)

  -- The diff line numbers read as muted-but-present, which is what NonText is
  -- for; it was already the exact value used here by hand in both flavours.
  local line_nr = pick("fg", { "NonText", "Whitespace", "LineNr" }, gutter)

  -- Subtle tint in the theme's own add/delete hue, with Normal's foreground on
  -- top: the theme's syntax colours are unreadable against a tinted background,
  -- so only the background carries the add/delete signal.
  --
  -- `diffAdded`/`GitSignsAdd` are theme-chosen; `Added`/`Removed` are last
  -- resorts because Neovim ships defaults for them, so a theme that never
  -- touches them still reports a colour that has nothing to do with its palette.
  local add = pick("fg", { "diffAdded", "GitSignsAdd", "Added", "String" }, fg)
  local del = pick("fg", { "diffRemoved", "GitSignsDelete", "Removed", "ErrorMsg" }, fg)
  local add_bg = blend(add, bg, DIFF_MIX)
  local del_bg = blend(del, bg, DIFF_MIX)

  local set = vim.api.nvim_set_hl
  set(0, "SnacksIndent", { fg = indent })
  set(0, "SnacksIndentScope", { fg = scope })
  set(0, "SnacksDiffContext", { link = "Normal" })
  set(0, "SnacksDiffContextLineNr", { fg = line_nr })
  set(0, "DiffAdd", { bg = add_bg, fg = fg })
  set(0, "DiffDelete", { bg = del_bg, fg = fg })
  set(0, "DiffChange", { link = "Normal" })
  set(0, "SnacksDiffAdd", { bg = add_bg, fg = fg })
  set(0, "SnacksDiffDelete", { bg = del_bg, fg = fg })
  set(0, "SnacksDiffAddLineNr", { bg = add_bg, fg = line_nr })
  set(0, "SnacksDiffDeleteLineNr", { bg = del_bg, fg = line_nr })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("maxx-theme-highlights", { clear = true }),
  pattern = "*",
  callback = apply_theme_highlights,
})

-- ColorScheme has usually already fired by the time anything reads these, but
-- not if a colorscheme was set before this file loaded.
if vim.g.colors_name then
  apply_theme_highlights()
end
