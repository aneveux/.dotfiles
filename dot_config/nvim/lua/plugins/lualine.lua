return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },

  -- See `:help lualine.txt`
  opts = {
    options = {
      icons_enabled = true,
      theme = "catppuccin",
      component_separators = "|",
      section_separators = "",
    },
  },
}
