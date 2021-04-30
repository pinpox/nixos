-- Name:         Onebuddy
-- Description:  Light and dark atom one theme
-- Author:       Th3Whit3Wolf <the.white.wolf.is.1337@gmail.com>
-- Maintainer:   Th3Whit3Wolf <the.white.wolf.is.1337@gmail.com>
-- Website:      httpc.//github.com/Th3Whit3Wolf/onebuddy
-- License:      MIT
local Color, c, Group, g, s = require("colorbuddy").setup()
local b = s.bold
local i = s.italic
local n = s.inverse
local uc = s.undercurl
local ul = s.underline
local r = s.reverse
local sto = s.standout
local no = s.NONE
local v = vim


Color.new('base00', "#2E3440")
Color.new('base01', "#3B4252")
Color.new('base02', "#434C5E")
Color.new('base03', "#4C566A")
Color.new('base04', "#D8DEE9")
Color.new('base05', "#E5E9F0")
Color.new('base06', "#ECEFF4")
Color.new('base07', "#8FBCBB") -- #55D1B4
Color.new('base08', "#F07178")
Color.new('base09', "#F78C6C")
Color.new('base0A', "#FFCB6B")
Color.new('base0B', "#C3E88D")
Color.new('base0C', "#89DDFF")
Color.new('base0D', "#82AAFF")
Color.new('base0E', "#C792EA")
Color.new('base0F', "#FF5370")

v.g.colors_name = 'generated'

Color.new('special_grey',  "#3b4048")
Color.new('visual_grey',   "#3e4452")
Color.new('syntax_gutter', "#636d83")
Color.new('syntax_cursor', "#2c323c")
Color.new('pmenu',         "#333841")

-------------------------
-- Vim Primary Colors --
-------------------------
Color.new('Red',         "#e88388")
Color.new('DarkRed',     "#e06c75")
Color.new('Blue',        "#61afef")
Color.new('DarkBlue',    "#528bff")
Color.new('Green',       "#98c379")
Color.new('DarkGreen',   "#50a14f")
Color.new('Orange',      "#d19a66")
Color.new('DarkOrange',  "#c18401")
Color.new('Yellow',      "#e5c07b")
Color.new('DarkYellow',  "#986801")
Color.new('Purple',      "#a626a4")
Color.new('Violet',      '#b294bb')
Color.new('Magenta',     '#ff80ff')
Color.new('DarkMagenta', '#a626a4')
Color.new('Black',       "#333841")
Color.new('Grey',        "#636d83")
Color.new('White',       '#f2e5bc')
Color.new('Cyan',        '#8abeb7')
Color.new('DarkCyan',    '#80a0ff')
Color.new('Aqua',        '#8ec07c')
Color.new('pink',        "#d291e4")

-------------------------
-- Vim Terminal Colors --
-------------------------

v.g.terminal_color_0  = "#353a44"
v.g.terminal_color_8  = "#353a44"
v.g.terminal_color_1  = "#e88388"
v.g.terminal_color_9  = "#e88388"
v.g.terminal_color_2  = "#a7cc8c"
v.g.terminal_color_10 = "#a7cc8c"
v.g.terminal_color_3  = "#ebca8d"
v.g.terminal_color_11 = "#ebca8d"
v.g.terminal_color_4  = "#72bef2"
v.g.terminal_color_12 = "#72bef2"
v.g.terminal_color_5  = "#d291e4"
v.g.terminal_color_13 = "#d291e4"
v.g.terminal_color_6  = "#65c2cd"
v.g.terminal_color_14 = "#65c2cd"
v.g.terminal_color_7  = "#e3e5e9"
v.g.terminal_color_15 = "#e3e5e9"

----------------------
-- Vim Editor Color --
----------------------

