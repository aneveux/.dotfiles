return {
  -- No tabs/buffer bar in the workflow. Drops <leader>b*, <S-h>/<S-l>, [b/]b.
  { "akinsho/bufferline.nvim", enabled = false },

  -- Never used the start screen.
  { "folke/snacks.nvim", opts = { dashboard = { enabled = false } } },
}
