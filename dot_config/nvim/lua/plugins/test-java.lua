return {
  {
    "nvim-neotest/neotest",
    dependencies = { "rcasia/neotest-java" },
    opts = { adapters = { ["neotest-java"] = {} } },
  },
  -- The java extra's jdtls test maps (<leader>tt/tr/tT) are buffer-local and would shadow
  -- test.core in Java buffers. Debugging is unaffected: the debug bundle is gated on opts.dap.
  { "mfussenegger/nvim-jdtls", opts = { test = false } },
}
