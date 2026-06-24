local M = {}

function M.open()
  local path = vim.fn.stdpath("config") .. "/cheatsheet.md"
  if vim.fn.filereadable(path) == 0 then
    vim.notify("cheatsheet.md not found: " .. path, vim.log.levels.WARN)
    return
  end
  local lines = vim.fn.readfile(path)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false

  local width = math.min(100, vim.o.columns - 8)
  local height = math.min(#lines + 2, vim.o.lines - 6)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Cheatsheet  (/ to search, q to close) ",
    title_pos = "center",
  })
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
  vim.keymap.set("n", "<esc>", "<cmd>close<cr>", { buffer = buf, nowait = true })
end

return M
