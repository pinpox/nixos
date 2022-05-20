call wilder#setup({'modes': [':', '/', '?']})

call wilder#set_option('renderer', wilder#popupmenu_renderer(wilder#popupmenu_border_theme({
      \ 'highlighter': wilder#basic_highlighter(),
	  \ 'highlights': {
	  \    'default': 'WilderDefault',
      \    'accent': 'WilderAccent',
      \    'selected': 'WilderSelected',
      \    'error': 'WilderError',
      \    'separator': 'WilderSeparator',
      \    'border': 'WilderBorder',
	  \ },
      \ 'left': [
      \   ' ', wilder#popupmenu_devicons(),
      \ ],
      \ 'right': [
      \   ' ', wilder#popupmenu_scrollbar(),
      \ ],
      \ 'min_width': '100%',
      \ 'max_height': '30%',
	  \ 'border': 'rounded',
      \ 'reverse': 0,
      \ })))

