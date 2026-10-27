return {
  -- No tabs/buffer bar in the workflow. Drops <leader>bp/bP/br/bl/bj; <S-h>/<S-l> and [b/]b are core maps.
  { "akinsho/bufferline.nvim", enabled = false },

  -- Never used the start screen.
  { "folke/snacks.nvim", opts = { dashboard = { enabled = false } } },
}
