# General Config
export XDG_CONFIG_HOME="$HOME/.config"
export PATH=/opt/homebrew/bin:$PATH
eval $(brew shellenv)

# setup gpg
export GPG_TTY=$(tty)

## Fix compinit security check
ZSH_DISABLE_COMPFIX=true

# Initialize completion system properly
autoload -Uz compinit
compinit -u

# Shell status function
shell_status() {
    # Only show for interactive shells
    [[ $- != *i* ]] && return
    
    local user_host="$(whoami)@$(hostname -s)"
    local current_dir="$(pwd | sed "s|$HOME|~|")"
    local uptime_info="$(uptime | sed 's/.*up //' | sed 's/users.*//' | sed 's/,.*load.*//' | xargs)"
    local current_time="$(date '+%H:%M')"
    
    # Git info if in a git repository
    local git_info=""
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local branch="$(git branch --show-current 2>/dev/null || echo 'detached')"
        local git_status=""
        if [[ -z "$(git status --porcelain 2>/dev/null)" ]]; then
            git_status="✓"
        else
            git_status="±"
        fi
        git_info="📦 $branch $git_status | "
    fi
    
    echo "🏠 $user_host $current_dir | ⏱ $uptime_info | $git_info🕐 $current_time"
}

# Initialize starship prompt
eval "$(starship init zsh)"

# Show status on new interactive shell
if [[ $- == *i* ]]; then
    shell_status
fi

# setup vim
alias vim=$(which nvim)

# setup rust
source "$HOME/.cargo/env"

# Setup GVM first
[[ -s "/Users/ianlivingstone/.gvm/scripts/gvm" ]] && source "/Users/ianlivingstone/.gvm/scripts/gvm"

# Setup go (after GVM)
export GOPATH=~/code
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN
export GOPRIVATE=github.com/keycardlabs


# Setup node.js
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Always start the ssh-agent
eval "$(ssh-agent -s)" > /dev/null

# Start gpg-agent if not already running
if ! pgrep -x "gpg-agent" > /dev/null; then
    eval "$(gpg-agent --daemon --enable-ssh-support)" > /dev/null
fi
