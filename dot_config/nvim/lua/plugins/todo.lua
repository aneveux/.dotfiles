return {
  "folke/todo-comments.nvim",
  keys = {
    {
      "<leader>st",
      function()
        require("telescope").extensions["todo-comments"].todo({
          cwd = require("lazyvim.util").root(),
        })
      end,
      desc = "Todo",
    },
  },
}
