-- remote_dev.lua — rsync-on-save to a remote host.
--
-- Not required from pack/init.lua on purpose: the remote is per-project, so
-- call setup from a project's .nvim.lua (needs vim.o.exrc + :trust):
--
--   require("pack.remote_dev").setup({
--     remote = { host = "carson@devbox", path = "/srv/www/myproject" },
--     -- root = "/abs/project/root",   -- defaults to cwd at setup() time
--     -- ignore = { "^%.git/", ... },  -- lua patterns vs project-relative path
--     -- exclude = { ".git", ... },    -- rsync globs, used by :RemoteSyncAll
--   })
--
-- Runtime kill switch: :RemoteSyncToggle (or :lua vim.g.remote_sync = false)
-- Full sync: :RemoteSyncAll   (:RemoteSyncAll! also deletes remote extras)
-- Dirty sync: :RemoteSyncModified — push every file git status reports as
--   changed/added/untracked, and delete removed ones on the remote.
-- Diff view: :RemoteSyncDiff [subdir]  — list files that differ / exist on
--   only one side (! compares by checksum, slower). <CR> on a line diffsplits
--   local vs remote, q closes the list.

local M = {}

local ns = vim.api.nvim_create_namespace("remote_dev")

-- Deliberately not -a (-rlptgoD): the p/g/o bits mirror local perms, group,
-- and owner onto the remote, which a web docroot we don't fully own rejects
-- (chgrp: Operation not permitted). -O skips setting mtimes on dirs for the
-- same reason. Content still transfers; the remote keeps its own ownership.
local rsync_flags = "-rltzO"

local defaults = {
  -- Local project root that maps onto remote.path. nil = cwd when setup runs.
  root = nil,
  remote = {
    host = nil,
    path = "/srv/www/myproject",
  },
  -- Lua patterns matched against the project-relative path; matches don't push.
  ignore = {
    "^%.git/",
    "^node_modules/",
    "^vendor/",
    "^storage/",
    "%.sw[po]$",
	"%.env$"
  },
  -- rsync --exclude globs for the full sync (rsync speaks globs, not patterns).
  exclude = { ".git", "node_modules", "vendor", "storage", ".env" },
}

M.opts = defaults

