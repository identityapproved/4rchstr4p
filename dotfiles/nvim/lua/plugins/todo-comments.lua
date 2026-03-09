return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    -- keep defaults; rely on fzf-lua for picker
    search = {
      command = "rg",
    },
  },
  config = function(_, opts)
    local todo = require("todo-comments")
    todo.setup(opts)

    local map = vim.keymap.set
    map("n", "]t", todo.jump_next, { desc = "Next todo comment" })
    map("n", "[t", todo.jump_prev, { desc = "Previous todo comment" })
    map("n", "<leader>ft", "<cmd>TodoFzfLua<cr>", { desc = "Find todos (fzf)" })
  end,
}
