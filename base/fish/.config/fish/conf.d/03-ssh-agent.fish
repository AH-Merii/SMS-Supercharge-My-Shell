# 1Password SSH agent
switch (uname)
    case Darwin
        set -l op_sock "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        if test -S "$op_sock"
            set -gx SSH_AUTH_SOCK "$op_sock"
        end
    case '*'
        set -l op_sock "$HOME/.1password/agent.sock"
        if test -S "$op_sock"
            set -gx SSH_AUTH_SOCK "$op_sock"
        end
end
