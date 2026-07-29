-- review.lua — plaintext-file-backed code review overlay.
-- This is powered on vibes.
--   require("review").setup()            -- or setup({ file = "/abs/path/review.txt" })
--
-- Source of truth is a grep-format text file (default: <cwd>/review.txt).
-- Diagnostics are the live overlay: gutter signs + virtual text, position-
-- tracked via extmarks within a session. The file is durable + gitignore-able.
--
-- Mappings (visual for add, normal for the rest):
--   <leader>rn   note   (HINT)   over the visual selection
--   <leader>rw   warn   (WARN)   over the visual selection
--   <leader>re   error  (ERROR)  over the visual selection
--   <leader>rt   toggle showing the overlay (hide/show, non-destructive)
--   <leader>rr   resolve item under cursor: drop it from file + overlay
--
-- Commands:
--   :ReviewLoad   (re)read the file into the overlay
--   :ReviewQf     push current overlay into the quickfix list (]q / [q)

local M = {}
M.opts = {}
M._shown = true
M._setup_done = false

local ns = vim.api.nvim_create_namespace("review")
local S = vim.diagnostic.severity

-- type char <-> severity. Note: quickfix/diagnostics call a "note" a HINT.
local sev_of  = { N = S.HINT, W = S.WARN, I = S.INFO, E = S.ERROR }
local char_of = { [S.HINT] = "N", [S.WARN] = "W", [S.INFO] = "I", [S.ERROR] = "E" }

-- Resolved lazily so it follows :cd. Keep cwd pinned at the project root and
-- the cwd-relative paths written below will resolve when read back.
local function review_file()
  return M.opts.file or (vim.fn.getcwd() .. "/review.txt")
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

-- ── add (visual mode) ──────────────────────────────────────────────────────
local function add(tc)
  return function()
    local path = vim.fn.expand("%:.")            -- relative to cwd
    local a, b = vim.fn.line("v"), vim.fn.line(".")  -- live selection ends
    if a > b then a, b = b, a end
    vim.ui.input({ prompt = ("%s note: "):format(tc) }, function(msg)
      if not msg or msg == "" then return end
      local line = fmt_line(path, a, b, tc, msg)
      append_line(line)
      -- push a live diagnostic so the sign shows immediately, no reload
      local cur = vim.diagnostic.get(0, { namespace = ns })
      cur[#cur + 1] = {
        lnum = a - 1, end_lnum = b - 1, col = 0,  -- file is 1-idx, diags 0-idx
        severity = sev_of[tc], message = msg, source = "review",
        user_data = { review = line },
      }
      vim.diagnostic.set(ns, 0, cur)
      vim.notify(("review += %s:%s-%s [%s]"):format(path, a, b, tc))
    end)
  end
end

-- ── resolve (normal mode) ──────────────────────────────────────────────────
local function resolve()
  local line0 = vim.fn.line(".") - 1
  local here = vim.diagnostic.get(0, { namespace = ns, lnum = line0 })
  if #here == 0 then
    vim.notify("review: nothing under cursor", vim.log.levels.WARN)
    return
  end
  local key = here[1].user_data and here[1].user_data.review
  if key then
    if not remove_line(key) then
      vim.notify("review: entry not found in file (removed from overlay only)",
        vim.log.levels.WARN)
    end
  end
  -- drop it from the live overlay
  local all, kept = vim.diagnostic.get(0, { namespace = ns }), {}
  for _, d in ipairs(all) do
    if not (d.user_data and d.user_data.review == key) then kept[#kept + 1] = d end
  end
  vim.diagnostic.set(ns, 0, kept)
  vim.notify("review: resolved")
end

-- ── load whole file into the overlay ───────────────────────────────────────
function M.load()
  vim.diagnostic.reset(ns)
  local groups = {}
  for _, raw in ipairs(read_lines()) do
    if raw:match("%S") then
      local path, a, b, tc, msg = parse_line(raw)
      if path then
        local bufnr = vim.fn.bufadd(path)   -- handle only; signs show on open
        groups[bufnr] = groups[bufnr] or {}
        table.insert(groups[bufnr], {
          lnum = a - 1, end_lnum = b - 1, col = 0,
          severity = sev_of[tc], message = msg, source = "review",
          user_data = { review = raw },
        })
      else
        vim.notify("review: unparsed line: " .. raw, vim.log.levels.WARN)
      end
    end
  end
  for bufnr, ds in pairs(groups) do
    vim.diagnostic.set(ns, bufnr, ds)
  end
end

local function toggle()
  M._shown = not M._shown
  vim.diagnostic.enable(M._shown, { ns_id = ns })
  vim.notify(M._shown and "review: shown" or "review: hidden")
end

-- ── setup ──────────────────────────────────────────────────────────────────
function M.setup(opts)
  M.opts = opts or {}
  if M._setup_done then return M end
  M._setup_done = true

  -- Drop this line if you already manage signcolumn yourself.
  vim.opt.signcolumn = "yes"

  vim.diagnostic.config({
    severity_sort = true,
    virtual_text = { prefix = "▶" },  -- set to false for gutter-only
    signs = {
      text = {
        [S.ERROR] = "▶", [S.WARN] = "▶", [S.INFO] = "▶", [S.HINT] = "▶",
      },
    },
  }, ns)

  local km = vim.keymap.set
  km("x", "<leader>rn", add("N"), { desc = "review: note" })
  km("x", "<leader>rw", add("W"), { desc = "review: warn" })
  km("x", "<leader>re", add("E"), { desc = "review: error" })
  km("n", "<leader>rt", toggle,   { desc = "review: toggle overlay" })
  km("n", "<leader>rr", resolve,  { desc = "review: resolve under cursor" })

  vim.api.nvim_create_user_command("ReviewLoad", function() M.load() end, {})
  vim.api.nvim_create_user_command("ReviewQf", function()
    vim.diagnostic.setqflist({ namespace = ns })
  end, {})

  -- Pull in any existing notes for this project on startup.
  M.load()
  return M
end

return M