Group.new('Normal',       c.base05,       c.base00,        no)
Group.new('bold',         c.none,         c.none,          b)
Group.new('ColorColumn',  c.none,         c.syntax_cursor, no)
Group.new('Conceal',      c.base03,       c.base00,        no)
Group.new('Cursor',       c.none,         c.base0C,        no)
Group.new('CursorIM',     c.none,         c.none,          no)
Group.new('CursorColumn', c.none,         c.syntax_cursor, no)
Group.new('CursorLine',   c.none,         c.syntax_cursor, no)
Group.new('Directory',    c.base0C,       c.none,          no)
Group.new('ErrorMsg',     c.base08,       c.none,          no)
Group.new('VertSplit',    c.base0D,       c.none,          no)
Group.new('Folded',       c.base02,       c.none,          no)
Group.new('FoldColumn',   c.base02,       c.syntax_cursor, no)
Group.new('IncSearch',    c.base00,       c.base0C,        no)
Group.new('LineNr',       c.base03,       c.none,          no)
Group.new('CursorLineNr', c.base05,       c.syntax_cursor, no)
Group.new('MatchParen',   c.base08,       c.syntax_cursor, ul + b)
Group.new('Italic',       c.none,         c.none,          i)
Group.new('ModeMsg',      c.base05,       c.none,          no)
Group.new('MoreMsg',      c.base05,       c.none,          no)
Group.new('NonText',      c.base02,       c.none,          no)
Group.new('PMenu',        c.none,         c.pmenu,         no)
Group.new('PMenuSel',     c.none,         c.base03,        no)
Group.new('PMenuSbar',    c.none,         c.base02,        no)
Group.new('PMenuThumb',   c.none,         c.base05,        no)
Group.new('Question',     c.base0C,       c.none,          no)
Group.new('Search',       c.base02,       c.base09,        no)
Group.new('SpecialKey',   c.special_grey, c.none,          no)
Group.new('Whitespace',   c.special_grey, c.none,          no)
Group.new('StatusLine',   c.base05,       c.base03,        no)
Group.new('StatusLineNC', c.base02,       c.none,          no)
Group.new('TabLine',      c.base04,       c.visual_grey,   no)
Group.new('TabLineFill',  c.base02,       c.visual_grey,   no)
Group.new('TabLineSel',   c.base02,       c.base0C,        no)
Group.new('Title',        c.base05,       c.none,          b)
Group.new('Visual',       c.none,         c.visual_grey,   no)
Group.new('VisualNOS',    c.none,         c.visual_grey,   no)
Group.new('WarningMsg',   c.base08,       c.none,          no)
Group.new('TooLong',      c.base08,       c.none,          no)
Group.new('WildMenu',     c.base05,       c.base02,        no)
Group.new('SignColumn',   c.none,         c.none,          no)
Group.new('Special',      c.base0C,       c.none,          no)

---------------------------
-- Vim Help Highlighting --
---------------------------

Group.new('helpCommand',      c.base09,  c.none,  no)
Group.new('helpExample',      c.base09,  c.none,  no)
Group.new('helpHeader',       c.base05,   c.none,  b)
Group.new('helpSectionDelim', c.base02,   c.none,  no)

----------------------------------
-- Standard Syntax Highlighting --
----------------------------------

Group.new('Comment',        c.base02, c.none,   i)
Group.new('Constant',       c.base0B, c.none,   no)
Group.new('String',         c.base0B, c.none,   no)
Group.new('Character',      c.base0B, c.none,   no)
Group.new('Number',         c.base0A, c.none,   no)
Group.new('Boolean',        c.base0A, c.none,   no)
Group.new('Float',          c.base0A, c.none,   no)
Group.new('Identifier',     c.base08, c.none,   no)
Group.new('Function',       c.base0C, c.none,   no)
Group.new('Statement',      c.base0E, c.none,   no)
Group.new('Conditional',    c.base0E, c.none,   no)
Group.new('Repeat',         c.base0E, c.none,   no)
Group.new('Label',          c.base0E, c.none,   no)
Group.new('Operator',       c.base0C, c.none,   no)
Group.new('Keyword',        c.base08, c.none,   no)
Group.new('Exception',      c.base0E, c.none,   no)
Group.new('PreProc',        c.base09, c.none,   no)
Group.new('Include',        c.base0C, c.none,   no)
Group.new('Define',         c.base0E, c.none,   no)
Group.new('Macro',          c.base0E, c.none,   no)
Group.new('PreCondit',      c.base09, c.none,   no)
Group.new('Type',           c.base09, c.none,   no)
Group.new('StorageClass',   c.base09, c.none,   no)
Group.new('Structure',      c.base09, c.none,   no)
Group.new('Typedef',        c.base09, c.none,   no)
Group.new('Special',        c.base0C, c.none,   no)
Group.new('SpecialChar',    c.none,   c.none,   no)
Group.new('Tag',            c.none,   c.none,   no)
Group.new('Delimiter',      c.none,   c.none,   no)
Group.new('SpecialComment', c.none,   c.none,   no)
Group.new('Debug',          c.none,   c.none,   no)
Group.new('Underlined',     c.none,   c.none,   ul)
Group.new('Ignore',         c.none,   c.none,   no)
Group.new('Error',          c.base08, c.base02, b)
Group.new('Todo',           c.base0E, c.base02, no)

-----------------------
-- Diff Highlighting --
-----------------------

