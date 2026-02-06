function gh-setup-1p-ssh --description "Set up a GitHub org with 1Password SSH keys"
    argparse h/help i/interactive 'org=' 'name=' 'email=' 'host=' 'vault=' 'key-name=' -- $argv
    or return

    # ── Help ──────────────────────────────────────────────────────────
    if set -q _flag_help
        echo
        set_color --bold cyan; echo -n "gh-setup-1p-ssh"; set_color normal
        echo " — Set up a GitHub org with 1Password SSH keys"
        echo
        set_color --bold; echo "USAGE"; set_color normal
        echo "  gh-setup-1p-ssh --org <org> --name <name> --email <email> [OPTIONS]"
        echo "  gh-setup-1p-ssh --interactive"
        echo
        set_color --bold; echo -n "REQUIRED FLAGS"; set_color normal
        set_color --dim; echo " (unless --interactive)"; set_color normal
        set_color green; echo -n "  --org"; set_color normal; echo "        GitHub organization name"
        set_color green; echo -n "  --name"; set_color normal; echo "       Git author name for commits"
        set_color green; echo -n "  --email"; set_color normal; echo "      Git author email for commits"
        echo
        set_color --bold; echo "OPTIONAL FLAGS"; set_color normal
        set_color cyan; echo -n "  --host"; set_color normal; echo -n "       SSH host alias          "; set_color --dim; echo "(default: github-<org>)"; set_color normal
        set_color cyan; echo -n "  --vault"; set_color normal; echo -n "      1Password vault          "; set_color --dim; echo "(default: Personal)"; set_color normal
        set_color cyan; echo -n "  --key-name"; set_color normal; echo -n "   1Password item name      "; set_color --dim; echo "(default: GitHub <org>)"; set_color normal
        set_color cyan; echo -n "  -i"; set_color normal; echo "           Interactive mode — prompts for all values"
        set_color cyan; echo -n "  -h"; set_color normal; echo "           Show this help"
        echo
        set_color --bold; echo "EXAMPLES"; set_color normal
        set_color --dim
        echo "  # Minimal — uses sensible defaults"
        set_color normal
        echo '  gh-setup-1p-ssh --org AECOM-AI-Engineering --name "John Doe" --email "john@aecom.com"'
        echo
        set_color --dim
        echo "  # Custom vault and host alias"
        set_color normal
        echo '  gh-setup-1p-ssh --org AECOM-AI-Engineering --vault Work --host github-aecom \'
        echo '      --name "John Doe" --email "john@aecom.com"'
        echo
        set_color --dim
        echo "  # Interactive — walks you through every option"
        set_color normal
        echo "  gh-setup-1p-ssh -i"
        echo
        return 0
    end

    # ── Internal helpers ──────────────────────────────────────────────
    function _gs1p_info
        set_color blue; echo -n ":: "; set_color normal; echo $argv
    end
    function _gs1p_success
        set_color green; echo -n "✓ "; set_color normal; echo $argv
    end
    function _gs1p_warn
        set_color yellow; echo -n "! "; set_color normal; echo $argv
    end
    function _gs1p_error
        set_color red; echo -n "✗ "; set_color normal; echo $argv >&2
    end
    function _gs1p_step
        echo
        set_color --bold cyan; echo -n "[$argv[1]]"; set_color normal
        echo " $argv[2]"
    end
    function _gs1p_prompt --argument-names label default
        if test -n "$default"
            set_color --bold; echo -n "  $label"; set_color normal
            set_color --dim; echo -n " [$default]"; set_color normal
            echo -n ": "
        else
            set_color --bold; echo -n "  $label"; set_color normal
            echo -n ": "
        end
        read -l value
        if test -n "$value"
            echo $value
        else
            echo $default
        end
    end
    function _gs1p_require --argument-names label default
        set -l value (_gs1p_prompt "$label" "$default")
        while test -z "$value"
            _gs1p_error "$label is required"
            set value (_gs1p_prompt "$label" "$default")
        end
        echo $value
    end

    # ── Collect values ────────────────────────────────────────────────
    set -l org "$_flag_org"
    set -l uname "$_flag_name"
    set -l email "$_flag_email"
    set -l host "$_flag_host"
    set -l vault (test -n "$_flag_vault"; and echo "$_flag_vault"; or echo "Personal")
    set -l key_name "$_flag_key_name"

    # ── Interactive mode ──────────────────────────────────────────────
    if set -q _flag_interactive
        echo
        set_color --bold cyan; echo -n "gh-setup-1p-ssh"; set_color normal
        echo " — interactive setup"
        echo
        set org (_gs1p_require "Organization" "$org")
        set -l org_lower (string lower $org)
        test -z "$host"; and set host "github-$org_lower"
        set host (_gs1p_prompt "Host alias" "$host")
        set vault (_gs1p_prompt "1Password vault" "$vault")
        test -z "$key_name"; and set key_name "GitHub $org"
        set key_name (_gs1p_prompt "1Password key name" "$key_name")
        test -z "$uname"; and set uname (git config user.name 2>/dev/null; or true)
        set uname (_gs1p_prompt "Git author name" "$uname")
        test -z "$email"; and set email (git config user.email 2>/dev/null; or true)
        set email (_gs1p_prompt "Git author email" "$email")
        echo
    end

    # ── Validate required flags ───────────────────────────────────────
    set -l missing
    test -z "$org"; and set -a missing "--org"
    test -z "$uname"; and set -a missing "--name"
    test -z "$email"; and set -a missing "--email"
    if test (count $missing) -gt 0
        _gs1p_error "Missing required flags: $missing"
        echo
        _gs1p_info "Provide them directly:"
        echo "  gh-setup-1p-ssh --org <org> --name <name> --email <email>"
        echo
        _gs1p_info "Or run interactively:"
        echo "  gh-setup-1p-ssh -i"
        echo
        return 1
    end

    # ── Compute defaults ──────────────────────────────────────────────
    set -l org_lower (string lower $org)
    test -z "$host"; and set host "github-$org_lower"
    test -z "$key_name"; and set key_name "GitHub $org"

    echo
    set_color --bold; echo -n "Setting up "; set_color cyan; echo -n "$org"; set_color normal
    set_color --bold; echo " with 1Password SSH"; set_color normal
    echo "  org:      $org"
    echo "  host:     $host"
    echo "  vault:    $vault"
    echo "  key:      $key_name"
    echo "  name:     $uname"
    echo "  email:    $email"
    echo

    # ── Step 1: Check dependencies ────────────────────────────────────
    _gs1p_step "1/8" "Checking dependencies"
    if not command -q gh
        _gs1p_error "gh is not installed."
        _gs1p_info "Install with: brew install gh"
        return 1
    end
    if not command -q op
        _gs1p_error "op (1Password CLI) is not installed."
        _gs1p_info "Install with: brew install 1password-cli"
        return 1
    end
    _gs1p_success "gh and op are installed"

    # ── Step 2: Check 1Password SSH agent ─────────────────────────────
    _gs1p_step "2/8" "Checking 1Password SSH agent"
    set -l agent_sock
    switch (uname -s)
        case Darwin
            set agent_sock "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        case '*'
            set agent_sock "$HOME/.1password/agent.sock"
    end
    if test -S "$agent_sock"
        _gs1p_success "1Password SSH agent socket found"
    else
        _gs1p_error "1Password SSH agent socket not found at: $agent_sock"
        _gs1p_info "Open 1Password → Settings → Developer → Enable SSH Agent"
        return 1
    end

    # ── Step 3: Generate SSH key in 1Password ─────────────────────────
    _gs1p_step "3/8" "Creating SSH key in 1Password"
    if op item get "$key_name" --vault "$vault" &>/dev/null
        _gs1p_warn "Key \"$key_name\" already exists in vault \"$vault\" — skipping creation"
    else
        op item create --category ssh --title "$key_name" --vault "$vault" >/dev/null
        _gs1p_success "Created SSH key \"$key_name\" in vault \"$vault\""
    end

    # ── Step 4: Add bookmark ──────────────────────────────────────────
    _gs1p_step "4/8" "Adding SSH host bookmark to 1Password item"
    op item edit "$key_name" --vault "$vault" --url "ssh://$host" >/dev/null 2>&1; or true
    _gs1p_success "Bookmark set to ssh://$host"

    # ── Step 5: Update SSH config ─────────────────────────────────────
    _gs1p_step "5/8" "Updating ~/.ssh/config"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    test -f "$HOME/.ssh/config"; or touch "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"

    set -l include_line "Include ~/.ssh/1Password/config"
    if not grep -qF "$include_line" "$HOME/.ssh/config" 2>/dev/null
        set -l tmp (mktemp)
        echo "$include_line" > $tmp
        echo >> $tmp
        cat "$HOME/.ssh/config" >> $tmp
        mv $tmp "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
        _gs1p_success "Added 1Password Include to ~/.ssh/config"
    else
        _gs1p_info "1Password Include already present in ~/.ssh/config"
    end

    if grep -qE "^Host[[:space:]]+$host[[:space:]]*\$" "$HOME/.ssh/config" 2>/dev/null
        _gs1p_info "Host $host already exists in ~/.ssh/config — skipping"
    else
        echo "" >> "$HOME/.ssh/config"
        echo "Host $host" >> "$HOME/.ssh/config"
        echo "    HostName github.com" >> "$HOME/.ssh/config"
        echo "    User git" >> "$HOME/.ssh/config"
        echo "    IdentitiesOnly yes" >> "$HOME/.ssh/config"
        _gs1p_success "Added Host $host to ~/.ssh/config"
    end

    # ── Step 6: Login with gh ─────────────────────────────────────────
    _gs1p_step "6/8" "Authenticating with GitHub CLI"
    _gs1p_info "A browser window will open for authentication"
    if not gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key
        _gs1p_warn "GitHub authentication failed — some steps may not work"
    end

    # ── Step 7: Upload SSH public key ─────────────────────────────────
    _gs1p_step "7/8" "Uploading SSH public key to GitHub"
    set -l pub_key (op read "op://$vault/$key_name/public key" 2>/dev/null; or true)
    if test -n "$pub_key"
        set -l tmp (mktemp)
        echo -n "$pub_key" > $tmp
        gh ssh-key add $tmp --title "$key_name (1Password)" 2>/dev/null
        and _gs1p_success "SSH key uploaded to GitHub"
        or _gs1p_warn "Key may already be uploaded — check github.com/settings/keys"
        rm -f $tmp
    else
        _gs1p_error "Could not read public key from 1Password"
        _gs1p_warn "This is a known issue on Apple Silicon — the 1Password CLI may not expose the public key field"
        _gs1p_info "Upload it manually: open 1Password → find \"$key_name\" → copy public key → github.com/settings/keys"
    end

    # ── Step 8: Update gitconfig ──────────────────────────────────────
    _gs1p_step "8/8" "Updating git configuration"
    set -l main_cfg "$HOME/.gitconfig"
    set -l org_cfg "$HOME/.gitconfig-$org_lower"
    set -l condition "hasconfig:remote.*.url:git@$host:$org/**"

    if not grep -qF "$condition" "$main_cfg" 2>/dev/null
        echo "" >> "$main_cfg"
        echo "[includeIf \"$condition\"]" >> "$main_cfg"
        echo "    path = $org_cfg" >> "$main_cfg"
        _gs1p_success "Added includeIf for $org to ~/.gitconfig"
    else
        _gs1p_info "includeIf for $org already in ~/.gitconfig — skipping"
    end

    printf '[user]\n    name = %s\n    email = %s\n' "$uname" "$email" > "$org_cfg"
    _gs1p_success "Wrote $org_cfg with name/email"

    # ── Summary ───────────────────────────────────────────────────────
    echo
    set_color --bold green; echo "── Setup complete ──────────────────────────────────────"; set_color normal
    echo
    _gs1p_warn "If your org uses SAML/SSO, authorize the key at:"
    set_color cyan; echo "  https://github.com/settings/keys"; set_color normal
    set_color --bold; echo -n "  Click "; echo -n "Configure SSO"; set_color normal; echo " → Authorize next to \"$key_name\""
    echo
    _gs1p_info "Clone a repo:"
    set_color --dim; echo "  git clone git@$host:$org/<repo>.git"; set_color normal
    echo
    _gs1p_info "Test the connection:"
    set_color --dim; echo "  ssh -T git@$host"; set_color normal
    echo

    # Clean up internal functions
    functions -e _gs1p_info _gs1p_success _gs1p_warn _gs1p_error _gs1p_step _gs1p_prompt _gs1p_require
end
