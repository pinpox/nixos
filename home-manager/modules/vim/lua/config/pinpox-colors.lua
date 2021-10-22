local Color, c, Group, g, s = require("colorbuddy").setup()
local b   = s.bold
local i   = s.italic
local n   = s.inverse
local uc  = s.undercurl
local ul  = s.underline
local r   = s.reverse
local sto = s.standout
local no  = s.NONE
local v   = vim


-- TODO Think of a better colorscheme name
v.g.colors_name = 'generated'


local nixcolors = require('nixcolors')

-------------------------
-- Vim Primary Colors --
-------------------------
Color.new('Black',         nixcolors.Black)

Color.new('DarkGrey',      nixcolors.DarkGrey)
Color.new('Grey',          nixcolors.Grey)
Color.new('BrightGrey',    nixcolors.BrightGrey)

Color.new('DarkWhite',     nixcolors.DarkWhite)
Color.new('White',         nixcolors.White)
Color.new('BrightWhite',   nixcolors.BrightWhite)

Color.new('DarkRed',       nixcolors.DarkRed)
Color.new('Red',           nixcolors.Red)
Color.new('BrightRed',     nixcolors.BrightRed)

Color.new('DarkYellow',    nixcolors.DarkYellow)
Color.new('Yellow',        nixcolors.Yellow)
Color.new('BrightYellow',  nixcolors.BrightYellow)

Color.new('DarkGreen',     nixcolors.DarkGreen)
Color.new('Green',         nixcolors.Green)
Color.new('BrightGreen',   nixcolors.BrightGreen)

Color.new('DarkCyan',      nixcolors.DarkCyan)
Color.new('Cyan',          nixcolors.Cyan)
Color.new('BrightCyan',    nixcolors.BrightCyan)

Color.new('DarkBlue',      nixcolors.DarkBlue)
Color.new('Blue',          nixcolors.Blue)
Color.new('BrightBlue',    nixcolors.BrightBlue)

Color.new('DarkMagenta',   nixcolors.DarkMagenta)
Color.new('Magenta',       nixcolors.Magenta)
Color.new('BrightMagenta', nixcolors.BrightMagenta)


---------------------------
---- Vim Terminal Colors --
---------------------------

v.g.terminal_color_0  = "#353a44"  -- TODO: use nixcolors here
v.g.terminal_color_8  = "#353a44"  -- TODO: use nixcolors here
v.g.terminal_color_1  = "#e88388"  -- TODO: use nixcolors here
v.g.terminal_color_9  = "#e88388"  -- TODO: use nixcolors here
v.g.terminal_color_2  = "#a7cc8c"  -- TODO: use nixcolors here
v.g.terminal_color_10 = "#a7cc8c"  -- TODO: use nixcolors here
v.g.terminal_color_3  = "#ebca8d"  -- TODO: use nixcolors here
v.g.terminal_color_11 = "#ebca8d"  -- TODO: use nixcolors here
v.g.terminal_color_4  = "#72bef2"  -- TODO: use nixcolors here
v.g.terminal_color_12 = "#72bef2"  -- TODO: use nixcolors here
v.g.terminal_color_5  = "#d291e4"  -- TODO: use nixcolors here
v.g.terminal_color_13 = "#d291e4"  -- TODO: use nixcolors here
v.g.terminal_color_6  = "#65c2cd"  -- TODO: use nixcolors here
v.g.terminal_color_14 = "#65c2cd"  -- TODO: use nixcolors here
v.g.terminal_color_7  = "#e3e5e9"  -- TODO: use nixcolors here
v.g.terminal_color_15 = "#e3e5e9"  -- TODO: use nixcolors here

------------------------
---- Vim Editor Color --
------------------------

Group.new('Normal',       c.White,     c.Black,      no)
Group.new('bold',         c.none,      c.none,       b)
Group.new('ColorColumn',  c.none,      c.Grey,       no)
Group.new('Conceal',      c.Grey,      c.Black,      no)
Group.new('Cursor',       c.none,      c.Cyan,       no)
Group.new('CursorIM',     c.none,      c.none,       no)
Group.new('CursorColumn', c.none,      c.Grey,       no)
Group.new('CursorLine',   c.none,      c.Grey,       no)
Group.new('Directory',    c.Cyan,      c.none,       no)
Group.new('ErrorMsg',     c.Red,       c.none,       no)
Group.new('VertSplit',    c.Blue,      c.none,       no)
Group.new('Folded',       c.Grey,      c.none,       no)
Group.new('FoldColumn',   c.Grey,      c.Grey,       no)
Group.new('IncSearch',    c.Black,     c.Cyan,       no)
Group.new('LineNr',       c.Grey,      c.none,       no)
Group.new('CursorLineNr', c.White,     c.Grey,       no)
Group.new('MatchParen',   c.Red,       c.Grey,       ul + b)
Group.new('Italic',       c.none,      c.none,       i)
Group.new('ModeMsg',      c.White,     c.none,       no)
Group.new('MoreMsg',      c.White,     c.none,       no)
Group.new('NonText',      c.Grey,      c.none,       no)
Group.new('PMenu',        c.none,      c.Grey,       no)
Group.new('PMenuSel',     c.none,      c.Grey,       no)
Group.new('PMenuSbar',    c.none,      c.Grey,       no)
Group.new('PMenuThumb',   c.none,      c.White,      no)
Group.new('Question',     c.Cyan,      c.none,       no)
Group.new('Search',       c.Grey,      c.DarkYellow, no)
Group.new('SpecialKey',   c.Grey,      c.none,       no)
Group.new('Whitespace',   c.Grey,      c.none,       no)
Group.new('StatusLine',   c.White,     c.Grey,       no)
Group.new('StatusLineNC', c.Grey,      c.none,       no)
Group.new('TabLine',      c.DarkWhite, c.Grey,       no)
Group.new('TabLineFill',  c.Grey,      c.Grey,       no)
Group.new('TabLineSel',   c.Grey,      c.Cyan,       no)
Group.new('Title',        c.White,     c.none,       b)
Group.new('Visual',       c.none,      c.Grey,       no)
Group.new('VisualNOS',    c.none,      c.Grey,       no)
Group.new('WarningMsg',   c.Red,       c.none,       no)
Group.new('TooLong',      c.Red,       c.none,       no)
Group.new('WildMenu',     c.White,     c.Grey,       no)
Group.new('SignColumn',   c.none,      c.none,       no)
Group.new('Special',      c.Cyan,      c.none,       no)