Group.new('DiffAdd',     c.base0B, c.visual_grey, no)
Group.new('DiffChange',  c.base0A, c.visual_grey, no)
Group.new('DiffDelete',  c.base08, c.visual_grey, no)
Group.new('DiffText',    c.base0C, c.visual_grey, no)
Group.new('DiffAdded',   c.base0B, c.visual_grey, no)
Group.new('DiffFile',    c.base08, c.visual_grey, no)
Group.new('DiffNewFile', c.base0B, c.visual_grey, no)
Group.new('DiffLine',    c.base0C, c.visual_grey, no)
Group.new('DiffRemoved', c.base08, c.visual_grey, no)

---------------------------
-- Filetype Highlighting --
---------------------------

-- Asciidoc
Group.new('asciidocListingBlock', c.base04, c.none, no)

-- C/C++ highlighting
Group.new('cInclude',           c.base0E, c.none,  no)
Group.new('cPreCondit',         c.base0E, c.none,  no)
Group.new('cPreConditMatch',    c.base0E, c.none,  no)
Group.new('cType',              c.base0E, c.none,  no)
Group.new('cStorageClass',      c.base0E, c.none,  no)
Group.new('cStructure',         c.base0E, c.none,  no)
Group.new('cOperator',          c.base0E, c.none,  no)
Group.new('cStatement',         c.base0E, c.none,  no)
Group.new('cTODO',              c.base0E, c.none,  no)
Group.new('cConstant',          c.base0A, c.none,  no)
Group.new('cSpecial',           c.base07, c.none,  no)
Group.new('cSpecialCharacter',  c.base07, c.none,  no)
Group.new('cString',            c.base0B, c.none,  no)
Group.new('cppType',            c.base0E, c.none,  no)
Group.new('cppStorageClass',    c.base0E, c.none,  no)
Group.new('cppStructure',       c.base0E, c.none,  no)
Group.new('cppModifier',        c.base0E, c.none,  no)
Group.new('cppOperator',        c.base0E, c.none,  no)
Group.new('cppAccess',          c.base0E, c.none,  no)
Group.new('cppStatement',       c.base0E, c.none,  no)
Group.new('cppConstant',        c.base08, c.none,  no)
Group.new('cCppString',         c.base0B, c.none,  no)

-- Cucumber
Group.new('cucumberGiven',           c.base0C, c.none, no)
Group.new('cucumberWhen',            c.base0C, c.none, no)
Group.new('cucumberWhenAnd',         c.base0C, c.none, no)
Group.new('cucumberThen',            c.base0C, c.none, no)
Group.new('cucumberThenAnd',         c.base0C, c.none, no)
Group.new('cucumberUnparsed',        c.base0A, c.none, no)
Group.new('cucumberFeature',         c.base08, c.none, b)
Group.new('cucumberBackground',      c.base0E, c.none, b)
Group.new('cucumberScenario',        c.base0E, c.none, b)
Group.new('cucumberScenarioOutline', c.base0E, c.none, b)
Group.new('cucumberTags',            c.base02, c.none, b)
Group.new('cucumberDelimiter',       c.base02, c.none, b)

-- CSS/Sass
Group.new('cssAttrComma',         c.base0E, c.none, no)
Group.new('cssAttributeSelector', c.base0B, c.none, no)
Group.new('cssBraces',            c.base04, c.none, no)
Group.new('cssClassName',         c.base0A, c.none, no)
Group.new('cssClassNameDot',      c.base0A, c.none, no)
Group.new('cssDefinition',        c.base0E, c.none, no)
Group.new('cssFontAttr',          c.base0A, c.none, no)
Group.new('cssFontDescriptor',    c.base0E, c.none, no)
Group.new('cssFunctionName',      c.base0C, c.none, no)
Group.new('cssIdentifier',        c.base0C, c.none, no)
Group.new('cssImportant',         c.base0E, c.none, no)
Group.new('cssInclude',           c.base05, c.none, no)
Group.new('cssIncludeKeyword',    c.base0E, c.none, no)
Group.new('cssMediaType',         c.base0A, c.none, no)
Group.new('cssProp',              c.base07, c.none, no)
Group.new('cssPseudoClassId',     c.base0A, c.none, no)
Group.new('cssSelectorOp',        c.base0E, c.none, no)
Group.new('cssSelectorOp2',       c.base0E, c.none, no)
Group.new('cssStringQ',           c.base0B, c.none, no)
Group.new('cssStringQQ',          c.base0B, c.none, no)
Group.new('cssTagName',           c.base08, c.none, no)
Group.new('cssAttr',              c.base0A, c.none, no)
Group.new('sassAmpersand',        c.base08, c.none, no)
Group.new('sassClass',            c.base09, c.none, no)
Group.new('sassControl',          c.base0E, c.none, no)
Group.new('sassExtend',           c.base0E, c.none, no)
Group.new('sassFor',              c.base05, c.none, no)
Group.new('sassProperty',         c.base07, c.none, no)
Group.new('sassFunction',         c.base07, c.none, no)
Group.new('sassId',               c.base0C, c.none, no)
Group.new('sassInclude',          c.base0E, c.none, no)
Group.new('sassMedia',            c.base0E, c.none, no)
Group.new('sassMediaOperators',   c.base05, c.none, no)
Group.new('sassMixin',            c.base0E, c.none, no)
Group.new('sassMixinName',        c.base0C, c.none, no)
Group.new('sassMixing',           c.base0E, c.none, no)
Group.new('scssSelectorName',     c.base09, c.none, no)

