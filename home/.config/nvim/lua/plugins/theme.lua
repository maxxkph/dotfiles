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
  -- dark  -> catppuccin-frappe  (matches ghostty's `dark:Catppuccin Frappe`)
  -- light -> catppuccin-latte
  --
  -- This has to agree with the auto-dark-mode callbacks below: LazyVim applies
  -- it at startup, before auto-dark-mode's first poll, so naming a different
  -- colorscheme here shows that one briefly and then swaps.
  --
  -- oldworld and mellow are still installed and colors/maxx-mellow{,-dawn}.lua
  -- still alias them, so going back is a change to this line and the two
  -- callbacks.
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin-frappe" },
  },
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    priority = 999,
    opts = {
      update_interval = 3000,
      set_dark_mode = function()
        vim.o.background = "dark"
        vim.cmd.colorscheme("catppuccin-frappe")
      end,
      set_light_mode = function()
        vim.o.background = "light"
        vim.cmd.colorscheme("catppuccin-latte")
      end,
    },
  },
}