------------------------------
---- Wilder.nvim Popup-Menu --
------------------------------

Group.new('WilderDefault',        c.White,      c.none,       no)
Group.new('WilderAccent',         c.Yellow,     c.none,       no)
Group.new('WilderSelected',       c.Blue,       c.BrightGrey, b)
Group.new('WilderSelectedAccent', c.Magenta,    c.BrightGrey, b)
Group.new('WilderError',          c.Red,        c.none,       no)
Group.new('WilderSeparator',      c.Green,      c.Grey,       no)
Group.new('WilderBorder',         c.Blue,       c.none,       no)

-----------------------------
---- Vim Help Highlighting --
-----------------------------

Group.new('helpCommand',      c.DarkYellow, c.none, no)
Group.new('helpExample',      c.DarkYellow, c.none, no)
Group.new('helpHeader',       c.White,      c.none, b)
Group.new('helpSectionDelim', c.Grey,       c.none, no)

------------------------------------
---- Standard Syntax Highlighting --
------------------------------------

Group.new('Comment',             c.DarkBlue, c.none,  i)
Group.new('Constant',            c.Green,    c.none, no)
Group.new('String',              c.Green,    c.none, no)
Group.new('Character',           c.Green,    c.none, no)
Group.new('Number',             c.Yellow,    c.none, no)
Group.new('Boolean',            c.Yellow,    c.none, no)
Group.new('Float',              c.Yellow,    c.none, no)
Group.new('Identifier',            c.Red,    c.none, no)
Group.new('Function',             c.Cyan,    c.none, no)
Group.new('Statement',         c.Magenta,    c.none, no)
Group.new('Conditional',       c.Magenta,    c.none, no)
Group.new('Repeat',            c.Magenta,    c.none, no)
Group.new('Label',             c.Magenta,    c.none, no)
Group.new('Operator',             c.Cyan,    c.none, no)
Group.new('Keyword',               c.Red,    c.none, no)
Group.new('Exception',         c.Magenta,    c.none, no)
Group.new('PreProc',        c.DarkYellow,    c.none, no)
Group.new('Include',              c.Cyan,    c.none, no)
Group.new('Define',            c.Magenta,    c.none, no)
Group.new('Macro',             c.Magenta,    c.none, no)
Group.new('PreCondit',      c.DarkYellow,    c.none, no)
Group.new('Type',           c.DarkYellow,    c.none, no)
Group.new('StorageClass',   c.DarkYellow,    c.none, no)
Group.new('Structure',      c.DarkYellow,    c.none, no)
Group.new('Typedef',        c.DarkYellow,    c.none, no)
Group.new('Special',              c.Cyan,    c.none, no)
Group.new('SpecialChar',          c.none,    c.none, no)
Group.new('Tag',                  c.none,    c.none, no)
Group.new('Delimiter',            c.none,    c.none, no)
Group.new('SpecialComment',       c.none,    c.none, no)
Group.new('Debug',                c.none,    c.none, no)
Group.new('Underlined',           c.none,    c.none, ul)
Group.new('Ignore',               c.none,    c.none, no)
Group.new('Error',                 c.Red,    c.Grey,  b)
Group.new('Todo',         c.BrightYellow,    c.Grey, no)

-------------------------
---- Diff Highlighting --
-------------------------

Group.new('DiffAdd',                       c.Green, c.Grey, no)
Group.new('DiffChange',                    c.Yellow, c.Grey, no)
Group.new('DiffDelete',                    c.Red, c.Grey, no)
Group.new('DiffText',                      c.Cyan, c.Grey, no)
Group.new('DiffAdded',                     c.Green, c.Grey, no)
Group.new('DiffFile',                      c.Red, c.Grey, no)
Group.new('DiffNewFile',                   c.Green, c.Grey, no)
Group.new('DiffLine',                      c.Cyan, c.Grey, no)
Group.new('DiffRemoved',                   c.Red, c.Grey, no)

-----------------------------
---- Filetype Highlighting --
-----------------------------

