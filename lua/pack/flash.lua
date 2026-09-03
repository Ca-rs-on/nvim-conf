local ns = vim.api.nvim_create_namespace("ffjump")
local labels = "asdghklqwertyuiop"  -- skip 'f'/'j' to avoid muscle-memory collisions

vim.api.nvim_set_hl(0, "FFJumpLabel", { fg = "#ff007c", bold = true })

local function matches_on_line(char, forward)
  local line = vim.api.nvim_get_current_line()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0)) -- col is 0-based
  local out = {}
  if forward then
    for i = col + 2, #line do                 -- 1-based, strictly after cursor
      if line:sub(i, i) == char then out[#out + 1] = i - 1 end
    end
  else
    for i = col, 1, -1 do
      if line:sub(i, i) == char then out[#out + 1] = i - 1 end
    end
  end
  return out, row
end

local function jump(key)
  local ok, char = pcall(vim.fn.getcharstr)
  if not ok or char == "\27" then return end

  local forward = key == "f" or key == "t"
  local m, row = matches_on_line(char, forward)
  if #m == 0 then return end

  local n = 1
  if #m > 1 then
    local buf = vim.api.nvim_get_current_buf()
    for i, c in ipairs(m) do
      local lbl = labels:sub(i, i)
      if lbl == "" then break end
      vim.api.nvim_buf_set_extmark(buf, ns, row - 1, c, {
        virt_text = { { lbl, "FFJumpLabel" } },
        virt_text_pos = "overlay",
        hl_mode = "combine",
        priority = 200,
      })
    end
    vim.cmd("redraw")
    local ok2, lbl = pcall(vim.fn.getcharstr)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    if not ok2 then return end
    n = labels:find(lbl, 1, true)
    if not n or n > #m then return end
  end

  vim.api.nvim_feedkeys(n .. key .. char, "n", false)
end

for _, k in ipairs({ "f", "F", "t", "T" }) do
  vim.keymap.set({ "n", "x", "o" }, k, function() jump(k) end)
end