--- Project-relative path, or nil if abs is outside the project.
local function relative(abs)
  local root = M.opts.root
  if abs:sub(1, #root + 1) ~= root .. "/" then
    return nil
  end
  return abs:sub(#root + 2)
end

local function ignored(rel)
  for _, pat in ipairs(M.opts.ignore) do
    if rel:match(pat) then
      return true
    end
  end
  return false
end

function M.push(abs)
  local rel = relative(abs)
  if not rel or ignored(rel) then
    return
  end

  -- The `/./` marker plus -R tells rsync to recreate only the path after the
  -- dot on the remote, so missing parent dirs get created for free.
  local src = ("%s/./%s"):format(M.opts.root, rel)
  local dest = ("%s:%s/"):format(M.opts.remote.host, M.opts.remote.path)

  vim.system({ "rsync", rsync_flags .. "R", src, dest }, { text = true }, function(out)
    -- on_exit runs in a fast event context; defer anything touching the UI.
    vim.schedule(function()
      if out.code ~= 0 then
        vim.notify(
          ("rsync failed (%d): %s"):format(out.code, (out.stderr or ""):gsub("%s+$", "")),
          vim.log.levels.ERROR
        )
      end
    end)
  end)
end

function M.sync_all(delete)
  local args = { "rsync", rsync_flags, "--info=stats1" }
  if delete then
    table.insert(args, "--delete")
  end
  for _, pat in ipairs(M.opts.exclude) do
    table.insert(args, "--exclude=" .. pat)
  end
  vim.list_extend(args, {
    M.opts.root .. "/",
    ("%s:%s/"):format(M.opts.remote.host, M.opts.remote.path),
  })

  vim.notify("syncing project...")
  vim.system(args, { text = true }, function(out)
    vim.schedule(function()
      local ok = out.code == 0
      vim.notify(
        ok and (out.stdout or "sync complete") or ("sync failed: " .. (out.stderr or "")),
        ok and vim.log.levels.INFO or vim.log.levels.ERROR
      )
    end)
  end)
end

--- Sync only what git status reports: modified/added/untracked files are
--- pushed, deleted ones are removed on the remote. Assumes M.opts.root is the
--- repo root (porcelain paths are repo-root-relative).
function M.sync_modified()
  vim.system(
    -- -z: NUL-separated, no quoting. --no-renames: a rename becomes D + A so
    -- every record is a single path. -uall: list files inside untracked dirs.
    { "git", "-C", M.opts.root, "status", "--porcelain", "-z", "--no-renames", "-uall" },
    { text = true },
    function(out)
      vim.schedule(function()
        if out.code ~= 0 then
          vim.notify("git status failed: " .. (out.stderr or ""), vim.log.levels.ERROR)
          return
        end

        local files = {}
        for _, entry in ipairs(vim.split(out.stdout or "", "\0", { trimempty = true })) do
          local rel = entry:sub(4) -- strip the two status chars + space
          if rel ~= "" and not ignored(rel) then
            files[#files + 1] = rel
          end
        end
        if #files == 0 then
          vim.notify("git status clean, nothing to sync")
          return
        end

        -- --delete-missing-args turns list entries that no longer exist
        -- locally (git D) into deletion requests on the remote.
        local args = { "rsync", rsync_flags, "--files-from=-", "--from0", "--delete-missing-args", "--info=stats1" }
        for _, pat in ipairs(M.opts.exclude) do
          table.insert(args, "--exclude=" .. pat)
        end
        vim.list_extend(args, {
          M.opts.root .. "/",
          ("%s:%s/"):format(M.opts.remote.host, M.opts.remote.path),
        })

        vim.notify(("syncing %d modified file(s)..."):format(#files))
        vim.system(
          args,
          { text = true, stdin = table.concat(files, "\0") .. "\0" },
          function(rout)
            vim.schedule(function()
              local ok = rout.code == 0
              vim.notify(
                ok and (rout.stdout or "sync complete") or ("sync failed: " .. (rout.stderr or "")),
                ok and vim.log.levels.INFO or vim.log.levels.ERROR
              )
            end)
          end
        )
      end)
    end
  )
end

-- ── remote diff ────────────────────────────────────────────────────────────

--- Cat a project-relative file off the remote. cb(out) runs on the main loop.
local function fetch_remote(rel, cb)
  local rpath = ("%s/%s"):format(M.opts.remote.path, rel)
  vim.system(
    { "ssh", M.opts.remote.host, "cat -- " .. vim.fn.shellescape(rpath) },
    { text = true },
    function(out)
      vim.schedule(function()
        cb(out)
      end)
    end
  )
end

local function open_entry(entry)
  -- Nothing on the remote to compare against; just open it.
  if entry.status == "local_only" then
    vim.cmd.tabedit(M.opts.root .. "/" .. entry.path)
    return
  end

  fetch_remote(entry.path, function(out)
    if out.code ~= 0 then
      vim.notify(
        ("fetch failed: %s"):format((out.stderr or ""):gsub("%s+$", "")),
        vim.log.levels.ERROR
      )
      return
    end
    local rlines = vim.split(out.stdout or "", "\n")
    if rlines[#rlines] == "" then
      table.remove(rlines)
    end

    local diffing = entry.status == "changed"
    local ft
    if diffing then
      vim.cmd.tabedit(M.opts.root .. "/" .. entry.path)
      ft = vim.bo.filetype
      vim.cmd.diffthis()
      vim.cmd.vnew()
    else -- remote_only: view it, nothing local to diff against
      vim.cmd.tabnew()
      ft = vim.filetype.match({ filename = entry.path }) or ""
    end

    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, rlines)
    vim.api.nvim_buf_set_name(buf, ("rsync://%s/%s"):format(M.opts.remote.host, entry.path))
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = ft
    if diffing then
      vim.cmd.diffthis()
    end
  end)
end

--- rsync -i lines -> { { path, status = changed|local_only|remote_only } }
-- ">f+++++++++" = file missing on remote, ">f..." = file differs,
-- "*deleting" = exists only on remote (courtesy of --delete on a dry run).
local function parse_itemized(stdout, prefix)
  local entries = {}
  for _, line in ipairs(vim.split(stdout or "", "\n", { trimempty = true })) do
    local flags, path = line:match("^(%S+)%s+(.*)$")
    if flags and path and path ~= "" then
      if flags == "*deleting" and not path:match("/$") then
        entries[#entries + 1] = { status = "remote_only", path = prefix .. path }
      elseif flags:sub(1, 2) == ">f" then
        entries[#entries + 1] = {
          status = flags:sub(3, 3) == "+" and "local_only" or "changed",
          path = prefix .. path,
        }
      end
    end
  end
  return entries
end

local function render(entries)
  local dev_ok, devicons = pcall(require, "nvim-web-devicons")

  local sections = {
    { status = "changed", label = "Differs" },
    { status = "local_only", label = "Only local" },
    { status = "remote_only", label = "Only remote" },
  }

  local lines, meta, hls = {}, {}, {} -- meta[lnum] = entry
  for _, sec in ipairs(sections) do
    local bucket = vim.tbl_filter(function(e)
      return e.status == sec.status
    end, entries)
    if #bucket > 0 then
      table.sort(bucket, function(a, b)
        return a.path < b.path
      end)
      if #lines > 0 then
        lines[#lines + 1] = ""
      end
      lines[#lines + 1] = sec.label
      hls[#hls + 1] = { #lines - 1, 0, #sec.label, "Title" }
      for _, e in ipairs(bucket) do
        local icon, icon_hl = " ", nil
        if dev_ok then
          icon, icon_hl = devicons.get_icon(e.path, e.path:match("%.([^.]+)$"), { default = true })
        end
        lines[#lines + 1] = ("  %s %s"):format(icon, e.path)
        meta[#lines] = e
        if icon_hl then
          hls[#hls + 1] = { #lines - 1, 2, 2 + #icon, icon_hl }
        end
      end
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_set_extmark(buf, ns, h[1], h[2], { end_col = h[3], hl_group = h[4] })
  end

  local width = 40
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l) + 2)
  end
  width = math.min(width, vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - 6)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2) - 1,
    style = "minimal",
    border = "rounded",
    title = (" remote diff — %s "):format(M.opts.remote.host),
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set("n", "q", close, { buffer = buf })
  vim.keymap.set("n", "<CR>", function()
    local e = meta[vim.fn.line(".")]
    if e then
      close()
      open_entry(e)
    end
  end, { buffer = buf })
end

--- Dry-run rsync against the remote and show what's out of sync.
--- @param subdir string|nil  limit the comparison to this project-relative dir
--- @param checksum boolean   compare contents, not size+mtime (slower)
function M.diff(subdir, checksum)
  local args = { "rsync", rsync_flags .. (checksum and "nc" or "n"), "--delete", "--itemize-changes" }
  for _, pat in ipairs(M.opts.exclude) do
    table.insert(args, "--exclude=" .. pat)
  end

  local prefix = ""
  local src = M.opts.root .. "/"
  local dest = ("%s:%s/"):format(M.opts.remote.host, M.opts.remote.path)
  if subdir and subdir ~= "" then
    subdir = subdir:gsub("/+$", "")
    prefix = subdir .. "/"
    src = ("%s/%s/"):format(M.opts.root, subdir)
    dest = ("%s:%s/%s/"):format(M.opts.remote.host, M.opts.remote.path, subdir)
  end
  vim.list_extend(args, { src, dest })

  vim.notify("diffing against " .. dest .. " ...")
  vim.system(args, { text = true }, function(out)
    vim.schedule(function()
      if out.code ~= 0 then
        vim.notify(
          ("rsync failed (%d): %s"):format(out.code, (out.stderr or ""):gsub("%s+$", "")),
          vim.log.levels.ERROR
        )
        return
      end
      local entries = parse_itemized(out.stdout, prefix)
      if #entries == 0 then
        vim.notify("remote is in sync")
        return
      end
      render(entries)
    end)
  end)
end

-- ── setup ──────────────────────────────────────────────────────────────────
function M.setup(opts)
  opts = opts or {}
  M.opts = {
    -- :p adds a trailing slash to dirs; strip it so relative() math holds.
    root = vim.fn.fnamemodify(opts.root or vim.fn.getcwd(), ":p"):gsub("/+$", ""),
    remote = vim.tbl_extend("force", defaults.remote, opts.remote or {}),
    ignore = opts.ignore or defaults.ignore,
    exclude = opts.exclude or defaults.exclude,
  }

  -- Runtime kill switch: :lua vim.g.remote_sync = false
  if vim.g.remote_sync == nil then
    vim.g.remote_sync = true
  end

  local group = vim.api.nvim_create_augroup("remote_sync", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    -- A pattern containing a slash is matched against the full path, so this
    -- autocmd is inert for buffers outside the project.
    pattern = M.opts.root .. "/*",
    callback = function(args)
      if not vim.g.remote_sync then
        return
      end
      -- Second guard: args.file can be a symlink or relative in odd cases.
      M.push(vim.fn.fnamemodify(args.file, ":p"))
    end,
  })

  vim.api.nvim_create_user_command("RemoteSyncToggle", function()
    vim.g.remote_sync = not vim.g.remote_sync
    vim.notify("remote sync " .. (vim.g.remote_sync and "on" or "off"))
  end, { desc = "Toggle rsync-on-save for this project" })

  vim.api.nvim_create_user_command("RemoteSyncAll", function(cmd)
    M.sync_all(cmd.bang)
  end, { bang = true, desc = "Full project rsync (! also deletes remote extras)" })

  vim.api.nvim_create_user_command("RemoteSyncModified", function()
    M.sync_modified()
  end, { desc = "Rsync files git status reports as dirty (deletes removed ones remotely)" })

  vim.api.nvim_create_user_command("RemoteSyncDiff", function(cmd)
    M.diff(cmd.args ~= "" and cmd.args or nil, cmd.bang)
  end, {
    nargs = "?",
    bang = true,
    complete = "dir",
    desc = "List files out of sync with the remote (! = checksum compare)",
  })

  return M
end

return M
