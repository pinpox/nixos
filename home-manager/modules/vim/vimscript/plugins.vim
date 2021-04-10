" Plugin options

" Switch
let g:switch_custom_definitions =
			\ [
			\   ['foo', 'bar', 'baz'],
			\   [ 'on', 'off'],
			\   ['_', '#'],
			\   ['LOW', 'HIGH']
			\ ]

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

let g:mapleader = "\<Space>"
let g:maplocalleader = ','
nnoremap <silent> <leader>      :<c-u>WhichKey '<Space>'<CR>
nnoremap <silent> <localleader> :<c-u>WhichKey ','<CR>

" packadd! vim-which-key " Needed so that vim-which-key functions are available here
call which_key#register('<Space>', 'g:which_key_map')

set inccommand=nosplit

