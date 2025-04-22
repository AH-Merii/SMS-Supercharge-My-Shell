local M = { "echasnovski/mini.comment", version = "*", event = "VeryLazy" }

function M.config()
  require("mini.comment").setup({
    mappings = {
      -- Toggle comment (Normal and Visual modes)
      comment = "<C-_>",

      -- Toggle comment on current line
      comment_line = "<C-_>",

      -- Toggle comment on visual selection
      comment_visual = "<C-_>",

      -- Define 'comment' textobject
      textobject = "<C-_>",
    },
  })
end

return M
