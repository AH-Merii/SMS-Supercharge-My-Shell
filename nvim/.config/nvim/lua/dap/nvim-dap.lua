local M = {
  "mfussenegger/nvim-dap",
  recommended = true,
  desc = "Debugging support. Requires language-specific adapters to be configured. (see lang extras)",

  dependencies = {
    {
      "rcarriga/nvim-dap-ui",
      dependencies = { "nvim-neotest/nvim-nio" }
    },
    {
      "theHamsta/nvim-dap-virtual-text",
      opts = {},
    },
    "jay-babu/mason-nvim-dap.nvim",
    "mfussenegger/nvim-dap-python",
  },
}

--- Configures the nvim-dap plugin.
function M.config()
  -- auto install daps using mason
  require('mason-nvim-dap').setup({
    ensure_installed = { "python" }
  })
  require("dap-python").setup()

  local dap = require("dap")

  dap.adapters.python = {
    type = "executable",
    command = "python",
    args = { "-m", "debugpy.adapter" },
  }

  dap.configurations.python = {
    {
      type = "python",
      request = "launch",
      name = "Launch file",
      program = "${file}",
      console = "integratedTerminal",
      env = { PYDEVD_LOAD_VALUES_ASYNC = "1" }, -- Asynchronous loading for large objects
      justMyCode = false,
    },
  }

  require("dapui").setup()

  -- nvim-dap events to open and close the windows automatically
  local dapui = require("dapui")
  dap.listeners.before.attach.dapui_config = function()
    dapui.open()
  end
  dap.listeners.before.launch.dapui_config = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
  end
  dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
  end

  -- Highlight for the currently stopped line
  vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

  -- Configure dap signs using icons
  for name, sign in pairs(require("user.icons").dap) do
    sign = type(sign) == "table" and sign or { sign }
    vim.fn.sign_define(
      "Dap" .. name,
      { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
    )
  end
end

--- Keymaps for nvim-dap
M.keys = {
  { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Breakpoint Condition" },
  { "<leader>db", function() require("dap").toggle_breakpoint() end,                                    desc = "Toggle Breakpoint" },
  { "<leader>dc", function() require("dap").continue() end,                                             desc = "Run/Continue" },
  { "<leader>da", function() require("dap").continue({ before = get_args }) end,                        desc = "Run with Args" },
  { "<leader>dC", function() require("dap").run_to_cursor() end,                                        desc = "Run to Cursor" },
  { "<leader>dg", function() require("dap").goto_() end,                                                desc = "Go to Line (No Execute)" },
  { "<leader>di", function() require("dap").step_into() end,                                            desc = "Step Into" },
  { "<leader>dj", function() require("dap").down() end,                                                 desc = "Down" },
  { "<leader>dk", function() require("dap").up() end,                                                   desc = "Up" },
  { "<leader>dl", function() require("dap").run_last() end,                                             desc = "Run Last" },
  { "<leader>do", function() require("dap").step_out() end,                                             desc = "Step Out" },
  { "<leader>dO", function() require("dap").step_over() end,                                            desc = "Step Over" },
  { "<leader>dP", function() require("dap").pause() end,                                                desc = "Pause" },
  { "<leader>dr", function() require("dap").repl.toggle() end,                                          desc = "Toggle REPL" },
  { "<leader>ds", function() require("dap").session() end,                                              desc = "Session" },
  { "<leader>dt", function() require("dap").terminate() end,                                            desc = "Terminate" },
  { "<leader>dw", function() require("dap.ui.widgets").hover() end,                                     desc = "Widgets" },
}

return M
