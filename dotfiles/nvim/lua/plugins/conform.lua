return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.format_on_save = opts.format_on_save
      or function()
        return { timeout_ms = 2000, lsp_fallback = true }
      end

    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.markdown = { "prettier" }
    opts.formatters_by_ft.markdown_inline = { "prettier" }
    opts.formatters_by_ft.json = { "prettier" }
    opts.formatters_by_ft.jsonc = { "prettier" }
    opts.formatters_by_ft.yaml = { "prettier" }
    opts.formatters_by_ft.yml = { "prettier" }
    return opts
  end,
}
