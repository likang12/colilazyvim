local function is_kernel_like_path(path)
  local normalized = (path or ""):gsub("\\", "/"):lower()
  return normalized:match("/linux[%w%._-]*/")
    or normalized:match("/kernel[%w%._-]*/")
    or normalized:match("/linux[%w%._-]*$")
    or normalized:match("/kernel[%w%._-]*$")
end

local path = vim.api.nvim_buf_get_name(0)
if is_kernel_like_path(path) then
  -- Keep real tabs in kernel sources but render each tab as width 4.
  vim.opt_local.expandtab = false
  vim.opt_local.tabstop = 4
  vim.opt_local.shiftwidth = 4
  vim.opt_local.softtabstop = 4
else
  vim.opt_local.expandtab = true
  vim.opt_local.tabstop = 4
  vim.opt_local.shiftwidth = 4
  vim.opt_local.softtabstop = 4
end
