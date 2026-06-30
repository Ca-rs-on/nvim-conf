vim.pack.add({ 'https://github.com/neovim/nvim-lspconfig' })
vim.pack.add({ 'https://github.com/hrsh7th/cmp-nvim-lsp' })
vim.pack.add({ 'https://github.com/hrsh7th/cmp-buffer' })
vim.pack.add({ 'https://github.com/hrsh7th/cmp-path' })
vim.pack.add({ 'https://github.com/hrsh7th/cmp-cmdline' })
vim.pack.add({ 'https://github.com/hrsh7th/nvim-cmp' })

local cmp = require("cmp")

cmp.setup({
	snippet = {
		expand = function(args)
			vim.snippet.expand(args.body)
		end,
	},
	source = cmp.config.sources({
		{ name = "nvim_lsp" },
	}),
	mapping = cmp.mapping.preset.insert({
		['<C-b>'] = cmp.mapping.scroll_docs(-4),
		['<C-f>'] = cmp.mapping.scroll_docs(4),
		['<C-Space>'] = cmp.mapping.complete(),
		['<C-e>'] = cmp.mapping.abort(),
		['<CR>'] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
		['<Tab>'] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif vim.snippet.active({ direction = 1 }) then
				vim.snippet.jump(1)
			else
				fallback()
			end
		end, { "i", "s" }),
		['<S-Tab>'] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif vim.snippet.active({ direction = -1 }) then
				vim.snippet.jump(1)
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	preselect = cmp.PreselectMode.None,
})
vim.opt.completeopt = 'menu,menuone,noselect'
-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = 'buffer' }
	}
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = 'path' }
	}, {
			{ name = 'cmdline' }
		}),
	matching = { disallow_symbol_nonprefix_matching = false }
})
vim.lsp.config("*", {
	capabilities = require("cmp_nvim_lsp").default_capabilities(),
})
