local uv = vim.uv or vim.loop
local unpack = table.unpack or unpack ---@diagnostic disable-line: deprecated

local LAYOUT = { HALF = "half", FULL = "full" }

local AGENT_SPECS = {
  claude = { cmd = "claude",       args = {}, description = "Claude CLI" },
  cursor = { cmd = "cursor-agent", args = {}, description = "Cursor CLI" },
  codex  = { cmd = "codex",        args = {}, description = "Codex CLI"  },
  agent  = { cmd = "agent",        args = {}, description = "agent CLI"  },
}
local AGENT_PICKER_CHOICES = { "claude", "cursor", "codex" }

local CLI_WIN_OPTS = {
  list = false,
  wrap = true,
  number = false,
  relativenumber = false,
  signcolumn = "no",
}

local CLI_WINDOWS = {
  [LAYOUT.HALF] = {
    layout = "vertical",
    full_height = true,
    position = "right",
    width = 0.5,
    opts = CLI_WIN_OPTS,
  },
  [LAYOUT.FULL] = {
    layout = "tab",
    opts = CLI_WIN_OPTS,
  },
}

local AGENT = "claude"

-- Queue rather than single slot: concurrent <leader>ae presses each get their
-- own ref before the corresponding input buffer fires.
local pending_visual_refs = {}

-- Mirror of upstream's private `clis` table — populated by our
-- CodeCompanionCLI{Created,Closed} autocmds in `config`. Insertion order =
-- cycling order for <leader>an / <leader>ap.
local cli_sessions = {}

-- Upstream's `cli.last_cli()` is set only on create, never on focus, so after
-- cycling back to A and hiding it, last_cli still points to whichever was
-- created last. Maintained via BufEnter so the MRU pointer reflects the user's
-- actual focus history.
local last_used_cli = nil

local function find_session(predicate)
  for i, sess in ipairs(cli_sessions) do
    if predicate(sess, i) then
      return sess, i
    end
  end
end

local function track_session(instance)
  if not instance or find_session(function(s) return s == instance end) then
    return
  end
  table.insert(cli_sessions, instance)
end

local function untrack_session_by_bufnr(bufnr)
  local _, idx = find_session(function(s) return s.bufnr == bufnr end)
  if idx then
    table.remove(cli_sessions, idx)
  end
end

local function prune_dead_sessions()
  for i = #cli_sessions, 1, -1 do
    local inst = cli_sessions[i]
    if not inst or not inst.bufnr or not vim.api.nvim_buf_is_valid(inst.bufnr) then
      table.remove(cli_sessions, i)
    end
  end
end

