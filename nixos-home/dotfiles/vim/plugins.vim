call plug#begin('~/.vim/plugged')
Plug 'binaryplease/vim-gopher-syntax'
" Plug 'chrisbra/csv.vim'                                         " Csv filetype
" Plug 'christoomey/vim-tmux-navigator'                             " Seamless Tmux navigation
" Plug 'morhetz/gruvbox'
" Plug 'vimwiki/vimwiki'
" Plug 'zchee/deoplete-go'
" Plug 'nsf/gocode', { 'rtp': 'vim', 'do': '~/.vim/plugged/gocode/vim/symlink.sh' }
" Plug 'vim-pandoc/vim-pandoc'
" Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'rafalbromirski/vim-aurora'
" Plug 'vim-pandoc/vim-rmarkdown'
" Plug 'markonm/traces.vim'
" Plug 'benekastah/neomake'                                         " Linter/maker
" Plug 'davinche/godown-vim'
" Plug 'jiangmiao/auto-pairs'                                     " Auto-close brackets
" Plug 'rakr/vim-one'                         " Colorscheme
" Plug 'reewr/vim-monokai-phoenix'                                " Colortheme
Plug 'LnL7/vim-nix'
" Plug 'edkolev/tmuxline.vim'
" Plug 'tclem/vim-arduino'
" Plug 'vim-latex/vim-latex'
" Plug 'lukaszkorecki/workflowish'
" Plug 'Stautob/vim-fish'                                         " Fish shell syntac
Plug 'liuchengxu/vim-which-key'

Plug 'kovetskiy/sxhkd-vim'

" Latex
Plug 'lervag/vimtex', {'for': 'tex'}
Plug 'dracula/vim'
Plug 'xuhdev/vim-latex-live-preview', { 'for': 'tex' }            " Latex preview Plug
Plug 'nicwest/vim-camelsnek'

Plug 'ryanoasis/vim-devicons'


Plug 'rrethy/vim-illuminate'

" Colorschemes
" Plug 'jeffkreeftmeijer/vim-dim'
" Plug 'noahfrederick/vim-noctu'
" Plug 'evgenyzinoviev/vim-vendetta'
Plug 'chriskempson/base16-vim'                                    " Base16 colorschemes
" Plug 'mhartington/oceanic-next'
" Plug 'kristijanhusak/vim-hybrid-material'
" Plug 'liuchengxu/space-vim-theme'
Plug 'rakr/vim-one'

" Other appeareance
" Plug 'bluz71/vim-moonfly-statusline'
" Plug 'ap/vim-buftabline'                                        " Forget Vim tabs, now you can have buffer tabs
Plug 'vim-airline/vim-airline-themes'
Plug 'bling/vim-airline'                                        " Lean & mean status/tabline
" Plug 'bling/vim-bufferline'

Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }       " Colorize color definitions
Plug 'timakro/vim-searchant'                                    " Better highlighting of search

" Syntax and language specific
" TODO try out: sheerun/vim-polyglot " can replace python, i3, hastkell, vim-go
Plug 'OrangeT/vim-csharp', {'for': 'cs'}                        " Csharp syntax
Plug 'PotatoesMaster/i3-vim-syntax', {'for': 'i3'}              " I3-config syntax
Plug 'hdima/python-syntax', {'for': 'python'}
Plug 'neovimhaskell/haskell-vim', {'for': 'haskell'}
Plug 'jeroenbourgois/vim-actionscript', {'for': 'actionscript'} " Actionscript syntax
Plug 'buoto/gotests-vim'                         " Generate test for Go function in current line
Plug 'justinmk/vim-syntax-extra'
Plug 'stevearc/vim-arduino'
Plug 'pearofducks/ansible-vim'
Plug 'kana/vim-textobj-user' " Dependency for vim-textobj-between
Plug 'thinca/vim-textobj-between'     "Text objects for a range between a character
Plug 'fvictorio/vim-textobj-backticks' "Text object between backticks



Plug 'hashivim/vim-terraform'
Plug 'juliosueiras/vim-terraform-snippets'
" Completion and snippets
" "TODO
" Plug 'Shougo/deoplete.nvim', {'do': ':UpdateRemotePlugins'}       " Autocompletion
" Plug 'zchee/deoplete-clang'


" Plug 'neovim/nvim-lsp' 

" Plug 'autozimu/LanguageClient-neovim', {
"     \ 'branch': 'next',
"     \ 'do': 'bash install.sh',
"     \ }


" Plug 'thomasfaingnaert/vim-lsp-snippets'
" Plug 'thomasfaingnaert/vim-lsp-ultisnips'
" Plug 'lighttiger2505/deoplete-vim-lsp'
"
" Plug 'SirVer/ultisnips'                                           " Snippet engine
"
Plug 'fatih/vim-go'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Plug 'neoclide/coc-snippets', {'do': 'yarn install --frozen-lockfile'}
Plug 'honza/vim-snippets'                                         " Snippets



Plug 'voldikss/vim-floaterm'

" Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/async.vim'
" Plug 'prabirshrestha/vim-lsp'
" Plug 'mattn/vim-lsp-settings'
" Plug 'prabirshrestha/asyncomplete-lsp.vim'
" Plug 'prabirshrestha/asyncomplete-file.vim'
" Plug 'w0rp/ale'


Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } }

Plug 'Xuyuanp/scrollbar.nvim'

