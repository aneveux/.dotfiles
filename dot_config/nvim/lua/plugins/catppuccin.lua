return {

  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,

  opts = {
    flavour = "mocha",
    integrations = {
      which_key = true,
      neotree = true,
      fidget = true,
      hop = true,
      mason = true,
      indent_blankline = {
        enabled = true,
        scope_color = "",
        colored_indent_levels = false,
      },
    },
  },

  config = function()
    vim.cmd.colorscheme("catppuccin")
  end,
}
