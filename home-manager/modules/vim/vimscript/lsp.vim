"let g:lsp_signs_enabled = 1
"let g:lsp_signs_error = {'text': '✗'}
"let g:lsp_signs_warning = {'text': '‼'}
"let g:lsp_signs_hint = {'text': 'i'}

"let g:lsp_log_verbose = 1
"let g:lsp_log_file = expand('~/vim-lsp.log')

"" pip install python-language-server
"if executable('pyls')
"    au User lsp_setup call lsp#register_server({
"        \ 'name': 'pyls',
"        \ 'cmd': {server_info->['pyls']},
"        \ 'whitelist': ['python'],
"        \ })
"endif

"" go get -u golang.org/x/tools/cmd/gopls
"if executable('gopls')
"    au User lsp_setup call lsp#register_server({
"        \ 'name': 'gopls',
"        \ 'cmd': {server_info->['gopls', '-mode', 'stdio']},
"        \ 'whitelist': ['go'],
"        \ })
"    autocmd BufWritePre *.go LspDocumentFormatSync
"endif

"" go get -u github.com/sourcegraph/go-langserver
"if executable('go-langserver')
"    au User lsp_setup call lsp#register_server({
"        \ 'name': 'go-langserver',
"        \ 'cmd': {server_info->['go-langserver', '-gocodecompletion']},
"        \ 'whitelist': ['go'],
"        \ })
"    autocmd BufWritePre *.go LspDocumentFormatSync
"endif

"" mkdir -p ~/lsp/eclipse.jdt.ls
"" cd ~/lsp/eclipse.jdt.ls
"" curl -L https://download.eclipse.org/jdtls/milestones/0.35.0/jdt-language-server-0.35.0-201903142358.tar.gz -O
"" tar xf jdt-language-server-0.35.0-201903142358.tar.gz
"" edit config_linux
""
""if executable('java') && filereadable(expand('~/lsp/eclipse.jdt.ls/plugins/org.eclipse.equinox.launcher_1.5.300.v20190213-1655.jar'))
"    " au User lsp_setup call lsp#register_server({
"    "     \ 'name': 'eclipse.jdt.ls',
"    "     \ 'cmd': {server_info->[
"    "     \     'java',
"    "     \     '-Declipse.application=org.eclipse.jdt.ls.core.id1',
"    "     \     '-Dosgi.bundles.defaultStartLevel=4',
"    "     \     '-Declipse.product=org.eclipse.jdt.ls.core.product',
"    "     \     '-Dlog.level=ALL',
"    "     \     '-noverify',
"    "     \     '-Dfile.encoding=UTF-8',
"    "     \     '-Xmx1G',
"    "     \     '-jar',
"    "     \     expand('~/lsp/eclipse.jdt.ls/plugins/org.eclipse.equinox.launcher_1.5.300.v20190213-1655.jar'),
"    "     \     '-configuration',
"    "     \     expand('~/lsp/eclipse.jdt.ls/config_win'),
"    "     \     '-data',
"    "     \     getcwd()
"    "     \ ]},
"    "     \ 'whitelist': ['java'],
"    "     \ })
"" endif
" Tab completion
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr>    pumvisible() ? "\<C-y>" : "\<cr>"
" Force refresh completion
imap <c-space> <Plug>(asyncomplete_force_refresh)
" To enable preview window:

set completeopt+=preview
" To auto close preview window when completion is done.

autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

" Required for operations modifying multiple buffers like rename.
" set hidden

" let g:LanguageClient_serverCommands = {
"     \ 'python': ['/usr/local/bin/pyls'],
"     \ 'ruby': ['~/.rbenv/shims/solargraph', 'stdio'],
"     \ 'go': ['~/.go/bin/gopls'],
"     \ }

" nnoremap <F5> :call LanguageClient_contextMenu()<CR>
