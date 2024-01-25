-- Add the clipboard configuration for WSL
vim.g.clipboard = {
       name = 'WslClipboard',
       copy = {
          ['+'] = 'clip.exe',
          ['*'] = 'clip.exe',
       },
       paste = {
          ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring():gsub("\\r", ""))',
          ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring():gsub("\\r", ""))',
       },
       cache_enabled = 0,
     }