-- Preference order: visible → our MRU → upstream's create-time pointer →
-- list tail. The list-tail fallback matters because upstream nils last_cli
-- when its instance is closed, so after <leader>ax hidden sessions can
-- otherwise become unreachable.
local function pick_cli_instance()
  prune_dead_sessions()
  local cli = require("codecompanion.interactions.cli")
  local visible = cli.get_visible()
  if visible then
    return visible
  end
  if last_used_cli and last_used_cli.bufnr and vim.api.nvim_buf_is_valid(last_used_cli.bufnr) then
    return last_used_cli
  end
  last_used_cli = nil
  return cli.last_cli() or cli_sessions[#cli_sessions]
end

local function is_in_cli_buffer()
  return vim.bo.filetype == "codecompanion_cli"
end

-- Deferred so it runs after ui:open()'s focus-stealing side effects.
local function restore_focus_to(winnr)
  vim.schedule(function()
    if winnr and vim.api.nvim_win_is_valid(winnr) then
      pcall(vim.api.nvim_set_current_win, winnr)
      pcall(vim.cmd.stopinsert)
    end
  end)
end

-- Apply the focus rule: in-CC takes the new target's focus; out-of-CC stays.
local function apply_focus_rule(target, was_in_cli, saved_win)
  if was_in_cli then
    if target then target:focus() end
  else
    restore_focus_to(saved_win)
  end
end

-- Test hatch — read-only access to module locals from tests/.
_G.__codecompanion_test_internals = {
  cli_sessions = cli_sessions,
  prune_dead_sessions = prune_dead_sessions,
  get_last_used_cli = function() return last_used_cli end,
}

-- vim.ui.select is async; bail re-entrant <leader>aa presses.
local am_picker_open = false

local cli_layout = LAYOUT.HALF

local function set_cli_window(layout)
  local config = require("codecompanion.config")
  config.display.cli = config.display.cli or {}
  config.display.cli.window = vim.deepcopy(CLI_WINDOWS[layout])
end

local function snapshot_buffers()
  local buffers = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    buffers[bufnr] = true
  end
  return buffers
end

local function cleanup_new_empty_buffers(before)
  local displayed = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      displayed[vim.api.nvim_win_get_buf(win)] = true
    end
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if not before[bufnr]
      and vim.api.nvim_buf_is_valid(bufnr)
      and not displayed[bufnr]
      and vim.api.nvim_buf_get_name(bufnr) == ""
      and vim.bo[bufnr].buftype == ""
      and vim.api.nvim_buf_line_count(bufnr) == 1
      and vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == ""
    then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end
end

local function defer_cleanup_buffers(before)
  vim.defer_fn(function()
    cleanup_new_empty_buffers(before)
  end, 100)
end

-- POSIX SIGWINCH (Linux/macOS/BSD = 28); resize-wiggle fallback covers others.
local SIGWINCH = 28

local last_dims_by_chan = {}

local function send_sigwinch_to_chan(chan)
  local ok_pid, pid = pcall(vim.fn.jobpid, chan)
  if not ok_pid or type(pid) ~= "number" or pid <= 0 then
    return false
  end
  local ok, ret = pcall(uv.kill, pid, SIGWINCH)
  return ok and ret == 0
end

local function scroll_to_live_region(winnr, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local last_line = vim.api.nvim_buf_line_count(bufnr)
  if last_line > 0 then
    pcall(vim.api.nvim_win_set_cursor, winnr, { last_line, 0 })
  end
end

-- Debounced final repaint after the user stops toggling — fires on the
-- *current* window, not a captured (possibly stale) winnr.
local FOLLOWUP_MS = 80
local pending_followups = {}

local function cancel_followup(chan)
  local timer = pending_followups[chan]
  if not timer then
    return
  end
  pending_followups[chan] = nil
  pcall(function()
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end)
end

local function schedule_followup(chan, instance, bufnr)
  cancel_followup(chan)
  local timer = uv.new_timer()
  if not timer then
    return
  end
  pending_followups[chan] = timer
  timer:start(FOLLOWUP_MS, 0, vim.schedule_wrap(function()
    if pending_followups[chan] == timer then
      pending_followups[chan] = nil
    end
    pcall(function()
      if not timer:is_closing() then
        timer:stop()
        timer:close()
      end
    end)

    -- Re-derive winnr: captured one may be recycled during a hide/show storm.
    if not instance or not instance.ui or not instance.ui:is_visible() then
      return
    end
    local cur_winnr = instance.ui.winnr
    if not cur_winnr or not vim.api.nvim_win_is_valid(cur_winnr) then
      return
    end
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    if vim.api.nvim_win_get_buf(cur_winnr) ~= bufnr then
      return
    end

    send_sigwinch_to_chan(chan)
    scroll_to_live_region(cur_winnr, bufnr)
    pcall(vim.cmd, "redraw!")
  end))
end

local function refresh_cli_terminal(instance)
  local winnr = instance and instance.ui and instance.ui.winnr
  if not winnr or not vim.api.nvim_win_is_valid(winnr) then
    return
  end
  local bufnr = instance.bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local chan = instance.provider and instance.provider.chan
  if not chan then
    return
  end

  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(winnr) then
      return
    end
    -- Bail if winnr was recycled onto a different buffer.
    if vim.api.nvim_win_get_buf(winnr) ~= bufnr then
      return
    end

    local w = vim.api.nvim_win_get_width(winnr)
    local h = vim.api.nvim_win_get_height(winnr)
    if w <= 1 or h <= 0 then
      return
    end

    local prev = last_dims_by_chan[chan]
    last_dims_by_chan[chan] = { w = w, h = h }

    -- Only force SIGWINCH on no-op resizes; vim's own resize already triggers
    -- one otherwise and an extra nudge yields a wrong-size intermediate frame.
    if prev and prev.w == w and prev.h == h then
      if not send_sigwinch_to_chan(chan) then
        pcall(vim.fn.jobresize, chan, w - 1, h)
        pcall(vim.fn.jobresize, chan, w, h)
      end
    end

    scroll_to_live_region(winnr, bufnr)
  end)

  schedule_followup(chan, instance, bufnr)
end

local function open_cli_window(instance, opts)
  opts = opts or {}
  local before = opts.before or snapshot_buffers()
  instance.ui:open()
  cleanup_new_empty_buffers(before)
  defer_cleanup_buffers(before)
  refresh_cli_terminal(instance)
end

local function switch_away_from_cli_buffer(bufnr)
  if vim.api.nvim_get_current_buf() ~= bufnr then
    return
  end

  local alt = vim.fn.bufnr("#")
  if alt > 0 and alt ~= bufnr and vim.api.nvim_buf_is_valid(alt) and vim.api.nvim_buf_is_loaded(alt) then
    if pcall(vim.api.nvim_set_current_buf, alt) then
      return
    end
  end

  for _, candidate in ipairs(vim.api.nvim_list_bufs()) do
    if candidate ~= bufnr and vim.api.nvim_buf_is_loaded(candidate) then
      local buftype = vim.bo[candidate].buftype
      if buftype == "" then
        if pcall(vim.api.nvim_set_current_buf, candidate) then
          return
        end
      end
    end
  end

  vim.cmd("enew")
end

local function close_cli_tab(instance)
  local winnr = instance and instance.ui.winnr
  if not winnr or not vim.api.nvim_win_is_valid(winnr) then
    return
  end

  local tab = vim.api.nvim_win_get_tabpage(winnr)
  local tab_wins = vim.api.nvim_tabpage_list_wins(tab)
  if #tab_wins == 1 and #vim.api.nvim_list_tabpages() > 1 then
    local tabnr
    for i, candidate in ipairs(vim.api.nvim_list_tabpages()) do
      if candidate == tab then
        tabnr = i
        break
      end
    end
    for _, candidate in ipairs(vim.api.nvim_list_tabpages()) do
      if candidate ~= tab then
        local target_win = vim.api.nvim_tabpage_get_win(candidate)
        pcall(vim.api.nvim_set_current_win, target_win)
        break
      end
    end
    if tabnr then
      pcall(vim.cmd, tabnr .. "tabclose")
    end
    return
  end

  pcall(vim.api.nvim_win_hide, winnr)
end

local function hide_cli(instance)
  if not instance or not instance.ui:is_visible() then
    return
  end

  pcall(vim.cmd.stopinsert)

  if cli_layout == LAYOUT.FULL then
    close_cli_tab(instance)
    return
  end

  local ok = pcall(function()
    instance.ui:hide()
  end)
  if ok then
    return
  end

  if instance.ui.winnr and vim.api.nvim_win_is_valid(instance.ui.winnr) then
    pcall(vim.api.nvim_win_hide, instance.ui.winnr)
  end
end

local function close_cli(instance)
  if not instance then
    return
  end

  -- Read chan BEFORE instance:close() nils it; libuv reuses chan IDs and a
  -- stale follow-up could otherwise fire against the wrong process.
  local chan = instance.provider and instance.provider.chan
  if chan then
    cancel_followup(chan)
    last_dims_by_chan[chan] = nil
  end

  hide_cli(instance)
  if vim.api.nvim_buf_is_valid(instance.bufnr) then
    pcall(function()
      instance:close()
    end)
  end
end

local function open_cli(layout)
  cli_layout = layout or cli_layout
  set_cli_window(cli_layout)

  local instance = pick_cli_instance()
  if instance then
    if not instance.ui:is_visible() then
      open_cli_window(instance)
    end
    instance:focus()
    return
  end

  local cli = require("codecompanion.interactions.cli")
  instance = cli.create({ agent = AGENT })
  if instance then
    open_cli_window(instance)
    instance:focus()
  end
end

local function toggle_cli_layout()
  local instance = pick_cli_instance()
  local was_visible = instance and instance.ui:is_visible()

  if was_visible then
    local before = snapshot_buffers()
    hide_cli(instance)
    cli_layout = cli_layout == LAYOUT.HALF and LAYOUT.FULL or LAYOUT.HALF
    set_cli_window(cli_layout)
    open_cli_window(instance, { before = before })
    instance:focus()
    return
  end

  open_cli(cli_layout)
end

local function toggle_cli_visibility()
  local instance = pick_cli_instance()

  if instance and instance.ui:is_visible() then
    hide_cli(instance)
    return
  end

  open_cli(cli_layout)
end

-- Show `target` in the current cli_layout, then apply the focus rule.
local function show_target(target, was_in_cli, saved_win)
  if target then
    set_cli_window(cli_layout)
    if not target.ui:is_visible() then
      open_cli_window(target)
    end
  end
  apply_focus_rule(target, was_in_cli, saved_win)
end

-- direction=1 next, -1 previous. With no visible session we fall back to the
-- first or last entry so the user can rejoin the cycle from a hidden state.
-- Focus rule: in-CC follows the target; out-of-CC stays in the original window.
local function cycle_cli_session(direction)
  -- Prune defensively: CLIClosed should untrack on its own, but stale entries
  -- here would crash show_target → target.ui:open(). Cheap, O(N).
  prune_dead_sessions()
  if #cli_sessions == 0 then
    vim.notify("No CodeCompanion CLI sessions", vim.log.levels.WARN)
    return
  end

  local was_in_cli = is_in_cli_buffer()
  local saved_win = vim.api.nvim_get_current_win()
  local current = require("codecompanion.interactions.cli").get_visible()

  if #cli_sessions == 1 then
    show_target(cli_sessions[1], was_in_cli, saved_win)
    return
  end

  local _, idx = find_session(function(s) return s == current end)
  local target_idx
  if not idx then
    target_idx = direction > 0 and 1 or #cli_sessions
  else
    target_idx = ((idx - 1 + direction) % #cli_sessions) + 1
  end
  local target = cli_sessions[target_idx]
  if not target or target == current then
    apply_focus_rule(current, was_in_cli, saved_win)
    return
  end

  if current and current.ui:is_visible() then
    hide_cli(current)
  end
  show_target(target, was_in_cli, saved_win)
end

-- Close current and auto-open the predecessor (cycling order) if any remain.
local function close_current_cli_session()
  local instance = pick_cli_instance()
  if not instance then
    vim.notify("No CodeCompanion CLI session to close", vim.log.levels.WARN)
    return
  end

  local was_in_cli = is_in_cli_buffer()
  local saved_win = vim.api.nvim_get_current_win()
  -- Capture old position; after table.remove, the original predecessor lives
  -- at old_idx-1, or at #cli_sessions when old_idx was 1 (wrap) or nil.
  local _, old_idx = find_session(function(s) return s == instance end)

  close_cli(instance)
  prune_dead_sessions()

  if #cli_sessions == 0 then
    if not was_in_cli then
      restore_focus_to(saved_win)
    end
    return
  end

  local target_idx = (not old_idx or old_idx <= 1) and #cli_sessions or old_idx - 1
  show_target(cli_sessions[target_idx], was_in_cli, saved_win)
end

-- Picker keymaps (<leader>af / <leader>ad / <leader>aB) all funnel here.
local function send_ref_to_cli(ref)
  if not ref or ref == "" then
    return
  end
  open_cli(cli_layout)
  require("codecompanion").cli(ref, {
    agent = AGENT,
    submit = false,
    focus = true,
  })
end

-- Snacks-picker items for cwd subdirs; prefer fd/fdfind, fall back to find.
local function list_directory_items()
  local cmd
  if vim.fn.executable("fd") == 1 then
    cmd = { "fd", "--type", "d", "--hidden", "--exclude", ".git", "--strip-cwd-prefix" }
  elseif vim.fn.executable("fdfind") == 1 then
    cmd = { "fdfind", "--type", "d", "--hidden", "--exclude", ".git", "--strip-cwd-prefix" }
  else
    cmd = { "find", ".", "-type", "d", "-not", "-path", "*/.git*", "-mindepth", "1" }
  end
  local out = vim.fn.systemlist(cmd)
  local items = {}
  for _, raw in ipairs(out) do
    local rel = raw:gsub("^%./", ""):gsub("/$", "")
    if rel ~= "" and rel ~= "." then
      table.insert(items, { text = rel, file = rel })
    end
  end
  return items
end

local function visual_reference()
  local _, sl = unpack(vim.fn.getpos("'<"))
  local _, el = unpack(vim.fn.getpos("'>"))
  local path = vim.fn.expand("%:.")
  if path == "" then
    -- Unnamed / terminal / [No Name] — no resolvable ref to send downstream.
    vim.notify("Visual selection has no resolvable file path", vim.log.levels.WARN)
    return nil
  end
  if sl == el then
    return string.format("@%s (line %d)", path, sl)
  end
  return string.format("@%s (lines %d-%d)", path, sl, el)
end

-- Feed <Esc> first: visual marks aren't valid until visual mode exits.
local function with_visual_ref(callback)
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "nx", false)
  vim.schedule(function()
    callback(visual_reference())
  end)
end

-- Snacks `confirm` factory: closes picker, normalizes, sends "@<rel><suffix>".
local function picker_send_path_to_cli(opts)
  opts = opts or {}
  return function(picker, item)
    picker:close()
    if not item then
      return
    end
    local path = item.file or item._path or item.text
    if not path or path == "" then
      if opts.warn_missing then
        vim.notify("Selected item has no file path", vim.log.levels.WARN)
      end
      return
    end
    local rel = vim.fn.fnamemodify(path, ":.")
    send_ref_to_cli("@" .. rel .. (opts.suffix or ""))
  end
end

return {
  {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    interactions = {
      cli = {
        agent = AGENT,
        agents = AGENT_SPECS,
        opts = {
          auto_insert = true,
        },
      },
      chat = {
        slash_commands = {
          file = {
            opts = {
              provider = "snacks",
            },
          },
          buffer = {
            opts = {
              provider = "snacks",
            },
          },
        },
      },
    },
    display = {
      cli = {
        window = CLI_WINDOWS[cli_layout],
      },
    },
  },
  keys = {
    {
      "<leader>at",
      function()
        toggle_cli_visibility()
      end,
      desc = "Toggle Agent CLI",
    },
    {
      "<leader>aa",
      function()
        local cli = require("codecompanion.interactions.cli")
        if am_picker_open then
          vim.notify("Agent picker is already open", vim.log.levels.INFO)
          return
        end
        -- Race guard: abort if another <leader>a* changed state while the
        -- picker was up.
        local snapshot_visible = cli.get_visible()
        local snapshot_last = cli.last_cli()
        am_picker_open = true
        vim.ui.select(AGENT_PICKER_CHOICES, {
          prompt = "Select CLI Agent:",
          format_item = function(item)
            return item == AGENT and ("* " .. item) or ("  " .. item)
          end,
        }, function(choice)
          am_picker_open = false
          if not choice then
            return
          end
          if cli.get_visible() ~= snapshot_visible or cli.last_cli() ~= snapshot_last then
            vim.notify("CLI state changed during agent picker — aborted", vim.log.levels.WARN)
            return
          end

          close_cli(cli.get_visible())
          close_cli(cli.last_cli())

          AGENT = choice
          set_cli_window(cli_layout)
          local instance = cli.create({ agent = choice })
          if instance then
            open_cli_window(instance)
            instance:focus()
          end
        end)
      end,
      desc = "Select CLI agent (Claude/Codex/Cursor)",
    },
    {
      "<C-M-k>",
      function()
        toggle_cli_layout()
      end,
      mode = { "n", "t" },
      desc = "Toggle CLI Half/Full Screen",
    },
    {
      "<leader>an",
      function()
        cycle_cli_session(1)
      end,
      desc = "Next CodeCompanion CLI session",
    },
    {
      "<leader>ap",
      function()
        cycle_cli_session(-1)
      end,
      desc = "Previous CodeCompanion CLI session",
    },
    {
      "<leader>aN",
      function()
        local cli = require("codecompanion.interactions.cli")
        local was_in_cli = is_in_cli_buffer()
        local saved_win = vim.api.nvim_get_current_win()
        -- Hide (not close) so <leader>ap can cycle back: aN means "add".
        local current = cli.get_visible()
        if current and current.ui:is_visible() then
          hide_cli(current)
        end
        show_target(cli.create({ agent = AGENT }), was_in_cli, saved_win)
      end,
      desc = "New CodeCompanion CLI session",
    },
    {
      "<leader>ax",
      function()
        close_current_cli_session()
      end,
      desc = "Close current CodeCompanion CLI session",
    },
    {
      "<leader>ae",
      function()
        local mode = vim.fn.mode()
        local is_visual = mode == "v" or mode == "V" or mode == "\22"
        if is_visual then
          with_visual_ref(function(ref)
            if not ref then
              return
            end
            -- Enqueue: a second press could clobber the first ref otherwise.
            table.insert(pending_visual_refs, ref)
            require("codecompanion").cli("", { agent = AGENT, prompt = true, submit = false, focus = true })
          end)
          return
        end
        require("codecompanion").cli({ agent = AGENT, prompt = true, submit = true })
      end,
      mode = { "n", "v" },
      desc = "Prompt Agent CLI (auto-submit)",
    },
    {
      "<leader>ac",
      function()
        local mode = vim.fn.mode()
        local is_visual = mode == "v" or mode == "V" or mode == "\22"
        local opts = { agent = AGENT, submit = false, focus = true }
        if is_visual then
          with_visual_ref(function(ref)
            if not ref then
              return
            end
            require("codecompanion").cli(ref, opts)
          end)
          return
        end
        require("codecompanion").cli("#{this}", opts)
      end,
      mode = { "n", "v" },
      desc = "Add context to Agent CLI",
    },
    {
      "<leader>af",
      function()
        Snacks.picker.files({ confirm = picker_send_path_to_cli() })
      end,
      mode = { "n" },
      desc = "Pick file -> CLI",
    },
    {
      "<leader>ab",
      function()
        local source = vim.api.nvim_buf_get_name(0)
        if source == "" then
          vim.notify("Current buffer has no file path", vim.log.levels.WARN)
          return
        end
        local target = vim.fn.fnamemodify(source, ":.")
        open_cli(cli_layout)
        require("codecompanion").cli("#{buffer:" .. target .. "}", { agent = AGENT, submit = false, focus = true })
      end,
      mode = { "n" },
      desc = "Add current buffer to CLI",
    },
    {
      "<leader>aB",
      function()
        Snacks.picker.buffers({ confirm = picker_send_path_to_cli({ warn_missing = true }) })
      end,
      mode = { "n" },
      desc = "Pick buffer -> CLI",
    },
    {
      "<leader>ad",
      function()
        local items = list_directory_items()
        if #items == 0 then
          vim.notify("No directories found", vim.log.levels.WARN)
          return
        end
        Snacks.picker.pick({
          items = items,
          format = "file",
          title = "Pick directory",
          confirm = picker_send_path_to_cli({ suffix = "/" }),
        })
      end,
      mode = { "n" },
      desc = "Pick directory -> CLI",
    },
    {
      "<leader>aD",
      function()
        -- Diagnostics disabled by default (see CLAUDE.md); skip the picker.
        if #vim.diagnostic.get() == 0 then
          vim.notify("No diagnostics to send", vim.log.levels.WARN)
          return
        end
        Snacks.picker.diagnostics({
          confirm = function(picker, _item)
            local picked = picker:selected({ fallback = true })
            picker:close()
            if not picked or #picked == 0 then
              return
            end
            local sev_names = vim.diagnostic.severity
            local lines = { "Please fix these diagnostics:" }
            for _, it in ipairs(picked) do
              local file = it.file and vim.fn.fnamemodify(it.file, ":.") or "?"
              local lnum = it.pos and it.pos[1] or ((it.lnum or 0) + 1)
              local sev = it.severity
              if type(sev) == "number" then
                sev = sev_names[sev] or tostring(sev)
              end
              local msg = (it.item and it.item.message) or it.comment or ""
              table.insert(lines, string.format("- %s:%d [%s] %s", file, lnum, sev or "?", msg))
            end
            open_cli(cli_layout)
            require("codecompanion").cli(table.concat(lines, "\n"), {
              agent = AGENT,
              submit = false,
              focus = true,
            })
          end,
        })
      end,
      mode = { "n" },
      desc = "Pick diagnostics -> CLI",
    },
    {
      "<C-M-l>",
      function()
        local instance = pick_cli_instance()
        local mode = vim.fn.mode()
        local is_visual = mode == "v" or mode == "V" or mode == "\22"

        local function send_visual_ref()
          local before = snapshot_buffers()
          with_visual_ref(function(ref)
            if ref then
              require("codecompanion").cli(ref, {
                agent = AGENT, submit = false, focus = true,
              })
            end
            defer_cleanup_buffers(before)
          end)
        end

        if instance and instance.ui:is_visible() then
          if instance.ui:is_active() then
            hide_cli(instance)
          elseif is_visual then
            send_visual_ref()
          else
            instance:focus()
          end
          return
        end

        if is_visual then
          send_visual_ref()
        else
          open_cli(cli_layout)
        end
      end,
      mode = { "n", "v", "t" },
      desc = "Smart toggle CLI (Ctrl+Alt+L)",
    },
  },
  config = function(_, opts)
    require("codecompanion").setup(opts)

    -- Mirror upstream's create/close events into cli_sessions + last_used_cli.
    -- Using events (not wrapping cli.create call sites) also catches upstream
    -- :CodeCompanionCLI invocations.
    vim.api.nvim_create_autocmd("User", {
      pattern = "CodeCompanionCLICreated",
      callback = function(args)
        local instance = require("codecompanion.interactions.cli").last_cli()
        if instance and instance.bufnr == (args.data and args.data.bufnr) then
          track_session(instance)
        end
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      pattern = "CodeCompanionCLIClosed",
      callback = function(args)
        local bufnr = args.data and args.data.bufnr
        if bufnr then
          untrack_session_by_bufnr(bufnr)
          if last_used_cli and last_used_cli.bufnr == bufnr then
            last_used_cli = nil
          end
        end
      end,
    })

    -- Update MRU on any focus into a CC buffer — covers our own open path,
    -- upstream :CodeCompanionCLI, and manual <C-w> window navigation.
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function(args)
        if not vim.api.nvim_buf_is_valid(args.buf)
          or vim.bo[args.buf].filetype ~= "codecompanion_cli"
        then
          return
        end
        local sess = find_session(function(s) return s.bufnr == args.buf end)
        if sess then
          last_used_cli = sess
        end
      end,
    })

    -- Terminal buffer keymaps for codecompanion CLI
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "codecompanion_cli",
      callback = function(args)
        local bufnr = args.buf

        -- Ctrl+Alt+N: exit insert → terminal-normal mode
        vim.keymap.set("t", "<C-M-n>", "<C-\\><C-n>", {
          buffer = bufnr, nowait = true, desc = "Exit terminal insert mode (Ctrl+Alt+N)",
        })

        -- Esc: in terminal-normal mode → switch focus away
        vim.keymap.set("n", "<Esc>", function()
          local wins = vim.api.nvim_list_wins()
          local cur = vim.api.nvim_get_current_win()
          for _, win in ipairs(wins) do
            if win ~= cur then
              vim.api.nvim_set_current_win(win)
              return
            end
          end
        end, { buffer = bufnr, nowait = true, desc = "Leave CodeCompanion CLI" })

        -- Ctrl+hjkl: window switching from terminal insert mode
        vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", {
          buffer = bufnr, nowait = true, desc = "Window left",
        })
        vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", {
          buffer = bufnr, nowait = true, desc = "Window up",
        })
        vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", {
          buffer = bufnr, nowait = true, desc = "Window right",
        })

        -- Ctrl+hjkl: window switching from terminal-normal mode
        vim.keymap.set("n", "<C-h>", "<C-w>h", {
          buffer = bufnr, nowait = true, desc = "Window left",
        })
        vim.keymap.set("n", "<C-j>", "<C-w>j", {
          buffer = bufnr, nowait = true, desc = "Window down",
        })
        vim.keymap.set("n", "<C-k>", "<C-w>k", {
          buffer = bufnr, nowait = true, desc = "Window up",
        })
        vim.keymap.set("n", "<C-l>", "<C-w>l", {
          buffer = bufnr, nowait = true, desc = "Window right",
        })
      end,
    })

    -- Input buffer claims one queued visual ref per instance.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "codecompanion_input",
      callback = function(args)
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(args.buf) then
            return
          end
          local claimed_ref = nil
          if #pending_visual_refs > 0 then
            claimed_ref = table.remove(pending_visual_refs, 1)
          end
          vim.b[args.buf].codecompanion_visual_ref = claimed_ref

          local function send_with_ref()
            local ref = vim.b[args.buf].codecompanion_visual_ref
            vim.b[args.buf].codecompanion_visual_ref = nil
            if ref then
              local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
              while #lines > 0 and lines[#lines]:match("^%s*$") do
                table.remove(lines)
              end
              table.insert(lines, "")
              table.insert(lines, ref)
              vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, lines)
            end
            vim.cmd("write!")
          end

          local map_opts = { buffer = args.buf, noremap = true, silent = true }
          vim.keymap.set("n", "<CR>", send_with_ref, map_opts)
          vim.keymap.set("n", "<C-s>", send_with_ref, map_opts)
          vim.keymap.set("i", "<C-s>", function()
            vim.cmd("stopinsert")
            send_with_ref()
          end, map_opts)
        end)
      end,
    })
  end,
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>a", group = "codecompanion", icon = "🪄" },
      },
    },
  },
}
