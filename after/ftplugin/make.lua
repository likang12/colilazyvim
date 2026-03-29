local function is_kernel_like_path(path)
  local normalized = (path or ""):gsub("\\", "/"):lower()
  return normalized:match("/linux[%w%._-]*/")
    or normalized:match("/kernel[%w%._-]*/")
    or normalized:match("/linux[%w%._-]*$")
    or normalized:match("/kernel[%w%._-]*$")
end

local path = vim.api.nvim_buf_get_name(0)
vim.opt_local.expandtab = false
vim.opt_local.tabstop = 4

if is_kernel_like_path(path) then
  -- In kernel-like trees, keep recipe tabs while using 2-space indent step.
  vim.opt_local.shiftwidth = 2
  vim.opt_local.softtabstop = 2
else
  vim.opt_local.shiftwidth = 4
  vim.opt_local.softtabstop = 4
end
