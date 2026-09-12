-- Catppuccin, paired with the OS appearance. Change DARK here to switch the
-- whole editor; latte is the only light flavour, so LIGHT has no alternatives.
--
--   frappe     lightest of the dark three
--   macchiato  the default, mirrors home/.config/ghostty/themes/catppuccin-macchiato
--   mocha      darkest
local DARK = "macchiato"
local LIGHT = "latte"

-- `colorscheme catppuccin` — no flavour suffix — resolves the flavour from
-- `vim.o.background`, which auto-dark-mode.nvim flips when macOS does. Naming
-- `catppuccin-macchiato` instead would pin it and break light mode.

-- Highlights catppuccin does not get right on its own. Re-derived from the
-- active flavour's palette on every colorscheme change, so they survive a
-- light/dark flip instead of keeping the dark flavour's values.
local function apply_overrides()
	local flavour = vim.o.background == "light" and LIGHT or DARK
	local palette = require("catppuccin.palettes").get_palette(flavour)

	-- Telescope panes share the editor background instead of floating on their own.
	for _, pane in ipairs({ "", "Prompt", "Results", "Preview" }) do
		vim.api.nvim_set_hl(0, "Telescope" .. pane .. "Normal", { bg = palette.base })
		vim.api.nvim_set_hl(0, "Telescope" .. pane .. "Border", { fg = palette.blue, bg = palette.base })
	end
	for _, pane in ipairs({ "", "Prompt", "Results", "Preview" }) do
		vim.api.nvim_set_hl(0, "Telescope" .. pane .. "Title", { fg = palette.mauve, bg = palette.base })
	end

	-- Hide all semantic highlights until upstream issues are resolved
	-- (https://github.com/catppuccin/nvim/issues/480)
	for _, group in ipairs(vim.fn.getcompletion("@lsp", "highlight")) do
		vim.api.nvim_set_hl(0, group, {})
	end
end

return {
	{
		"catppuccin/nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				background = { light = LIGHT, dark = DARK },
				-- float = {
				-- 	-- transparent = true,
				-- 	-- solid = false,
				-- },
				integrations = {
					diffview = true,
					fidget = true,
					harpoon = true,
					mason = true,
					native_lsp = { enabled = true },
					noice = true,
					notify = true,
					symbols_outline = true,
					snacks = {
						enabled = true,
						indent_scope_color = "mauve",
					},
					render_markdown = true,
					telescope = true,
					treesitter = true,
					treesitter_context = true,
					ufo = true,
					which_key = true,
				},
			})

			vim.cmd.colorscheme("catppuccin")
			apply_overrides()

			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("maxxkph-catppuccin-overrides", { clear = true }),
				callback = apply_overrides,
			})
		end,
	},

	-- Flips vim.o.background with the OS, then re-runs the colorscheme so
	-- catppuccin picks up the other flavour. Keeps nvim in step with ghostty's
	-- `theme = light:Catppuccin Latte,dark:catppuccin-macchiato`.
	{
		"f-person/auto-dark-mode.nvim",
		lazy = false,
		priority = 999,
		opts = {
			update_interval = 3000,
			set_dark_mode = function()
				vim.o.background = "dark"
				vim.cmd.colorscheme("catppuccin")
			end,
			set_light_mode = function()
				vim.o.background = "light"
				vim.cmd.colorscheme("catppuccin")
			end,
		},
	},
}

-- macchiato palette, for reference when hand-picking colours:
-- rosewater = "#f4dbd6",  flamingo = "#f0c6c6",  pink     = "#f5bde6",
-- mauve     = "#c6a0f6",  red      = "#ed8796",  maroon   = "#ee99a0",
-- peach     = "#f5a97f",  yellow   = "#eed49f",  green    = "#a6da95",
-- teal      = "#8bd5ca",  sky      = "#91d7e3",  sapphire = "#7dc4e4",
-- blue      = "#8aadf4",  lavender = "#b7bdf8",  text     = "#cad3f5",
-- subtext1  = "#b8c0e0",  subtext0 = "#a5adcb",  overlay2 = "#939ab7",
-- overlay1  = "#8087a2",  overlay0 = "#6e738d",  surface2 = "#5b6078",
-- surface1  = "#494d64",  surface0 = "#363a4f",  base     = "#24273a",
-- mantle    = "#1e2030",  crust    = "#181926",
