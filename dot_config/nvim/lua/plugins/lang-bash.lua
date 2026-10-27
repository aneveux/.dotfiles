-- bashls runs shellcheck itself when it is on PATH; an nvim-lint shellcheck on top doubles every diagnostic.
return {
  { "neovim/nvim-lspconfig", opts = { servers = { bashls = {} } } },
  { "mason-org/mason.nvim", opts = { ensure_installed = { "shellcheck" } } },
  { "stevearc/conform.nvim", opts = { formatters_by_ft = { bash = { "shfmt" } } } },
}
