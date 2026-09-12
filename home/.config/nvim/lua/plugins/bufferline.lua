-- Buffer tabs, coloured from the active theme. bufferline's own derived colours
-- are washed out, and several themes (oldworld among them) ship no bufferline
-- integration at all, so the highlights are built here instead.
--
-- `opts.highlights` is passed as a *function*, which bufferline re-runs on every
-- ColorScheme event -- that is what keeps the tabs in step with a light/dark
-- flip, or with switching theme entirely.

local palette = require("config.palette")

local function hex(n)
  return string.format("#%06x", n)
end

-- Every entry comes from a group the theme defines itself. Checked against
-- maxx-mellow and its light companion, this reproduces the palette that used to
-- be hardcoded here exactly, for all but `visible` and `info`.
local function derive()
  local fg = palette.pick("fg", { "Normal" }, 0xc9c7cd)
  local bg = palette.pick("bg", { "Normal" }, 0x161617)

  -- Unselected tab text. TabLine is precisely this in every theme checked.
  local inactive = palette.pick("fg", { "TabLine", "NonText", "Comment" }, fg)

  return {
    -- The empty stretch of tabline. TabLineFill is the theme's own opinion on
    -- that exact strip; failing that, a shade below the editor background.
    fill = hex(palette.pick("bg", { "TabLineFill", "NormalFloat" }, palette.darken(bg, 0.14))),
    -- The selected tab takes the editor background, so it reads as connected
    -- to the buffer beneath it.
    bg = hex(bg),
    fg = hex(fg),
    inactive = hex(inactive),
    -- Visible-but-unfocused sits between the two.
    visible = hex(palette.blend(fg, inactive, 0.58)),
    modified = hex(palette.pick("fg", { "diffAdded", "GitSignsAdd", "String" }, fg)),
    close = hex(palette.pick("fg", { "diffRemoved", "GitSignsDelete", "DiagnosticError" }, fg)),
    error = hex(palette.pick("fg", { "DiagnosticError" }, fg)),
    warning = hex(palette.pick("fg", { "DiagnosticWarn" }, fg)),
    info = hex(palette.pick("fg", { "DiagnosticInfo" }, fg)),
    hint = hex(palette.pick("fg", { "DiagnosticHint" }, fg)),
  }
end

local function gen()
  local p = derive()
  local inact = { fg = p.inactive, bg = p.fill }
  local vis = { fg = p.visible, bg = p.bg }
  local sel = { fg = p.fg, bg = p.bg }

  local hl = {
    fill = { bg = p.fill },
    background = inact,
    buffer_visible = vis,
    buffer_selected = { fg = p.fg, bg = p.bg, bold = true, italic = false },

    close_button = inact,
    close_button_visible = vis,
    close_button_selected = { fg = p.close, bg = p.bg },

    -- separators blend into each tab's own background (flat blocks)
    separator = { fg = p.fill, bg = p.fill },
    separator_visible = { fg = p.bg, bg = p.bg },
    separator_selected = { fg = p.bg, bg = p.bg },
    offset_separator = { fg = p.fill, bg = p.fill },

    indicator_visible = { fg = p.bg, bg = p.bg },
    indicator_selected = { fg = p.bg, bg = p.bg },

    modified = { fg = p.modified, bg = p.fill },
    modified_visible = { fg = p.modified, bg = p.bg },
    modified_selected = { fg = p.modified, bg = p.bg },

    duplicate = { fg = p.inactive, bg = p.fill, italic = true },
    duplicate_visible = { fg = p.visible, bg = p.bg, italic = true },
    duplicate_selected = { fg = p.fg, bg = p.bg, italic = true },

    numbers = inact,
    numbers_visible = vis,
    numbers_selected = { fg = p.fg, bg = p.bg, bold = true },

    tab = inact,
    tab_selected = { fg = p.fg, bg = p.bg, bold = true },
    tab_close = { fg = p.close, bg = p.fill },
    tab_separator = { fg = p.fill, bg = p.fill },
    tab_separator_selected = { fg = p.bg, bg = p.bg },

    pick = { fg = p.close, bg = p.fill, bold = true },
    pick_visible = { fg = p.close, bg = p.bg, bold = true },
    pick_selected = { fg = p.close, bg = p.bg, bold = true },
  }

  for name, color in pairs({ error = p.error, warning = p.warning, info = p.info, hint = p.hint }) do
    hl[name] = { fg = p.inactive, bg = p.fill }
    hl[name .. "_visible"] = { fg = p.visible, bg = p.bg }
    hl[name .. "_selected"] = { fg = color, bg = p.bg, bold = true, italic = false }
    hl[name .. "_diagnostic"] = { fg = p.inactive, bg = p.fill }
    hl[name .. "_diagnostic_visible"] = { fg = p.visible, bg = p.bg }
    hl[name .. "_diagnostic_selected"] = { fg = color, bg = p.bg, bold = true, italic = false }
  end

  return hl
end

return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      highlights = gen,
      options = {
        -- LazyVim hides the tabline until a second buffer is open, which makes
        -- the whole editor jump down a line the moment you open one. Always
        -- showing it keeps the layout fixed.
        always_show_bufferline = true,
      },
    },
  },
}
