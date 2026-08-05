vim.pack.add({ 'https://github.com/nvim-mini/mini.snippets' })

local gen_loader = require('mini.snippets').gen_loader
require('mini.snippets').setup({
	snippets = {
		-- Load snippets based on current language from "snippets/"
		-- subdirectories of 'runtimepath' directories.
		gen_loader.from_lang(),
	},
	expand = {
		-- Default exact matching requires whitespace/punctuation before the
		-- prefix, so `(` won't match in `foo(`. Retry punctuation-only
		-- prefixes with no boundary requirement.
		match = function(snips)
			local matched = MiniSnippets.default_match(snips) or {}
			if #matched > 0 then
				return matched
			end
			local punct = vim.tbl_filter(function(s)
				return s.prefix:find('^%p+$') ~= nil
			end, snips)
			return MiniSnippets.default_match(punct, { pattern_exact_boundary = '.?' })
		end,
	},
})

-- Sessions normally stay active after the last tabstop (allowing jumps back);
-- stop instead, matching vim.snippet behavior.
vim.api.nvim_create_autocmd('User', {
	pattern = 'MiniSnippetsSessionJump',
	callback = function(args)
		if args.data.tabstop_to == '0' then
			MiniSnippets.session.stop()
		end
	end,
})
