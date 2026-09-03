-- review.lua — plaintext-file-backed code review overlay.
-- This is powered on vibes.
--   require("pack.review").setup()       -- or setup({ file = "/abs/path/review.txt" })
--
-- Source of truth is a grep-format text file (default: <cwd>/review.txt).
-- Diagnostics are the live overlay: gutter signs + virtual text, position-
-- tracked via extmarks within a session. The file is durable + gitignore-able.
--
-- The file is re-read when its mtime changes (on BufEnter/FocusGained), so
-- notes written by something else — a review agent, another nvim — show up
-- without a manual reload. Diagnostics are only ever set on *loaded* buffers;
-- unloaded ones get theirs on BufReadPost.
--
-- Mappings (add works in normal mode on the cursor line, or in visual mode over
-- the selection; visual mode is exited once the note is taken):
--   <leader>rn   note   (HINT)
--   <leader>rw   warn   (WARN)
--   <leader>re   error  (ERROR)
--   <leader>rt   toggle showing the overlay (hide/show, non-destructive)
--   <leader>rr   resolve item under cursor: drop it from file + overlay
--
-- Commands:
--   :ReviewLoad   (re)read the file into the overlay
--   :ReviewQf     push every entry into the quickfix list (]q / [q)

local M = {}
M.opts = {}
M._shown = true
M._setup_done = false
M._items = {}   -- parsed entries: { path, abs, a, b, tc, msg, raw }
M._mtime = 0    -- mtime the current _items were read at

local uv = vim.uv or vim.loop
local ns = vim.api.nvim_create_namespace("review")
local S = vim.diagnostic.severity

-- type char -> severity. Note: quickfix/diagnostics call a "note" a HINT.
local sev_of  = { N = S.HINT, W = S.WARN, I = S.INFO, E = S.ERROR }

-- Resolved lazily so it follows :cd. Keep cwd pinned at the project root and
-- the cwd-relative paths written below will resolve when read back.
local function review_file()
  return M.opts.file or (vim.fn.getcwd() .. "/review.txt")
end

local function file_mtime()
  local st = uv.fs_stat(review_file())
  return st and st.mtime.sec or 0
end

-- Absolute + normalized, so a cwd-relative entry and a buffer's full path
-- compare equal. Relative paths resolve against cwd, same as the file format.
local function abspath(p)
  return vim.fs.normalize(vim.fn.fnamemodify(p, ":p"))
end

-- Canonical on-disk line. Same function feeds the file write AND the diagnostic
-- user_data key, so the two never drift and resolve can match exactly.
local function fmt_line(path, a, b, tc, msg)
  local loc = (a == b) and tostring(a) or (a .. "-" .. b)
  return string.format("%s:%s %s: %s", path, loc, tc, msg)
end

-- Returns path, a, b(=a if single), type_char, msg  — or nil on no match.
local function parse_line(line)
  local path, a, b, tc, msg = line:match("^(.-):(%d+)%-(%d+)%s+([NWIE]):%s?(.*)$")
  if path then return path, tonumber(a), tonumber(b), tc, msg end
  path, a, tc, msg = line:match("^(.-):(%d+)%s+([NWIE]):%s?(.*)$")
  if path then return path, tonumber(a), tonumber(a), tc, msg end
  return nil
end

