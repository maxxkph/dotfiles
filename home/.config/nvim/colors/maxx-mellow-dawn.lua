-- maxx-mellow-dawn — light companion to maxx-mellow (nvim/colors/maxx-mellow.lua).
--
-- oldworld.nvim is dark-only, but every one of its highlight groups is defined
-- purely in terms of palette keys (no hardcoded hex). So we swap in a light,
-- warm palette with the same key names and let oldworld generate the whole
-- theme — editor, syntax, and all its plugin integrations — from it.
--
-- Palette mirrors ghostty/themes/maxx-mellow-dawn: warm off-white ground,
-- muted earthy accents darkened for contrast on light.

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.background = "light"
vim.o.termguicolors = true
vim.g.colors_name = "maxx-mellow-dawn"

local palette = {
  bg = "#f4f2f0",
  fg = "#48454f",
  subtext1 = "#6a6774",
  subtext2 = "#7d7a86",
  subtext3 = "#847f8d", -- comments
  subtext4 = "#a8a3b0",
  bg_dark = "#eae7e3",
  black = "#e6e3df", -- popup / search / tabline backgrounds in light mode
  red = "#b85a7c",
  green = "#4f7d5e",
  yellow = "#996f42",
  purple = "#6f639d",
  magenta = "#9c5695",
  orange = "#bd6650",
  blue = "#5464a8",
  cyan = "#468086",
  gray0 = "#efece9",
  gray1 = "#e9e6e2",
  gray2 = "#ded9d3",
  gray3 = "#cec9c1",
  gray4 = "#c8c2b8",
  gray5 = "#afa99f",
  white = "#2c2a32", -- PmenuSel foreground
  none = "NONE",
}

-- Reload oldworld's modules against the light palette. They capture the palette
-- as an upvalue at load time, so anything cached from a previous (dark) load has
-- to be dropped first. Keep `oldworld.config` so user `setup()` opts survive.
local function drop_oldworld()
  for name in pairs(package.loaded) do
    if name:match("^oldworld") and name ~= "oldworld.config" then
      package.loaded[name] = nil
    end
  end
end

drop_oldworld()
package.loaded["oldworld.palette"] = palette
require("oldworld.highlights").setup()

-- Leave the module cache clean: drop our light-palette injection and the modules
-- built against it, so switching back to `oldworld` rebuilds from its dark source.
drop_oldworld()

-- A handful of oldworld groups use `black` as a *foreground* on a bright fill
-- (it doubles as both roles in the dark palette). Flip those for light mode.
local set = vim.api.nvim_set_hl
set(0, "Cursor", { fg = palette.bg, bg = palette.fg })
set(0, "lCursor", { fg = palette.bg, bg = palette.fg })
set(0, "CursorIM", { fg = palette.bg, bg = palette.fg })
set(0, "IncSearch", { fg = "#f9f6f2", bg = palette.yellow })
set(0, "CurSearch", { fg = "#f9f6f2", bg = palette.yellow })
set(0, "WildMenu", { fg = palette.bg, bg = palette.purple })
