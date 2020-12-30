" Switcch ; and :
nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;

" Remap the arrow keys to nothing
nnoremap <left> <nop>
nnoremap <right> <nop>
nnoremap <up> <nop>
nnoremap <down> <nop>

" Cycle buffers
nnoremap <C-N> :bnext<CR>
nnoremap <C-P> :bprev<CR>

" indent lines and reselect visual group
vnoremap < <gv
vnoremap > >gv

" move lines up and down
vnoremap <C-k> :m-2<CR>gv
vnoremap <C-j> :m '>+<CR>gv

" Overwrite with yanked text in visual mode
xnoremap p "_dP

" Use Q for playing q macro
noremap Q @q

" Switch common words like "false" and "true"
nnoremap <BS> :Switch<CR>

" Toggle the Tagbar
nnoremap <F9> :TagbarToggle<CR>

" Spell checking
nnoremap <F5> ]s
nnoremap <F6> 1z=
nnoremap <F7> z=
nnoremap <F8> :spellr<CR>

" Leader commands
let mapleader="\<Space>"

" open a file using fzf
nnoremap <leader>f :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>t :Vista finder<CR>
nnoremap <leader>v :e $MYVIMRC<CR>
nnoremap ' :CocList marks<CR>

" Terminal

let g:floaterm_keymap_toggle = '<Leader>t'

"toggle line wrapping
" nnoremap <leader>l :set wrap!<CR>
" nnoremap <leader>` :<CR>!<CR>
" nnoremap <leader>a ]sz=
