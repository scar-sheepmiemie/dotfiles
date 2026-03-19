# ====================================================================
# .zshrc - Portable and efficient configuration by CircuIT (v17 - Final)
#
# This is the definitive, readable, and feature-complete version.
# It includes a native Zsh function to reliably set the Splunk environment,
# replacing the need for external, problematic scripts.
# ====================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

# Set VIM as default editor
export VISUAL=vim
export EDITOR="$VISUAL"

# --- Full, desired plugin list ---
plugins=(
  git
  z
  sudo
  you-should-use
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# --- ZSH Syntax Highlighting Configuration ---
export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

# --- Oh My Zsh Core ---
source $ZSH/oh-my-zsh.sh

# --- General Exports and Options ---
export TERM="xterm-256color"
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS

# --- Pyenv Initialization (if installed) ---
if command -v pyenv &> /dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# --- Custom Command Execution Timer ---
zmodload zsh/datetime
CMD_EXEC_THRESHOLD=1
local zsh_timer

preexec() {
    zsh_timer=${EPOCHREALTIME}
}

update_cmd_duration() {
    if [[ -n $zsh_timer ]]; then
        local duration
        duration=$((${EPOCHREALTIME} - ${zsh_timer}))
        if (( duration > CMD_EXEC_THRESHOLD )); then
            CMD_DURATION_STR=$(printf "⏱ %.3fs " "$duration")
        else
            CMD_DURATION_STR=""
        fi
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
prompt_status() {
    local exit_code=$1
    if ((exit_code == 0)); then
        echo "%F{green}${ICON_SUCCESS}%f"
    else
        echo "%F{red}${ICON_FAIL}%f"
    fi
}

prompt_git() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -z "$branch" ]]; then
        return
    fi

    local bg_color
    if ! git diff --quiet; then
        bg_color=$COLOR_BG_GIT_DIRTY
    elif ! git diff --cached --quiet; then
        bg_color=$COLOR_BG_GIT_STAGED
    else
        bg_color=$COLOR_BG_GIT_CLEAN
    fi
    echo "%K{$bg_color}%F{$COLOR_FG_GIT}${ICON_GIT} ${branch}%f%k"
}

prompt_dir() {
    echo "%K{$COLOR_BG_DIR}%F{$COLOR_FG_DIR}%1~%f%k"
}

prompt_pyenv() {
    if [[ -n "$PYENV_VIRTUAL_ENV" ]]; then
        local py_version
        py_version=$(pyenv version-name)
        echo "%F{$COLOR_FG_PY}(${py_version})%f "
    fi
}

# --- PROMPT BUILDER FUNCTIONS ---
build_left_prompt() {
    local last_exit_code=$1
    local prompt_string=""
    local last_bg_color="black"

    if [[ -n "$SSH_CONNECTION" ]]; then
        prompt_string+="%K{$COLOR_BG_USER_HOST}%F{$COLOR_FG_USER_HOST}%n@%m%f%k"
        last_bg_color=$COLOR_BG_USER_HOST
    fi

    local git_segment
    git_segment=$(prompt_git)
    if [[ -n "$git_segment" ]]; then
        local git_bg_color
        if ! git diff --quiet; then git_bg_color=$COLOR_BG_GIT_DIRTY
        elif ! git diff --cached --quiet; then git_bg_color=$COLOR_BG_GIT_STAGED
        else git_bg_color=$COLOR_BG_GIT_CLEAN; fi
        
        prompt_string+="%K{$git_bg_color}%F{$last_bg_color}${SEPARATOR}%f%k"
        prompt_string+=${git_segment}
        last_bg_color=$git_bg_color
    fi

    local dir_segment
    dir_segment=$(prompt_dir)
    prompt_string+="%K{$COLOR_BG_DIR}%F{$last_bg_color}${SEPARATOR}%f%k"
    prompt_string+=${dir_segment}
    prompt_string+="%F{$COLOR_BG_DIR}${SEPARATOR}%f "

    PROMPT="$(prompt_pyenv)$(prompt_status $last_exit_code) ${prompt_string}"
}

build_right_prompt() {
    RPROMPT="${CMD_DURATION_STR}%F{gray}%*%f"
}

# --- PRECMD HOOK (This contains the critical fix for the status bug) ---
precmd() {
    local last_exit_code=$? # Capture the exit code IMMEDIATELY
    update_cmd_duration
    build_left_prompt $last_exit_code # Pass the captured code to the builder
    build_right_prompt
}

