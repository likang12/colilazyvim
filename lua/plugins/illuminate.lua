-- default configuration
return {
  "RRethy/vim-illuminate",
  event = "LazyFile", -- 在打开文件时延迟加载，优化启动速度
  opts = {
    -- 在这里填入你想要修改的配置
    delay = 999999999999,
    large_file_cutoff = 2000,
    filetypes_denylist = {
      "dirbuf",
      "dirvish",
      "fugitive",
      "NvimTree",
      "TelescopePrompt",
    },
  },
  config = function(_, opts)
    require("illuminate").configure(opts)
  end,
}