-- Elixir highlighting

Group.new('elixirModuleDefine',      g.Define,  g.Define,    g.Define)
Group.new('elixirAlias',             c.base09, c.none, no)
Group.new('elixirAtom',              c.base07,   c.none, no)
Group.new('elixirBlockDefinition',   c.base0E,   c.none, no)
Group.new('elixirModuleDeclaration', c.base0A,   c.none, no)
Group.new('elixirInclude',           c.base08,   c.none, no)
Group.new('elixirOperator',          c.base0A,   c.none, no)

-- Git and git related plugins
Group.new('gitcommitComment',        c.base02,                 c.none,                   no)
Group.new('gitcommitUnmerged',       c.base0B,                 c.none,                   no)
Group.new('gitcommitOnBranch',       c.none,                   c.none,                   no)
Group.new('gitcommitBranch',         c.base0E,                 c.none,                   no)
Group.new('gitcommitDiscardedType',  c.base08,                 c.none,                   no)
Group.new('gitcommitSelectedType',   c.base0B,                 c.none,                   no)
Group.new('gitcommitHeader',         c.none,                   c.none,                   no)
Group.new('gitcommitUntrackedFile',  c.base07,                 c.none,                   no)
Group.new('gitcommitDiscardedFile',  c.base08,                 c.none,                   no)
Group.new('gitcommitSelectedFile',   c.base0B,                 c.none,                   no)
Group.new('gitcommitUnmergedFile',   c.base09,                 c.none,                   no)
Group.new('gitcommitFile',           c.none,                   c.none,                   no)
Group.new('gitcommitNoBranch',       g.gitcommitBranch,        g.gitcommitBranch,        g.gitcommitBranch)
Group.new('gitcommitUntracked',      g.gitcommitComment,       g.gitcommitComment,       g.gitcommitComment)
Group.new('gitcommitDiscarded',      g.gitcommitComment,       g.gitcommitComment,       g.gitcommitComment)
Group.new('gitcommitDiscardedArrow', g.gitcommitDiscardedFile, g.gitcommitDiscardedFile, g.gitcommitDiscardedFile)
Group.new('gitcommitSelectedArrow',  g.gitcommitSelectedFile,  g.gitcommitSelectedFile,  g.gitcommitSelectedFile)
Group.new('gitcommitUnmergedArrow',  g.gitcommitUnmergedFile,  g.gitcommitUnmergedFile,  g.gitcommitUnmergedFile)
Group.new('SignifySignAdd',          c.base0B,                 c.none,                   no)
Group.new('SignifySignChange',       c.base0D,                 c.none,                   no)
Group.new('SignifySignDelete',       c.base08,                 c.none,                   no)
Group.new('GitGutterAdd',            g.SignifySignAdd,         g.SignifySignAdd,         g.SignifySignAdd)
Group.new('GitGutterChange',         g.SignifySignChange,      g.SignifySignChange,      g.SignifySignChange)
Group.new('GitGutterDelete',         g.SignifySignDelete,      g.SignifySignDelete,      g.SignifySignDelete)
Group.new('diffAdded',               c.base0B,                 c.none,                   no)
Group.new('diffRemoved',             c.base08,                 c.none,                   no)

-- Go
Group.new('goDeclaration',  c.base0E, c.none, no)
Group.new('goField',        c.base08, c.none, no)
Group.new('goMethod',       c.base07, c.none, no)
Group.new('goType',         c.base0E, c.none, no)
Group.new('goUnsignedInts', c.base07, c.none, no)

-- Haskell highlighting
Group.new('haskellDeclKeyword',    c.base0C, c.none, no)
Group.new('haskellType',           c.base0B, c.none, no)
Group.new('haskellWhere',          c.base08, c.none, no)
Group.new('haskellImportKeywords', c.base0C, c.none, no)
Group.new('haskellOperators',      c.base08, c.none, no)
Group.new('haskellDelimiter',      c.base0C, c.none, no)
Group.new('haskellIdentifier',     c.base0A, c.none, no)
Group.new('haskellKeyword',        c.base08, c.none, no)
Group.new('haskellNumber',         c.base07, c.none, no)
Group.new('haskellString',         c.base07, c.none, no)

