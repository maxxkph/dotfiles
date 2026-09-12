-- oldworld.nvim ships no bufferline integration, so the buffer tabs fall back to
-- bufferline's washed-out derived colors in both themes. Re-color them from the
-- active palette here. `opts.highlights` as a function is re-run by bufferline on
-- every ColorScheme event, so this follows the maxx-mellow <-> maxx-mellow-dawn swap.

local palettes = {
  dark = {
    fill = "#131314", -- empty tabline area (a touch below editor bg)
    bg = "#161617", -- selected tab: editor bg, "connected" to the buffer
    inactive = "#6c6874",
    visible = "#9f9ca6",
    fg = "#c9c7cd",
    modified = "#90b99f",
    close = "#ea83a5",
    error = "#ea83a5",
    warning = "#e6b99d",
    info = "#92a2d5",
    hint = "#85b5ba",
  },
  light = {
    fill = "#eae7e3",
    bg = "#f4f2f0",
    inactive = "#9a95a2",
    visible = "#6b6874",
    fg = "#48454f",
    modified = "#4f7d5e",
    close = "#b85a7c",
    error = "#b85a7c",
    warning = "#996f42",
    info = "#5464a8",
    hint = "#468086",
  },
}

local function gen()
  local p = palettes[vim.o.background] or palettes.dark
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
    },
  },
}
