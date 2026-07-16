require("lang.php")
require("lang.zig")
require("lang.html")
require("lang.css")
require("lang.json")
require("lang.eslint")
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then return end
		if client:supports_method("textDocument/completion") then
			local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
			-- vue files were sad
			if client.server_capabilities.completionProvider then
				client.server_capabilities.completionProvider.triggerCharacters = chars
			end
			vim.lsp.completion.enable(true, client.id, args.buf, {autotrigger = true})
		end
		vim.lsp.on_type_formatting.enable(true, { client_id = args.data.client_id })
	end,
})