---- Asciidoc
Group.new('asciidocListingBlock',          c.DarkWhite, c.none,   no)

---- C/C++ highlighting
Group.new('cInclude',                      c.Magenta, c.none,   no)
Group.new('cPreCondit',                    c.Magenta, c.none,   no)
Group.new('cPreConditMatch',               c.Magenta, c.none,   no)
Group.new('cType',                         c.Magenta, c.none,   no)
Group.new('cStorageClass',                 c.Magenta, c.none,   no)
Group.new('cStructure',                    c.Magenta, c.none,   no)
Group.new('cOperator',                     c.Magenta, c.none,   no)
Group.new('cStatement',                    c.Magenta, c.none,   no)
Group.new('cTODO',                         c.Magenta, c.none,   no)
Group.new('cConstant',                     c.Yellow, c.none,   no)
Group.new('cSpecial',                      c.Green, c.none,   no)
Group.new('cSpecialCharacter',             c.Green, c.none,   no)
Group.new('cString',                       c.Green, c.none,   no)
Group.new('cppType',                       c.Magenta, c.none,   no)
Group.new('cppStorageClass',               c.Magenta, c.none,   no)
Group.new('cppStructure',                  c.Magenta, c.none,   no)
Group.new('cppModifier',                   c.Magenta, c.none,   no)
Group.new('cppOperator',                   c.Magenta, c.none,   no)
Group.new('cppAccess',                     c.Magenta, c.none,   no)
Group.new('cppStatement',                  c.Magenta, c.none,   no)
Group.new('cppConstant',                   c.Red, c.none,   no)
Group.new('cCppString',                    c.Green, c.none,   no)

---- Cucumber
Group.new('cucumberGiven',                 c.Cyan, c.none,   no)
Group.new('cucumberWhen',                  c.Cyan, c.none,   no)
Group.new('cucumberWhenAnd',               c.Cyan, c.none,   no)
Group.new('cucumberThen',                  c.Cyan, c.none,   no)
Group.new('cucumberThenAnd',               c.Cyan, c.none,   no)
Group.new('cucumberUnparsed',              c.Yellow, c.none,   no)
Group.new('cucumberFeature',               c.Red, c.none,   b)
Group.new('cucumberBackground',            c.Magenta, c.none,   b)
Group.new('cucumberScenario',              c.Magenta, c.none,   b)
Group.new('cucumberScenarioOutline',       c.Magenta, c.none,   b)
Group.new('cucumberTags',                  c.Grey, c.none,   b)
Group.new('cucumberDelimiter',             c.Grey, c.none,   b)

---- CSS/Sass
Group.new('cssAttrComma',                  c.Magenta, c.none,   no)
Group.new('cssAttributeSelector',          c.Green, c.none,   no)
Group.new('cssBraces',                     c.DarkWhite, c.none,   no)
Group.new('cssClassName',                  c.Yellow, c.none,   no)
Group.new('cssClassNameDot',               c.Yellow, c.none,   no)
Group.new('cssDefinition',                 c.Magenta, c.none,   no)
Group.new('cssFontAttr',                   c.Yellow, c.none,   no)
Group.new('cssFontDescriptor',             c.Magenta, c.none,   no)
Group.new('cssFunctionName',               c.Cyan, c.none,   no)
Group.new('cssIdentifier',                 c.Cyan, c.none,   no)
Group.new('cssImportant',                  c.Magenta, c.none,   no)
Group.new('cssInclude',                    c.White, c.none,   no)
Group.new('cssIncludeKeyword',             c.Magenta, c.none,   no)
Group.new('cssMediaType',                  c.Yellow, c.none,   no)
Group.new('cssProp',                       c.Green, c.none,   no)
Group.new('cssPseudoClassId',              c.Yellow, c.none,   no)
Group.new('cssSelectorOp',                 c.Magenta, c.none,   no)
Group.new('cssSelectorOp2',                c.Magenta, c.none,   no)
Group.new('cssStringQ',                    c.Green, c.none,   no)
Group.new('cssStringQQ',                   c.Green, c.none,   no)
Group.new('cssTagName',                    c.Red, c.none,   no)
Group.new('cssAttr',                       c.Yellow, c.none,   no)
Group.new('sassAmpersand',                 c.Red, c.none,   no)
Group.new('sassClass',                     c.DarkYellow, c.none,   no)
Group.new('sassControl',                   c.Magenta, c.none,   no)
Group.new('sassExtend',                    c.Magenta, c.none,   no)
Group.new('sassFor',                       c.White, c.none,   no)
Group.new('sassProperty',                  c.Green, c.none,   no)
Group.new('sassFunction',                  c.Green, c.none,   no)
Group.new('sassId',                        c.Cyan, c.none,   no)
Group.new('sassInclude',                   c.Magenta, c.none,   no)
Group.new('sassMedia',                     c.Magenta, c.none,   no)
Group.new('sassMediaOperators',            c.White, c.none,   no)
Group.new('sassMixin',                     c.Magenta, c.none,   no)
Group.new('sassMixinName',                 c.Cyan, c.none,   no)
Group.new('sassMixing',                    c.Magenta, c.none,   no)
Group.new('scssSelectorName',              c.DarkYellow, c.none,   no)