" Git
Plug 'airblade/vim-gitgutter'                                     " Shows a git diff in the gutter
Plug 'rhysd/committia.vim'                                        " Better commit message editor
Plug 'romainl/vim-sweet16'

" Markup
Plug 'godlygeek/tabular'                                          " The tabular plugin must come before vim-markdown
Plug 'plasticboy/vim-markdown'
Plug 'shime/vim-livedown'
Plug 'dhruvasagar/vim-table-mode', {'on': 'TableModeToggle'}      " Easy ascii tables

" Tags
Plug 'ludovicchabant/vim-gutentags'                               " Autognerate Tags
" Plug 'majutsushi/tagbar'                                          " Show Tagbar
" Plug 'lvht/tagbar-markdown'                                       " Tagbar support for markdown files
"
" Tagbar replacement
Plug 'liuchengxu/vista.vim'

" Vim text-objects
Plug 'michaeljsmith/vim-indent-object'                            " Indention based Textobject (dai, cai...)
" Plug 'tpope/vim-surround'                                         " Surround text-object
Plug 'machakann/vim-sandwich'

" Whitespace
Plug 'junegunn/vim-easy-align'
Plug 'ntpeters/vim-better-whitespace'                             " Hightlight all trailing whitespace in red
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'Yggdroot/indentLine'

" Other helpers
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' } " Fuzzy find everything
Plug 'junegunn/fzf.vim'
Plug 'jamessan/vim-gnupg', {'for': 'gpg'}                         " Edit ggp-encrypted files
Plug 'AndrewRadev/switch.vim'                                     " Switch segments of text with predefined replacements
Plug 'Chiel92/vim-autoformat'                                     " Autoformat files integrating existing code formatters
Plug 'vim-scripts/BufOnly.vim'                                    " Close all buffers except the current
Plug 'tpope/vim-commentary'                                       " Commenter
Plug 'tpope/vim-eunuch'                                           " Usefull shell comamnds as vim commands e.g. :SudoWrite
Plug 'tpope/vim-repeat'                                           " Repeat with dot for more actions
Plug 'tpope/vim-vinegar'                                          " Enhance netrw file browser
Plug 'triglav/vim-visual-increment'                               " Visually increment numbers
Plug 'rhysd/vim-grammarous'                                       " Grammar checking with languagetool

" Plug 'arzg/vim-colors-xcode'

Plug 'lifepillar/vim-colortemplate'

call plug#end()

" Plugin options

" Arduino
let g:arduino_programmer = 'arduino:avrispmkii'                   " arduino programmer
let g:arduino_dir = '/usr/share/arduino'
let g:arduino_args = '--verbose-upload'

" Markdown
let g:livedown_browser = "firefox"                                " the browser to use for preview

" Ultisnips
" let g:UltiSnipsExpandTrigger="<tab>"
" let g:UltiSnipsJumpForwardTrigger="<tab>"
" let g:UltiSnipsJumpBackwardTrigger="<s-tab>"

" Deoplete
" let g:deoplete#enable_at_startup = 1
" let g:deoplete#sources#clang#libclang_path = '/usr/lib/libclang.so'
" let g:deoplete#sources#clang#clang_header = '/usr/lib/clang'
" call deoplete#custom#source('ultisnips', 'matchers', ['matcher_fuzzy'])
" if !exists('g:deoplete#omni_patterns')
" 	let g:deoplete#omni_patterns = {}
" endif
" let g:deoplete#omni_patterns.tex =
" 			\ '\v\\%('
" 			\ . '\a*cite\a*%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
" 			\ . '|\a*ref%(\s*\{[^}]*|range\s*\{[^,}]*%(}\{)?)'
" 			\ . '|hyperref\s*\[[^]]*'
" 			\ . '|includegraphics\*?%(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
" 			\ . '|%(include%(only)?|input)\s*\{[^}]*'
" 			\ . ')\m'


" Ale
" let g:ale_linters ={
" \   'haskell': ['hlint', 'hdevtools', 'hfmt'],
" \}
let g:ale_sign_column_always = 1    "Keep the sign gutter open

" Neomake
" autocmd! BufWritePost * Neomake " run neomake on file save
" call neomake#configure#automake('nrwi', 500)
" Default file type for .tex files

" Fzf, show file preview
let g:fzf_files_options = '--preview "(coderay {} || cat {}) 2> /dev/null | head -'.&lines.'"'

" Switch
let g:switch_custom_definitions =
			\ [
			\   ['foo', 'bar', 'baz'],
			\   [ 'on', 'off'],
			\   ['_', '#'],
			\   ['LOW', 'HIGH']
			\ ]

let g:grammarous#disabled_rules = {
            \ '*' : ['WHITESPACE_RULE', 'EN_QUOTES'],
            \ 'help' : ['WHITESPACE_RULE', 'EN_QUOTES', 'SENTENCE_WHITESPACE', 'UPPERCASE_SENTENCE_START'],
            \ }

" set to 1, nvim will open the preview window after entering the markdown buffer
" default: 0
let g:mkdp_auto_start = 0


" specify browser to open preview page
let g:mkdp_browser = 'chromium'

let g:mkdp_echo_preview_url = 1

" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)



" disable vim-go :GoDef short cut (gd)
" this is handled by LanguageClient [LC]
let g:go_def_mapping_enabled = 0


" disable concellevel for markdown
let g:vim_markdown_conceal = 0


" Terraform options
let g:terraform_align=1
let g:terraform_fmt_on_save=1

