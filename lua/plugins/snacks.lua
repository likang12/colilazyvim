return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    -- 默认 max=0.4 会压窄通知，长路径（Ctrl+G、:pwd 等）易被截断；放宽宽度并允许换行以显示全文
    opts.notifier = vim.tbl_deep_extend("force", opts.notifier or {}, {
      timeout = 5000, -- 默认 3000ms + 2s
      width = { min = 40, max = 0.94 },
      height = { min = 1, max = 0.65 },
    })
    opts.styles = vim.tbl_deep_extend("force", opts.styles or {}, {
      notification = {
        wo = {
          wrap = true,
        },
      },
    })
    return opts
  end,
}
