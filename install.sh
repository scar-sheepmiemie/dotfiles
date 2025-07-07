#!/bin/bash

# ==============================================================================
# The Ultimate Dotfiles Installer v13 by CircuIT
#
# This is the definitive, fully-automated, and readable version. It handles
# all prerequisites, configurations, and verifications.
# ==============================================================================

set -e

# --- Configuration ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
FILES_TO_LINK=(
  ".zshrc"
  ".vimrc"
)
# --------------------

# --- Color Definitions & Helper Functions ---
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'
info() { echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"; }
success() { echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"; }
warn() { echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"; }
error() { echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"; }

# --- Setup Functions ---

install_prerequisites() {
    info "--- Step 1: Installing Core Prerequisites ---"

    if ! command -v git &> /dev/null || ! command -v curl &> /dev/null; then
        error "Git and Curl are required. Please install them first."
        exit 1
    fi

    if ! command -v zsh &> /dev/null; then
        warn "Zsh not found. Attempting to install with sudo..."
        if command -v sudo &> /dev/null; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y zsh
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y zsh
            else
                error "Cannot determine package manager. Please install Zsh manually."
                exit 1
            fi
        else
            error "sudo not found. Cannot install Zsh. Please install it manually."
            exit 1
        fi
    fi
    success "Zsh is installed."

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        warn "Oh My Zsh not found. Installing automatically..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    if [ -d "$HOME/.oh-my-zsh" ] && [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        success "Oh My Zsh installation verified."
    else
        error "FATAL: Oh My Zsh installation failed or is incomplete."
        exit 1
    fi
}

set_default_shell() {
    info "--- Step 2: Setting Zsh as the default shell ---"
    local zsh_path
    zsh_path=$(which zsh)

    if [[ "$SHELL" != *zsh* ]]; then
        warn "Default shell is not Zsh. Attempting to change it (requires sudo)..."
        sudo chsh -s "$zsh_path" "$USER"
        success "Default shell change command executed."
    else
        success "Default shell is already Zsh."
    fi
}

setup_personal_git_config() {
    info "--- Step 3: Setting up personal Git config ---"
    if [ -f "$HOME/.gitconfig-personal" ]; then
        success "Personal Git config already exists. Skipping."
        return
    fi
    info "Please provide your PERSONAL Git identity."
    read -p "Enter your personal Git name: " git_name
    read -p "Enter your personal Git email: " git_email
    echo -e "[user]\n    name = $git_name\n    email = $git_email" > "$HOME/.gitconfig-personal"
    success "Created ~/.gitconfig-personal."
}

create_symlinks() {
    info "--- Step 4: Creating symbolic links ---"
    for file in "${FILES_TO_LINK[@]}"; do
        local source_file="$SCRIPT_DIR/$file"
        local dest_file="$HOME/$file"
        if [ -L "$dest_file" ] && [ "$(readlink "$dest_file")" = "$source_file" ]; then
            success "Link for $file already correct."
        else
            if [ -e "$dest_file" ]; then
                mv "$dest_file" "${dest_file}.bak"
            fi
            ln -s "$source_file" "$dest_file"
            success "Link for $file created."
        fi
    done
}

setup_global_git_config() {
    info "--- Step 5: Configuring global ~/.gitconfig ---"
    local global_config="$HOME/.gitconfig"
    if [ ! -f "$global_config" ]; then
        warn "Global ~/.gitconfig not found. Creating a minimal one."
        echo -e "[user]\n\n# Please configure your primary identity here." > "$global_config"
    fi
    if grep -q "path = ~/.gitconfig-personal" "$global_config"; then
        success "Conditional include rule already exists."
    else
        info "Appending conditional include rule..."
        echo "" >> "$global_config"
        cat "$SCRIPT_DIR/.gitconfig-include-personal" >> "$global_config"
        success "Successfully added conditional include rule."
    fi
}

setup_vim() {
    info "--- Step 6: Setting up Vim and plugins ---"
    local plug_vim="$HOME/.vim/autoload/plug.vim"
    if [ -f "$plug_vim" ]; then
        success "vim-plug is already installed."
    else
        info "Installing vim-plug..."
        curl -fLo "$plug_vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
    info "Installing Vim plugins..."
    vim +PlugInstall +qall
    success "Vim setup complete."
}

setup_zsh_enhancements() {
    info "--- Step 7: Setting up Zsh enhancements (fonts & plugins) ---"
    local zsh_setup_script="$SCRIPT_DIR/setup_zsh_enhancements.sh"
    if [ -f "$zsh_setup_script" ]; then
        chmod +x "$zsh_setup_script"
        "$zsh_setup_script" --install
    else
        warn "Zsh enhancement script not found."
    fi
}

main() {
    install_prerequisites
    set_default_shell
    setup_personal_git_config
    create_symlinks
    setup_global_git_config
    setup_vim
    setup_zsh_enhancements
    echo
    success "================ SETUP COMPLETE! ================"
    info "To verify, run: bash $SCRIPT_DIR/install.sh --verify"
    error "ACTION REQUIRED: Please LOG OUT and LOG BACK IN for all changes to take effect."
}

verify_installation() {
    info "==================== VERIFICATION CHECKLIST ===================="
    local all_ok=true
    info "1. Checking for personal Git config..."
    if [ -f "$HOME/.gitconfig-personal" ]; then success "   [✔] Found ~/.gitconfig-personal"; else error "   [✘] Missing ~/.gitconfig-personal"; all_ok=false; fi
    info "2. Checking for global Git config...";
    if [ -f "$HOME/.gitconfig" ]; then success "   [✔] Found ~/.gitconfig"; else error "   [✘] Missing ~/.gitconfig"; all_ok=false; fi
    info "3. Checking for Git conditional include...";
    if grep -q "path = ~/.gitconfig-personal" "$HOME/.gitconfig"; then success "   [✔] Found conditional include rule."; else error "   [✘] Missing conditional include rule."; all_ok=false; fi
    info "4. Checking for symbolic links...";
    for file in "${FILES_TO_LINK[@]}"; do
        if [ -L "$HOME/$file" ]; then success "   [✔] Link for $file exists."; else error "   [✘] Link for $file is missing."; all_ok=false; fi
    done
    info "5. Checking for vim-plug...";
    if [ -f "$HOME/.vim/autoload/plug.vim" ]; then success "   [✔] Found vim-plug."; else error "   [✘] vim-plug is not installed."; all_ok=false; fi
    info "6. Verifying Zsh setup...";
    "$SCRIPT_DIR/setup_zsh_enhancements.sh" --verify | sed 's/^/   /';
    echo "--------------------------------------------------------------"
    if [ "$all_ok" = true ]; then success "All checks passed!"; else error "Some checks failed."; fi
}

if [ "$1" == "--verify" ]; then
    verify_installation
else
    main
fi
