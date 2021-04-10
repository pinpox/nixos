" Display extra whitespace, show tabs as bar (indent-guides)
set listchars=tab:\|\ ,trail:·,nbsp:·
set list

set conceallevel=0

" Use true color, if possible
if (empty($TMUX))
	if (has("nvim"))
		let $NVIM_TUI_ENABLE_TRUE_COLOR=1
	endif
	if (has("termguicolors"))
		set termguicolors
	endif
endif
syntax on

set background=dark

" set ansible-generated colorscheme
let base16colorspace=256
colorscheme ansible-theme
" colorscheme noctu

" Italic comments
highlight Comment cterm=italic gui=italic

" Make background transparent
" highlight Normal guibg=none

" Airline
" let g:airline#extensions#ale#enabled = 1
" let g:airline_powerline_fonts = 0
let g:airline_theme='base16'
let g:airline_symbols = {}
let g:airline_symbols.linenr = 'ℓ'
let g:airline#extensions#tabline#enabled = 1

let g:airline#extensions#nvimlsp#enabled = 0


set noshowmode " dont show the current mode below the bar
" let g:airline#extensions#tabline#left_sep = ' '
" let g:airline#extensions#tabline#left_alt_sep = '|'

" Color max line length of 100
let &colorcolumn=join(range(101,999),",")

let g:buftabline_indicators=1


let g:moonflyWithCocIndicator = 1
set cmdheight=1

" set statusline=%F%m%r%h%w[%L][%{&ff}]%y[%p%%][%04l,%04v]
"              | | | | |  |   |      |  |     |    |
"              | | | | |  |   |      |  |     |    +-- current column
"              | | | | |  |   |      |  |     +-- current line
"              | | | | |  |   |      |  +-- current % into file
"              | | | | |  |   |      +-- current syntax
"              | | | | |  |   +-- current fileformat
"              | | | | |  +-- number of lines
"              | | | | +-- preview flag in square brackets
"              | | | +-- help flag in square brackets
"              | | +-- readonly flag in square brackets
"              | +-- rodified flag in square brackets
"              +-- full path to file in the buffer
" Customize fzf colors to match your color scheme
" - fzf#wrap translates this to a set of `--color` options
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Include'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }
