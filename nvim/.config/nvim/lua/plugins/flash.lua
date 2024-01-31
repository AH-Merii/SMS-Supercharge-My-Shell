local M = {
	"folke/flash.nvim",
	event = "VeryLazy",
	---@type Flash.Config
	opts = {},
}

function M.config()
	local wk = require("which-key")
  wk.register({
      s = { function() require("flash").jump() end, "Flash" },
      S = { function() require("flash").treesitter() end, "Flash Treesitter" },
  }, { mode = "n" })  -- Normal mode mappings

  wk.register({
      s = { function() require("flash").jump() end, "Flash" },
      S = { function() require("flash").treesitter() end, "Flash Treesitter" },
  }, { mode = "x" })  -- Visual block mode mappings

  wk.register({
      s = { function() require("flash").jump() end, "Flash" },
      S = { function() require("flash").treesitter() end, "Flash Treesitter" },
      r = { function() require("flash").remote() end, "Remote Flash" },
      R = { function() require("flash").treesitter_search() end, "Treesitter Search" },
  }, { mode = "o" })  -- Operator-pending mode mappings

  wk.register({
      ["<c-s>"] = { function() require("flash").toggle() end, "Toggle Flash Search" },
  }, { mode = "c" })  -- Command-line mode mappings

end

return M