-- HTML
Group.new('htmlArg',            c.base0A, c.none,          no)
Group.new('htmlTagName',        c.base08, c.none,          no)
Group.new('htmlTagN',           c.base08, c.none,          no)
Group.new('htmlSpecialTagName', c.base08, c.none,          no)
Group.new('htmlTag',            c.base04, c.none,          no)
Group.new('htmlEndTag',         c.base04, c.none,          no)
Group.new('MatchTag',           c.base08, c.syntax_cursor, ul + b)

-- JavaScript
Group.new('coffeeString',           c.base0B, c.none, no)
Group.new('javaScriptBraces',       c.base04, c.none, no)
Group.new('javaScriptFunction',     c.base0E, c.none, no)
Group.new('javaScriptIdentifier',   c.base0E, c.none, no)
Group.new('javaScriptNull',         c.base0A, c.none, no)
Group.new('javaScriptNumber',       c.base0A, c.none, no)
Group.new('javaScriptRequire',      c.base07, c.none, no)
Group.new('javaScriptReserved',     c.base0E, c.none, no)
-- httpc.//github.com/pangloss/vim-javascript
Group.new('jsArrowFunction',        c.base0E, c.none, no)
Group.new('jsBraces',               c.base04, c.none, no)
Group.new('jsClassBraces',          c.base04, c.none, no)
Group.new('jsClassKeywords',        c.base0E, c.none, no)
Group.new('jsDocParam',             c.base0C, c.none, no)
Group.new('jsDocTags',              c.base0E, c.none, no)
Group.new('jsFuncBraces',           c.base04, c.none, no)
Group.new('jsFuncCall',             c.base0C, c.none, no)
Group.new('jsFuncParens',           c.base04, c.none, no)
Group.new('jsFunction',             c.base0E, c.none, no)
Group.new('jsGlobalObjects',        c.base09, c.none, no)
Group.new('jsModuleWords',          c.base0E, c.none, no)
Group.new('jsModules',              c.base0E, c.none, no)
Group.new('jsNoise',                c.base04, c.none, no)
Group.new('jsNull',                 c.base0A, c.none, no)
Group.new('jsOperator',             c.base0E, c.none, no)
Group.new('jsParens',               c.base04, c.none, no)
Group.new('jsStorageClass',         c.base0E, c.none, no)
Group.new('jsTemplateBraces',       c.base0F, c.none, no)
Group.new('jsTemplateVar',          c.base0B, c.none, no)
Group.new('jsThis',                 c.base08, c.none, no)
Group.new('jsUndefined',            c.base0A, c.none, no)
Group.new('jsObjectValue',          c.base0C, c.none, no)
Group.new('jsObjectKey',            c.base07, c.none, no)
Group.new('jsReturn',               c.base0E, c.none, no)
-- httpc.//github.com/othree/yajs.vim
Group.new('javascriptArrowFunc',    c.base0E, c.none, no)
Group.new('javascriptClassExtends', c.base0E, c.none, no)
Group.new('javascriptClassKeyword', c.base0E, c.none, no)
Group.new('javascriptDocNotation',  c.base0E, c.none, no)
Group.new('javascriptDocParamName', c.base0C, c.none, no)
Group.new('javascriptDocTags',      c.base0E, c.none, no)
Group.new('javascriptEndColons',    c.base02, c.none, no)
Group.new('javascriptExport',       c.base0E, c.none, no)
Group.new('javascriptFuncArg',      c.base05, c.none, no)
Group.new('javascriptFuncKeyword',  c.base0E, c.none, no)
Group.new('javascriptIdentifier',   c.base08, c.none, no)
Group.new('javascriptImport',       c.base0E, c.none, no)
Group.new('javascriptObjectLabel',  c.base05, c.none, no)
Group.new('javascriptOpSymbol',     c.base07, c.none, no)
Group.new('javascriptOpSymbols',    c.base07, c.none, no)
Group.new('javascriptPropertyName', c.base0B, c.none, no)
Group.new('javascriptTemplateSB',   c.base0F, c.none, no)
Group.new('javascriptVariable',     c.base0E, c.none, no)

