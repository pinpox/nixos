filetype plugin indent on
set hidden                     " Buffer becomes hidden when it is abandoned but is not unloaded
set title                      " Show title in terminal window
set autochdir                  " Automatically change the working dir to the one of the file
set autoindent                 " always set autoindenting on
set backspace=indent,eol,start " allow backspacing over everything in insert mode
set clipboard=unnamedplus      " Set Clipboard to system's clipboard
set cursorline                 " highlight current line
set directory=~/.vimtmp        " Dir for temp files
set foldlevelstart=20          " start with open folds
set foldmethod=syntax          " set folding based on syntax
set history=50                 " keep 50 lines of command line history
set hlsearch                   " highlight matches
set ignorecase                 " Case insensitive search
set incsearch                  " search as characters are entered
set laststatus=2               " Always show the status line
set lazyredraw                 " redraw only when we need to.
set nobackup                   " dont create backups
set noswapfile                 " dont create a swapfile
set relativenumber             " show relative line numbers
set number                     " show absolute line numbers
set ruler                      " show the cursor position all the time
set scrolloff=5                " show lines above and below when scrolling
set showcmd                    " display incomplete commands
set smartcase                  " Case sensitive then capital is typed
set synmaxcol=200              " Maximum length of syntax highlighting
set tabstop=4                  " A tab is displayed 4 collumns wide
set softtabstop=4              " Size of a tab
set shiftwidth=4               " Size of a tab
set noexpandtab                " Don't expand tabs to spaces
set undofile                   " Maintain undo history between sessions
set undodir=~/.vimtmp          " Dir for undofiles, same dir as the tempdir
set wildmenu                   " Complete commands
set wrapscan                   " Wrap when searching to beginning
set mouse=a
set path+=**                   " Search down into subfolders, provides tab-completion for all file-related tasks
syntax enable                  " enable syntax highlighting
set conceallevel=0             " Don't ever hide stuff from me



" let g:go_auto_type_info = 1 "Show Go type info of variables
au FileType xml setlocal equalprg=xmllint\ --format\ --recover\ -\ 2>/dev/null "autoindent xml correctly
au BufRead,BufNewFile *.md setlocal textwidth=80 " Wrap markdown files to 80 chars per line
let g:tex_flavor = "latex"

" Cursor to last know position
if has("autocmd")
	autocmd BufReadPost *
				\ if line("'\"") > 1 && line("'\"") <= line("$") |
				\   exe "normal! g`\"" |
				\ endif
endif


