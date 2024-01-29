-- [[ Basic Keymaps ]]

local keymap = vim.keymap

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

keymap.set({ "n" }, "<leader>qq", "<cmd>wqa<CR>", { desc = "Save all and exit" })

-- delete single character without copying into register
keymap.set("n", "x", '"_x')

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "[S]plit [V]ertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "[S]plit [H]orizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "[S]plit [E]qually" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", ":close<CR>", { desc = "[S]plit [X]close" }) -- close current split window

keymap.set("n", "<leader>to", ":tabnew<CR>", { desc = "[T]ab [O]pen" }) -- open new tab
keymap.set("n", "<leader>tx", ":tabclose<CR>", { desc = "[T]ab [X]close" }) -- close current tab
keymap.set("n", "<leader>tn", ":tabn<CR>", { desc = "[T]ab [N]ext" }) --  go to next tab
keymap.set("n", "<leader>tp", ":tabp<CR>", { desc = "[T]ab [P]revious" }) --  go to previous tab

-- keymaps cheatsheet from Telescope
keymap.set("n", "<leader>kk", ":Telescope keymaps<CR>", { desc = "Telescope Keymaps" })

-- Remap for dealing with word wrap
keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })
