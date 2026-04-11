return {
  {
    "folke/flash.nvim",
    keys = function(_, keys)
      keys = vim.tbl_filter(function(key)
        return not vim.tbl_contains({ "s", "S", "r", "R" }, key[1])
      end, keys)

      vim.list_extend(keys, {
        {
          "<leader>jj",
          mode = { "n", "x", "o" },
          function()
            require("flash").jump()
          end,
          desc = "flash jump",
        },
        {
          "<leader>jt",
          mode = { "n", "x", "o" },
          function()
            require("flash").treesitter()
          end,
          desc = "flash treesitter",
        },
        {
          "<leader>jr",
          mode = "o",
          function()
            require("flash").remote()
          end,
          desc = "flash remote",
        },
        {
          "<leader>js",
          mode = { "x", "o" },
          function()
            require("flash").treesitter_search()
          end,
          desc = "flash treesitter search",
        },
      })

      return keys
    end,
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>j", group = "flash", icon = "" },
      },
    },
  },
}
