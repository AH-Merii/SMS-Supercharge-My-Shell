# 1Password SSH agent
set -l op_sock
switch $OS_KIND
    case macos
        set op_sock "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    case '*'
        set op_sock "$HOME/.1password/agent.sock"
end
if test -S "$op_sock"
    set -gx SSH_AUTH_SOCK "$op_sock"
end
