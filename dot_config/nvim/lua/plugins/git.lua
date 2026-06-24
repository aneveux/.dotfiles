return {
  -- Inline current-line blame replaces the removed git-blame.nvim.
  {
    "lewis6991/gitsigns.nvim",
    opts = { current_line_blame = true },
  },

  -- Branch/range diffs, file history, merge-conflict resolution — the core
  -- of in-editor review. octo (PR review) comes from the util.octo extra.
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    keys = {
      { "<leader>gdo", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
      { "<leader>gdc", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
      { "<leader>gdh", "<cmd>DiffviewFileHistory<cr>", desc = "Branch File History" },
      { "<leader>gdf", "<cmd>DiffviewFileHistory %<cr>", desc = "Current File History" },
      {
        "<leader>gdm",
        -- Resolve the remote default branch (main vs master) instead of hardcoding.
        function()
          local head = vim.fn.systemlist("git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null")[1]
          local base = (head and head ~= "") and head or "origin/HEAD"
          vim.cmd("DiffviewOpen " .. base .. "...HEAD")
        end,
        desc = "Diff vs default branch",
      },
    },
    opts = {},
  },
}
