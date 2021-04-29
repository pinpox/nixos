" Plugin options

" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)


" disable concellevel for markdown
let g:vim_markdown_conceal = 0

" Terraform options
let g:terraform_align=1
let g:terraform_fmt_on_save=1

" Set timeout, e.g. used in whichkey
set timeoutlen=500

let g:mapleader      = "\<Space>"
let g:maplocalleader = ','
nnoremap <silent> <leader>      :<c-u>WhichKey '<Space>'<CR>
nnoremap <silent> <localleader> :<c-u>WhichKey ','<CR>

" packadd! vim-which-key " Needed so that vim-which-key functions are available here
" call which_key#register('<Space>', 'g:which_key_map')

set inccommand=nosplit


" NETRW.VIM

let g:netrw_banner=0                           " disable annoying banner
let g:netrw_browse_split=4                     " open in prior window
let g:netrw_altv=1                             " open splits to the right
let g:netrw_liststyle=3                        " tree view
let g:netrw_list_hide=netrw_gitignore#Hide()
let g:netrw_list_hide.=',\(^\|\s\s\)\zs\.\S\+'


" STYLE.VIM

" Display extra whitespace, show tabs as bar (indent-guides)
" set listchars=trail:·,nbsp:·
set listchars=tab:\│\ ,trail:·,nbsp:·
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

set noshowmode " dont show the current mode below the bar
" let g:airline#extensions#tabline#left_sep = ' '
" let g:airline#extensions#tabline#left_alt_sep = '|'

" Color characters on lines exceeding length of 100
match CursorLine /\%>100c/
" let &colorcolumn=join(range(101,999),",")

let g:buftabline_indicators=1

set cmdheight=1

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
