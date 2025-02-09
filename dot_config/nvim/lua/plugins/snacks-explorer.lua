return {
  {
    "folke/snacks.nvim",
    opts = { explorer = {} },
    keys = {
      {
        "<leader>e",
        function()
          Snacks.picker.get({ source = "explorer" })[1].input.win:focus()
        end,
        desc = "Focus Snacks Explorer",
      },
    },
  },
}