# --- Recommended Bonus Features ---
alias ll='ls -lhaG'
alias ..='cd ..'
alias g='git'
alias vi='vim'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# --- Zsh Autosuggestions Key Binding ---
bindkey '^ ' autosuggest-accept

# --- Helper function for setting up the Splunk environment ---
# This function replaces the need for the problematic setSplunkEnv script.
function setup_splunk_env() {
    # You can customize this path to your default Splunk installation directory
    local splunk_dir="${SPLUNK_HOME:-$HOME/splunk}"

    if [ ! -d "$splunk_dir" ]; then
        echo "Error: Splunk directory not found at '$splunk_dir'." >&2
        echo "Please set \$SPLUNK_HOME or place Splunk in ~/splunk." >&2
        return 1
    fi

    local splunk_exec="$splunk_dir/bin/splunk"

    if [ ! -x "$splunk_exec" ]; then
        echo "Error: splunk executable not found or not executable at '$splunk_exec'." >&2
        return 1
    fi

    echo "Sourcing environment from Splunk..."
    # Use process substitution source <(...) to safely evaluate the output.
    # This avoids the 'eval' black hole and will show any errors from 'splunk envvars'.
    source <("$splunk_exec" envvars | grep -v "Warning")

    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "Splunk environment variables sourced successfully."
        # Optionally, source the completion script as well
        if [ -f "$SPLUNK_HOME/share/splunk/cli-command-completion.sh" ]; then
            source "$SPLUNK_HOME/share/splunk/cli-command-completion.sh"
            echo 'Tab-completion of "splunk <verb> <object>" is now available.' >&2
        fi
    else
        echo "Error: Failed to source Splunk environment. Please check the output above." >&2
    fi
    return $exit_code
}

# Create a simple alias to run the setup function
alias splunk-on='setup_splunk_env'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
eval "$(pyenv virtualenv-init - zsh)"

alias splunk-clean='rm -fr "$SPLUNK_HOME"/* ; rm -fr "$SPLUNK_BUILD"/* ; cd "$SPLUNK_SOURCE/contrib" && ./buildit.py distclean ; cd "$SPLUNK_SOURCE" && git clean -dfx -e $SPLUNK_SOURCE/codex-plans/'

# Copy local splunkd to remote host and restart Splunk
splunk_update() {
  local host="$1"
  if [[ -z "$host" ]]; then
    echo "usage: splunk_update <ip-or-hostname>" >&2
    return 2
  fi

  env -i \
    PATH=/usr/bin:/bin \
    HOME="$HOME" \
    SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}" \
    scp -P 2222 "$HOME/splunk_home/bin/splunkd" "ansible@${host}:~/splunkd" || return $?

  env -i \
    PATH=/usr/bin:/bin \
    HOME="$HOME" \
    SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}" \
    ssh -p 2222 "ansible@${host}" \
    "sudo mv -n /opt/splunk/bin/splunkd /opt/splunk/bin/splunkd.bak || true && \
     sudo chown splunk:splunk ~/splunkd && \
     sudo mv ~/splunkd /opt/splunk/bin/splunkd && \
     sudo -u splunk sh -c '/opt/splunk/bin/splunk restart'"
}

