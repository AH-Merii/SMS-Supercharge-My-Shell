--- Checks whether your current system is running WSL    or not
local function is_wsl()
	local file = io.open("/proc/version", "r")
	if not file then
		return false -- Not a Linux-like environment
	end

	local content = file:read("*a")
	file:close()

	local lower_input = string.lower(content)

	return string.match(lower_input, "microsoft") or string.match(lower_input, "wsl")
end

--- function that sets up wsl specific options when called
local function configure_wsl_options()
	-- Add the clipboard configuration for WSL
	if vim.fn.executable("clip.exe") == 1 and vim.fn.executable("powershell.exe") == 1 then
		vim.g.clipboard = {
			name = "WslClipboard",
			copy = {
				["+"] = "clip.exe",
				["*"] = "clip.exe",
			},
			paste = {
				["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring():gsub("\\r", ""))',
				["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring():gsub("\\r", ""))',
			},
			cache_enabled = 0,
		}
	else
		vim.notify("Clipboard tools (clip.exe (and|or) powershell.exe) (are|is) not available.", vim.log.levels.WARN)
	end
	-- Add other WSL   specific configurations below
end

if is_wsl() then
	configure_wsl_options()
end
