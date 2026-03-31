return {
  {
    "Exafunction/codeium.nvim",
    event = "InsertEnter",
    opts = {
      enable_cmp_source = false,
      virtual_text = {
        enabled = true,
        manual = false,
        idle_delay = 0,
        filetypes = {
          codecompanion = false,
        },
        default_filetype_enabled = true,
        map_keys = true,
        accept_fallback = nil,
        key_bindings = {
          accept = "<M-;>",
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
    },
    init = function()
      local group = vim.api.nvim_create_augroup("CodeiumOnInsertEnter", { clear = true })
      vim.api.nvim_create_autocmd("InsertEnter", {
        group = group,
        callback = function()
          if vim.bo.buftype ~= "" then
            return
          end
          vim.schedule(function()
            local ok, vt = pcall(require, "codeium.virtual_text")
            if ok and type(vt.debounced_complete) == "function" then
              vt.debounced_complete()
            end
          end)
        end,
      })
    end,
    keys = {
      {
        "<M-\\>",
        "<cmd>Codeium Toggle<cr>",
        mode = { "n", "i" },
        desc = "Codeium Toggle",
      },
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "Exafunction/codeium.nvim" },
    opts = function(_, opts)
      opts.completion = opts.completion or {}
      opts.completion.list = vim.tbl_deep_extend("force", opts.completion.list or {}, {
        selection = {
          preselect = false,
        },
      })
      opts.completion.ghost_text = vim.tbl_deep_extend("force", opts.completion.ghost_text or {}, {
        enabled = false,
      })

      --- opts.keymap = opts.keymap or {}
      --- opts.keymap["<C-n>"] = { "select_next", "fallback" }
      --- opts.keymap["<C-p>"] = { "select_prev", "fallback" }
    end,
  },
}
