return {
  "nvim-neo-tree/neo-tree.nvim",
  keys = {
    -- Override LazyVim's <leader>e (which is a toggle remap-alias to <leader>fe).
    -- focus = show + switch focus, never closes; reveal = highlight current file on open.
    {
      "<leader>e",
      function()
        require("neo-tree.command").execute({
          action = "focus",
          reveal = true,
          dir = LazyVim.root(),
        })
      end,
      desc = "Explorer NeoTree (focus + reveal, root dir)",
    },
  },
  opts = {
    filesystem = {
      -- Req #1: stop neo-tree from auto-opening when editing a directory (vi .).
      hijack_netrw_behavior = "disabled",
    },
  },
}
