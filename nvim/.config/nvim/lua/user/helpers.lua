--- Helpers module for common utility functions.
--- Provides reusable utility functions for notifications, debugging, and table manipulations.
local M = {}

--- Debug mode flag. Set to `true` to enable debug logs globally.
--- @type boolean
M.debug_mode = false

--- Utility function for notifications.
--- Provides a centralized way to handle notifications with optional debug logging.
--- @param msg string: The message to display.
--- @param level number|nil: The log level (e.g., vim.log.levels.INFO, WARN, ERROR). Defaults to `INFO`.
--- @param debug boolean|nil: If true, the message is only shown when `debug_mode` is enabled.
function M.notify(msg, level, debug)
  if debug and not M.debug_mode then
    return -- Suppress debug messages when debug mode is disabled.
  end
  vim.notify(msg, level or vim.log.levels.INFO)
end

--- Removes the first occurrence of a value from a table.
--- Operates on array-like tables (tables with numerical indices).
--- @param tbl table: The table to remove the value from.
--- @param value any: The value to remove from the table.
function M.remove_value(tbl, value)
  for i, v in ipairs(tbl) do
    if v == value then
      table.remove(tbl, i)
      break -- Exit the loop after removing the value
    end
  end
end

--- Toggles the global debug mode flag.
--- Updates the `debug_mode` flag and notifies the user of the current state.
function M.toggle_debug()
  M.debug_mode = not M.debug_mode
  M.notify("Debug mode " .. (M.debug_mode and "enabled" or "disabled"), vim.log.levels.INFO)
end

return M

