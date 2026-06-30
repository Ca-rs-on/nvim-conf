require("lang.php")
require("lang.zig")

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client:supports_method("textDoucment/completion") then
			vim.lsp.completion.enable(true, client.id, args.buf, {
				autotrigger = true,
			})
		end
	end,
})
