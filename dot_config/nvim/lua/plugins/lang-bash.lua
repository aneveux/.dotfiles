return {
  { "neovim/nvim-lspconfig", opts = { servers = { bashls = {} } } },
  { "mason-org/mason.nvim", opts = { ensure_installed = { "shfmt", "shellcheck" } } },
  { "stevearc/conform.nvim", opts = { formatters_by_ft = { sh = { "shfmt" }, bash = { "shfmt" } } } },
  { "mfussenegger/nvim-lint", opts = { linters_by_ft = { sh = { "shellcheck" }, bash = { "shellcheck" } } } },
}
