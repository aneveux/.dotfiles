-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- LazyVim only runs checktime on FocusGained/TermClose/TermLeave, so files edited by
-- agents in another tmux pane stay stale while nvim keeps focus.
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = vim.api.nvim_create_augroup("checktime_on_hold", { clear = true }),
  callback = function(args)
    if vim.bo[args.buf].buftype ~= "" or vim.fn.getcmdwintype() ~= "" then
      return
    end
    vim.cmd.checktime(args.buf)
  end,
})
