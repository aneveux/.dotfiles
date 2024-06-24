return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
    -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
  },
  opts = {
  },

  config = function()
    vim.keymap.set("n", "<C-e>", ":Neotree focus filesystem left reveal<CR>", { desc = "[E]xplore with neotree" })
    vim.keymap.set("n", "<leader>e", ":Neotree focus filesystem left reveal<CR>", { desc = "[E]xplore with neotree" })
    require('neo-tree').setup {
    filesystem = {
      follow_current_file = { enabled = true },
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    }
  end,
}
