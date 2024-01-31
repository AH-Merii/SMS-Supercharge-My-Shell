local M = {
	"sourcegraph/sg.nvim",
  event = "InsertEnter",
	dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
}

function M.config()
  require("sg").setup {
    enable_cody = true,
  }
end

return M