-- JSON
Group.new('jsonCommentError',       c.base05, c.none, no)
Group.new('jsonKeyword',            c.base08, c.none, no)
Group.new('jsonQuote',              c.base02, c.none, no)
Group.new('jsonTrailingCommaError', c.base08, c.none, r)
Group.new('jsonMissingCommaError',  c.base08, c.none, r)
Group.new('jsonNoQuotesError',      c.base08, c.none, r)
Group.new('jsonNumError',           c.base08, c.none, r)
Group.new('jsonString',             c.base0B, c.none, no)
Group.new('jsonBoolean',            c.base0E, c.none, no)
Group.new('jsonNumber',             c.base0A, c.none, no)
Group.new('jsonStringSQError',      c.base08, c.none, r)
Group.new('jsonSemicolonError',     c.base08, c.none, r)

-- Markdown
Group.new('markdownUrl',              c.base02, c.none, no)
Group.new('markdownBold',             c.base0A, c.none, b)
Group.new('markdownItalic',           c.base0A, c.none, b)
Group.new('markdownCode',             c.base0B, c.none, no)
Group.new('markdownCodeBlock',        c.base08, c.none, no)
Group.new('markdownCodeDelimiter',    c.base0B, c.none, no)
Group.new('markdownHeadingDelimiter', c.base0F, c.none, no)
Group.new('markdownH1',               c.base08, c.none, no)
Group.new('markdownH2',               c.base08, c.none, no)
Group.new('markdownH3',               c.base08, c.none, no)
Group.new('markdownH3',               c.base08, c.none, no)
Group.new('markdownH4',               c.base08, c.none, no)
Group.new('markdownH5',               c.base08, c.none, no)
Group.new('markdownH6',               c.base08, c.none, no)
Group.new('markdownListMarker',       c.base08, c.none, no)

-- PHP
Group.new('phpClass',        c.base09, c.none, no)
Group.new('phpFunction',     c.base0C, c.none, no)
Group.new('phpFunctions',    c.base0C, c.none, no)
Group.new('phpInclude',      c.base0E, c.none, no)
Group.new('phpKeyword',      c.base0E, c.none, no)
Group.new('phpParent',       c.base02, c.none, no)
Group.new('phpType',         c.base0E, c.none, no)
Group.new('phpSuperGlobals', c.base08, c.none, no)

-- Pug (Formerly Jade)
Group.new('pugAttributesDelimiter', c.base0A, c.none, no)
Group.new('pugClass',               c.base0A, c.none, no)
Group.new('pugDocType',             c.base02, c.none, i)
Group.new('pugTag',                 c.base08, c.none, no)

-- PureScript
Group.new('purescriptKeyword',     c.base0E, c.none, no)
Group.new('purescriptModuleName',  c.base05, c.none, no)
Group.new('purescriptIdentifier',  c.base05, c.none, no)
Group.new('purescriptType',        c.base09, c.none, no)
Group.new('purescriptTypeVar',     c.base08, c.none, no)
Group.new('purescriptConstructor', c.base08, c.none, no)
Group.new('purescriptOperator',    c.base05, c.none, no)

-- Python
Group.new('pythonImport',          c.base0E, c.none, no)
Group.new('pythonBuiltin',         c.base07, c.none, no)
Group.new('pythonStatement',       c.base0E, c.none, no)
Group.new('pythonParam',           c.base0A, c.none, no)
Group.new('pythonEscape',          c.base08, c.none, no)
Group.new('pythonSelf',            c.base04, c.none, i)
Group.new('pythonClass',           c.base0C, c.none, no)
Group.new('pythonOperator',        c.base0E, c.none, no)
Group.new('pythonEscape',          c.base08, c.none, no)
Group.new('pythonFunction',        c.base0C, c.none, no)
Group.new('pythonKeyword',         c.base0C, c.none, no)
Group.new('pythonModule',          c.base0E, c.none, no)
Group.new('pythonStringDelimiter', c.base0B, c.none, no)
Group.new('pythonSymbol',          c.base07, c.none, no)

-- Ruby
Group.new('rubyBlock',                     c.base0E, c.none, no)
Group.new('rubyBlockParameter',            c.base08, c.none, no)
Group.new('rubyBlockParameterList',        c.base08, c.none, no)
Group.new('rubyCapitalizedMethod',         c.base0E, c.none, no)
Group.new('rubyClass',                     c.base0E, c.none, no)
Group.new('rubyConstant',                  c.base09, c.none, no)
Group.new('rubyControl',                   c.base0E, c.none, no)
Group.new('rubyDefine',                    c.base0E, c.none, no)
Group.new('rubyEscape',                    c.base08, c.none, no)
Group.new('rubyFunction',                  c.base0C, c.none, no)
Group.new('rubyGlobalVariable',            c.base08, c.none, no)
Group.new('rubyInclude',                   c.base0C, c.none, no)
Group.new('rubyIncluderubyGlobalVariable', c.base08, c.none, no)
Group.new('rubyInstanceVariable',          c.base08, c.none, no)
Group.new('rubyInterpolation',             c.base07, c.none, no)
Group.new('rubyInterpolationDelimiter',    c.base08, c.none, no)
Group.new('rubyKeyword',                   c.base0C, c.none, no)
Group.new('rubyModule',                    c.base0E, c.none, no)
Group.new('rubyPseudoVariable',            c.base08, c.none, no)
Group.new('rubyRegexp',                    c.base07, c.none, no)
Group.new('rubyRegexpDelimiter',           c.base07, c.none, no)
Group.new('rubyStringDelimiter',           c.base0B, c.none, no)
Group.new('rubySymbol',                    c.base07, c.none, no)

