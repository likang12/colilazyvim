local AGENT = "claude"
local pending_visual_ref = nil

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
    -- display = {
    --   cli = {
    --     window = {
    --       width = 1 / 3,
    --     },
    --   },
    -- },
  },
  keys = {
    {
      "<leader>at",
      function()
        require("codecompanion").toggle_cli()
      end,
      desc = "Toggle Agent CLI",
    },
    {
      "<leader>aa",
      function()
        local cli = require("codecompanion.interactions.cli")
        local instance = cli.last_cli()
        if instance then
          if not instance.ui:is_visible() then
            instance.ui:open()
          end
          instance:focus()
          return
        end
        require("codecompanion").cli({})
      end,
      desc = "Open CLI",
    },
    {
      "<leader>an",
      function()
        local cli = require("codecompanion.interactions.cli")
        local existing = cli.get_visible() or cli.last_cli()
        if existing then
          existing:close()
        end
        local instance = cli.create({ agent = AGENT })
        if instance then
          instance.ui:open()
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
        local cli = require("codecompanion.interactions.cli")
        local instance = cli.get_visible() or cli.last_cli()
        if instance then
          if not instance.ui:is_visible() then
            instance.ui:open()
          end
          instance:focus()
          return
        end
        require("codecompanion").cli({})
      end,
      desc = "Focus CLI",
    },
    {
      "<leader>ab",
      function()
        local cli = require("codecompanion.interactions.cli")
        local instance = cli.get_visible() or cli.last_cli()
        if not instance then
          instance = cli.create()
        end
        if instance then
          if not instance.ui:is_visible() then
            instance.ui:open()
          end
          require("codecompanion").cli("#{buffer}", { submit = false, focus = true})
        end
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
            require("codecompanion").toggle_cli()
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

        require("codecompanion").toggle_cli()
        vim.schedule(function()
          local inst = cli.get_visible() or cli.last_cli()
          if inst then
            inst:focus()
          end
        end)
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
