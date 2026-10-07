-- Expand VS Code-style snippets from snippets/<filetype>.json on 'runtimepath'
-- with vim.snippet. <C-j> in insert mode expands the prefix before the cursor.
local cache = {}

local function load(ft)
	if cache[ft] then return cache[ft] end
	local snips = {}
	for _, path in ipairs(vim.api.nvim_get_runtime_file('snippets/' .. ft .. '.json', true)) do
		local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), '\n'))
		if not ok then
			vim.notify('bad snippet file ' .. path .. ': ' .. data, vim.log.levels.WARN)
		else
			for _, s in pairs(data) do
				local body = type(s.body) == 'table' and table.concat(s.body, '\n') or s.body
				local prefixes = type(s.prefix) == 'table' and s.prefix or { s.prefix }
				for _, p in ipairs(prefixes) do
					table.insert(snips, { prefix = p, body = body })
				end
			end
		end
	end
	cache[ft] = snips
	return snips
end

-- Longest prefix ending at the cursor. Word prefixes need whitespace or
-- punctuation (or line start) before them; punctuation-only prefixes like `(`
-- match anywhere, so `foo(` still expands.
local function find(before)
	local best
	for _, s in ipairs(load(vim.bo.filetype)) do
		local p = s.prefix
		if #p <= #before and before:sub(-#p) == p and (not best or #p > #best.prefix) then
			local prev = before:sub(-#p - 1, -#p - 1)
			if p:find('^%p+$') or prev == '' or prev:find('[%s%p]') then
				best = s
			end
		end
	end
	return best
end

vim.keymap.set('i', '<C-j>', function()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local before = vim.api.nvim_get_current_line():sub(1, col)
	local snip = find(before)
	if not snip then return end
	vim.api.nvim_buf_set_text(0, row - 1, col - #snip.prefix, row - 1, col, {})
	vim.snippet.expand(snip.body)
end, { desc = 'expand snippet' })
