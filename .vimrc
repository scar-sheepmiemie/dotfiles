" ============================================================================
" The Ultimate .vimrc v3 - Minimalist Pro by CircuIT
" - Removed vim-airline for a native, clean statusline.
" - Added a convenient keymap for copying to the system clipboard.
" ============================================================================

" --- Plugin Management (vim-plug) ---
call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-fugitive'                 " Git integration
Plug 'scrooloose/nerdtree'               " File explorer
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } } " Fuzzy finder core
Plug 'junegunn/fzf.vim'                  " Fuzzy finder integration
call plug#end()


" --- Core Behavior ---
syntax on
filetype plugin indent on
set encoding=utf-8
set history=500
set autoread
set hid

" --- UI & Visuals ---
"set number
"set relativenumber
set cursorline
set showmatch
set ruler
set laststatus=2            " Always show statusline
set wildmenu                " Enhanced command-line completion
set scrolloff=8             " Keep 8 lines of context around the cursor
set cmdheight=1             " Back to 1, since we don't have a fancy statusline
set noerrorbells novisualbell

" --- Search ---
"set incsearch hlsearch ignorecase smartcase
set incsearch hlsearch

" --- Indentation (4-space soft tabs) ---
set tabstop=4 softtabstop=4 shiftwidth=4 expandtab
set autoindent smartindent

" --- Editing & Usability ---
set mouse=a
set backspace=indent,eol,start
set whichwrap+=<,>,h,l
set wrap
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store,*.o,*.pyc

" --- Key Mappings ---
let mapleader = ","

" High-Frequency Actions
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
command! W w !sudo tee % > /dev/null
nnoremap <silent> <leader><cr> :noh<CR>
nnoremap <leader>pp :setlocal paste!<CR>
vnoremap <leader>y "+y " <-- NEW: Copy to system clipboard

" Window Navigation
nnoremap <C-j> <C-W>j
nnoremap <C-k> <C-W>k
nnoremap <C-h> <C-W>h
nnoremap <C-l> <C-W>l

" Line Movement
nnoremap <M-j> :m+<CR>
nnoremap <M-k> :m-2<CR>
vmap <M-j> :m'>+<CR>gv
vmap <M-k> :m'<-2<CR>gv

" Buffer Navigation
nnoremap <leader>l :bnext<CR>
nnoremap <leader>h :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

" Plugin Mappings
nnoremap <leader>nt :NERDTreeToggle<CR>
nnoremap <leader>p :Files<CR>

" --- File Management ---
set backupdir=~/.vim/backup
set directory=~/.vim/swap
if !isdirectory(&backupdir) | call mkdir(&backupdir, "p") | endif
if !isdirectory(&directory) | call mkdir(&directory, "p") | endif
set backup
set swapfile

" --- Auto Commands ---
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
autocmd BufWritePre *.txt,*.js,*.py,*.sh,*.java,*.c,*.cpp :call CleanExtraSpaces()

" --- Helper Functions ---
function! CleanExtraSpaces()
    let save_cursor = getpos(".")
    let old_query = getreg('/')
    silent! %s/\s\+$//e
    call setpos('.', save_cursor)
    call setreg('/', old_query)
endfunction