-- Spelling
Group.new('SpellBad',   c.base02, c.none, uc)
Group.new('SpellLocal', c.base02, c.none, uc)
Group.new('SpellCap',   c.base02, c.none, uc)
Group.new('SpellRare',  c.base02, c.none, uc)

-- Vim
Group.new('vimCommand',      c.base0E, c.none, no)
Group.new('vimCommentTitle', c.base02, c.none, b)
Group.new('vimFunction',     c.base07, c.none, no)
Group.new('vimFuncName',     c.base0E, c.none, no)
Group.new('vimHighlight',    c.base0C, c.none, no)
Group.new('vimLineComment',  c.base02, c.none, i)
Group.new('vimParenSep',     c.base04, c.none, no)
Group.new('vimSep',          c.base04, c.none, no)
Group.new('vimUserFunc',     c.base07, c.none, no)
Group.new('vimVar',          c.base08, c.none, no)

-- XML
Group.new('xmlAttrib',  c.base09, c.none, no)
Group.new('xmlEndTag',  c.base08, c.none, no)
Group.new('xmlTag',     c.base08, c.none, no)
Group.new('xmlTagName', c.base08, c.none, no)

-- ZSH
Group.new('zshCommands',    c.base05, c.none, no)
Group.new('zshDeref',       c.base08, c.none, no)
Group.new('zshShortDeref',  c.base08, c.none, no)
Group.new('zshFunction',    c.base07, c.none, no)
Group.new('zshKeyword',     c.base0E, c.none, no)
Group.new('zshSubst',       c.base08, c.none, no)
Group.new('zshSubstDelim',  c.base02, c.none, no)
Group.new('zshTypes',       c.base0E, c.none, no)
Group.new('zshVariableDef', c.base0A, c.none, no)

-- Rust
Group.new('rustExternCrate',          c.base08, c.none, b)
Group.new('rustIdentifier',           c.base0C, c.none, no)
Group.new('rustDeriveTrait',          c.base0B, c.none, no)
Group.new('SpecialComment',           c.base02, c.none, no)
Group.new('rustCommentLine',          c.base02, c.none, no)
Group.new('rustCommentLineDoc',       c.base02, c.none, no)
Group.new('rustCommentLineDocError',  c.base02, c.none, no)
Group.new('rustCommentBlock',         c.base02, c.none, no)
Group.new('rustCommentBlockDoc',      c.base02, c.none, no)
Group.new('rustCommentBlockDocError', c.base02, c.none, no)

-- Man
Group.new('manTitle',  g.String, g.String,    g.String)
Group.new('manFooter', c.base02, c.none, no)

-------------------------
-- Plugin Highlighting --
-------------------------

-- ALE (Asynchronous Lint Engine)
Group.new('ALEWarningSign', c.base09, c.none, no)
Group.new('ALEErrorSign',   c.base08, c.none, no)

-- Neovim NERDTree Background fix
Group.new('NERDTreeFile', c.base05, c.none, no)

