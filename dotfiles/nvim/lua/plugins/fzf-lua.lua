return {
  -- remove Telescope in favor of fzf-lua
  { "nvim-telescope/telescope.nvim", enabled = false },
  { "nvim-telescope/telescope-fzf-native.nvim", enabled = false },

  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local fzf = require("fzf-lua")
      local theme_opts = {
        "--highlight-line",
        "--info=inline-right",
        "--ansi",
        "--layout=reverse",
        "--border=none",
        "--color=fg:#908caa,bg:#191724,hl:#ebbcba",
        "--color=fg+:#e0def4,bg+:#26233a,hl+:#ebbcba",
        "--color=border:#403d52,header:#31748f,gutter:#191724",
        "--color=spinner:#f6c177,info:#9ccfd8",
        "--color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa",
      }

      local env_opts = table.concat(theme_opts, " ")
      vim.env.FZF_DEFAULT_OPTS = vim.trim((vim.env.FZF_DEFAULT_OPTS or "") .. " " .. env_opts)

      fzf.setup({
        winopts = {
          width = 0.85,
          height = 0.85,
        },
        files = {
          -- include hidden and ignored files so .txt never gets filtered out
          rg_opts = "--hidden --follow --no-ignore --color=never --files",
        },
        fzf_opts = {
          ["--highlight-line"] = "",
          ["--info"] = "inline-right",
          ["--ansi"] = "",
          ["--layout"] = "reverse",
          ["--border"] = "none",
          ["--color"] = {
            "fg:#908caa",
            "bg:#191724",
            "hl:#ebbcba",
            "fg+:#e0def4",
            "bg+:#26233a",
            "hl+:#ebbcba",
            "border:#403d52",
            "header:#31748f",
            "gutter:#191724",
            "spinner:#f6c177",
            "info:#9ccfd8",
            "pointer:#c4a7e7",
            "marker:#eb6f92",
            "prompt:#908caa",
          },
        },
      })

      local map = vim.keymap.set
      map("n", "<leader>ff", fzf.files, { desc = "Find files (fzf)" })
      map("n", "<leader>fg", fzf.live_grep, { desc = "Live grep (fzf)" })
      map("n", "<leader>fb", fzf.buffers, { desc = "Buffers (fzf)" })
      map("n", "<leader>fh", fzf.help_tags, { desc = "Help tags (fzf)" })
      map("n", "<leader>fr", fzf.oldfiles, { desc = "Recent files (fzf)" })
      map("n", "<leader>fw", fzf.grep_cword, { desc = "Grep word under cursor (fzf)" })
      map("n", "<leader>fs", fzf.live_grep, { desc = "Search in project (fzf)" })
      map("n", "<leader>/", fzf.live_grep, { desc = "Search in project (fzf)" })
    end,
  },
}
