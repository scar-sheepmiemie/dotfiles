# ====================================================================
# .zshrc - Portable and efficient configuration by CircuIT (v8 - Context-Aware Pro)
#
# v8 Update:
# - The user@hostname segment is now context-aware: it ONLY appears
#   in SSH sessions by checking for the $SSH_CONNECTION variable.
# ====================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git z sudo you-should-use zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

export TERM="xterm-256color"
HISTFILE=~/.zsh_history; HISTSIZE=10000; SAVEHIST=10000; setopt HIST_IGNORE_DUPS

# --- Pyenv Initialization (if installed) ---
if command -v pyenv &> /dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# --- Custom Command Execution Timer ---
zmodload zsh/datetime
CMD_EXEC_THRESHOLD=1; local zsh_timer
preexec() { zsh_timer=${EPOCHREALTIME}; }
update_cmd_duration() {
    if [[ -n $zsh_timer ]]; then
        local duration=$((${EPOCHREALTIME} - ${zsh_timer}))
        if (( duration > CMD_EXEC_THRESHOLD )); then CMD_DURATION_STR=$(printf "⏱ %.3fs " "$duration");
        else CMD_DURATION_STR=""; fi
        unset zsh_timer
    fi
}

# --- Custom Prompt ---
ICON_SUCCESS="✔" ICON_FAIL="✘" ICON_GIT="" SEPARATOR=""
COLOR_BG_USER_HOST="240" COLOR_FG_USER_HOST="214"
COLOR_BG_GIT_CLEAN="71"  COLOR_BG_GIT_DIRTY="161" COLOR_BG_GIT_STAGED="214" COLOR_FG_GIT="255"
COLOR_BG_DIR="68"       COLOR_FG_DIR="255"
COLOR_FG_PY="111"

# --- PROMPT SEGMENT FUNCTIONS ---
prompt_status() { if (($? == 0)); then echo "%F{green}${ICON_SUCCESS}%f"; else echo "%F{red}${ICON_FAIL}%f"; fi; }
prompt_git() {
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); [[ -z "$branch" ]] && return
  local bg_color; if ! git diff --quiet; then bg_color=$COLOR_BG_GIT_DIRTY; elif ! git diff --cached --quiet; then bg_color=$COLOR_BG_GIT_STAGED; else bg_color=$COLOR_BG_GIT_CLEAN; fi
  echo "%K{$bg_color}%F{$COLOR_FG_GIT}${ICON_GIT} ${branch}%f%k"
}
prompt_dir() { echo "%K{$COLOR_BG_DIR}%F{$COLOR_FG_DIR}%1~%f%k"; }
prompt_pyenv() {
  if [[ -n "$PYENV_VIRTUAL_ENV" ]]; then
    local py_version=$(pyenv version-name)
    echo "%F{$COLOR_FG_PY}(${py_version})%f "
  fi
}

# --- PROMPT BUILDER FUNCTIONS ---
build_left_prompt() {
  local prompt_string=""
  local last_bg_color="black" # Default terminal background

  # --- THIS IS THE FIX for conditional hostname ---
  # Only draw the user@host segment if in an SSH session.
  if [[ -n "$SSH_CONNECTION" ]]; then
    prompt_string+="%K{$COLOR_BG_USER_HOST}%F{$COLOR_FG_USER_HOST}%n@%m%f%k"
    last_bg_color=$COLOR_BG_USER_HOST
  fi

  # Git Segment
  local git_segment=$(prompt_git)
  if [[ -n "$git_segment" ]]; then
    local git_bg_color; if ! git diff --quiet; then git_bg_color=$COLOR_BG_GIT_DIRTY; elif ! git diff --cached --quiet; then git_bg_color=$COLOR_BG_GIT_STAGED; else git_bg_color=$COLOR_BG_GIT_CLEAN; fi
    # The separator correctly uses the last_bg_color, whether it's black or grey.
    prompt_string+="%K{$git_bg_color}%F{$last_bg_color}${SEPARATOR}%f%k"
    prompt_string+=${git_segment}
    last_bg_color=$git_bg_color
  fi

  # Directory Segment
  local dir_segment=$(prompt_dir)
  if [[ -n "$dir_segment" ]]; then # Check if dir is not empty
    prompt_string+="%K{$COLOR_BG_DIR}%F{$last_bg_color}${SEPARATOR}%f%k"
    prompt_string+=${dir_segment}
    # Final closing separator
    prompt_string+="%F{$COLOR_BG_DIR}${SEPARATOR}%f "
  fi

  PROMPT="$(prompt_pyenv)$(prompt_status) ${prompt_string}"
}
build_right_prompt() { RPROMPT="${CMD_DURATION_STR}%F{gray}%*%f"; }
precmd() { update_cmd_duration; build_left_prompt; build_right_prompt; }

# --- Recommended Bonus Features ---
alias ll='ls -lhaG'; alias ..='cd ..'; alias g='git'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
if command -v zoxide &> /dev/null; then eval "$(zoxide init zsh)"; fi
