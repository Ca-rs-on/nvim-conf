-- ~/.config/nvim/after/plugin/netrw_ls.lua
-- ls -al style columns for netrw, drawn as inline virtual text.
-- Buffer text is untouched, so netrw's own filename parsing keeps working.

local ns = vim.api.nvim_create_namespace("netrw_ls")
local uv = vim.uv

-- uid/gid -> name, read once from /etc/passwd and /etc/group
local function id_map(path)
  local t = {}
  local f = io.open(path)
  if f then
    for line in f:lines() do
      local name, id = line:match("^([^:]+):[^:]*:(%d+):")
      if name then t[tonumber(id)] = name end
    end
    f:close()
  end
  return t
end
local users, groups = id_map("/etc/passwd"), id_map("/etc/group")

local function perms(st)
  local out = { ({ directory = "d", link = "l" })[st.type] or "-" }
  local bits = "rwxrwxrwx"
  for i = 1, 9 do
    local on = bit.band(st.mode, bit.lshift(1, 9 - i)) ~= 0
    out[#out + 1] = on and bits:sub(i, i) or "-"
  end
  return table.concat(out)
end

local function human(n)
  for _, u in ipairs({ "", "K", "M", "G", "T" }) do
    if n < 1024 then
      return u == "" and tostring(n) or string.format("%.1f%s", n, u)
    end
    n = n / 1024
  end
  return string.format("%.1fP", n)
end

local function decorate(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local dir = vim.b[buf].netrw_curdir
  if not dir or dir:match("^%w+://") then return end -- local dirs only

  local win = vim.fn.bufwinid(buf)
  local style = (win ~= -1 and vim.w[win].netrw_liststyle) or vim.g.netrw_liststyle or 0
  if style ~= 0 then return end -- thin listing only: one bare name per line

  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line ~= "" and not line:match('^"') then -- skip blanks and banner
      local st = uv.fs_lstat(dir .. "/" .. line)
      if not st then
        -- netrw appends a classify suffix (dir/, link@, exec*); retry without it
        st = uv.fs_lstat(dir .. "/" .. line:gsub("[/*@|=]$", ""))
      end
      if st then
        local text = string.format("%s %-8s %-8s %6s %s  ",
          perms(st),
          tostring(users[st.uid] or st.uid),
          tostring(groups[st.gid] or st.gid),
          human(st.size),
          os.date("%b %d %H:%M", st.mtime.sec))
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
          virt_text = { { text, "Comment" } },
          virt_text_pos = "inline",
        })
      end
    end
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function(ev)
    local buf = ev.buf
    vim.schedule(function() decorate(buf) end) -- let netrw finish drawing first
    vim.api.nvim_create_autocmd({ "TextChanged", "BufEnter" }, {
      buffer = buf,
      group = vim.api.nvim_create_augroup("netrw_ls_" .. buf, { clear = true }),
      callback = function() decorate(buf) end,
    })
  end,
})
