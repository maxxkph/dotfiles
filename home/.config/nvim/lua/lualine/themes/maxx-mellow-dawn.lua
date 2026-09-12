-- lualine theme for maxx-mellow-dawn (light).
-- Mirrors maxx-mellow.lua with the same semantic role mapping.
--
-- Mode blocks use the canonical ("solid") dawn accents rather than the
-- deepened text variants: these are fills, not text on the light ground,
-- so they take light text on top.

local on_accent = "#f4f2f0"

return {
  normal = {
    a = { fg = on_accent, bg = "#7c70a8", gui = "bold" },
    b = { fg = "#48454f", bg = "#ded9d3" },
    c = { fg = "#7d7a86", bg = "#e9e6e2" },
  },
  insert = { a = { fg = on_accent, bg = "#588368", gui = "bold" } },
  visual = { a = { fg = on_accent, bg = "#a9744f", gui = "bold" } },
  replace = { a = { fg = on_accent, bg = "#b25c7e", gui = "bold" } },
  command = { a = { fg = on_accent, bg = "#5f6fb0", gui = "bold" } },
  terminal = { a = { fg = on_accent, bg = "#4d868b", gui = "bold" } },
  inactive = {
    a = { fg = "#a8a3b0", bg = "#eae7e3", gui = "bold" },
    b = { fg = "#a8a3b0", bg = "#eae7e3" },
    c = { fg = "#a8a3b0", bg = "#eae7e3" },
  },
}
