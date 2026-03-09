-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Manual signature help (auto popups disabled in options)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("custom_signature_help", { clear = true }),
  callback = function(event)
    vim.keymap.set("n", "<leader>cs", vim.lsp.buf.signature_help, {
      buffer = event.buf,
      desc = "Signature help",
    })
  end,
})

-- Markdown: insert file link via fzf-lua
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("custom_markdown_links", { clear = true }),
  pattern = { "markdown", "markdown_inline" },
  callback = function(event)
    vim.keymap.set("n", "<leader>if", function()
      require("fzf-lua").files({
        file_icons = false,
        git_icons = false,
        actions = {
          ["default"] = function(selected)
            local entry = selected[1]
            if not entry or entry == "" then
              return
            end
            local path = tostring(entry)
            local absolute = vim.fn.fnamemodify(path, ":p")
            local relative = vim.fn.fnamemodify(absolute, ":.")
            local name = vim.fn.fnamemodify(absolute, ":t")
            vim.api.nvim_put({ string.format("[%s](%s)", name, relative) }, "c", true, true)
          end,
        },
      })
    end, { buffer = event.buf, desc = "Insert file link" })
  end,
})
