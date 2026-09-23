# mise honours a project's pin and owns nothing else: the global config declares no tools, so
# there is nothing to shim and no reason for a non-interactive shell to pay for activation.
# Everything a machine has comes from the Nix profile that conf.d/00-nix.fish put on PATH.
if status is-interactive; and type -q mise
    mise activate fish | source
end
