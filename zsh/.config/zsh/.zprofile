# SSH Agent: prefer 1Password, fall back to traditional ssh-agent
if [[ "$OSTYPE" == darwin* ]]; then
    _op_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
else
    _op_sock="$HOME/.1password/agent.sock"
fi

if [[ -S "$_op_sock" ]]; then
    export SSH_AUTH_SOCK="$_op_sock"
else
    # Traditional ssh-agent fallback
    env=~/.ssh/agent.env
    agent_load_env () { test -f "$env" && . "$env" >| /dev/null ; }
    agent_start () { (umask 077; ssh-agent >| "$env"); . "$env" >| /dev/null ; }
    agent_load_env
    agent_run_state=$(ssh-add -l >| /dev/null 2>&1; echo $?)
    if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
        agent_start; ssh-add
    elif [ "$SSH_AUTH_SOCK" ] && [ $agent_run_state = 1 ]; then
        ssh-add
    fi
    unset env
fi
unset _op_sock
