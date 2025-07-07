#!/bin/bash

# ==============================================================================
# Zsh Enhancement Manager v12 by CircuIT
#
# This definitive version correctly installs ALL required custom plugins,
# including 'zsh-you-should-use', and is formatted for readability.
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
            if command -v apt-get &> /dev/null; then info "To install it, run: sudo apt-get install -y $(dpkg -S /usr/bin/$cmd | cut -d: -f1)";
            elif command -v dnf &> /dev/null; then info "To install it, run: sudo dnf install -y /usr/bin/$cmd";
            else warn "Could not detect package manager. Please install '$cmd' manually."; fi
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
            if brew list --cask "$FONT_CASK" &> /dev/null; then
                success "Font '$FONT_CASK' is already installed. Skipping."
            else
                info "Installing font: $FONT_CASK..."
                brew install --cask "$FONT_CASK"
                success "Font '$FONT_CASK' installed successfully."
            fi
            ;;
        Linux)
            check_dependencies curl unzip fc-cache
            local FONT_DIR="$HOME/.local/share/fonts"
            if ls "$FONT_DIR"/MesloLGS*Regular*.ttf &> /dev/null; then
                success "A MesloLGS Regular Nerd Font file already exists. Skipping download."
            else
                info "Downloading and installing 'MesloLGS NF'..."
                local FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
                local TEMP_DIR
                TEMP_DIR=$(mktemp -d)
                curl -fsSL "$FONT_URL" -o "$TEMP_DIR/Meslo.zip"
                unzip -o "$TEMP_DIR/Meslo.zip" -d "$TEMP_DIR/MesloFonts" > /dev/null
                mkdir -p "$FONT_DIR"
                find "$TEMP_DIR/MesloFonts" -name "*.ttf" -exec mv {} "$FONT_DIR/" \;
                rm -rf "$TEMP_DIR"
                success "Font files downloaded and moved successfully."
            fi
            info "Reloading system font cache..."
            fc-cache -fv
            success "Font cache reloaded."
            ;;
        *)
            warn "Unsupported OS: $(uname -s). Font installation skipped."
            ;;
    esac
}

install_zsh_plugins() {
    info "--- Starting Zsh Plugin Installation ---"
    check_dependencies git
    local ZSH_CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    mkdir -p "$ZSH_CUSTOM_PLUGINS_DIR"

    local plugins_to_install=(
        "https://github.com/zsh-users/zsh-autosuggestions"
        "https://github.com/zsh-users/zsh-syntax-highlighting.git"
        "https://github.com/MichaelAquilina/zsh-you-should-use.git"
    )

    for plugin_url in "${plugins_to_install[@]}"; do
        local plugin_name
        plugin_name=$(basename "$plugin_url" .git)
        local target_dir_name="$plugin_name"

        # Handle the special case for zsh-you-should-use
        if [[ "$plugin_name" == "zsh-you-should-use" ]]; then
            target_dir_name="you-should-use"
        fi

        local plugin_dir="$ZSH_CUSTOM_PLUGINS_DIR/$target_dir_name"

        if [ -d "$plugin_dir" ]; then
            success "Plugin '$target_dir_name' is already installed. Skipping."
        else
            info "Cloning '$target_dir_name' from $plugin_url..."
            git clone -q "$plugin_url" "$plugin_dir"
            success "Plugin '$target_dir_name' installed."
        fi
    done
}

check_font_status() {
    info "--- Verifying Font Installation ---"
    case "$(uname -s)" in
        Linux)
            local FONT_DIR="$HOME/.local/share/fonts"
            if ls "$FONT_DIR"/MesloLGS*Regular*.ttf &> /dev/null; then
                success "   [✔] MesloLGS Nerd Font file found."
            else
                error "   [✘] MesloLGS Nerd Font file not found in '$FONT_DIR'."
            fi
            ;;
        Darwin)
            if brew list --cask font-meslo-lg-nerd-font &> /dev/null; then
                 success "   [✔] Font cask 'font-meslo-lg-nerd-font' is installed via Homebrew."
            else
                 error "   [✘] Font cask 'font-meslo-lg-nerd-font' is not installed."
            fi
            ;;
    esac
}

verify_plugins() {
    info "--- Verifying Custom Plugin Installation ---"
    local ZSH_CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    [ -d "$ZSH_CUSTOM_PLUGINS_DIR/zsh-autosuggestions" ] && success "   [✔] zsh-autosuggestions found." || error "   [✘] zsh-autosuggestions missing."
    [ -d "$ZSH_CUSTOM_PLUGINS_DIR/zsh-syntax-highlighting" ] && success "   [✔] zsh-syntax-highlighting found." || error "   [✘] zsh-syntax-highlighting missing."
    [ -d "$ZSH_CUSTOM_PLUGINS_DIR/you-should-use" ] && success "   [✔] you-should-use found." || error "   [✘] you-should-use missing."
}

# --- Main Execution Logic ---
main() {
    info "Starting Zsh enhancement setup..."
    install_fonts
    install_zsh_plugins
    success "All Zsh enhancement tasks completed!"
}

verify() {
    info "==================== ZSH ENHANCEMENT VERIFICATION ===================="
    check_font_status
    verify_plugins
    echo "--------------------------------------------------------------------"
}

# --- Argument Parsing ---
if [ "$1" == "--verify" ]; then
    verify
else
    main
fi
