-- lualine theme for maxx-mellow (dark).
-- Found automatically by lualine's `auto` theme, which resolves
-- `lualine.themes.<vim.g.colors_name>` before generating its own.
--
-- Mode colors follow the palette's semantic roles: purple=brand (normal),
-- green=success (insert), peach=warning (visual), rose=danger (replace),
-- blue=info (command), cyan=special (terminal). The accents are light
-- pastels on this ground, so mode blocks take dark text.

local bg = "#161617"

return {
  normal = {
    a = { fg = bg, bg = "#aca1cf", gui = "bold" },
    b = { fg = "#c9c7cd", bg = "#2a2a2c" },
    c = { fg = "#9f9ca6", bg = "#1b1b1c" },
  },
  insert = { a = { fg = bg, bg = "#90b99f", gui = "bold" } },
  visual = { a = { fg = bg, bg = "#e6b99d", gui = "bold" } },
  replace = { a = { fg = bg, bg = "#ea83a5", gui = "bold" } },
  command = { a = { fg = bg, bg = "#92a2d5", gui = "bold" } },
  terminal = { a = { fg = bg, bg = "#85b5ba", gui = "bold" } },
  inactive = {
    a = { fg = "#6c6874", bg = "#131314", gui = "bold" },
    b = { fg = "#6c6874", bg = "#131314" },
    c = { fg = "#6c6874", bg = "#131314" },
  },
}
