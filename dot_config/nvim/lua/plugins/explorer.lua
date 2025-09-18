return {
  {
    "folke/snacks.nvim",
    opts = { explorer = {
      hidden = true,
      ignored = true,
      exclude = { "node_modules", ".git" },
    } },
    keys = {
      {
        "<leader>e",
        function()
          local explorer = Snacks.picker.get({ source = "explorer" })[1]
          if explorer then
            explorer.input.win:focus()
            -- I don't want the explorer textbox to be focused
            vim.defer_fn(function()
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
            end, 50) -- Small delay to ensure it escapes properly
          else
            Snacks.explorer({ cwd = LazyVim.root() })
          end
        end,
        desc = "Focus Snacks Explorer",
      },
    },
  },
}
