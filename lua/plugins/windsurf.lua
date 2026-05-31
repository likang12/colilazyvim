-- Keymaps (Insert mode unless noted):
--   <M-;>   accept current suggestion
--   <M-]>   next suggestion
--   <M-[>   previous suggestion
--   <M-\>   toggle Codeium on/off  (Normal + Insert)
return {
  {
    "Exafunction/windsurf.nvim",
    event = "InsertEnter",
    opts = {
      enable_cmp_source = false,
      virtual_text = {
        enabled = true,
        manual = false,
        idle_delay = 50,
        map_keys = true,
        default_filetype_enabled = true,
        key_bindings = {
          accept = "<M-;>",
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
    },
    config = function(_, opts)
      require("codeium").setup(opts)

      -- Fix: lazy-loading on InsertEnter misses VimEnter, so set_style()
      -- (which defines the gray CodeiumSuggestion highlight group) never runs.
      -- The virtual text then falls back to Normal highlight, making
      -- suggestions visually indistinguishable from real code.
      require("codeium.virtual_text").set_style()

      -- Restrict suggestions to real file buffers (buftype == "").
      -- Excludes plugin buffers: Telescope/snacks/fzf (prompt|nofile),
      -- CodeCompanion chat & input (acwrite), terminals, help, quickfix, etc.
      local vt = require("codeium.virtual_text")
      if not vt._buftype_patched then
        local original = vt.filetype_enabled
        vt.filetype_enabled = function(bufnr)
          if vim.bo[bufnr].buftype ~= "" then
            return false
          end
          return original(bufnr)
        end
        vt._buftype_patched = true
      end
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
    dependencies = { "Exafunction/windsurf.nvim" },
    opts = function(_, opts)
      opts.completion = opts.completion or {}
      opts.completion.list = vim.tbl_deep_extend("force", opts.completion.list or {}, {
        selection = { preselect = false },
      })
      -- Disable blink's ghost text so it doesn't collide with codeium virtual text.
      opts.completion.ghost_text = vim.tbl_deep_extend("force", opts.completion.ghost_text or {}, {
        enabled = false,
      })
    end,
  },
}
