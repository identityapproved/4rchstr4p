return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = lint.linters_by_ft or {}
    lint.linters_by_ft.markdown = { "markdownlint_cli2" }

    lint.linters.markdownlint_cli2 = {
      cmd = "markdownlint-cli2",
      args = { "--no-globs", ":" .. "$FILENAME" },
      stdin = false,
      stream = "stdout",
      ignore_exitcode = true,
      parser = function(output, bufnr)
        local diagnostics = {}
        local filename = vim.api.nvim_buf_get_name(bufnr)
        for line in vim.gsplit(output or "", "\n", { plain = true, trimempty = true }) do
          -- Typical format: path:line:col MD### message
          local file, lnum, col, code, message = line:match("^(.+):(%d+):(%d+)%s+(MD%d+)%s+(.*)$")
          if file and lnum and col then
            table.insert(diagnostics, {
              lnum = tonumber(lnum) - 1,
              col = tonumber(col) - 1,
              end_lnum = tonumber(lnum) - 1,
              end_col = tonumber(col),
              source = "markdownlint-cli2",
              message = (code and (code .. " ") or "") .. (message or ""),
              severity = vim.diagnostic.severity.WARN,
            })
          elseif filename ~= "" and line:find(filename, 1, true) then
            -- ignore non-diagnostic banner/status lines
          end
        end
        return diagnostics
      end,
    }

    local group = vim.api.nvim_create_augroup("custom_lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
      group = group,
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