-- Elixir
Group.new('elixirModuleDefine',            g.Define, g.Define, g.Define)
Group.new('elixirAlias',                   c.DarkYellow, c.none,   no)
Group.new('elixirAtom',                    c.Green, c.none,   no)
Group.new('elixirBlockDefinition',         c.Magenta, c.none,   no)
Group.new('elixirModuleDeclaration',       c.Yellow, c.none,   no)
Group.new('elixirInclude',                 c.Red, c.none,   no)
Group.new('elixirOperator',                c.Yellow, c.none,   no)

---- Go
Group.new('goDeclaration',                 c.Magenta, c.none,   no)
Group.new('goField',                       c.Red, c.none,   no)
Group.new('goMethod',                      c.Green, c.none,   no)
Group.new('goType',                        c.Magenta, c.none,   no)
Group.new('goUnsignedInts',                c.Green, c.none,   no)

---- Haskell
Group.new('haskellDeclKeyword',            c.Cyan, c.none,   no)
Group.new('haskellType',                   c.Green, c.none,   no)
Group.new('haskellWhere',                  c.Red, c.none,   no)
Group.new('haskellImportKeywords',         c.Cyan, c.none,   no)
Group.new('haskellOperators',              c.Red, c.none,   no)
Group.new('haskellDelimiter',              c.Cyan, c.none,   no)
Group.new('haskellIdentifier',             c.Yellow, c.none,   no)
Group.new('haskellKeyword',                c.Red, c.none,   no)
Group.new('haskellNumber',                 c.Green, c.none,   no)
Group.new('haskellString',                 c.Green, c.none,   no)

-- HTML
Group.new('htmlArg',                       c.Yellow, c.none,   no)
Group.new('htmlTagName',                   c.Red, c.none,   no)
Group.new('htmlTagN',                      c.Red, c.none,   no)
Group.new('htmlSpecialTagName',            c.Red, c.none,   no)
Group.new('htmlTag',                       c.DarkWhite, c.none,   no)
Group.new('htmlEndTag',                    c.DarkWhite, c.none,   no)
Group.new('MatchTag',                      c.Red, c.Grey, ul + b)

---- JavaScript
Group.new('coffeeString',                  c.Green, c.none,   no)
Group.new('javaScriptBraces',              c.DarkWhite, c.none,   no)
Group.new('javaScriptFunction',            c.Magenta, c.none,   no)
Group.new('javaScriptIdentifier',          c.Magenta, c.none,   no)
Group.new('javaScriptNull',                c.Yellow, c.none,   no)
Group.new('javaScriptNumber',              c.Yellow, c.none,   no)
Group.new('javaScriptRequire',             c.Green, c.none,   no)
Group.new('javaScriptReserved',            c.Magenta, c.none,   no)
-- httpc.//github.com/pangloss/vim-javascript
Group.new('jsArrowFunction',               c.Magenta, c.none,   no)
Group.new('jsBraces',                      c.DarkWhite, c.none,   no)
Group.new('jsClassBraces',                 c.DarkWhite, c.none,   no)
Group.new('jsClassKeywords',               c.Magenta, c.none,   no)
Group.new('jsDocParam',                    c.Cyan, c.none,   no)
Group.new('jsDocTags',                     c.Magenta, c.none,   no)
Group.new('jsFuncBraces',                  c.DarkWhite, c.none,   no)
Group.new('jsFuncCall',                    c.Cyan, c.none,   no)
Group.new('jsFuncParens',                  c.DarkWhite, c.none,   no)
Group.new('jsFunction',                    c.Magenta, c.none,   no)
Group.new('jsGlobalObjects',               c.DarkYellow, c.none,   no)
Group.new('jsModuleWords',                 c.Magenta, c.none,   no)
Group.new('jsModules',                     c.Magenta, c.none,   no)
Group.new('jsNoise',                       c.DarkWhite, c.none,   no)
Group.new('jsNull',                        c.Yellow, c.none,   no)
Group.new('jsOperator',                    c.Magenta, c.none,   no)
Group.new('jsParens',                      c.DarkWhite, c.none,   no)
Group.new('jsStorageClass',                c.Magenta, c.none,   no)
Group.new('jsTemplateBraces',              c.BrightRed, c.none,   no)
Group.new('jsTemplateVar',                 c.Green, c.none,   no)
Group.new('jsThis',                        c.Red, c.none,   no)
Group.new('jsUndefined',                   c.Yellow, c.none,   no)
Group.new('jsObjectValue',                 c.Cyan, c.none,   no)
Group.new('jsObjectKey',                   c.Green, c.none,   no)
Group.new('jsReturn',                      c.Magenta, c.none,   no)
-- httpc.//github.com/othree/yajs.vim
Group.new('javascriptArrowFunc',           c.Magenta, c.none,   no)
Group.new('javascriptClassExtends',        c.Magenta, c.none,   no)
Group.new('javascriptClassKeyword',        c.Magenta, c.none,   no)
Group.new('javascriptDocNotation',         c.Magenta, c.none,   no)
Group.new('javascriptDocParamName',        c.Cyan, c.none,   no)
Group.new('javascriptDocTags',             c.Magenta, c.none,   no)
Group.new('javascriptEndColons',           c.Grey, c.none,   no)
Group.new('javascriptExport',              c.Magenta, c.none,   no)
Group.new('javascriptFuncArg',             c.White, c.none,   no)
Group.new('javascriptFuncKeyword',         c.Magenta, c.none,   no)
Group.new('javascriptIdentifier',          c.Red, c.none,   no)
Group.new('javascriptImport',              c.Magenta, c.none,   no)
Group.new('javascriptObjectLabel',         c.White, c.none,   no)
Group.new('javascriptOpSymbol',            c.Green, c.none,   no)
Group.new('javascriptOpSymbols',           c.Green, c.none,   no)
Group.new('javascriptPropertyName',        c.Green, c.none,   no)
Group.new('javascriptTemplateSB',          c.BrightRed, c.none,   no)
Group.new('javascriptVariable',            c.Magenta, c.none,   no)

