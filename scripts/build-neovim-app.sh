#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

/Applications/Platypus.app/Contents/Resources/platypus_clt \
    --name 'Neovim' \
    --interface-type 'None' \
    --interpreter '/bin/bash' \
    --app-icon "${SCRIPT_DIR}/nvim.icns" \
    --bundle-identifier 'com.ah-merii.neovim-ghostty' \
    --app-version '1.0.0' \
    --author 'ah_merii' \
    --droppable \
    --uniform-type-identifiers 'public.text|public.plain-text|public.source-code|public.data|public.unix-executable|public.shell-script|public.json|public.xml|public.yaml' \
    --quit-after-execution \
    --overwrite \
    "${SCRIPT_DIR}/open-in-nvim.sh" \
    ~/Applications/Neovim.app

xattr -cr ~/Applications/Neovim.app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ~/Applications/Neovim.app

echo "Neovim.app built and registered at ~/Applications/Neovim.app"
