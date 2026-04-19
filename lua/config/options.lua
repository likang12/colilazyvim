-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.mapleader = ","
vim.g.ai_cmp = true

-- 基础设置
-- 显示设置
vim.opt.number = true -- 显示行号
vim.opt.relativenumber = false -- 显示相对行号
vim.opt.cursorline = true -- 高亮当前行
vim.opt.scrolloff = 2
-- 不与系统剪贴板同步无名寄存器；需要时再 `"+y` / `"+p`
vim.opt.clipboard = ""

-- 缩进设置
vim.opt.autoindent = true -- 自动缩进
vim.opt.smartindent = true -- 智能缩进
vim.opt.tabstop = 4 -- Tab宽度为4空格
vim.opt.shiftwidth = 4 -- 缩进宽度为4空格
vim.opt.softtabstop = 4 -- 按Tab键插入4空格
vim.opt.expandtab = true -- 使用空格代替Tab

-- 搜索设置
--- vim.opt.ignorecase = true -- 搜索时忽略大小写
--- vim.opt.smartcase = true -- 智能大小写搜索
--- vim.opt.hlsearch = true -- 高亮搜索结果

-- 鼠标设置（添加这一行）
--- vim.opt.mouse = "" -- 完全关闭鼠标功能
-- vim.opt.mouse = "n"         -- 如果只想在普通模式禁用鼠标，可以用这个

local opt = vim.opt

-- 基础 UI 设置
opt.relativenumber = false -- 开启相对行号 (对应 L)
opt.wrap = true -- 开启自动换行 (对应 w)
opt.spell = false -- 关闭拼写检查 (对应 s)

-- 全局变量控制 (LazyVim 专用)
vim.g.autoformat = false -- 禁用全局自动格式化 (对应 f)
vim.g.snacks_animate = false -- 禁用动画 (对应 a)

--- 关闭LSP检查
vim.diagnostic.enable(false)

--- 关闭永久撤销功能
vim.opt.undofile = false
