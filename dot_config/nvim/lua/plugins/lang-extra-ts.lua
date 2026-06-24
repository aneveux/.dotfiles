return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      -- NOTE: no "hugo" parser exists — Hugo templates use the gotmpl parser.
      -- NOTE: no "asciidoc" parser in current nvim-treesitter — omitted to avoid
      -- a startup warning; asciidoc gets no treesitter highlighting for now.
      ensure_installed = {
        "bash", "xml", "html", "css", "javascript",
        "gotmpl", "properties",
      },
    },
  },
  -- Hugo Go-templates: map the template extensions to gotmpl so the parser
  -- engages. (No markdown-content override — Hugo content is plain markdown.)
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      vim.filetype.add({
        extension = { gohtml = "gotmpl", gotmpl = "gotmpl", tmpl = "gotmpl" },
      })
    end,
  },
}
