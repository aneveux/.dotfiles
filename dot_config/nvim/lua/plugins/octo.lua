return {
  {
    "pwntester/octo.nvim",
    keys = {
      { "<leader>ol", "<cmd>Octo pr list<cr>", desc = "PR list" },
      { "<leader>oo", "<cmd>Octo pr checkout<cr>", desc = "PR checkout" },
      { "<leader>on", "<cmd>Octo pr create<cr>", desc = "PR create (new)" },
      { "<leader>or", "<cmd>Octo review start<cr>", desc = "Review start" },
      { "<leader>os", "<cmd>Octo review submit<cr>", desc = "Review submit" },
      { "<leader>oR", "<cmd>Octo review resume<cr>", desc = "Review resume" },
      { "<leader>oc", "<cmd>Octo comment add<cr>", desc = "Comment add" },
      { "<leader>oa", "<cmd>Octo actions<cr>", desc = "Actions (all)" },
    },
  },
}
