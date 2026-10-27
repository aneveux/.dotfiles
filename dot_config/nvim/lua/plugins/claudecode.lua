-- Claude Code runs in its own tmux pane and attaches with `/ide`; nvim only hosts the
-- WebSocket server (selection, diagnostics, diff accept/deny), so drop the terminal toggles.
return {
  "coder/claudecode.nvim",
  opts = { terminal = { provider = "none" } },
  keys = {
    { "<leader>ac", false },
    { "<leader>af", false },
    { "<leader>ar", false },
    { "<leader>aC", false },
  },
}
