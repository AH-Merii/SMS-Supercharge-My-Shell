# Warn when git identity or commit signing is not set up on this machine.
# The stowed git config enforces SSH signing but strips [user] and [gpg "ssh"] on
# commit, so each machine needs `ggh` to write them (see base/git/README.md).
status is-interactive; or return
type -q git; or return

set -l missing
git -C $HOME config --get user.name >/dev/null; or set -a missing user.name
git -C $HOME config --get user.email >/dev/null; or set -a missing user.email
if contains -- true (git -C $HOME config --get commit.gpgsign 2>/dev/null)
    git -C $HOME config --get user.signingkey >/dev/null; or set -a missing user.signingkey
end

if test (count $missing) -gt 0
    set_color yellow
    echo "git is not configured on this machine (missing: $missing)"
    set_color normal
    echo "  ggh op init --name 'Your Name' --email you@example.com   # 1Password SSH key"
    echo "  ggh init    --name 'Your Name' --email you@example.com   # plain SSH key"
    echo "  ggh op add  --org MyOrg --name 'Your Name' --email you@work.com   # per-org identity"
    echo "  details: ~/SMS-Supercharge-My-Shell/base/git/README.md"
end
