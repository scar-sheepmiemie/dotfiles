#!/bin/bash

# ==============================================================================
# Zsh Enhancement Manager by CircuIT (v11)
#
# A command-line tool to install and verify Zsh enhancements.
#
# v11 Update:
# - Implemented a definitive, pattern-based font check for Linux to robustly
#   handle minor filename variations from the source zip file.
# ==============================================================================

# --- Setup and Color Definitions ---
set -e
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'

info() { echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"; }
success() { echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"; }
warn() { echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"; }
error() { echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"; }

# --- Core Action Functions ---
check_dependencies() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "Command not found: $cmd."
            local pkg_name=$([ "$cmd" = "fc-cache" ] || [ "$cmd" = "fc-match" ] && echo "fontconfig" || echo "$cmd")
            if command -v apt-get &> /dev/null; then info "To install it, please run: sudo apt-get update && sudo apt-get install -y $pkg_name";
            elif command -v dnf &> /dev/null; then info "To install it, please run: sudo dnf install -y $pkg_name";
            elif command -v pacman &> /dev/null; then info "To install it, please run: sudo pacman -Syu $pkg_name";
            else warn "Could not detect your package manager. Please install '$cmd' manually."; fi
            exit 1
        fi
    done
}

install_fonts() {
    info "--- Starting Font Installation ---"
    case "$(uname -s)" in
        Darwin)
            info "Detected macOS. Using Homebrew."
            check_dependencies brew
            local FONT_CASK="font-meslo-lg-nerd-font"
            if brew list --cask "$FONT_CASK" &> /dev/null; then success "Font '$FONT_CASK' is already installed. Skipping.";
            else
                info "Installing font: $FONT_CASK..."
                brew install --cask "$FONT_CASK"
                success "Font '$FONT_CASK' installed successfully."
            fi
            ;;
        Linux)
            check_dependencies curl unzip fc-cache
            local FONT_DIR="$HOME/.local/share/fonts"
            # Use a pattern to check for existence, more robust
            if ls "$FONT_DIR"/MesloLGS*Regular*.ttf &> /dev/null; then
                success "A MesloLGS Regular Nerd Font file already exists. Skipping download."
            else
                info "Downloading and installing 'MesloLGS NF'..."
                local FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
                local TEMP_DIR=$(mktemp -d)
                curl -fsSL "$FONT_URL" -o "$TEMP_DIR/Meslo.zip"
                unzip -o "$TEMP_DIR/Meslo.zip" -d "$TEMP_DIR/MesloFonts" > /dev/null
                mkdir -p "$FONT_DIR"; find "$TEMP_DIR/MesloFonts" -name "*.ttf" -exec mv {} "$FONT_DIR/" \;
                rm -rf "$TEMP_DIR"; success "Font files downloaded and moved successfully."
            fi
            info "Reloading system font cache... (This may take a moment)"; fc-cache -fv
            success "Font cache reloaded."
            ;;
        *) warn "Unsupported OS: $(uname -s). Font installation skipped."; ;;
    esac
}

install_zsh_plugins() {
    info "--- Starting Zsh Plugin Installation ---"
    check_dependencies git
    local ZSH_CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    mkdir -p "$ZSH_CUSTOM_PLUGINS_DIR"
    local plugins_to_install=("https://github.com/zsh-users/zsh-autosuggestions" "https://github.com/zsh-users/zsh-syntax-highlighting.git")
    for plugin_url in "${plugins_to_install[@]}"; do
        local plugin_name=$(basename "$plugin_url" .git)
        local plugin_dir="$ZSH_CUSTOM_PLUGINS_DIR/$plugin_name"
        if [ -d "$plugin_dir" ]; then success "Plugin '$plugin_name' is already installed. Skipping.";
        else info "Cloning '$plugin_name'..."; git clone -q "$plugin_url" "$plugin_dir"; success "Plugin '$plugin_name' installed."; fi
    done
}

check_font_status() {
    local FONT_IS_OK=false
    echo; info "------------------------- Font Status Check --------------------------"
    case "$(uname -s)" in
        Linux)
            # --- THIS IS THE FINAL, ROBUST CHECK ---
            info "Running robust, pattern-based font check for Linux..."
            local FONT_DIR="$HOME/.local/share/fonts"
            local FONT_PATTERN="$FONT_DIR/MesloLGS*Regular*.ttf"
            
            # Use 'ls' with a glob pattern to check for file existence.
            # This is much more reliable than checking a hardcoded name.
            if ls $FONT_PATTERN &> /dev/null; then
                success "A MesloLGS Regular Nerd Font file was found in '$FONT_DIR'."
                FONT_IS_OK=true
                # Optional: run fc-list as a secondary diagnostic
                if command -v fc-list &> /dev/null && ! fc-list | grep -q "MesloLGS NF"; then
                    warn "System cache may be out of sync. A terminal restart is recommended."
                fi
            else
                error "No MesloLGS Regular Nerd Font file found in '$FONT_DIR'."
            fi
            ;;
        Darwin)
            info "Checking Homebrew for 'font-meslo-lg-nerd-font' cask..."
            check_dependencies brew
            if brew list --cask font-meslo-lg-nerd-font &> /dev/null; then
                 success "Font cask 'font-meslo-lg-nerd-font' is installed via Homebrew."
                 FONT_IS_OK=true
            else
                 error "Font cask 'font-meslo-lg-nerd-font' is not installed via Homebrew."
            fi
            ;;
    esac
    if [ "$FONT_IS_OK" = true ]; then warn "Reminder: You must still MANUALLY select 'MesloLGS NF' in your terminal's settings.";
    else info "Suggestion: Run './$(basename "$0") --install' to install the font."; fi
    echo "--------------------------------------------------------------------"
    [ "$FONT_IS_OK" = true ]
}

list_installed_plugins() {
    echo; info "------------------- Installed Custom Zsh Plugins ---------------------"
    local ZSH_CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    if [ -d "$ZSH_CUSTOM_PLUGINS_DIR" ] && [ "$(ls -A $ZSH_CUSTOM_PLUGINS_DIR)" ]; then
        find "$ZSH_CUSTOM_PLUGINS_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sed 's/^/  - /'
    else warn "No custom plugins found in '$ZSH_CUSTOM_PLUGINS_DIR'."; fi
    echo "--------------------------------------------------------------------"
}

show_help() {
    cat << EOF
Zsh Enhancement Manager by CircuIT (v11)

A command-line tool to install and verify Zsh enhancements.

Usage:
  $0 [command]

Commands:
  --install         Install all tools, fonts, and plugins. Then show a summary. (Default)
  --check-font      Verify if the required font is recognized by the system.
  --list-plugins    List all installed custom Oh My Zsh plugins.
  --verify          Run all checks (--check-font and --list-plugins) without installing.
  --help, -h        Show this help message.
EOF
}

generate_summary_report() {
    info "======================= INSTALLATION SUMMARY ======================="
    check_font_status
    list_installed_plugins
    info "===================================================================="
    echo
    success "All tasks completed!"
    echo
    info "--> NEXT STEP: Restart your terminal or run 'source ~/.zshrc'!"
}

main() {
    local action=${1:---install}
    case "$action" in
        --install) info "Starting full installation..."; install_fonts; install_zsh_plugins; generate_summary_report ;;
        --check-font) check_font_status ;;
        --list-plugins) list_installed_plugins ;;
        --verify) info "Running all verification checks..."; check_font_status; list_installed_plugins ;;
        --help|-h) show_help ;;
        *) error "Invalid option: $1"; show_help; exit 1 ;;
    esac
}

main "$@"
