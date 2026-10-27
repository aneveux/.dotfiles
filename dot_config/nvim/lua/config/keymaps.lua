-- ⚡ custom keymaps
-- ⚡ default: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua--

-- Position cursor at the middle of the screen after scrolling half page
vim.keymap.set("n", "<C-d>", "<C-d>zz") -- Scroll down half a page and center the cursor
vim.keymap.set("n", "<C-u>", "<C-u>zz") -- Scroll up half a page and center the cursor

-- delete single character without copying into register
vim.keymap.set("n", "x", '"_x')

-- Personal cheatsheet float (forgettable verbs: surround, textobjects, flash…)
vim.keymap.set("n", "<leader>mc", function()
  require("util.cheatsheet").open()
end, { desc = "Cheatsheet" })
