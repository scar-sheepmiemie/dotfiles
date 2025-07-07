" ============================================================================
" A solid, modern .vimrc configuration for macOS
" This file provides the "furnished" experience that Linux has by default.
" ============================================================================

" --- THE FIX: Explicitly turn on syntax highlighting ---
syntax on

" --- Enable filetype detection, required for syntax highlighting ---
filetype plugin indent on

" --- Highly Recommended UI Improvements ---
"set number             " Show line numbers
"set relativenumber     " Show relative line numbers
set cursorline         " Highlight the current line
set showmatch          " Highlight matching brackets
set ruler              " Always show cursor position

" --- Better Search ---
set incsearch          " Show search results as you type
set hlsearch           " Highlight all search results
"set ignorecase         " Ignore case when searching
"set smartcase          " ...unless the query contains an uppercase letter

" --- Modern Indentation ---
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent

" --- Mouse Support ---
set mouse=a