local function read_lines()
  local out, f = {}, io.open(review_file(), "r")
  if not f then return out end
  for l in f:lines() do out[#out + 1] = l end
  f:close()
  return out
end

local function append_line(line)
  local f = assert(io.open(review_file(), "a"))
  f:write(line .. "\n")
  f:close()
end

local function remove_line(target)
  local lines, kept, hit = read_lines(), {}, false
  for _, l in ipairs(lines) do
    if not hit and l == target then hit = true else kept[#kept + 1] = l end
  end
  local f = assert(io.open(review_file(), "w"))
  for _, l in ipairs(kept) do f:write(l .. "\n") end
  f:close()
  return hit
end

-- ── overlay ────────────────────────────────────────────────────────────────
-- Only loaded buffers get diagnostics: positions (and therefore extmarks) are
-- undefined until the file is read, and an out-of-range lnum can throw in the
-- underline handler. BufReadPost catches the rest.
local function apply_buf(bufnr)
  if not vim.api.nvim_buf_is_loaded(bufnr) then return end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then return end

  local path, last, ds = abspath(name), vim.api.nvim_buf_line_count(bufnr), {}
  for _, it in ipairs(M._items) do
    if it.abs == path then
      -- clamp: the file may have shrunk since the note was written
      local a = math.min(it.a, last)
      local b = math.min(math.max(it.b, a), last)
      ds[#ds + 1] = {
        lnum = a - 1, end_lnum = b - 1, col = 0,  -- file is 1-idx, diags 0-idx
        severity = sev_of[it.tc], message = it.msg, source = "review",
        user_data = { review = it.raw },
      }
    end
  end

  -- don't churn DiagnosticChanged for the buffers this file says nothing about
  if #ds > 0 or #vim.diagnostic.get(bufnr, { namespace = ns }) > 0 then
    vim.diagnostic.set(ns, bufnr, ds)
  end
end

local function apply_all()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    apply_buf(b)
  end
end

-- ── load whole file into the overlay ───────────────────────────────────────
function M.load()
  M._items, M._mtime = {}, file_mtime()
  for _, raw in ipairs(read_lines()) do
    if raw:match("%S") then
      local path, a, b, tc, msg = parse_line(raw)
      if path then
        M._items[#M._items + 1] =
          { path = path, abs = abspath(path), a = a, b = b, tc = tc, msg = msg, raw = raw }
      else
        vim.notify("review: unparsed line: " .. raw, vim.log.levels.WARN)
      end
    end
  end
  vim.diagnostic.reset(ns)
  apply_all()
end

local function maybe_reload()
  if file_mtime() ~= M._mtime then M.load() end
end

-- ── add (normal: cursor line, visual: selection) ──────────────────────────────────────────────────────
local function add(tc)
  return function()
    local path = vim.fn.expand("%:.")            -- relative to cwd
    if path == "" then
      return vim.notify("review: buffer has no file", vim.log.levels.WARN)
    end
    local bufnr = vim.api.nvim_get_current_buf()
    local a, b = vim.fn.line("."), vim.fn.line(".")  -- normal: just this line
    if vim.fn.mode():match("^[vV\22]") then          -- visual: live selection ends
      a = vim.fn.line("v")
      if a > b then a, b = b, a end
      -- leave visual mode so the prompt returns to a normal buffer
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    end
    vim.ui.input({ prompt = ("%s note: "):format(tc) }, function(msg)
      if not msg or msg == "" then return end
      local raw = fmt_line(path, a, b, tc, msg)
      append_line(raw)
      M._items[#M._items + 1] =
        { path = path, abs = abspath(path), a = a, b = b, tc = tc, msg = msg, raw = raw }
      M._mtime = file_mtime()                    -- our own write isn't a reload
      apply_buf(bufnr)
      vim.notify(("review += %s:%s-%s [%s]"):format(path, a, b, tc))
    end)
  end
end

-- ── resolve (normal mode) ──────────────────────────────────────────────────
local function resolve()
  local bufnr = vim.api.nvim_get_current_buf()
  local line0 = vim.fn.line(".") - 1

  -- anywhere inside the range counts, not just its first line; innermost wins
  local hit
  for _, d in ipairs(vim.diagnostic.get(bufnr, { namespace = ns })) do
    local last = d.end_lnum or d.lnum
    if line0 >= d.lnum and line0 <= last then
      if not hit or (last - d.lnum) < ((hit.end_lnum or hit.lnum) - hit.lnum) then
        hit = d
      end
    end
  end
  if not hit then
    return vim.notify("review: nothing under cursor", vim.log.levels.WARN)
  end

  local key = hit.user_data and hit.user_data.review
  if key then
    if not remove_line(key) then
      vim.notify("review: entry not found in file (removed from overlay only)",
        vim.log.levels.WARN)
    end
    for i, it in ipairs(M._items) do
      if it.raw == key then table.remove(M._items, i) break end
    end
  end
  M._mtime = file_mtime()
  apply_buf(bufnr)
  vim.notify("review: resolved")
end

local function toggle()
  M._shown = not M._shown
  vim.diagnostic.enable(M._shown, { ns_id = ns })
  vim.notify(M._shown and "review: shown" or "review: hidden")
end

-- ── setup ──────────────────────────────────────────────────────────────────
function M.setup(opts)
  if opts and opts.file then M.opts.file = opts.file end
  if M._setup_done then
    M.load()
    return M
  end
  M._setup_done = true

  -- Drop this line if you already manage signcolumn yourself.
  vim.opt.signcolumn = "yes"

  vim.diagnostic.config({
    severity_sort = true,
    underline = false,                -- a whole-range squiggle is just noise
    virtual_text = { prefix = "▶" },  -- set to false for gutter-only
    signs = {
      text = {
        [S.ERROR] = "▶", [S.WARN] = "▶", [S.INFO] = "▶", [S.HINT] = "▶",
      },
    },
  }, ns)

  local km = vim.keymap.set
  km({ "n", "x" }, "<leader>rn", add("N"), { desc = "review: note" })
  km({ "n", "x" }, "<leader>rw", add("W"), { desc = "review: warn" })
  km({ "n", "x" }, "<leader>re", add("E"), { desc = "review: error" })
  km("n", "<leader>rt", toggle,   { desc = "review: toggle overlay" })
  km("n", "<leader>rr", resolve,  { desc = "review: resolve under cursor" })

  vim.api.nvim_create_user_command("ReviewLoad", function() M.load() end, {})
  vim.api.nvim_create_user_command("ReviewQf", function()
    local items = {}
    for _, it in ipairs(M._items) do
      items[#items + 1] = {
        filename = it.path, lnum = it.a, end_lnum = it.b, col = 1,
        type = it.tc, text = it.msg,
      }
    end
    if #items == 0 then
      return vim.notify("review: no entries", vim.log.levels.WARN)
    end
    vim.fn.setqflist({}, " ", { title = "review", items = items })
    vim.cmd.copen()
  end, {})

  local group = vim.api.nvim_create_augroup("review", { clear = true })
  -- positions only exist once the file is read; also re-applies after :e!
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group, callback = function(ev) apply_buf(ev.buf) end,
  })
  -- pick up notes written behind our back (review agent, another nvim)
  vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained" }, {
    group = group, callback = function(ev)
      maybe_reload()
      apply_buf(ev.buf)
    end,
  })
  -- a different cwd is a different review file
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group, callback = function() M.load() end,
  })

  -- Pull in any existing notes for this project on startup.
  M.load()
  return M
end

return M
