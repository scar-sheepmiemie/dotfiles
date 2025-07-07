#!/bin/bash

# ==============================================================================
# Dotfiles Uninstaller v3 by CircuIT
#
# This version performs a complete cleanup, including removing the
# ~/.oh-my-zsh directory and its related backup files.
# ==============================================================================

set -e

# --- Configuration & Helpers ---
FILES_TO_UNLINK=(".zshrc" ".vimrc")
COLOR_YELLOW='\033[0;33m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'
info() { echo -e "${COLOR_YELLOW}[INFO]${COLOR_RESET} $1"; }
danger() { echo -e "${COLOR_RED}[DANGER]${COLOR_RESET} $1"; }

# --- Uninstallation Functions ---

restore_shell() {
    info "--- Reverting default shell to Bash ---"
    if ! command -v bash &> /dev/null; then danger "Could not find 'bash'. Skipping."; return; fi
    local bash_path; bash_path=$(which bash)
    local current_login_shell; current_login_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [ "$current_login_shell" != "$bash_path" ]; then
        danger "This will change your default shell back to Bash (requires sudo)."
        sudo chsh -s "$bash_path" "$USER"
    else info "Default login shell is already Bash."; fi
}

remove_symlinks_and_restore_backups() {
    info "--- Removing symlinks and restoring backups ---"
    for file in "${FILES_TO_UNLINK[@]}"; do
        local dest_file="$HOME/$file"
        local backup_file="${dest_file}.bak"
        if [ -L "$dest_file" ]; then
            info "Removing symlink: $dest_file"
            rm "$dest_file"
            if [ -f "$backup_file" ]; then
                info "Restoring backup: $backup_file -> $dest_file"
                mv "$backup_file" "$dest_file"
            fi
        else info "No symlink found for $file. Skipping."; fi
    done
}

cleanup_git_config() {
    info "--- Cleaning up Git configurations ---"
    if [ -f "$HOME/.gitconfig-personal" ]; then
        info "Removing personal Git config: ~/.gitconfig-personal"
        rm "$HOME/.gitconfig-personal"
    fi
    if [ -f "$HOME/.gitconfig" ]; then
        info "Removing conditional include rule from ~/.gitconfig..."
        sed -i.bak '/\[includeIf "gitdir:.*\/workspace\/personal\/"\]/,/path = ~\/\.gitconfig-personal/d' "$HOME/.gitconfig"
        sed -i.bak '/^$/N;/^\n$/D' "$HOME/.gitconfig"
        rm "${HOME}/.gitconfig.bak"
    fi
}

# --- THIS IS THE NEW CLEANUP FUNCTION ---
cleanup_oh_my_zsh() {
    info "--- Performing full Oh My Zsh cleanup ---"
    if [ -d "$HOME/.oh-my-zsh" ]; then
        danger "Removing Oh My Zsh directory: ~/.oh-my-zsh"
        rm -rf "$HOME/.oh-my-zsh"
    fi
    if [ -f "$HOME/.zshrc.pre-oh-my-zsh" ]; then
        danger "Removing Oh My Zsh backup file: ~/.zshrc.pre-oh-my-zsh"
        rm "$HOME/.zshrc.pre-oh-my-zsh"
    fi
}

# --- Main Execution ---
main() {
    danger "This script will COMPLETELY undo the dotfiles setup."
    read -p "Are you absolutely sure? Type 'yes': " response
    if [ "$response" != "yes" ]; then info "Uninstallation cancelled."; exit 0; fi

    restore_shell
    remove_symlinks_and_restore_backups
    cleanup_git_config
    cleanup_oh_my_zsh # <-- New, thorough cleanup step

    info ""; info "Uninstallation complete. Please log out and log back in."
}

main
