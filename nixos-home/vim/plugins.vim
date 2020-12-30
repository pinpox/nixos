
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




" autocmd! User vim-which-key call which_key#register('<Space>', 'g:which_key_map')
" nnoremap <silent> <leader> :WhichKey '<Space>'<CR>

" autocmd! FileType which_key
" autocmd  FileType which_key set laststatus=0 noshowmode noruler
" 			\| autocmd BufLeave <buffer> set laststatus=2 showmode ruler



" nnoremap <silent> <leader> :<c-u>WhichKey '<Space>'<CR>
" vnoremap <silent> <leader> :<c-u>WhichKeyVisual '<Space>'<CR>

let g:which_key_map =  {}

" Set timeout, e.g. used in whichkey
set timeoutlen=500

let g:which_key_map.g = {
			\ 'name' : '+GOTO',
			\ 'd' : ['<Plug>(coc-definition)'      , 'Definition'],
			\ 'y' : ['<Plug>(coc-type-difinition)' , 'Type definiton'],
			\ 'i' : ['<Plug>(coc-implementation)'  , 'Implementation'],
			\ 'r' : ['<Plug>(coc-references)'      , 'References'],
			\}

let g:which_key_map.l = {
			\ 'name' : '+LSP',
			\ 'f' : ['<Plug>(coc-format-selected)' , 'Autoformat'],
			\ 'R' : ['<Plug>(coc-references)'      , 'References'],
			\ 'r' : ['<Plug>(coc-rename)'          , 'Rename'],
			\ 'a' : ['<Plug>(coc-codeaction)'      , 'Code action'],
			\ 'F' : ['<Plug>(coc-fix-current)'     , 'Fix automatically'],
			\ 'o' : [':CocList outline'            , 'Code outline'],
			\ 's' : [':CocList -I symbols'         , 'Symbols'],
			\ 'd' : [':CocList dignostics'         , 'Diagnostics'],
			\ 'e' : [':CocList extensions'         , 'Extensions'],
			\ 'c' : [':CocList commands'           , 'Commands'],
			\ 'b' : ['<Plug>(coc-bookmark-toggle)' , 'Toggle bookmark'],
			\ }

let g:which_key_map['w'] = {
			\ 'name' : '+windows' ,
			\ 'w' : ['<C-W>w'     , 'other-window']          ,
			\ 'd' : ['<C-W>c'     , 'delete-window']         ,
			\ '-' : ['<C-W>s'     , 'split-window-below']    ,
			\ '|' : ['<C-W>v'     , 'split-window-right']    ,
			\ '2' : ['<C-W>v'     , 'layout-double-columns'] ,
			\ 'h' : ['<C-W>h'     , 'window-left']           ,
			\ 'j' : ['<C-W>j'     , 'window-below']          ,
			\ 'l' : ['<C-W>l'     , 'window-right']          ,
			\ 'k' : ['<C-W>k'     , 'window-up']             ,
			\ 'H' : ['<C-W>5<'    , 'expand-window-left']    ,
			\ 'J' : [':resize +5' , 'expand-window-below']   ,
			\ 'L' : ['<C-W>5>'    , 'expand-window-right']   ,
			\ 'K' : [':resize -5' , 'expand-window-up']      ,
			\ '=' : ['<C-W>='     , 'balance-window']        ,
			\ 's' : ['<C-W>s'     , 'split-window-below']    ,
			\ 'v' : ['<C-W>v'     , 'split-window-below']    ,
			\ '?' : ['Windows'    , 'fzf-window']            ,
			\ }


nnoremap <silent> <leader>oq  :copen<CR>
nnoremap <silent> <leader>ol  :lopen<CR>
let g:which_key_map.o = {
      \ 'name' : '+open',
      \ 'q' : 'open-quickfix'    ,
      \ 'l' : 'open-locationlist',
      \ }

let g:mapleader = "\<Space>"
let g:maplocalleader = ','
nnoremap <silent> <leader>      :<c-u>WhichKey '<Space>'<CR>
nnoremap <silent> <localleader> :<c-u>WhichKey ','<CR>


packadd! vim-which-key " Needed so that vim-which-key functions are available here
call which_key#register('<Space>', 'g:which_key_map')

set inccommand=nosplit

