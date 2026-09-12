return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
  },
  {
    "dgox16/oldworld.nvim",
    name = "oldworld",
    lazy = false,
    priority = 1000,
  },
  {
    "mellow-theme/mellow.nvim",
    name = "mellow",
  },

  -- Baseline colorscheme; auto-dark-mode swaps it per OS appearance.
  -- dark  -> maxx-mellow       (nvim/colors/maxx-mellow.lua, aliases oldworld's dark palette)
  -- light -> maxx-mellow-dawn  (nvim/colors/maxx-mellow-dawn.lua)
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "maxx-mellow" },
  },
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    priority = 999,
    opts = {
      update_interval = 3000,
      set_dark_mode = function()
        vim.o.background = "dark"
        vim.cmd.colorscheme("maxx-mellow")
      end,
      set_light_mode = function()
        vim.o.background = "light"
        vim.cmd.colorscheme("maxx-mellow-dawn")
      end,
    },
  },
}
