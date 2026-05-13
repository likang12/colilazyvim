local AGENT = "codex"
local pending_visual_ref = nil

local cli_layout = "half"

local CLI_WINDOWS = {
  half = {
    layout = "vertical",
    full_height = true,
    position = "right",
    width = 0.5,
    opts = {
      list = false,
      wrap = true,
    },
  },
  full = {
    layout = "tab",
    opts = {
      list = false,
      wrap = true,
    },
  },
}

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
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if not before[bufnr]
      and vim.api.nvim_buf_is_valid(bufnr)
      and vim.api.nvim_buf_get_name(bufnr) == ""
      and vim.bo[bufnr].buftype == ""
      and vim.api.nvim_buf_line_count(bufnr) == 1
      and vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == ""
    then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end
end

local function open_cli_window(instance)
  local before = snapshot_buffers()
  instance.ui:open()
  cleanup_new_empty_buffers(before)
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

  if cli_layout == "full" then
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

  local cli = require("codecompanion.interactions.cli")
  local instance = cli.get_visible() or cli.last_cli()

  if instance then
    if not instance.ui:is_visible() then
      open_cli_window(instance)
    end
    instance:focus()
    return
  end

  instance = cli.create({ agent = AGENT })
  if instance then
    open_cli_window(instance)
    instance:focus()
  end
end

local function toggle_cli_layout()
  local cli = require("codecompanion.interactions.cli")
  local instance = cli.get_visible() or cli.last_cli()
  local was_visible = instance and instance.ui:is_visible()

  if was_visible then
    hide_cli(instance)
    cli_layout = cli_layout == "half" and "full" or "half"
    set_cli_window(cli_layout)
    open_cli_window(instance)
    instance:focus()
    return
  end

  open_cli(cli_layout)
end

local function toggle_cli_visibility()
  local cli = require("codecompanion.interactions.cli")
  local instance = cli.get_visible() or cli.last_cli()

  if instance and instance.ui:is_visible() then
    hide_cli(instance)
    return
  end

  open_cli(cli_layout)
end

local function visual_reference()
  local _, sl = unpack(vim.fn.getpos("'<"))
  local _, el = unpack(vim.fn.getpos("'>"))
  local path = vim.fn.expand("%:.")
  if sl == el then
    return string.format("@%s (line %d)", path, sl)
  end
  return string.format("@%s (lines %d-%d)", path, sl, el)
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
        agents = {
          claude = {
            cmd = "claude",
            args = {},
            description = "Claude CLI",
          },
          codex = {
            cmd = "codex",
            args = {},
            description = "Codex CLI",
          },
          agent = {
            cmd = "agent",
            args = {},
            description = "agent CLI",
          },
        },
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
        open_cli(cli_layout)
      end,
      mode = { "n", "t" },
      desc = "Open CLI",
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
        local cli = require("codecompanion.interactions.cli")
        close_cli(cli.get_visible())
        close_cli(cli.last_cli())
        set_cli_window(cli_layout)
        local instance = cli.create({ agent = AGENT })
        if instance then
          open_cli_window(instance)
          instance:focus()
        end
      end,
      desc = "New CodeCompanion session",
    },
    {
      "<leader>ae",
      function()
        local mode = vim.fn.mode()
        local is_visual = mode == "v" or mode == "V" or mode == "\22"
        if is_visual then
          local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
          vim.api.nvim_feedkeys(esc, "nx", false)
          vim.schedule(function()
            pending_visual_ref = visual_reference()
            require("codecompanion").cli("", { agent = AGENT, prompt = true, submit = false, focus = true })
          end)
          return
        end
        pending_visual_ref = nil
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
          local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
          vim.api.nvim_feedkeys(esc, "nx", false)
          vim.schedule(function()
            local ref = visual_reference()
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
        open_cli(cli_layout)
      end,
      mode = { "n", "t" },
      desc = "Focus CLI",
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
      desc = "Add file to CLI",
    },
    {
      "<leader>ap",
      function()
        local dirs = {}
        for _, dir in ipairs({
          vim.fn.expand("~/.cursor/plans"),
          vim.fn.getcwd() .. "/.cursor/plans",
          vim.fn.expand("~/.claude/plans"),
        }) do
          if vim.fn.isdirectory(dir) == 1 then
            table.insert(dirs, dir)
          end
        end
        if #dirs == 0 then
          vim.notify("No plan directories found", vim.log.levels.WARN)
          return
        end
        Snacks.picker.files({ dirs = dirs, filter = { search = "*.md" } })
      end,
      desc = "Open plan files",
    },
    {
      "<leader>ad",
      function()
        require("codecompanion").cli("#{diagnostics} Please fix these issues.", {
          agent = AGENT,
          focus = false,
          submit = true,
        })
      end,
      mode = { "n" },
      desc = "Send diagnostics to Agent CLI",
    },
    {
      "<C-M-l>",
      function()
        local cli = require("codecompanion.interactions.cli")
        local instance = cli.get_visible() or cli.last_cli()
        local mode = vim.fn.mode()
        local is_visual = mode == "v" or mode == "V" or mode == "\22"

        if instance and instance.ui:is_visible() then
          if instance.ui:is_active() then
            hide_cli(instance)
            return
          end
          if is_visual then
            local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
            vim.api.nvim_feedkeys(esc, "nx", false)
            vim.schedule(function()
              local ref = visual_reference()
              require("codecompanion").cli(ref, {
                submit = false, focus = true,
              })
            end)
            return
          end
          instance:focus()
          return
        end

        if is_visual then
          local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
          vim.api.nvim_feedkeys(esc, "nx", false)
          vim.schedule(function()
            local ref = visual_reference()
            require("codecompanion").cli(ref, {
              submit = false, focus = true,
            })
          end)
          return
        end

        open_cli(cli_layout)
      end,
      mode = { "n", "v", "t" },
      desc = "Smart toggle CLI (Ctrl+Alt+L)",
    },
  },
  config = function(_, opts)
    require("codecompanion").setup(opts)

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
        -- vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", {
        --   buffer = bufnr, nowait = true, desc = "Window down",
        -- })
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

    -- Input buffer: append visual reference on send, override plugin's keymaps
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "codecompanion_input",
      callback = function(args)
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(args.buf) then
            return
          end
          local function send_with_ref()
            local ref = pending_visual_ref
            pending_visual_ref = nil
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
        { "<leader>a", group = "codecompanion", icon = "✨" },
      },
    },
  },
}
