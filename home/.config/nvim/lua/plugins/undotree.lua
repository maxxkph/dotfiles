return {
	{
		"mbbill/undotree",
		event = { "BufReadPost" },
		lazy = true,
		config = function()
			if vim.fn.has("persistent_undo") == 1 then
				-- Upstream keeps this in ~/.config/nvim/.undodir. Here that
				-- directory is a symlink into the dotfiles repo, so every undo
				-- write would dirty the working tree with binary files. Undo
				-- history is machine-local state, so it belongs in stdpath
				-- "state" — which is also Neovim's own default.
				local target_path = vim.fn.stdpath("state") .. "/undo"
				vim.fn.mkdir(target_path, "p")
				vim.opt.undodir = target_path
				vim.opt.undofile = true
			end
		end,
	},
}
