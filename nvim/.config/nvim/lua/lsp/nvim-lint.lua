local M = {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
}

function M.config()
  local lint = require('lint')

  --TODO: Autoinstall linters
  -- Define linters by filetype
  lint.linters_by_ft = {
    markdown   = { 'vale' },
    -- python     = { 'pylint' },
    terraform  = { 'tflint', 'tfsec' },
    dockerfile = { 'hadolint' },
    json       = { 'jsonlint' },
    bash       = { 'shellcheck' },
    text       = { "vale" },
    makefile   = { "checkmake" },
    javascript = { "eslint" },
    typescript = { "eslint" },
  }

  -- Function to get activated linters for the current buffer
  function M.get_activated_linters()
    local ft = vim.bo.filetype
    local activated_linters = lint.linters_by_ft[ft] or {}
    return activated_linters
  end

  local helpers = require('user.helpers')
  --- Toggles a specific linter on or off for the current file type.
  --- @param linter_name string: The name of the linter to toggle.
  function M.toggle_linter(linter_name)
    local ft = vim.bo.filetype

    if not lint.linters_by_ft[ft] then
      helpers.notify({ msg = "No linters configured for file type: " .. ft, level = vim.log.levels.WARN })
      return
    end

    -- Check if the linter is already active, toggle it off
    if vim.tbl_contains(lint.linters_by_ft[ft], linter_name) then
      helpers.remove_value(lint.linters_by_ft[ft], linter_name)
      helpers.notify({ msg = "Disabled linter: " .. linter_name .. " for file type: " .. ft, level = vim.log.levels.INFO })
    else
      -- Add the linter if it's not already in the list
      table.insert(lint.linters_by_ft[ft], linter_name)
      helpers.notify({ msg = "Enabled linter: " .. linter_name .. " for file type: " .. ft, level = vim.log.levels.INFO })
    end

    -- Reset diagnostics and re-run linting
    local linter_namespace = vim.api.nvim_get_namespaces()[linter_name]
    vim.diagnostic.reset(linter_namespace)
    lint.try_lint()
  end

  --- Set up a user command to toggle linters
  vim.api.nvim_create_user_command(
    'ToggleLinter',
    function(opts)
      local linter_name = opts.args
      if linter_name and linter_name ~= "" then
        M.toggle_linter(linter_name)
      else
        helpers.notify({ msg = "Please provide a linter name", level = vim.log.levels.ERROR })
      end
    end,
    {
      nargs = 1, -- Command requires exactly one argument
      complete = function()
        -- Provide a list of available linters for autocompletion
        local linters = {}
        for linter, _ in pairs(lint.linters) do
          table.insert(linters, linter)
        end
        return linters
      end,
      desc = "Toggle a specific linter on or off for the current file type",
    }
  )

  -- User command to display activated linters for the current buffer
  vim.api.nvim_create_user_command('ListActivatedLinters', function()
    local activated_linters = M.get_activated_linters()
    if #activated_linters == 0 then
      vim.notify("No linters activated for filetype: " .. vim.bo.filetype, vim.log.levels.INFO)
    else
      vim.notify("Activated Linters for " .. vim.bo.filetype .. ": " .. table.concat(activated_linters, ", "))
    end
  end, {})


  -- Create autocommand which carries out the actual linting
  -- on the specified events.
  local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
    group = lint_augroup,
    callback = function()
      -- Only run the linter in buffers that you can modify in order to
      -- avoid superfluous noise, notably within the handy LSP pop-ups that
      -- describe the hovered symbol using Markdown.
      if vim.opt_local.modifiable:get() then
        lint.try_lint()
      end
    end,
  })
end

return M