splunk_conf() {
  emulate -L zsh
  setopt pipefail

  local method="GET"
  local file="" stanza="" name="" value=""
  local auth="admin:'Chang3d!'"
  local dryrun=0

  # If first arg doesn't start with '-', treat it as host and shift it off.
  local host=""
  if [[ -n "$1" && "$1" != -* ]]; then
    host="$1"
    shift
  fi

  local opt
  while getopts ":GPf:s:n:v:u:D" opt; do
    case "$opt" in
      G) method="GET" ;;
      P) method="POST" ;;
      f) file="$OPTARG" ;;
      s) stanza="$OPTARG" ;;
      n) name="$OPTARG" ;;
      v) value="$OPTARG" ;;
      u) auth="$OPTARG" ;;
      D) dryrun=1 ;;
      \?) print -u2 "Unknown option: -$OPTARG"; return 2 ;;
      :)  print -u2 "Option -$OPTARG requires an argument."; return 2 ;;
    esac
  done
  shift $((OPTIND - 1))

  # If host wasn't first, allow it as the last remaining arg (common with parhosts)
  if [[ -z "$host" ]]; then
    if [[ $# -ge 1 && "$1" != -* ]]; then
      host="$1"
      shift
    fi
  fi

  if [[ -z "$host" ]]; then
    print -u2 "usage: splunk_conf <host> [-G|-P] -f <file> -s <stanza> [-n <name>] [-v <value>] [-u \"admin:'Chang3d!'\" ] [-D]"
    return 2
  fi

  if [[ -z "$file" || -z "$stanza" ]]; then
    print -u2 "Error: -f <file> and -s <stanza> are required."
    return 2
  fi

  if [[ "$method" == "GET" ]]; then
    [[ -n "$value" ]] && { print -u2 "Error: GET does not take -v <value>."; return 2; }
  else
    [[ -z "$name" || -z "$value" ]] && { print -u2 "Error: POST requires -n <name> and -v <value>."; return 2; }
  fi

  local url="https://localhost:8089/servicesNS/nobody/system/configs/conf-${file}/${stanza}?output_mode=json"
  local pretty_cmd="(python3 -m json.tool 2>/dev/null || python -m json.tool 2>/dev/null || cat)"

  local curl_cmd="curl -sS -k -u ${auth} -X ${method} ${url}"
  if [[ "$method" == "POST" ]]; then
    curl_cmd+=" -d ${name}=${value}"
  fi
  curl_cmd+=" | ${pretty_cmd}"
  if [[ "$method" == "GET" && -n "$name" ]]; then
    curl_cmd+=" | grep -F -- ${name}"
  fi

  if (( dryrun )); then
    print -r -- "env -i PATH=/usr/bin:/bin HOME=\"$HOME\" SSH_AUTH_SOCK=\"${SSH_AUTH_SOCK:-}\" ssh -p 2222 ansible@${host} ${(qqq)curl_cmd}"
    return 0
  fi

  env -i \
    PATH=/usr/bin:/bin \
    HOME="$HOME" \
    SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}" \
    ssh -p 2222 "ansible@${host}" \
    "$curl_cmd"
}

parhosts() {
  emulate -L zsh
  setopt pipefail

  local hosts_csv="$1"; shift
  local jobs="${JOBS:-10}"

  if [[ -z "$hosts_csv" || $# -lt 1 ]]; then
    print -u2 "usage: parhosts <host[,host...]> <command...>   (set JOBS=N env var to change parallelism)"
    return 2
  fi

  local -a hosts pids pid_hosts ok_hosts fail_hosts
  local -A pid_to_host
  hosts=("${(@s:,:)hosts_csv}")
  hosts=("${hosts[@]//[[:space:]]/}")

  # helper: wait one pid, record success/fail, and remove it from pid list
  _parhosts_wait_one() {
    local pid="$1"
    local h="${pid_to_host[$pid]}"
    local rc=0
    wait "$pid" || rc=$?
    if (( rc == 0 )); then
      ok_hosts+=("$h")
    else
      fail_hosts+=("$h")
    fi
    unset "pid_to_host[$pid]"
  }

  for h in "${hosts[@]}"; do
    [[ -z "$h" ]] && continue

    {
      print -r -- "===== $h ====="
      "$@" "$h"
    } &
    local pid=$!
    pids+=("$pid")
    pid_to_host[$pid]="$h"

    # Throttle: if too many running, wait for the oldest
    if (( jobs > 0 && ${#pids[@]} >= jobs )); then
      _parhosts_wait_one "${pids[1]}"
      pids=("${pids[@]:1}")
    fi
  done

  # Wait the rest
  local pid
  for pid in "${pids[@]}"; do
    _parhosts_wait_one "$pid"
  done

  print -r -- ""
  print -r -- "====== Summary ======"
  if (( ${#ok_hosts[@]} > 0 )); then
    print -r -- "SUCCESS (${#ok_hosts[@]}): ${(j:, :)ok_hosts}"
  else
    print -r -- "SUCCESS (0):"
  fi
  if (( ${#fail_hosts[@]} > 0 )); then
    print -r -- "FAILED  (${#fail_hosts[@]}): ${(j:, :)fail_hosts}"
  else
    print -r -- "FAILED  (0):"
  fi

  (( ${#fail_hosts[@]} > 0 )) && return 1
  return 0
}
