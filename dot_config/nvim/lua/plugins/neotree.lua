return {
  "nvim-neo-tree/neo-tree.nvim",
  keys = {
    { "<leader>e", ":Neotree focus filesystem left reveal<CR>", desc = "[E]xplore with neotree" },
    { "<C-e>", ":Neotree focus filesystem left reveal<CR>", desc = "[E]xplore with neotree" },
  },
  opts = {
    filesystem = {
      follow_current_file = { enabled = true },
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
  },
}