-- Coc.nvim Floating Background fix
Group.new('CocFloating',                          c.base05, c.none,  no)
Group.new('NormalFloat',                          c.base05, c.pmenu, no)
-----------------------------
--     LSP Highlighting    --
-----------------------------
Group.new('LspDiagnosticsDefaultError',           c.base08, c.none,  no)
Group.new('LspDiagnosticsDefaultWarning',         c.base09, c.none,  no)
Group.new('LspDiagnosticsDefaultInformation',     c.base07, c.none,  no)
Group.new('LspDiagnosticsDefaultHint',            c.base0B, c.none,  no)
Group.new('LspDiagnosticsVirtualTextError',       c.base08, c.none,  no)
Group.new('LspDiagnosticsVirtualTextWarning',     c.base09, c.none,  no)
Group.new('LspDiagnosticsVirtualTextInformation', c.base07, c.none,  no)
Group.new('LspDiagnosticsVirtualTextHint',        c.base0B, c.none,  no)
Group.new('LspDiagnosticsUnderlineError',         c.base08, c.none,  ul)
Group.new('LspDiagnosticsUnderlineWarning',       c.base09, c.none,  ul)
Group.new('LspDiagnosticsUnderlineInformation',   c.base07, c.none,  ul)
Group.new('LspDiagnosticsUnderlineHint',          c.base0B, c.none,  ul)
Group.new('LspDiagnosticsFloatingError',          c.base08, g.pmenu, ul)
Group.new('LspDiagnosticsFloatingWarning',        c.base09, g.pmenu, ul)
Group.new('LspDiagnosticsFloatingInformation',    c.base07, g.pmenu, ul)
Group.new('LspDiagnosticsFloatingHint',           c.base0B, g.pmenu, ul)
Group.new('LspDiagnosticsSignError',              c.base08, c.none,  no)
Group.new('LspDiagnosticsSignWarning',            c.base09, c.none,  no)
Group.new('LspDiagnosticsSignInformation',        c.base07, c.none,  no)
Group.new('LspDiagnosticsSignHint',               c.base0B, c.none,  no)
-----------------------------
-- TreeSitter Highlighting --
-----------------------------
Group.new('TSAnnotation',                         c.base09, c.none,  no)
Group.new('TSAttribute',                          c.base07, c.none,  no)
Group.new('TSBoolean',                            c.base0A, c.none,  no)
Group.new('TSCharacter',                          c.base0B, c.none,  no)
Group.new('TSConditional',                        c.pink,   c.none,  no)
Group.new('TSConstant',                           c.base0C, c.none,  no)
Group.new('TSConstBuiltin',                       c.base0A, c.none,  no)
Group.new('TSConstMacro',                         c.base07, c.none,  no)
Group.new('TSConstructor',                        c.base07, c.none,  no)
Group.new('TSEmphasis',                           c.base09, c.none,  no)
Group.new('TSError',                              c.base08, c.none,  no)
Group.new('TSException',                          c.pink,   c.none,  no)
Group.new('TSField',                              c.base08, c.none,  no)
Group.new('TSFloat',                              c.base0B, c.none,  no)
Group.new('TSFunction',                           c.base0C, c.none,  no)
Group.new('TSFuncBuiltin',                        c.base0C, c.none,  no)
Group.new('TSFuncMacro',                          c.base09, c.none,  no)
Group.new('TSInclude',                            c.pink,   c.none,  no)
Group.new('TSKeyword',                            c.pink,   c.none,  no)
Group.new('TSKeywordFunction',                    c.pink,   c.none,  no)
Group.new('TSKeywordOperator',                    c.pink,   c.none,  no)
Group.new('TSLabel',                              c.base0C, c.none,  no)
Group.new('TSLiteral',                            c.base09, c.none,  no)
Group.new('TSMethod',                             c.base0C, c.none,  no)
Group.new('TSNamespace',                          c.pink,   c.none,  no)
Group.new('TSNumber',                             c.base0A, c.none,  no)
Group.new('TSOperator',                           c.base05, c.none,  no)
Group.new('TSParameter',                          c.base07, c.none,  no)
Group.new('TSParameterReference',                 c.base07, c.none,  no)
Group.new('TSProperty',                           c.base09, c.none,  no)
Group.new('TSPunctBracket',                       c.base05, c.none,  no)
Group.new('TSPunctDelimiter',                     c.base05, c.none,  no)
Group.new('TSPunctSpecial',                       c.base05, c.none,  no)
Group.new('TSRepeat',                             c.pink,   c.none,  no)
Group.new('TSString',                             c.base0B, c.none,  no)
Group.new('TSStringEscape',                       c.base07, c.none,  no)
Group.new('TSStringRegex',                        c.base0B, c.none,  no)
Group.new('TSStrong',                             c.base09, c.none,  no)
Group.new('TSStructure',                          c.base09, c.none,  no)
Group.new('TSTag',                                c.base08, c.none,  no)
Group.new('TSTagDelimiter',                       c.base02, c.none,  no)
Group.new('TSText',                               c.base09, c.none,  no)
Group.new('TSTitle',                              c.base09, c.none,  no)
Group.new('TSType',                               c.base0C, c.none,  no)
Group.new('TSTypeBuiltin',                        c.base0C, c.none,  no)
Group.new('TSUnderline',                          c.base09, c.none,  no)
Group.new('TSURI',                                c.base09, c.none,  no)
Group.new('TSVariable',                           c.base07, c.none,  no)
Group.new('TSVariableBuiltin',                    c.base09, c.none,  no)
