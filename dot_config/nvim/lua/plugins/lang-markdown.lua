-- markdownlint-cli2 floods prose with MD013/line-length on every read. nvim-lint pipes
-- the buffer over stdin, which makes markdownlint-cli2 ignore .markdownlint* config files
-- entirely, so there is no way to disable single rules per project. Drop the linter.
return {
  { "mfussenegger/nvim-lint", opts = { linters_by_ft = { markdown = {} } } },
}
