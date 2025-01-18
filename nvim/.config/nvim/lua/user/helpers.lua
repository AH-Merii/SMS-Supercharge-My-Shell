--- Helpers module for common utility functions.
local M = {}

--- Debug mode flag. Set to `true` to enable debug logs globally.
M.debug_mode = false

--- Utility function for notifications.
--- Provides a centralized way to handle notifications with optional debug logging.
--- @param msg string: The message to display.
--- @param level number: The log level (e.g., vim.log.levels.INFO, WARN, ERROR).
--- @param debug boolean|nil: If true, show debug messages when `debug_mode` is enabled.
function M.notify(msg, level, debug)
  if debug and not M.debug_mode then
    return -- Suppress debug messages when debug mode is disabled.
  end
  vim.notify(msg, level or vim.log.levels.INFO)
end

--- Toggles the global debug mode flag.
--- Notifies the user about the current debug mode state.
function M.toggle_debug()
  M.debug_mode = not M.debug_mode
  M.notify("Debug mode " .. (M.debug_mode and "enabled" or "disabled"), vim.log.levels.INFO)
end

return M

