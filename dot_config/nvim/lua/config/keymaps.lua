-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Position cursor at the middle of the screen after scrolling half page
vim.keymap.set("n", "<C-d>", "<C-d>zz") -- Scroll down half a page and center the cursor
vim.keymap.set("n", "<C-u>", "<C-u>zz") -- Scroll up half a page and center the cursor

-- delete single character without copying into register
vim.keymap.set("n", "x", '"_x')

-- Delete all buffers but the current one
vim.keymap.set(
  "n",
  "<leader>bq",
  '<Esc>:%bdelete|edit #|normal`"<Return>',
  { desc = "Delete other buffers but the current one" }
)
--
-- window management
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "[S]plit [V]ertically" }) -- split window vertically
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "[S]plit [H]orizontally" }) -- split window horizontally
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "[S]plit [E]qually" }) -- make split windows equal width & height
vim.keymap.set("n", "<leader>sx", ":close<CR>", { desc = "[S]plit [X]close" }) -- close current split window

vim.keymap.set("n", "<leader>to", ":tabnew<CR>", { desc = "[T]ab [O]pen" }) -- open new tab
vim.keymap.set("n", "<leader>tx", ":tabclose<CR>", { desc = "[T]ab [X]close" }) -- close current tab
vim.keymap.set("n", "<leader>tn", ":tabn<CR>", { desc = "[T]ab [N]ext" }) --  go to next tab
vim.keymap.set("n", "<leader>tp", ":tabp<CR>", { desc = "[T]ab [P]revious" }) --  go to previous tab

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
