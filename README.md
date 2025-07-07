# My Ultimate Dotfiles 🚀

This repository contains my personal, portable, and highly-automated development environment setup. It's designed to be deployed on any new macOS or Linux machine with a single command, providing a consistent and efficient Zsh and Vim experience everywhere.

The entire setup is orchestrated by a single, intelligent installation script that handles everything from dependency installation to configuration management.

## ✨ Features

*   **Fully Automated Setup**: A single script handles everything from installing Zsh and Oh My Zsh to setting up Vim plugins and fonts.
*   **Portable & Idempotent**: The scripts are designed to run safely on both macOS and Linux, and can be re-run multiple times without causing issues.
*   **Smart Git Identity Management**: Automatically configures a primary (company) and a secondary (personal) Git identity, which is conditionally loaded based on project location.
*   **Productive Zsh Environment**: A clean, powerful, and visually informative Zsh prompt.
*   **IDE-like Vim Experience**: A lightweight yet powerful Vim setup that feels like a modern IDE.
*   **Clean & Reversible**: Includes a comprehensive uninstaller to revert all changes cleanly.

## 🚀 Quick Start: Installation

Setting up a new machine from scratch is as simple as running one script.

**Prerequisites:**
*   `git`
*   `curl`
*   `sudo` access (for installing packages and changing the default shell)

**Installation Steps:**

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/your-username/dotfiles.git
    ```

2.  **Navigate into the directory and run the installer:**
    ```bash
    cd dotfiles
    chmod +x install.sh && ./install.sh
    ```

3.  **Follow the prompts:**
    *   The script may ask for your `sudo` password to install dependencies like Zsh.
    *   You will be prompted to enter your personal Git name and email.

4.  **Log Out and Log Back In:** This is a **crucial final step** to make Zsh your new default shell.

That's it! You are now ready to work in your new, supercharged environment.

## 🛠️ Components & Features

This project is composed of several key components that work together seamlessly.

### 1. The Installer (`install.sh`)

This is the master script and the single entry point for setting up a new system. It automates the following sequence:
1.  **Installs Prerequisites**: Automatically installs `Zsh` and `Oh My Zsh` if they are not found.
2.  **Sets Default Shell**: Changes the user's default login shell to Zsh.
3.  **Configures Git**: Prompts for personal Git details and sets up the conditional configuration.
4.  **Creates Symlinks**: Links the `.zshrc` and `.vimrc` from this repository to your home directory, backing up any existing files.
5.  **Sets up Vim**: Installs `vim-plug` and all the plugins defined in `.vimrc`.
6.  **Runs Zsh Setup**: Executes the `setup_zsh_enhancements.sh` script to install fonts and Zsh plugins.

You can verify the entire installation at any time by running `./install.sh --verify`.

### 2. Zsh Setup (`.zshrc` & `setup_zsh_enhancements.sh`)

The Zsh environment is designed for maximum productivity and visual feedback.

*   **Powerline-style Prompt**:
    *   **Status Icons**: `✔` for success, `✘` for failure.
    *   **Conditional Hostname**: `user@hostname` segment only appears in SSH sessions.
    *   **Git Integration**: Shows the current branch with color-coded status (green for clean, red for dirty, orange for staged).
    *   **Truncated Path**: Shows only the name of the current directory.
    *   **Pyenv Support**: Displays the active Python virtualenv name on the far left.
*   **Essential Plugins**:
    *   `zsh-autosuggestions`: Fish-like command suggestions.
    *   `zsh-syntax-highlighting`: Real-time syntax highlighting.
    *   `you-should-use`: Suggests using aliases when you type the original command.
*   **Productivity Keymaps**:
    *   `Ctrl + Space` is mapped to accept autosuggestions.
*   **Automatic Font & Plugin Installation**: The `setup_zsh_enhancements.sh` script handles the automatic installation of the `MesloLGS NF` Nerd Font and all required custom Zsh plugins.

### 3. Vim Setup (`.vimrc`)

The Vim configuration transforms the editor into a modern, IDE-like experience, managed by `vim-plug`.

*   **Plugin-Powered Workflow**:
    *   **`vim-plug`**: A fast, parallel plugin manager. Install plugins with `:PlugInstall`.
    *   **`vim-fugitive`**: The ultimate Git wrapper for Vim (`:Gstatus`, `:Gdiff`, etc.).
    *   **`nerdtree`**: A tree-style file explorer, toggled with `,nt`.
    *   **`fzf.vim`**: A lightning-fast fuzzy file finder, triggered with `,p`.
*   **Core Productivity Hacks**:
    *   **Seamless Navigation**: Use `Ctrl + h/j/k/l` to move between Vim splits.
    *   **Line Movement**: Move lines up and down with `Alt + j/k` (`Option + j/k` on Mac).
    *   **Cleanliness**: Automatically removes trailing whitespace on save.
    *   **Persistence**: Remembers your last cursor position in every file.
*   **Modern Editing Experience**:
    *   Smart, 4-space soft tabs for consistent code formatting.
    *   Intelligent search (`smartcase`) and incremental search (`incsearch`).
    *   Full mouse support (`mouse=a`).
    *   A safe and convenient `Ctrl + Y` mapping to copy to the system clipboard.

## 💣 Uninstallation

To revert all changes made by the installer, simply run the `uninstall.sh` script from within the `dotfiles` directory.

```bash
./uninstall.sh
```
This will restore your previous shell, remove all created symlinks and configurations, and completely clean up the Oh My Zsh installation.