-- JSON
Group.new('jsonCommentError',              c.White, c.none,   no)
Group.new('jsonKeyword',                   c.Red, c.none,   no)
Group.new('jsonQuote',                     c.Grey, c.none,   no)
Group.new('jsonTrailingCommaError',        c.Red, c.none,   r)
Group.new('jsonMissingCommaError',         c.Red, c.none,   r)
Group.new('jsonNoQuotesError',             c.Red, c.none,   r)
Group.new('jsonNumError',                  c.Red, c.none,   r)
Group.new('jsonString',                    c.Green, c.none,   no)
Group.new('jsonBoolean',                   c.Magenta, c.none,   no)
Group.new('jsonNumber',                    c.Yellow, c.none,   no)
Group.new('jsonStringSQError',             c.Red, c.none,   r)
Group.new('jsonSemicolonError',            c.Red, c.none,   r)

-- Markdown
Group.new('markdownUrl',                   c.DarkBlue, c.none,   no)
Group.new('markdownBold',                  c.Yellow, c.none,   b)
Group.new('markdownItalic',                c.Yellow, c.none,   i)
Group.new('markdownCode',                  c.DarkGreen, c.none,   no)
Group.new('markdownCodeBlock',             c.Red, c.none,   no)
Group.new('markdownCodeDelimiter',         c.Green, c.none,   no)
Group.new('markdownHeadingDelimiter',      c.BrightRed, c.none,   no)
Group.new('markdownH1',                    c.Red, c.none,   no)
Group.new('markdownH2',                    c.Red, c.none,   no)
Group.new('markdownH3',                    c.Red, c.none,   no)
Group.new('markdownH3',                    c.Red, c.none,   no)
Group.new('markdownH4',                    c.Red, c.none,   no)
Group.new('markdownH5',                    c.Red, c.none,   no)
Group.new('markdownH6',                    c.Red, c.none,   no)
Group.new('markdownListMarker',            c.Red, c.none,   no)
Group.new('markdownlinktext',              c.Blue, c.none,  no)


-- TODO possible additional markdown groups
-- 'markdownfootnote'
-- 'markdownfootnotedefinition'
-- 'markdownlinebreak'

