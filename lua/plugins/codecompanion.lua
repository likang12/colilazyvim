local function set_codecompanion_input_behavior(auto_submit, return_win)
  vim.schedule(function()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "codecompanion_input" then
        vim.b[bufnr].codecompanion_prompt_auto_submit = auto_submit
        vim.b[bufnr].codecompanion_prompt_return_win = return_win
      end
    end
  end)
end

return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    opts = {
      log_level = "INFO",
    },
    interactions = {
      cli = {
        agent = "cursor",
        agents = {
          cursor = {
            cmd = "agent",
            args = {},
            description = "Cursor CLI",
          },
          opencode = {
            cmd = "opencode",
            args = {},
            description = "OpenCode CLI",
          },
        },
      },
    },
    -- Keep Esc for mode switch in prompt editor; close uses q.
    display = {
      chat = {
        window = {
          width = 1 / 3,
        },
      },
      cli = {
        window = {
          width = 1 / 3,
        },
      },
      input = {
        keymaps = {
          close = {
            modes = {
              n = { "<Esc>" },
            },
            description = "Close",
          },
        },
      },
    },
  },
  keys = {
    {
      "<leader>aa",
      function()
        local cli = require("codecompanion.interactions.cli")
        local instance = cli.find_by_agent("cursor")
        if instance then
          if not instance.ui:is_visible() then
            instance.ui:open()
          end
          instance:focus()
          return
        end
        require("codecompanion").cli({ agent = "cursor" })
      end,
      desc = "Open CodeCompanionCLI chat",
    },
    {
      "<leader>an",
      function()
        local cli = require("codecompanion.interactions.cli")
        local visible = cli.get_visible()
        if visible then
          visible.ui:hide()
        end

        local instance = cli.create({ agent = "cursor" })
        if instance then
          instance.ui:open()
          instance:focus()
        end
      end,
      desc = "New CodeCompanion session",
    },
    {
      "<leader>af",
      function()
        local cli = require("codecompanion.interactions.cli")
        local instance = cli.get_visible() or cli.find_by_agent("cursor")
        if instance then
          if not instance.ui:is_visible() then
            instance.ui:open()
          end
          instance:focus()
          return
        end
        require("codecompanion").cli({ agent = "cursor" })
      end,
      desc = "Focus Cursor agent input",
    },
    {
      "<leader>at",
      function()
        require("codecompanion").toggle_cli()
      end,
      desc = "Toggle CodeCompanionCLI chat",
    },
    {
      "<leader>ae",
      function()
        local opts = { agent = "cursor", prompt = true , submit = true }
        require("codecompanion").cli(opts)
        set_codecompanion_input_behavior(true, nil)
      end,
      mode = { "n", "v" },
      desc = "Open prompt popup for CodeCompanionCLI",
    },
    {
      "<leader>ac",
      function()
        local mode = vim.fn.mode()
        local is_visual = mode == "v" or mode == "V" or mode == "\22"
        local opts = {
          agent = "cursor",
          submit = false,
          prompt = false,
          focus = true,
        }
        if is_visual then
          opts.args = { range = 1 }
          local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
          vim.api.nvim_feedkeys(esc, "nx", false)
          vim.schedule(function()
            require("codecompanion").cli("#{this}", opts)
          end)
          return
        end
        require("codecompanion").cli("#{this}", opts)
      end,
      mode = { "n", "v" },
      desc = "Add context and focus CodeCompanionCLI",
    },
    {
      "<leader>al",
      function()
        local editor_win = vim.api.nvim_get_current_win()
        local opts = { agent = "cursor", prompt = true , submit = false, focus = false }
        require("codecompanion").cli(opts)
        set_codecompanion_input_behavior(false, editor_win)
      end,
      mode = { "n", "v" },
      desc = "Open prompt popup for CodeCompanionCLI",
    },
    {
      "<leader>ad",
      function()
        require("codecompanion").cli("#{diagnostics} Please fix these issues.", {
          agent = "cursor",
          focus = false,
          submit = true,
        })
      end,
      mode = { "n" },
      desc = "Send diagnostics to Cursor CLI",
    },
  },
  config = function(_, opts)
    require("codecompanion").setup(opts)

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "codecompanion_cli",
      callback = function(args)
        local map_opts = { buffer = args.buf, noremap = true, silent = true }

        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], map_opts)
        vim.keymap.set("t", "<C-w>p", [[<C-\><C-n><C-w>p]], map_opts)
        vim.keymap.set("t", "<C-w>h", [[<C-\><C-n><C-w>h]], map_opts)
        vim.keymap.set("t", "<C-w>j", [[<C-\><C-n><C-w>j]], map_opts)
        vim.keymap.set("t", "<C-w>k", [[<C-\><C-n><C-w>k]], map_opts)
        vim.keymap.set("t", "<C-w>l", [[<C-\><C-n><C-w>l]], map_opts)
        vim.keymap.set("t", "<C-w><Left>", [[<C-\><C-n><C-w>h]], map_opts)
        vim.keymap.set("t", "<C-w><Down>", [[<C-\><C-n><C-w>j]], map_opts)
        vim.keymap.set("t", "<C-w><Up>", [[<C-\><C-n><C-w>k]], map_opts)
        vim.keymap.set("t", "<C-w><Right>", [[<C-\><C-n><C-w>l]], map_opts)
        vim.keymap.set("t", "<C-r>", function()
          local job = vim.b.terminal_job_id
          if job then
            vim.api.nvim_chan_send(job, "\x12")
          end
        end, map_opts)

        vim.keymap.set("n", "<Esc>", "<C-w>p", map_opts)
        vim.keymap.set("n", "<C-w>p", "<C-w>p", map_opts)
        vim.keymap.set("n", "<C-w>h", "<C-w>h", map_opts)
        vim.keymap.set("n", "<C-w>j", "<C-w>j", map_opts)
        vim.keymap.set("n", "<C-w>k", "<C-w>k", map_opts)
        vim.keymap.set("n", "<C-w>l", "<C-w>l", map_opts)
        vim.keymap.set("n", "<C-w><Left>", "<C-w>h", map_opts)
        vim.keymap.set("n", "<C-w><Down>", "<C-w>j", map_opts)
        vim.keymap.set("n", "<C-w><Up>", "<C-w>k", map_opts)
        vim.keymap.set("n", "<C-w><Right>", "<C-w>l", map_opts)
        vim.keymap.set("n", "<C-r>", function()
          local job = vim.b.terminal_job_id
          if job then
            vim.api.nvim_chan_send(job, "\x12")
          end
        end, map_opts)
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "codecompanion_input",
      callback = function(args)
        local map_opts = { buffer = args.buf, noremap = true, silent = true }

        -- Defer so our mappings override plugin defaults set right after FileType.
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(args.buf) then
            return
          end

          local function submit_input()
            local auto_submit = vim.b[args.buf].codecompanion_prompt_auto_submit == true
            local return_win = vim.b[args.buf].codecompanion_prompt_return_win
            if auto_submit then
              vim.cmd("write!")
            else
              vim.cmd("write")
            end
            if not auto_submit and return_win and vim.api.nvim_win_is_valid(return_win) then
              -- CLI focus happens with a small defer in the plugin; run later to keep editor focus.
              vim.defer_fn(function()
                if vim.api.nvim_win_is_valid(return_win) then
                  vim.api.nvim_set_current_win(return_win)
                  vim.cmd("stopinsert")
                end
              end, 30)
            end
          end

          vim.keymap.set("i", "<Esc>", "<C-[>", map_opts)
          vim.keymap.set("n", "<CR>", submit_input, map_opts)
          vim.keymap.set("n", "<C-s>", submit_input, map_opts)
          vim.keymap.set("i", "<C-s>", function()
            vim.cmd("stopinsert")
            submit_input()
          end, map_opts)
        end)
      end,
    })
  end,
}
