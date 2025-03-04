# https://github.com/doron-cohen/antidot
# Use antidot to export new xdg locations for cleaned programs
eval "$(antidot init)"

# editor
export EDITOR=nvim
export SUDOEDITOR=nvim
export VISUAL=nvim

# binaries

export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.local/share/go/bin:$PATH

### declutter home directory ###

# Set XDG base dirs.
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share
export XDG_STATE_HOME=~/.local/state
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_PROJECTS_DIR=~/Projects

# Set zsh config directory
export ZDOTDIR=$HOME/.config/zsh

# Store zsh history
export HISTFILE=$XDG_DATA_HOME/zsh/zsh_history

# XDG DATA
export PYENV_ROOT="$XDG_DATA_HOME"/pyenv 

# XDG CACHE
export TEXMFVAR="$XDG_CACHE_HOME"/texlive/texmf-var

# Define powerlevel10k theme
export ZSH_THEME="powerlevel10k/powerlevel10k"

# Custom
export GNUPGHOME=$XDG_DATA_HOME/gnupg
export REPO_HOME=$XDG_CACHE_HOME/repos
export ANTIDOTE_HOME=$REPO_HOME

# Do the initialization when the script is sourced (i.e. Initialize instantly) (zsh-vi-mode plugin)
ZVM_INIT_MODE=sourcing

# mattmc3/zephyr/zfunctions plugin
ZFUNCDIR=${ZDOTDIR:-$HOME/.config/zsh}/functions

# AWS CLI Autocompletions
export AWS_CLI_AUTO_PROMPT="on-partial"

# fzf configuration
export FZF_CTRL_T_COMMAND="fd --hidden --follow --type f --exclude '.git'"
export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always --style=numbers {}'
  --bind 'page-up:preview-up,page-down:preview-down'
  --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
# CTRL-/ to toggle small preview window to see the full command
# CTRL-Y to copy the command into clipboard using pbcopy
export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# API KEYS - DO NOT COMMIT
# export SRC_ENDPOINT='https://sourcegraph.com'
# export SRC_ACCESS_TOKEN=$(pass sourcegraph/tokens/cody | head -n 1)

# lf icons
export LF_ICONS="\
tw=:\
st=:\
ow=:\
dt=:\
di=:\
fi=:\
ln=:\
or=:\
ex=:\
*.c=:\
*.cc=:\
*.clj=:\
*.coffee=:\
*.cpp=:\
*.css=:\
*.d=:\
*.dart=:\
*.erl=:\
*.exs=:\
*.fs=:\
*.go=:\
*.h=:\
*.hh=:\
*.hpp=:\
*.hs=:\
*.html=:\
*.java=:\
*.jl=:\
*.js=:\
*.json=:\
*.lua=:\
*.md=:\
*.php=:\
*.pl=:\
*.pro=:\
*.py=:\
*.rb=:\
*.rs=:\
*.scala=:\
*.ts=:\
*.vim=:\
*.cmd=:\
*.ps1=:\
*.sh=:\
*.bash=:\
*.zsh=:\
*.fish=:\
*.tar=:\
*.tgz=:\
*.arc=:\
*.arj=:\
*.taz=:\
*.lha=:\
*.lz4=:\
*.lzh=:\
*.lzma=:\
*.tlz=:\
*.txz=:\
*.tzo=:\
*.t7z=:\
*.zip=:\
*.z=:\
*.dz=:\
*.gz=:\
*.lrz=:\
*.lz=:\
*.lzo=:\
*.xz=:\
*.zst=:\
*.tzst=:\
*.bz2=:\
*.bz=:\
*.tbz=:\
*.tbz2=:\
*.tz=:\
*.deb=:\
*.rpm=:\
*.jar=:\
*.war=:\
*.ear=:\
*.sar=:\
*.rar=:\
*.alz=:\
*.ace=:\
*.zoo=:\
*.cpio=:\
*.7z=:\
*.rz=:\
*.cab=:\
*.wim=:\
*.swm=:\
*.dwm=:\
*.esd=:\
*.jpg=:\
*.jpeg=:\
*.mjpg=:\
*.mjpeg=:\
*.gif=:\
*.bmp=:\
*.pbm=:\
*.pgm=:\
*.ppm=:\
*.tga=:\
*.xbm=:\
*.xpm=:\
*.tif=:\
*.tiff=:\
*.png=:\
*.svg=:\
*.svgz=:\
*.mng=:\
*.pcx=:\
*.mov=:\
*.mpg=:\
*.mpeg=:\
*.m2v=:\
*.mkv=:\
*.webm=:\
*.ogm=:\
*.mp4=:\
*.m4v=:\
*.mp4v=:\
*.vob=:\
*.qt=:\
*.nuv=:\
*.wmv=:\
*.asf=:\
*.rm=:\
*.rmvb=:\
*.flc=:\
*.avi=:\
*.fli=:\
*.flv=:\
*.gl=:\
*.dl=:\
*.xcf=:\
*.xwd=:\
*.yuv=:\
*.cgm=:\
*.emf=:\
*.ogv=:\
*.ogx=:\
*.aac=󰈣:\
*.au=󰈣:\
*.flac=󰈣:\
*.m4a=󰈣:\
*.mid=󰈣:\
*.midi=󰈣:\
*.mka=󰈣:\
*.mp3=󰈣:\
*.mpc=󰈣:\
*.ogg=󰈣:\
*.ra=󰈣:\
*.wav=󰈣:\
*.oga=󰈣:\
*.opus=󰈣:\
*.spx=󰈣:\
*.xspf=󰈣:\
*.pdf=:\
*.nix=:\
"