-- Markdown (keep consistent with HTML, above
-- Group.new('markdownItalic', c.fg3, c.none, i)
-- Group.new('markdownH1', g.htmlH1, g.htmlH1, g.htmlH1)
-- Group.new('markdownH2', g.htmlH2, g.htmlH2, g.htmlH2)
-- Group.new('markdownH3', g.htmlH3, g.htmlH3, g.htmlH3)
-- Group.new('markdownH4', g.htmlH4, g.htmlH4, g.htmlH4)
-- Group.new('markdownH5', g.htmlH5, g.htmlH5, g.htmlH5)
-- Group.new('markdownH6', g.htmlH6, g.htmlH6, g.htmlH6)
-- Group.new('markdownCode', c.purple2, c.none, no)
-- Group.new('mkdCode', g.markdownCode, g.markdownCode, g.markdownCode)
-- Group.new('markdownCodeBlock', c.aqua0, c.none, no)
-- Group.new('markdownCodeDelimiter', c.orange0, c.none, no)
-- Group.new('mkdCodeDelimiter', g.markdownCodeDelimiter, g.markdownCodeDelimiter, g.markdownCodeDelimiter)
-- Group.new('markdownBlockquote', c.grey, c.none, no)
-- Group.new('markdownListMarker', c.grey, c.none, no)
-- Group.new('markdownOrderedListMarker', c.grey, c.none, no)
-- Group.new('markdownRule', c.grey, c.none, no)
-- Group.new('markdownHeadingRule', c.grey, c.none, no)
-- Group.new('markdownUrlDelimiter', c.fg3, c.none, no)
-- Group.new('markdownLinkDelimiter', c.fg3, c.none, no)
-- Group.new('markdownLinkTextDelimiter', c.fg3, c.none, no)
-- Group.new('markdownHeadingDelimiter', c.orange0, c.none, no)
-- Group.new('markdownUrl', c.purple0, c.none, no)
-- Group.new('markdownUrlTitleDelimiter', c.green, c.none, no)
-- Group.new('markdownLinkText', g.htmlLink, g.htmlLink, g.htmlLink)
-- Group.new('markdownIdDeclaration', g.markdownLinkText, g.markdownLinkText, g.markdownLinkText)



-- PHP
Group.new('phpClass',                      c.DarkYellow, c.none,   no)
Group.new('phpFunction',                   c.Cyan, c.none,   no)
Group.new('phpFunctions',                  c.Cyan, c.none,   no)
Group.new('phpInclude',                    c.Magenta, c.none,   no)
Group.new('phpKeyword',                    c.Magenta, c.none,   no)
Group.new('phpParent',                     c.Grey, c.none,   no)
Group.new('phpType',                       c.Magenta, c.none,   no)
Group.new('phpSuperGlobals',               c.Red, c.none,   no)

---- Pug (Formerly Jade)
Group.new('pugAttributesDelimiter',        c.Yellow, c.none,   no)
Group.new('pugClass',                      c.Yellow, c.none,   no)
Group.new('pugDocType',                    c.Grey, c.none,   i)
Group.new('pugTag',                        c.Red, c.none,   no)

-- PureScript
Group.new('purescriptKeyword',             c.Magenta, c.none,   no)
Group.new('purescriptModuleName',          c.White, c.none,   no)
Group.new('purescriptIdentifier',          c.White, c.none,   no)
Group.new('purescriptType',                c.DarkYellow, c.none,   no)
Group.new('purescriptTypeVar',             c.Red, c.none,   no)
Group.new('purescriptConstructor',         c.Red, c.none,   no)
Group.new('purescriptOperator',            c.White, c.none,   no)

-- Python
Group.new('pythonImport',                  c.Magenta, c.none,   no)
Group.new('pythonBuiltin',                 c.Green, c.none,   no)
Group.new('pythonStatement',               c.Magenta, c.none,   no)
Group.new('pythonParam',                   c.Yellow, c.none,   no)
Group.new('pythonEscape',                  c.Red, c.none,   no)
Group.new('pythonSelf',                    c.DarkWhite, c.none,   i)
Group.new('pythonClass',                   c.Cyan, c.none,   no)
Group.new('pythonOperator',                c.Magenta, c.none,   no)
Group.new('pythonEscape',                  c.Red, c.none,   no)
Group.new('pythonFunction',                c.Cyan, c.none,   no)
Group.new('pythonKeyword',                 c.Cyan, c.none,   no)
Group.new('pythonModule',                  c.Magenta, c.none,   no)
Group.new('pythonStringDelimiter',         c.Green, c.none,   no)
Group.new('pythonSymbol',                  c.Green, c.none,   no)

-- Ruby
Group.new('rubyBlock',                     c.Magenta, c.none,   no)
Group.new('rubyBlockParameter',            c.Red, c.none,   no)
Group.new('rubyBlockParameterList',        c.Red, c.none,   no)
Group.new('rubyCapitalizedMethod',         c.Magenta, c.none,   no)
Group.new('rubyClass',                     c.Magenta, c.none,   no)
Group.new('rubyConstant',                  c.DarkYellow, c.none,   no)
Group.new('rubyControl',                   c.Magenta, c.none,   no)
Group.new('rubyDefine',                    c.Magenta, c.none,   no)
Group.new('rubyEscape',                    c.Red, c.none,   no)
Group.new('rubyFunction',                  c.Cyan, c.none,   no)
Group.new('rubyGlobalVariable',            c.Red, c.none,   no)
Group.new('rubyInclude',                   c.Cyan, c.none,   no)
Group.new('rubyIncluderubyGlobalVariable', c.Red, c.none,   no)
Group.new('rubyInstanceVariable',          c.Red, c.none,   no)
Group.new('rubyInterpolation',             c.Green, c.none,   no)
Group.new('rubyInterpolationDelimiter',    c.Red, c.none,   no)
Group.new('rubyKeyword',                   c.Cyan, c.none,   no)
Group.new('rubyModule',                    c.Magenta, c.none,   no)
Group.new('rubyPseudoVariable',            c.Red, c.none,   no)
Group.new('rubyRegexp',                    c.Green, c.none,   no)
Group.new('rubyRegexpDelimiter',           c.Green, c.none,   no)
Group.new('rubyStringDelimiter',           c.Green, c.none,   no)
Group.new('rubySymbol',                    c.Green, c.none,   no)

-- Spelling
Group.new('SpellBad',                      c.Grey, c.none,   uc)
Group.new('SpellLocal',                    c.Grey, c.none,   uc)
Group.new('SpellCap',                      c.Grey, c.none,   uc)
Group.new('SpellRare',                     c.Grey, c.none,   uc)

-- Vim
Group.new('vimCommand',                    c.Magenta, c.none,   no)
Group.new('vimCommentTitle',               c.Grey, c.none,   b)
Group.new('vimFunction',                   c.Green, c.none,   no)
Group.new('vimFuncName',                   c.Magenta, c.none,   no)
Group.new('vimHighlight',                  c.Cyan, c.none,   no)
Group.new('vimLineComment',                c.Grey, c.none,   i)
Group.new('vimParenSep',                   c.DarkWhite, c.none,   no)
Group.new('vimSep',                        c.DarkWhite, c.none,   no)
Group.new('vimUserFunc',                   c.Green, c.none,   no)
Group.new('vimVar',                        c.Red, c.none,   no)

-- XML
Group.new('xmlAttrib',                     c.DarkYellow, c.none,   no)
Group.new('xmlEndTag',                     c.Red, c.none,   no)
Group.new('xmlTag',                        c.Red, c.none,   no)
Group.new('xmlTagName',                    c.Red, c.none,   no)

---- ZSH
Group.new('zshCommands',                   c.White, c.none,   no)
Group.new('zshDeref',                      c.Red, c.none,   no)
Group.new('zshShortDeref',                 c.Red, c.none,   no)
Group.new('zshFunction',                   c.Green, c.none,   no)
Group.new('zshKeyword',                    c.Magenta, c.none,   no)
Group.new('zshSubst',                      c.Red, c.none,   no)
Group.new('zshSubstDelim',                 c.Grey, c.none,   no)
Group.new('zshTypes',                      c.Magenta, c.none,   no)
Group.new('zshVariableDef',                c.Yellow, c.none,   no)

-- Rust
Group.new('rustExternCrate',               c.Red, c.none,   b)
Group.new('rustIdentifier',                c.Cyan, c.none,   no)
Group.new('rustDeriveTrait',               c.Green, c.none,   no)
Group.new('SpecialComment',                c.Blue, c.none,   no)
Group.new('rustCommentLine',               c.DarkBlue, c.none,   no)
Group.new('rustCommentLineDoc',            c.Blue, c.none,   no)
Group.new('rustCommentLineDocError',       c.DarkRed, c.none,   no)
Group.new('rustCommentBlock',              c.DarkBlue, c.none,   no)
Group.new('rustCommentBlockDoc',           c.Blue, c.none,   no)
Group.new('rustCommentBlockDocError',      c.DarkRed, c.none,   no)

-- Man
Group.new('manTitle',                      g.String, g.String, g.String)
Group.new('manFooter',                     c.Grey, c.none,   no)

-------------------------
-- Plugin Highlighting --
-------------------------

-- ALE (Asynchronous Lint Engine)
Group.new('ALEWarningSign',                c.DarkYellow, c.none,   no)
Group.new('ALEErrorSign',                  c.Red, c.none,   no)

-- Neovim NERDTree Background fix
Group.new('NERDTreeFile',                  c.White, c.none,   no)

-- Coc.nvim Floating Background fix
-- Group.new('CocFloating',                   c.White, c.none,   no)
-- Group.new('NormalFloat',                   c.White, c.Grey, no)

-------------------------------
---- TreeSitter Highlighting --
-------------------------------
Group.new('TSAnnotation',         c.DarkYellow, c.none, no)
Group.new('TSAttribute',          c.Green,      c.none, no)
Group.new('TSBoolean',            c.Yellow,     c.none, no)
Group.new('TSCharacter',          c.Green,      c.none, no)
Group.new('TSConditional',        c.Magenta,       c.none, no)
Group.new('TSConstant',           c.Cyan,       c.none, no)
Group.new('TSConstBuiltin',       c.Yellow,     c.none, no)
Group.new('TSConstMacro',         c.Green,      c.none, no)
Group.new('TSConstructor',        c.Green,      c.none, no)
Group.new('TSEmphasis',           c.DarkYellow, c.none, no)
Group.new('TSError',              c.Red,        c.none, no)
Group.new('TSException',          c.Magenta,       c.none, no)
Group.new('TSField',              c.Red,        c.none, no)
Group.new('TSFloat',              c.Green,      c.none, no)
Group.new('TSFunction',           c.Cyan,       c.none, no)
Group.new('TSFuncBuiltin',        c.Cyan,       c.none, no)
Group.new('TSFuncMacro',          c.DarkYellow, c.none, no)
Group.new('TSInclude',            c.Magenta,       c.none, no)
Group.new('TSKeyword',            c.Magenta,       c.none, no)
Group.new('TSKeywordFunction',    c.Magenta,       c.none, no)
Group.new('TSKeywordOperator',    c.Magenta,       c.none, no)
Group.new('TSLabel',              c.Cyan,       c.none, no)
Group.new('TSLiteral',            c.DarkYellow, c.none, no)
Group.new('TSMethod',             c.Cyan,       c.none, no)
Group.new('TSNamespace',          c.Magenta,       c.none, no)
Group.new('TSNumber',             c.Yellow,     c.none, no)
Group.new('TSOperator',           c.Red,      c.none, no)
Group.new('TSParameter',          c.Green,      c.none, no)
Group.new('TSParameterReference', c.Green,      c.none, no)
Group.new('TSProperty',           c.DarkYellow, c.none, no)
Group.new('TSPunctBracket',       c.White,      c.none, no)
Group.new('TSPunctDelimiter',     c.White,      c.none, no)
Group.new('TSPunctSpecial',       c.White,      c.none, no)
Group.new('TSRepeat',             c.Magenta,       c.none, no)
Group.new('TSString',             c.Green,      c.none, no)
Group.new('TSStringEscape',       c.BrightBlue,      c.none, no)
Group.new('TSStringRegex',        c.BrightGreen,      c.none, no)
Group.new('TSStrong',             c.DarkYellow, c.none, no)
Group.new('TSStructure',          c.DarkYellow, c.none, no)
Group.new('TSTag',                c.Red,        c.none, no)
Group.new('TSTagDelimiter',       c.Grey,       c.none, no)
Group.new('TSText',               c.DarkYellow, c.none, no)
Group.new('TSTitle',              c.DarkYellow, c.none, no)
Group.new('TSType',               c.Blue,       c.none, no)
Group.new('TSTypeBuiltin',        c.BrightBlue,       c.none, no)
Group.new('TSUnderline',          c.DarkYellow, c.none, no)
Group.new('TSURI',                c.DarkYellow, c.none, no)
Group.new('TSVariable',           c.White,      c.none, no)
Group.new('TSVariableBuiltin',    c.DarkYellow, c.none, no)

-------------------------------
----     LSP Highlighting    --
-------------------------------
Group.new('LspDiagnosticsDefaultError',           c.BrightRed,        c.none, no)
Group.new('LspDiagnosticsDefaultWarning',         c.DarkYellow, c.none, no)
Group.new('LspDiagnosticsDefaultInformation',     c.DarkGreen,      c.none, no)
Group.new('LspDiagnosticsDefaultHint',            c.DarkGreen,      c.none, no)
Group.new('LspDiagnosticsVirtualTextError',       c.BrightRed,        c.none, no)
Group.new('LspDiagnosticsVirtualTextWarning',     c.DarkYellow, c.none, no)
Group.new('LspDiagnosticsVirtualTextInformation', c.DarkGreen,      c.none, no)
Group.new('LspDiagnosticsVirtualTextHint',        c.DarkGreen,      c.none, no)
Group.new('LspDiagnosticsUnderlineError',         c.BrightRed,        c.none, ul)
Group.new('LspDiagnosticsUnderlineWarning',       c.DarkYellow, c.none, ul)
Group.new('LspDiagnosticsUnderlineInformation',   c.DarkGreen,      c.none, ul)
Group.new('LspDiagnosticsUnderlineHint',          c.DarkGreen,      c.none, ul)
Group.new('LspDiagnosticsFloatingError',          c.BrightRed,        c.Grey, ul)
Group.new('LspDiagnosticsFloatingWarning',        c.DarkYellow, c.Grey, ul)
Group.new('LspDiagnosticsFloatingInformation',    c.DarkGreen,      c.Grey, ul)
Group.new('LspDiagnosticsFloatingHint',           c.DarkGreen,      c.Grey, ul)
Group.new('LspDiagnosticsSignError',              c.BrightRed,        c.none, no)
Group.new('LspDiagnosticsSignWarning',            c.DarkYellow, c.none, no)
Group.new('LspDiagnosticsSignInformation',        c.DarkGreen,      c.none, no)
Group.new('LspDiagnosticsSignHint',               c.DarkGreen,      c.none, no)



---- Git and git related plugins
Group.new('gitcommitComment',        c.Grey,                 c.none,                   no)
Group.new('gitcommitUnmerged',       c.Green,                 c.none,                   no)
Group.new('gitcommitOnBranch',       c.none,                   c.none,                   no)
Group.new('gitcommitBranch',         c.Magenta,                 c.none,                   no)
Group.new('gitcommitDiscardedType',  c.Red,                 c.none,                   no)
Group.new('gitcommitSelectedType',   c.Green,                 c.none,                   no)
Group.new('gitcommitHeader',         c.none,                   c.none,                   no)
Group.new('gitcommitUntrackedFile',  c.Green,                 c.none,                   no)
Group.new('gitcommitDiscardedFile',  c.Red,                 c.none,                   no)
Group.new('gitcommitSelectedFile',   c.Green,                 c.none,                   no)
Group.new('gitcommitUnmergedFile',   c.DarkYellow,                 c.none,                   no)
Group.new('gitcommitFile',           c.none,                   c.none,                   no)
Group.new('gitcommitNoBranch',       g.gitcommitBranch,        g.gitcommitBranch,        g.gitcommitBranch)
Group.new('gitcommitUntracked',      g.gitcommitComment,       g.gitcommitComment,       g.gitcommitComment)
Group.new('gitcommitDiscarded',      g.gitcommitComment,       g.gitcommitComment,       g.gitcommitComment)
Group.new('gitcommitDiscardedArrow', g.gitcommitDiscardedFile, g.gitcommitDiscardedFile, g.gitcommitDiscardedFile)
Group.new('gitcommitSelectedArrow',  g.gitcommitSelectedFile,  g.gitcommitSelectedFile,  g.gitcommitSelectedFile)
Group.new('gitcommitUnmergedArrow',  g.gitcommitUnmergedFile,  g.gitcommitUnmergedFile,  g.gitcommitUnmergedFile)
Group.new('SignifySignAdd',          c.Green,                 c.none,                   no)
Group.new('SignifySignChange',       c.Blue,                 c.none,                   no)
Group.new('SignifySignDelete',       c.Red,                 c.none,                   no)
Group.new('GitGutterAdd',            g.SignifySignAdd,         g.SignifySignAdd,         g.SignifySignAdd)
Group.new('GitGutterChange',         g.SignifySignChange,      g.SignifySignChange,      g.SignifySignChange)
Group.new('GitGutterDelete',         g.SignifySignDelete,      g.SignifySignDelete,      g.SignifySignDelete)
Group.new('diffAdded',               c.Green,                 c.none,                   no)
Group.new('diffRemoved',             c.Red,                 c.none,                   no)

