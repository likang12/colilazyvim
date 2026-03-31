-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

-- buffer 切换
vim.keymap.set("n", "<A-h>", "<cmd>bprev<cr>", { desc = "Prev Buffer" })
vim.keymap.set("n", "<A-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

-- Esc 保持原生行为：不清除搜索高亮
vim.keymap.set({ "i", "n", "s" }, "<Esc>", function()
  LazyVim.cmp.actions.snippet_stop()
  return "<Esc>"
end, { expr = true, desc = "Escape" })

-- 恢复 H 键的原生功能：移动到当前屏幕显示的第一行（顶部）
vim.keymap.set({ "n", "v" }, "H", "H", { desc = "Move to top of screen" })

-- 恢复 L 键的原生功能：移动到当前屏幕显示的最后一行（底部）
vim.keymap.set({ "n", "v" }, "L", "L", { desc = "Move to bottom of screen" })

-- 清理行尾多余空白（空格和 tab）
vim.keymap.set("n", "<leader>tw", function()
  local view = vim.fn.winsaveview()
  vim.cmd([[%s/[ \t]\+$//e]])
  vim.fn.winrestview(view)
end, { desc = "Trim trailing whitespace" })

vim.keymap.set("x", "<leader>tw", [[:s/[ \t]\+$//e<CR>]], { desc = "Trim trailing whitespace (selection)" })

-- 将默认 clang-format 模板复制到当前工作目录
vim.keymap.set("n", "<leader>tt", function()
  local src = vim.fn.stdpath("config") .. "/format/clang-format.default"
  local dst = vim.fn.getcwd() .. "/.clang-format"

  if vim.fn.filereadable(src) == 0 then
    vim.notify("Template not found: " .. src, vim.log.levels.ERROR)
    return
  end

  local ok, err = pcall(function()
    local content = vim.fn.readfile(src, "b")
    vim.fn.writefile(content, dst, "b")
  end)

  if not ok then
    vim.notify("Copy failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  vim.notify("Generated: " .. dst, vim.log.levels.INFO)
end, { desc = "Generate .clang-format from default template" })
