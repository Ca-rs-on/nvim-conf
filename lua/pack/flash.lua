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

-- Reads the target char, labels matches if there are several, and returns
-- (char, n, cols) where cols[n] is the chosen 0-based column. nil = cancelled.
local function pick(key)
  local ok, char = pcall(vim.fn.getcharstr)
  if not ok or char == "\27" then return end

  local forward = key == "f" or key == "t"
  local m, row = matches_on_line(char, forward)

  local n = vim.v.count1
  if vim.v.count == 0 and #m > 1 then
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

  return char, n, m
end

-- Normal / operator-pending: <expr> mapping that returns e.g. "3fx", so the
-- builtin motion does the work (operators like dtx, dot-repeat and ;/, intact).
local function jump_expr(key)
  local char, n = pick(key)
  if not char then return "" end
  if vim.v.count > 0 then return key .. char end -- typed count is still pending
  return n .. key .. char
end

-- Visual: labels don't render while an <expr> mapping is evaluating there, so
-- run as a normal callback and move the cursor ourselves (extends the selection).
local function jump_visual(key)
  local char, n, m = pick(key)
  if not char or not m[n] then return end

  local forward = key == "f" or key == "t"
  local till = key == "t" or key == "T"
  local col = m[n]
  if till then col = forward and col - 1 or col + 1 end

  vim.fn.setcharsearch({ char = char, forward = forward and 1 or 0, ["until"] = till and 1 or 0 })
  vim.api.nvim_win_set_cursor(0, { vim.fn.line("."), col })
end

for _, k in ipairs({ "f", "F", "t", "T" }) do
  vim.keymap.set({ "n", "o" }, k, function() return jump_expr(k) end, { expr = true })
  vim.keymap.set("x", k, function() jump_visual(k) end)
end
