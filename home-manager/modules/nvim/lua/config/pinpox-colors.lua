-- local Color, c, Group, g, s = require("colorbuddy").setup()


local colorbuddy = require('colorbuddy')

-- Set up your custom colorscheme if you want
-- colorbuddy.colorscheme("my-colorscheme-name")

-- And then modify as you like
local Color = colorbuddy.Color
local c = colorbuddy.colors
local Group = colorbuddy.Group
local g = colorbuddy.groups
local s = colorbuddy.styles


local b   = s.bold
local i   = s.italic
local n   = s.inverse
local uc  = s.undercurl
local ul  = s.underline
local r   = s.reverse
local sto = s.standout
local no  = s.NONE
local v   = vim
local st  = s.strikethrough




-- TODO Think of a better colorscheme name
v.g.colors_name = 'generated'

local nixcolors = require('nixcolors')

-- Overrides for testing:
-- nixcolors.Black         = '#080c10'
-- nixcolors.BrightBlack   = '#697077'
-- nixcolors.White         = '#e0e0e0'
-- nixcolors.BrightWhite   = '#b5bdc5'
-- nixcolors.Red           = '#fa4d56'
-- nixcolors.BrightRed     = '#ff8389'
-- nixcolors.Yellow        = "#ff9900"
-- nixcolors.BrightYellow  = "#e5e041"
-- nixcolors.Green         = '#42be65'
-- nixcolors.BrightGreen = "#68f288"
-- nixcolors.Cyan          = "#22c5b7"
-- nixcolors.BrightCyan = "#A1E4FF"
-- nixcolors.Blue          = '#5080ff'
-- nixcolors.BrightBlue    = '#a6c8ff'
-- nixcolors.Magenta       = '#a56eff'
-- nixcolors.BrightMagenta = '#d4bbff'

-------------------------
-- Vim Primary Colors --
-------------------------
Color.new('Black',         nixcolors.Black)

Color.new('BrightBlack',   nixcolors.BrightBlack)

Color.new('White',         nixcolors.White)
Color.new('BrightWhite',   nixcolors.BrightWhite)

Color.new('Red',           nixcolors.Red)
Color.new('BrightRed',     nixcolors.BrightRed)

Color.new('Yellow',        nixcolors.Yellow)
Color.new('BrightYellow',  nixcolors.BrightYellow)

Color.new('Green',         nixcolors.Green)
Color.new('BrightGreen',   nixcolors.BrightGreen)

Color.new('Cyan',          nixcolors.Cyan)
Color.new('BrightCyan',    nixcolors.BrightCyan)

Color.new('Blue',          nixcolors.Blue)
Color.new('BrightBlue',    nixcolors.BrightBlue)

Color.new('Magenta',       nixcolors.Magenta)
Color.new('BrightMagenta', nixcolors.BrightMagenta)

-- Highlight missing groups in bright green so we can fix them along the way
Color.new('TODO', "#00ff00")



-------------------------------
---- TreeSitter Highlighting --
-------------------------------

Group.new('@annotation',                         c.Yellow,       c.none, no)
Group.new('@attribute',                          c.Green,        c.none, no)
Group.new('@boolean',                            c.Yellow,       c.none, no)
Group.new('@character',                          c.Green,        c.none, no)
Group.new('@character.special',                  c.TODO,         c.none, no)
Group.new('@comment',                            c.Blue,         c.none, i)
Group.new('@conditional',                        c.Magenta,      c.none, i)
Group.new('@const.macro',                        c.Green,        c.none, no)
Group.new('@constant',                           c.Cyan,         c.none, no)
Group.new('@constant.builtin',                   c.BrightYellow, c.none, b)
Group.new('@constant.comment',                   c.TODO,         c.none, no)
Group.new('@constant.html',                      c.BrightYellow, c.none, b)
Group.new('@constant.macro',                     c.TODO,         c.none, no)
Group.new('@constructor',                        c.Green,        c.none, no)
Group.new('@constructor.javascript',             c.Blue,         c.none, no)
Group.new('@constructor.lua',                    c.BrightWhite,  c.none, no)
Group.new('@constructor.typescript',             c.TODO,         c.none, no)
Group.new('@danger',                             c.TODO,         c.none, no)
Group.new('@debug',                              c.TODO,         c.none, no)
Group.new('@define',                             c.TODO,         c.none, no)
Group.new('@emphasis',                           c.Yellow,       c.none, no)
Group.new('@environment.name',                   c.TODO,         c.none, no)
Group.new('@error',                              c.Red,          c.none, no)
Group.new('@exception',                          c.Magenta,      c.none, no)
Group.new('@field',                              c.Cyan,         c.none, no)
Group.new('@field.yaml',                         c.Cyan,         c.none, no)
Group.new('@float',                              c.Green,        c.none, no)
Group.new('@function',                           c.Blue,         c.none, no)
Group.new('@function.builtin',                   c.Blue,         c.none, no)
Group.new('@function.call',                      c.Blue,         c.none, no)
Group.new('@function.macro',                     c.Yellow,       c.none, no)
Group.new('@include',                            c.Magenta,      c.none, no)
Group.new('@keyword',                            c.Magenta,      c.none, no)
Group.new('@keyword.function',                   c.Magenta,      c.none, no)
Group.new('@keyword.operator',                   c.Magenta,      c.none, no)
Group.new('@keyword.return',                     c.Magenta,      c.none, no)
Group.new('@label',                              c.Cyan,         c.none, no)
Group.new('@label.markdown',                     c.Cyan,         c.none, b)
Group.new('@label.c',                            c.TODO,         c.none, no)
Group.new('@label.json',                         c.Magenta,      c.none, b)
Group.new('@literal',                            c.Yellow,       c.none, no)
Group.new('@math',                               c.TODO,         c.none, no)
Group.new('@method',                             c.Cyan,         c.none, no)
Group.new('@method.call',                        c.Blue,         c.none, no)
Group.new('@namespace',                          c.Magenta,      c.none, no)
Group.new('@none',                               c.White,        c.none, no)
Group.new('@note',                               c.TODO,         c.none, no)
Group.new('@number',                             c.BrightYellow, c.none, no)
Group.new('@operator',                           c.Cyan,         c.none, no)
Group.new('@operator.javascript',                c.Cyan,         c.none, no)
Group.new('@parameter',                          c.Red,          c.none, i)
Group.new('@parameter.bash',                     c.Yellow,       c.none, no)
Group.new('@parameter.java',                     c.Red,          c.none, i)
Group.new('@parameter.javascript',               c.Red,          c.none, i)
Group.new('@parameter.python',                   c.Red,          c.none, i)
Group.new('@parameter.reference',                c.Green,        c.none, no)
Group.new('@parameter.scss',                     c.TODO,         c.none, no)
Group.new('@preproc',                            c.none,         c.none, no)
Group.new('@property',                           c.Yellow,       c.none, no)
Group.new('@property.css',                       c.Cyan,         c.none, no)
Group.new('@property.javascript',                c.Cyan,         c.none, no)
Group.new('@property.scss',                      c.TODO,         c.none, no)
Group.new('@punct.bracket',                      c.White,        c.none, no)
Group.new('@punct.delimiter',                    c.White,        c.none, no)
Group.new('@punct.delimiter.javascript',         c.TODO,         c.none, no)
Group.new('@punct.special',                      c.White,        c.none, no)
Group.new('@punctBracket',                       c.TODO,         c.none, no)
Group.new('@punctDelimiter',                     c.TODO,         c.none, no)
Group.new('@punctSpecial',                       c.TODO,         c.none, no)
Group.new('@punctuation.bracket',                c.BrightWhite,  c.none, no)
Group.new('@punctuation.bracket.json',           c.White,        c.none, no)
Group.new('@punctuation.delimiter',              c.Cyan,         c.none, no)
Group.new('@punctuation.special',                c.Magenta,      c.none, no)
Group.new('@punctuation.special.markdown_inline',c.BrightBlue,   c.none, no)
Group.new('@punctuation.special.markdown',       c.BrightBlue,   c.none, no)
Group.new('@query.linter.error',                 c.TODO,         c.none, no)
Group.new('@repeat',                             c.Magenta,      c.none, no)
Group.new('@spell',                              c.none,         c.none, no)
Group.new('@spell.lua',                          c.Green,        c.none, no)
Group.new('@spell.json',                         c.none,         c.none, no)
Group.new('@spell.bash',                         c.Green,        c.none, no)
Group.new('@spell.comment',                      c.BrightWhite,  c.none, no)
Group.new('@spell.markdown',                     c.none,         c.none, no)
Group.new('@storageclass',                       c.TODO,         c.none, no)
Group.new('@strike',                             c.TODO,         c.none, no)
Group.new('@string',                             c.Green,        c.none, no)
Group.new('@string.json',                        c.Green,        c.none, no)
Group.new('@string.css',                         c.BrightYellow, c.none, no)
Group.new('@string.escape',                      c.BrightBlue,   c.none, no)
Group.new('@string.escape.regex',                c.TODO,         c.none, no)
Group.new('@string.regex',                       c.BrightGreen,  c.none, no)
Group.new('@string.special',                     c.BrightBlue,   c.none, no)
Group.new('@string.bash',                        c.Green,        c.none, no)
Group.new('@strong',                             c.Yellow,       c.none, no)
Group.new('@structure',                          c.Yellow,       c.none, no)
Group.new('@symbol',                             c.TODO,         c.none, no)
Group.new('@tag',                                c.Magenta,      c.none, no)
Group.new('@tag.attribute',                      c.Blue,         c.none, no)
Group.new('@tag.delimiter',                      c.BrightWhite,  c.none, no)
Group.new('@text',                               c.Yellow,       c.none, no)
Group.new('@text.danger',                        c.TODO,         c.none, no)
Group.new('@text.diff.add',                      c.TODO,         c.none, no)
Group.new('@text.diff.delete',                   c.TODO,         c.none, no)
Group.new('@text.emphasis',                      c.TODO,         c.none, no)
Group.new('@text.environment',                   c.TODO,         c.none, no)
Group.new('@text.environment.name',              c.TODO,         c.none, no)
Group.new('@text.todo.comment',                  c.BrightYellow, c.none, b)
Group.new('@text.literal',                       c.Yellow,       c.none, no)
Group.new('@text.math',                          c.TODO,         c.none, no)
Group.new('@text.note',                          c.TODO,         c.none, no)
Group.new('@text.reference',                     c.Blue,         c.none, no)
Group.new('@text.strike',                        c.TODO,         c.none, no)
Group.new('@text.strong',                        c.none,         c.none, b)
Group.new('@text.title',                         c.White,        c.none, b)
Group.new('@text.title.1',                       c.BrightBlue,   c.none, b)
Group.new('@text.title.2',                       c.Blue,         c.none, b)
Group.new('@text.title.3',                       c.Blue,         c.none, no)
Group.new('@text.title.4',                       c.DarkCyan,     c.none, b)
Group.new('@text.title.5',                       c.DarkCyan,     c.none, no)
Group.new('@text.title.6',                       c.Magenta,      c.none, no)
Group.new('@text.title.1.marker.markdown',       c.BrightYellow, c.none, b)
Group.new('@text.title.2.marker.markdown',       c.BrightYellow, c.none, b)
Group.new('@text.title.3.marker.markdown',       c.BrightYellow, c.none, b)
Group.new('@text.title.4.marker.markdown',       c.BrightYellow, c.none, b)
Group.new('@text.title.5.marker.markdown',       c.BrightYellow, c.none, b)
Group.new('@text.title.6.marker.markdown',       c.BrightYellow, c.none, b)
Group.new('@text.todo',                          c.TODO,         c.none, no)
Group.new('@text.underline',                     c.TODO,         c.none, no)
Group.new('@text.uri',                           c.Blue,         c.none, no)
Group.new('@text.warning',                       c.TODO,         c.none, no)
Group.new('@title',                              c.Yellow,       c.none, no)
Group.new('@todo',                               c.TODO,         c.none, no)
Group.new('@type',                               c.Blue,         c.none, no)
Group.new('@type.builtin',                       c.Yellow,       c.none, no)
Group.new('@type.css',                           c.Magenta,      c.none, no)
Group.new('@type.definition',                    c.Cyan,         c.none, b)
Group.new('@type.java',                          c.TODO,         c.none, no)
Group.new('@type.javascript',                    c.BrightBlue,   c.none, no)
Group.new('@type.python',                        c.TODO,         c.none, no)
Group.new('@type.ruby',                          c.TODO,         c.none, no)
Group.new('@type.scss',                          c.TODO,         c.none, no)
Group.new('@type.typescript',                    c.TODO,         c.none, no)
Group.new('@uRI',                                c.Yellow,       c.none, no)
Group.new('@underline',                          c.Yellow,       c.none, no)
Group.new('@uri',                                c.TODO,         c.none, no)
Group.new('@variable',                           c.White,        c.none, no)
Group.new('@variable.builtin',                   c.Yellow,       c.none, no)
Group.new('@variable.java',                      c.TODO,         c.none, no)
Group.new('@variable.javascript',                c.White,        c.none, no)
Group.new('@variable.scss',                      c.TODO,         c.none, no)
Group.new('@warning',                            c.TODO,         c.none, no)

Group.new('@markup.link',             c.BrightBlue,   c.none, no)
Group.new('@markup.link.label',       c.Blue,         c.none, ul)
Group.new('@markup.link.url',         c.BrightBlack,  c.none, i)
Group.new('@markup.strong',           c.none,         c.none, b)
Group.new('@markup.italic',           c.none,         c.none, i)
Group.new('@markup.strikethrough',    c.none,         c.none, st)
Group.new('@markup.quote',            c.Magenta,      c.none, i)
Group.new('@markup.raw.block',        c.BrightWhite,  c.none, no)
Group.new('@markup.block',            c.none,         c.none, no)
Group.new('@markup.list',             c.Cyan,         c.none, b)
Group.new('markdownCode',             c.Green,        c.none, no)
Group.new('markdownCode',             c.Green,        c.none, no)
Group.new('markdownCodeBlock',        c.Red,          c.none, no)
Group.new('markdownCodeDelimiter',    c.Green,        c.none, no)
Group.new('markdownHeadingDelimiter', c.BrightRed,    c.none, no)
Group.new('@markup.heading',          c.none,         c.none, sto)
Group.new('@markup.heading.1',        c.BrightRed,    c.none, b)
Group.new('@markup.heading.2',        c.Red,          c.none, b)
Group.new('@markup.heading.3',        c.Yellow,       c.none, b)
Group.new('@markup.heading.4',        c.BrightYellow, c.none, b)
Group.new('@markup.heading.5',        c.Green,        c.none, b)
Group.new('@markup.heading.6',        c.Red,          c.none, b)
Group.new('@markup.heading.7',        c.Red,          c.none, b)
Group.new('markdownListMarker',       c.Red,          c.none, b)
Group.new('markdownlinktext',         c.Blue,         c.none, b)

---------------------------
---- Vim Terminal Colors --
---------------------------

v.g.terminal_color_0  = nixcolors.Black
v.g.terminal_color_8  = nixcolors.BrightBlack
v.g.terminal_color_1  = nixcolors.Red
v.g.terminal_color_9  = nixcolors.BrightRed
v.g.terminal_color_2  = nixcolors.Green
v.g.terminal_color_10 = nixcolors.BrightGreen
v.g.terminal_color_3  = nixcolors.Yellow
v.g.terminal_color_11 = nixcolors.BrightYellow
v.g.terminal_color_4  = nixcolors.Blue
v.g.terminal_color_12 = nixcolors.BrightBlue
v.g.terminal_color_5  = nixcolors.Magenta
v.g.terminal_color_13 = nixcolors.BrightMagenta
v.g.terminal_color_6  = nixcolors.Cyan
v.g.terminal_color_14 = nixcolors.BrightCyan
v.g.terminal_color_7  = nixcolors.White
v.g.terminal_color_15 = nixcolors.BrightWhite


-- Group.new('@annotation', c.TODO ,c.none, no)
-- Group.new('@attribute', c.TODO ,c.none, no)
-- Group.new('@boolean', c.TODO ,c.none, no)
-- Group.new('@character', c.TODO ,c.none, no)
-- Group.new('@character.special', c.TODO ,c.none, no)
-- Group.new('@comment', c.TODO ,c.none, no)
-- Group.new('@conditional', c.TODO ,c.none, no)
-- Group.new('@constant', c.TODO ,c.none, no)
-- Group.new('@constant.builtin', c.TODO ,c.none, no)
-- Group.new('@constant.macro', c.TODO ,c.none, no)
-- Group.new('@constructor', c.TODO ,c.none, no)
-- Group.new('@debug', c.TODO ,c.none, no)
-- Group.new('@define', c.TODO ,c.none, no)
-- Group.new('@error', c.TODO ,c.none, no)
-- Group.new('@exception', c.TODO ,c.none, no)
-- Group.new('@field', c.TODO ,c.none, no)
-- Group.new('@float', c.TODO ,c.none, no)
-- Group.new('@function', c.TODO ,c.none, no)
-- Group.new('@function.builtin', c.TODO ,c.none, no)
-- Group.new('@function.call', c.TODO ,c.none, no)
-- Group.new('@function.macro', c.TODO ,c.none, no)
-- Group.new('@include', c.TODO ,c.none, no)
-- Group.new('@keyword', c.TODO ,c.none, no)
-- Group.new('@keyword.coroutine', c.TODO ,c.none, no)
-- Group.new('@keyword.function', c.TODO ,c.none, no)
-- Group.new('@keyword.operator', c.TODO ,c.none, no)
-- Group.new('@keyword.return', c.TODO ,c.none, no)
-- Group.new('@label', c.TODO ,c.none, no)
-- Group.new('@method', c.TODO ,c.none, no)
-- Group.new('@method.call', c.TODO ,c.none, no)
-- Group.new('@namespace', c.TODO ,c.none, no)
-- Group.new('@none', c.TODO ,c.none, no)
-- Group.new('@number', c.TODO ,c.none, no)
-- Group.new('@operator', c.TODO ,c.none, no)
-- Group.new('@parameter', c.TODO ,c.none, no)
-- Group.new('@parameter.reference', c.TODO ,c.none, no)
-- Group.new('@preproc', c.TODO ,c.none, no)
-- Group.new('@property', c.TODO ,c.none, no)
-- Group.new('@punctuation.bracket', c.TODO ,c.none, no)
-- Group.new('@punctuation.delimiter', c.TODO ,c.none, no)
-- Group.new('@punctuation.special', c.TODO ,c.none, no)
-- Group.new('@repeat', c.TODO ,c.none, no)
-- Group.new('@storageclass', c.TODO ,c.none, no)
-- Group.new('@string', c.TODO ,c.none, no)
-- Group.new('@string.escape', c.TODO ,c.none, no)
-- Group.new('@string.regex', c.TODO ,c.none, no)
-- Group.new('@string.special', c.TODO ,c.none, no)
-- Group.new('@symbol', c.TODO ,c.none, no)
-- Group.new('@tag', c.TODO ,c.none, no)
-- Group.new('@tag.attribute', c.TODO ,c.none, no)
-- Group.new('@tag.delimiter', c.TODO ,c.none, no)
-- Group.new('@text', c.TODO ,c.none, no)
-- Group.new('@text.danger', c.TODO ,c.none, no)
-- Group.new('@text.emphasis', c.TODO ,c.none, no)
-- Group.new('@text.environment', c.TODO ,c.none, no)
-- Group.new('@text.environment.name', c.TODO ,c.none, no)
-- Group.new('@text.literal', c.TODO ,c.none, no)
-- Group.new('@text.math', c.TODO ,c.none, no)
-- Group.new('@text.note', c.TODO ,c.none, no)
-- Group.new('@text.reference', c.TODO ,c.none, no)
-- Group.new('@text.strike', c.TODO ,c.none, no)
-- Group.new('@text.strong', c.TODO ,c.none, no)
-- Group.new('@text.title', c.TODO ,c.none, no)
-- Group.new('@text.todo', c.TODO ,c.none, no)
-- Group.new('@text.underline', c.TODO ,c.none, no)
-- Group.new('@text.uri', c.TODO ,c.none, no)
-- Group.new('@text.warning', c.TODO ,c.none, no)
-- Group.new('@type', c.TODO ,c.none, no)
-- Group.new('@type.builtin', c.TODO ,c.none, no)
-- Group.new('@type.definition', c.TODO ,c.none, no)
-- Group.new('@type.qualifier', c.TODO ,c.none, no)
-- Group.new('@variable', c.TODO ,c.none, no)
-- Group.new('@variable.builtin', c.TODO ,c.none, no)


------------------------
---- Vim Editor Color --
------------------------

Group.new('Normal',                   c.White,         c.Black,       no)
Group.new('bold',                     c.none,          c.none,        b)
Group.new('ColorColumn',              c.none,          c.BrightBlack, no)
Group.new('Conceal',                  c.BrightBlack,   c.Black,       no)
Group.new('Cursor',                   c.Magenta,       c.Cyan,        no)
Group.new('CursorIM',                 c.Red,           c.none,        no)
Group.new('CursorColumn',             c.Green,         c.BrightBlack, no)
Group.new('CursorLine',               c.none,          c.none,        no)
Group.new('CursorLineNr',             c.Cyan,          c.BrightBlack, no)
Group.new('Directory',                c.Cyan,          c.none,        no)
Group.new('ErrorMsg',                 c.Red,           c.none,        no)
Group.new('VertSplit',                c.Blue,          c.none,        no)
Group.new('Folded',                   c.BrightBlack,   c.none,        no)
Group.new('FoldColumn',               c.BrightBlack,   c.BrightBlack, no)
Group.new('IncSearch',                c.Black,         c.Cyan,        no)
Group.new('LineNr',                   c.BrightBlack,   c.none,        no)
Group.new('MatchParen',               c.Red,           c.BrightBlack, ul + b)
Group.new('Italic',                   c.none,          c.none,        i)
Group.new('ModeMsg',                  c.White,         c.none,        no)
Group.new('MoreMsg',                  c.White,         c.none,        no)
Group.new('NonText',                  c.BrightBlack,   c.none,        no)
Group.new('PMenu',                    c.none,          c.BrightBlack, no)
Group.new('PMenuSel',                 c.none,          c.Blue,        no)
Group.new('PMenuSbar',                c.none,          c.BrightBlue,  no)
Group.new('PMenuThumb',               c.none,          c.White,       no)
Group.new('Question',                 c.Cyan,          c.none,        no)
Group.new('Search',                   c.BrightBlack,   c.Yellow,      no)
Group.new('SpecialKey',               c.BrightBlack,   c.none,        no)
Group.new('Whitespace',               c.BrightBlack,   c.none,        no)
Group.new('StatusLine',               c.White,         c.BrightBlack, no)
Group.new('StatusLineNC',             c.BrightBlack,   c.none,        no)
Group.new('TabLine',                  c.White,         c.BrightBlack, no)
Group.new('TabLineFill',              c.BrightBlack,   c.BrightBlack, no)
Group.new('TabLineSel',               c.BrightBlack,   c.Cyan,        no)
Group.new('Title',                    c.White,         c.none,        b)
Group.new('Visual',                   c.none,          c.BrightBlack, no)
Group.new('VisualNOS',                c.none,          c.BrightBlack, no)
Group.new('WarningMsg',               c.Red,           c.none,        no)
Group.new('TooLong',                  c.Red,           c.none,        no)
Group.new('WildMenu',                 c.White,         c.BrightBlack, no)
Group.new('SignColumn',               c.none,          c.none,        no)
Group.new('Special',                  c.Cyan,          c.none,        no)

------------------------------
---- Wilder.nvim Popup-Menu --
------------------------------

Group.new('WilderDefault',            c.White,         c.none,        no)
Group.new('WilderAccent',             c.BrightYellow,  c.none,        no)
Group.new('WilderSelected',           c.Blue,          c.BrightBlack, b)
Group.new('WilderSelectedAccent',     c.Magenta,       c.BrightBlack, b)
Group.new('WilderError',              c.Red,           c.none,        no)
Group.new('WilderSeparator',          c.Green,         c.BrightBlack, no)
Group.new('WilderBorder',             c.Blue,          c.none,        no)

-----------------------------
---- Vim Help Highlighting --
-----------------------------

Group.new('helpCommand',              c.BrightYellow,  c.none,        no)
Group.new('helpExample',              c.BrightYellow,  c.none,        no)
Group.new('helpHeader',               c.White,         c.none,        b)
Group.new('helpSectionDelim',         c.BrightBlack,   c.none,        no)

------------------------------------
---- Standard Syntax Highlighting --
------------------------------------

Group.new('Comment',                  c.Blue,          c.none,        i)
Group.new('Constant',                 c.Green,         c.none,        no)
Group.new('String',                   c.Green,         c.none,        no)
Group.new('Character',                c.Green,         c.none,        no)
Group.new('Number',                   c.BrightYellow,  c.none,        no)
Group.new('Boolean',                  c.BrightYellow,  c.none,        no)
Group.new('Float',                    c.BrightYellow,  c.none,        no)
Group.new('Identifier',               c.Red,           c.none,        no)
Group.new('Function',                 c.Cyan,          c.none,        no)
Group.new('Statement',                c.Magenta,       c.none,        no)
Group.new('Conditional',              c.Magenta,       c.none,        no)
Group.new('Repeat',                   c.Magenta,       c.none,        no)
Group.new('Label',                    c.Magenta,       c.none,        no)
Group.new('Operator',                 c.Cyan,          c.none,        no)
Group.new('Keyword',                  c.Red,           c.none,        no)
Group.new('Exception',                c.Magenta,       c.none,        no)
Group.new('PreProc',                  c.Yellow,        c.none,        no)
Group.new('Include',                  c.Cyan,          c.none,        no)
Group.new('Define',                   c.Magenta,       c.none,        no)
Group.new('Macro',                    c.Magenta,       c.none,        no)
Group.new('PreCondit',                c.Yellow,        c.none,        no)
Group.new('Type',                     c.Yellow,        c.none,        no)
Group.new('StorageClass',             c.Yellow,        c.none,        no)
-- Group.new('Structure',             c.Yellow,        c.none,        no)
Group.new('Typedef',                  c.Yellow,        c.none,        no)
Group.new('Special',                  c.Cyan,          c.none,        no)
Group.new('SpecialChar',              c.none,          c.none,        no)
Group.new('Tag',                      c.none,          c.none,        no)
Group.new('Delimiter',                c.none,          c.none,        no)
Group.new('SpecialComment',           c.none,          c.none,        no)
Group.new('Debug',                    c.none,          c.none,        no)
Group.new('Underlined',               c.none,          c.none,        ul)
Group.new('Ignore',                   c.none,          c.none,        no)
Group.new('Error',                    c.Red,           c.BrightBlack, b)
Group.new('Todo',                     c.BrightYellow,  c.BrightBlack, no)

-------------------------
---- Diff Highlighting --
-------------------------

Group.new('DiffAdd',                  c.Green,         c.BrightBlack, no)
Group.new('DiffChange',               c.BrightYellow,  c.BrightBlack, no)
Group.new('DiffDelete',               c.Red,           c.BrightBlack, no)
Group.new('DiffText',                 c.Cyan,          c.BrightBlack, no)
Group.new('DiffAdded',                c.Green,         c.BrightBlack, no)
Group.new('DiffFile',                 c.Red,           c.BrightBlack, no)
Group.new('DiffNewFile',              c.Green,         c.BrightBlack, no)
Group.new('DiffLine',                 c.Cyan,          c.BrightBlack, no)
Group.new('DiffRemoved',              c.Red,           c.BrightBlack, no)

-----------------------------
---- Filetype Highlighting --
-----------------------------

---- Asciidoc
Group.new('asciidocListingBlock',     c.White,         c.none,        no)

---- C/C++ highlighting
Group.new('cInclude',                 c.Magenta,       c.none,        no)
Group.new('cPreCondit',               c.Magenta,       c.none,        no)
Group.new('cPreConditMatch',          c.Magenta,       c.none,        no)
Group.new('cType',                    c.Magenta,       c.none,        no)
Group.new('cStorageClass',            c.Magenta,       c.none,        no)
Group.new('cStructure',               c.Magenta,       c.none,        no)
Group.new('cOperator',                c.Magenta,       c.none,        no)
Group.new('cStatement',               c.Magenta,       c.none,        no)
Group.new('cTODO',                    c.Magenta,       c.none,        no)
Group.new('cConstant',                c.BrightYellow,  c.none,        no)
Group.new('cSpecial',                 c.Green,         c.none,        no)
Group.new('cSpecialCharacter',        c.Green,         c.none,        no)
Group.new('cString',                  c.Green,         c.none,        no)
Group.new('cppType',                  c.Magenta,       c.none,        no)
Group.new('cppStorageClass',          c.Magenta,       c.none,        no)
Group.new('cppStructure',             c.Magenta,       c.none,        no)
Group.new('cppModifier',              c.Magenta,       c.none,        no)
Group.new('cppOperator',              c.Magenta,       c.none,        no)
Group.new('cppAccess',                c.Magenta,       c.none,        no)
Group.new('cppStatement',             c.Magenta,       c.none,        no)
Group.new('cppConstant',              c.Red,           c.none,        no)
Group.new('cCppString',               c.Green,         c.none,        no)

---- Cucumber
Group.new('cucumberGiven',            c.Cyan,          c.none,        no)
Group.new('cucumberWhen',             c.Cyan,          c.none,        no)
Group.new('cucumberWhenAnd',          c.Cyan,          c.none,        no)
Group.new('cucumberThen',             c.Cyan,          c.none,        no)
Group.new('cucumberThenAnd',          c.Cyan,          c.none,        no)
Group.new('cucumberUnparsed',         c.BrightYellow,  c.none,        no)
Group.new('cucumberFeature',          c.Red,           c.none,        b)
Group.new('cucumberBackground',       c.Magenta,       c.none,        b)
Group.new('cucumberScenario',         c.Magenta,       c.none,        b)
Group.new('cucumberScenarioOutline',  c.Magenta,       c.none,        b)
Group.new('cucumberTags',             c.BrightBlack,   c.none,        b)
Group.new('cucumberDelimiter',        c.BrightBlack,   c.none,        b)

---- CSS/Sass
Group.new('cssAttrComma',             c.Magenta,       c.none,        no)
Group.new('cssAttributeSelector',     c.Green,         c.none,        no)
Group.new('cssBraces',                c.White,         c.none,        no)
Group.new('cssClassName',             c.BrightYellow,  c.none,        no)
Group.new('cssClassNameDot',          c.BrightYellow,  c.none,        no)
Group.new('cssDefinition',            c.Magenta,       c.none,        no)
Group.new('cssFontAttr',              c.BrightYellow,  c.none,        no)
Group.new('cssFontDescriptor',        c.BrightMagenta, c.none,        no)
Group.new('cssFunctionName',          c.Cyan,          c.none,        no)
Group.new('cssIdentifier',            c.Cyan,          c.none,        no)
Group.new('cssImportant',             c.Magenta,       c.none,        no)
Group.new('cssInclude',               c.White,         c.none,        no)
Group.new('cssIncludeKeyword',        c.Magenta,       c.none,        no)
Group.new('cssMediaType',             c.BrightYellow,  c.none,        no)
Group.new('cssProp',                  c.Green,         c.none,        no)
Group.new('cssPseudoClassId',         c.BrightYellow,  c.none,        no)
Group.new('cssSelectorOp',            c.Magenta,       c.none,        no)
Group.new('cssSelectorOp2',           c.Magenta,       c.none,        no)
Group.new('cssStringQ',               c.Green,         c.none,        no)
Group.new('cssStringQQ',              c.Green,         c.none,        no)
Group.new('cssTagName',               c.Red,           c.none,        no)
Group.new('cssAttr',                  c.BrightYellow,  c.none,        no)
Group.new('sassAmpersand',            c.Red,           c.none,        no)
Group.new('sassClass',                c.Yellow,        c.none,        no)
Group.new('sassControl',              c.Magenta,       c.none,        no)
Group.new('sassExtend',               c.Magenta,       c.none,        no)
Group.new('sassFor',                  c.White,         c.none,        no)
Group.new('sassProperty',             c.Green,         c.none,        no)
Group.new('sassFunction',             c.Green,         c.none,        no)
Group.new('sassId',                   c.Cyan,          c.none,        no)
Group.new('sassInclude',              c.Magenta,       c.none,        no)
Group.new('sassMedia',                c.Magenta,       c.none,        no)
Group.new('sassMediaOperators',       c.White,         c.none,        no)
Group.new('sassMixin',                c.Magenta,       c.none,        no)
Group.new('sassMixinName',            c.Cyan,          c.none,        no)
Group.new('sassMixing',               c.Magenta,       c.none,        no)
Group.new('scssSelectorName',         c.Yellow,        c.none,        no)

-- Elixir
Group.new('elixirModuleDefine',       g.Define,        g.Define,      g.Define)
Group.new('elixirAlias',              c.Yellow,        c.none,        no)
Group.new('elixirAtom',               c.Green,         c.none,        no)
Group.new('elixirBlockDefinition',    c.Magenta,       c.none,        no)
Group.new('elixirModuleDeclaration',  c.Yellow,        c.none,        no)
Group.new('elixirInclude',            c.Red,           c.none,        no)
Group.new('elixirOperator',           c.Yellow,        c.none,        no)

---- Go
Group.new('goDeclaration',            c.Magenta,       c.none,        no)
Group.new('goField',                  c.Red,           c.none,        no)
Group.new('goMethod',                 c.Green,         c.none,        no)
Group.new('goType',                   c.Magenta,       c.none,        no)
Group.new('goUnsignedInts',           c.Green,         c.none,        no)

---- Haskell
Group.new('haskellDeclKeyword',       c.Cyan,          c.none,        no)
Group.new('haskellType',              c.Green,         c.none,        no)
Group.new('haskellWhere',             c.Red,           c.none,        no)
Group.new('haskellImportKeywords',    c.Cyan,          c.none,        no)
Group.new('haskellOperators',         c.Red,           c.none,        no)
Group.new('haskellDelimiter',         c.Cyan,          c.none,        no)
Group.new('haskellIdentifier',        c.Yellow,        c.none,        no)
Group.new('haskellKeyword',           c.Red,           c.none,        no)
Group.new('haskellNumber',            c.Green,         c.none,        no)
Group.new('haskellString',            c.Green,         c.none,        no)

-- HTML
Group.new('htmlArg',                  c.Yellow,        c.none,        no)
Group.new('htmlTagName',              c.Red,           c.none,        no)
Group.new('htmlTagN',                 c.Red,           c.none,        no)
Group.new('htmlSpecialTagName',       c.Red,           c.none,        no)
Group.new('htmlTag',                  c.White,         c.none,        no)
Group.new('htmlEndTag',               c.White,         c.none,        no)
Group.new('MatchTag',                 c.Red,           c.BrightBlack, ul + b)

---- JavaScript
Group.new('coffeeString',             c.Green,         c.none,        no)
Group.new('javaScriptBraces',         c.White,         c.none,        no)
Group.new('javaScriptFunction',       c.Magenta,       c.none,        no)
Group.new('javaScriptIdentifier',     c.Magenta,       c.none,        no)
Group.new('javaScriptNull',           c.Yellow,        c.none,        no)
Group.new('javaScriptNumber',         c.Yellow,        c.none,        no)
Group.new('javaScriptRequire',        c.Green,         c.none,        no)
Group.new('javaScriptReserved',       c.Magenta,       c.none,        no)
-- httpc.//github.com/pangloss/vim-javascript
Group.new('jsArrowFunction',          c.Magenta,       c.none,        no)
Group.new('jsBraces',                 c.White,         c.none,        no)
Group.new('jsClassBraces',            c.White,         c.none,        no)
Group.new('jsClassKeywords',          c.Magenta,       c.none,        no)
Group.new('jsDocParam',               c.Cyan,          c.none,        no)
Group.new('jsDocTags',                c.Magenta,       c.none,        no)
Group.new('jsFuncBraces',             c.White,         c.none,        no)
Group.new('jsFuncCall',               c.Cyan,          c.none,        no)
Group.new('jsFuncParens',             c.White,         c.none,        no)
Group.new('jsFunction',               c.Magenta,       c.none,        no)
Group.new('jsGlobalObjects',          c.Yellow,        c.none,        no)
Group.new('jsModuleWords',            c.Magenta,       c.none,        no)
Group.new('jsModules',                c.Magenta,       c.none,        no)
Group.new('jsNoise',                  c.White,         c.none,        no)
Group.new('jsNull',                   c.Yellow,        c.none,        no)
Group.new('jsOperator',               c.Magenta,       c.none,        no)
Group.new('jsParens',                 c.White,         c.none,        no)
Group.new('jsStorageClass',           c.Magenta,       c.none,        no)
Group.new('jsTemplateBraces',         c.BrightRed,     c.none,        no)
Group.new('jsTemplateVar',            c.Green,         c.none,        no)
Group.new('jsThis',                   c.Red,           c.none,        no)
Group.new('jsUndefined',              c.Yellow,        c.none,        no)
Group.new('jsObjectValue',            c.Cyan,          c.none,        no)
Group.new('jsObjectKey',              c.Green,         c.none,        no)
Group.new('jsReturn',                 c.Magenta,       c.none,        no)
-- httpc.//github.com/othree/yajs.vim
Group.new('javascriptArrowFunc',      c.Magenta,       c.none,        no)
Group.new('javascriptClassExtends',   c.Magenta,       c.none,        no)
Group.new('javascriptClassKeyword',   c.Magenta,       c.none,        no)
Group.new('javascriptDocNotation',    c.Magenta,       c.none,        no)
Group.new('javascriptDocParamName',   c.Cyan,          c.none,        no)
Group.new('javascriptDocTags',        c.Magenta,       c.none,        no)
Group.new('javascriptEndColons',      c.BrightBlack,   c.none,        no)
Group.new('javascriptExport',         c.Magenta,       c.none,        no)
Group.new('javascriptFuncArg',        c.White,         c.none,        no)
Group.new('javascriptFuncKeyword',    c.Magenta,       c.none,        no)
Group.new('javascriptIdentifier',     c.Red,           c.none,        no)
Group.new('javascriptImport',         c.Magenta,       c.none,        no)
Group.new('javascriptObjectLabel',    c.White,         c.none,        no)
Group.new('javascriptOpSymbol',       c.Green,         c.none,        no)
Group.new('javascriptOpSymbols',      c.Green,         c.none,        no)
Group.new('javascriptPropertyName',   c.Green,         c.none,        no)
Group.new('javascriptTemplateSB',     c.BrightRed,     c.none,        no)
Group.new('javascriptVariable',       c.Magenta,       c.none,        no)

-- JSON
Group.new('jsonCommentError',         c.White,         c.none,        no)
Group.new('jsonKeyword',              c.Red,           c.none,        no)
Group.new('jsonQuote',                c.Blue,          c.none,        no)
Group.new('jsonTrailingCommaError',   c.Red,           c.none,        r)
Group.new('jsonMissingCommaError',    c.Red,           c.none,        r)
Group.new('jsonNoQuotesError',        c.Red,           c.none,        r)
Group.new('jsonNumError',             c.Red,           c.none,        r)
Group.new('jsonString',               c.Green,         c.none,        no)
Group.new('jsonBoolean',              c.Magenta,       c.none,        no)
Group.new('jsonNumber',               c.Yellow,        c.none,        no)
Group.new('jsonStringSQError',        c.Red,           c.none,        r)
Group.new('jsonSemicolonError',       c.Red,           c.none,        r)

-- Markdown

Group.new('markdownUrl',              c.Blue,          c.none,        no)
Group.new('markdownBold',             c.Yellow,        c.none,        b)
Group.new('markdownItalic',           c.Yellow,        c.none,        i)
Group.new('markdownCode',             c.Green,         c.none,        no)
Group.new('markdownCodeBlock',        c.Red,           c.none,        no)
Group.new('markdownCodeDelimiter',    c.Green,         c.none,        no)
Group.new('markdownHeadingDelimiter', c.BrightRed,     c.none,        no)
Group.new('markdownH1',               c.Red,           c.none,        no)
Group.new('markdownH2',               c.Red,           c.none,        no)
Group.new('markdownH3',               c.Red,           c.none,        no)
Group.new('markdownH3',               c.Red,           c.none,        no)
Group.new('markdownH4',               c.Red,           c.none,        no)
Group.new('markdownH5',               c.Red,           c.none,        no)
Group.new('markdownH6',               c.Red,           c.none,        no)
Group.new('markdownListMarker',       c.Red,           c.none,        no)
Group.new('markdownlinktext',         c.Blue,          c.none,        no)


-- TODO possible additional markdown groups
-- 'markdownfootnote'
-- 'markdownfootnotedefinition'
-- 'markdownlinebreak'

-- Markdown (keep consistent with HTML,   above
-- Group.new('markdownItalic',            c.fg3,                   c.none,                  i)
-- Group.new('markdownH1',                g.htmlH1,                g.htmlH1,                g.htmlH1)
-- Group.new('markdownH2',                g.htmlH2,                g.htmlH2,                g.htmlH2)
-- Group.new('markdownH3',                g.htmlH3,                g.htmlH3,                g.htmlH3)
-- Group.new('markdownH4',                g.htmlH4,                g.htmlH4,                g.htmlH4)
-- Group.new('markdownH5',                g.htmlH5,                g.htmlH5,                g.htmlH5)
-- Group.new('markdownH6',                g.htmlH6,                g.htmlH6,                g.htmlH6)
-- Group.new('markdownCode',              c.purple2,               c.none,                  no)
-- Group.new('mkdCode',                   g.markdownCode,          g.markdownCode,          g.markdownCode)
-- Group.new('markdownCodeBlock',         c.aqua0,                 c.none,                  no)
-- Group.new('markdownCodeDelimiter',     c.orange0,               c.none,                  no)
-- Group.new('mkdCodeDelimiter',          g.markdownCodeDelimiter, g.markdownCodeDelimiter, g.markdownCodeDelimiter)
-- Group.new('markdownBlockquote',        c.brightblack,           c.none,                  no)
-- Group.new('markdownListMarker',        c.brightblack,           c.none,                  no)
-- Group.new('markdownOrderedListMarker', c.brightblack,           c.none,                  no)
-- Group.new('markdownRule',              c.brightblack,           c.none,                  no)
-- Group.new('markdownHeadingRule',       c.brightblack,           c.none,                  no)
-- Group.new('markdownUrlDelimiter',      c.fg3,                   c.none,                  no)
-- Group.new('markdownLinkDelimiter',     c.fg3,                   c.none,                  no)
-- Group.new('markdownLinkTextDelimiter', c.fg3,                   c.none,                  no)
-- Group.new('markdownHeadingDelimiter',  c.orange0,               c.none,                  no)
-- Group.new('markdownUrl',               c.purple0,               c.none,                  no)
-- Group.new('markdownUrlTitleDelimiter', c.green,                 c.none,                  no)
-- Group.new('markdownLinkText',          g.htmlLink,              g.htmlLink,              g.htmlLink)
-- Group.new('markdownIdDeclaration',     g.markdownLinkText,      g.markdownLinkText,      g.markdownLinkText)



-- PHP
Group.new('phpClass',                             c.Yellow,      c.none,        no)
Group.new('phpFunction',                          c.Cyan,        c.none,        no)
Group.new('phpFunctions',                         c.Cyan,        c.none,        no)
Group.new('phpInclude',                           c.Magenta,     c.none,        no)
Group.new('phpKeyword',                           c.Magenta,     c.none,        no)
Group.new('phpParent',                            c.BrightBlack, c.none,        no)
Group.new('phpType',                              c.Magenta,     c.none,        no)
Group.new('phpSuperGlobals',                      c.Red,         c.none,        no)

---- Pug (Formerly Jade)
Group.new('pugAttributesDelimiter',               c.Yellow,      c.none,        no)
Group.new('pugClass',                             c.Yellow,      c.none,        no)
Group.new('pugDocType',                           c.BrightBlack, c.none,        i)
Group.new('pugTag',                               c.Red,         c.none,        no)

-- PureScript
Group.new('purescriptKeyword',                    c.Magenta,     c.none,        no)
Group.new('purescriptModuleName',                 c.White,       c.none,        no)
Group.new('purescriptIdentifier',                 c.White,       c.none,        no)
Group.new('purescriptType',                       c.Yellow,      c.none,        no)
Group.new('purescriptTypeVar',                    c.Red,         c.none,        no)
Group.new('purescriptConstructor',                c.Red,         c.none,        no)
Group.new('purescriptOperator',                   c.White,       c.none,        no)

-- Python
Group.new('pythonImport',                         c.Magenta,     c.none,        no)
Group.new('pythonBuiltin',                        c.Green,       c.none,        no)
Group.new('pythonStatement',                      c.Magenta,     c.none,        no)
Group.new('pythonParam',                          c.Yellow,      c.none,        no)
Group.new('pythonEscape',                         c.Red,         c.none,        no)
Group.new('pythonSelf',                           c.White,       c.none,        i)
Group.new('pythonClass',                          c.Cyan,        c.none,        no)
Group.new('pythonOperator',                       c.Magenta,     c.none,        no)
Group.new('pythonEscape',                         c.Red,         c.none,        no)
Group.new('pythonFunction',                       c.Cyan,        c.none,        no)
Group.new('pythonKeyword',                        c.Cyan,        c.none,        no)
Group.new('pythonModule',                         c.Magenta,     c.none,        no)
Group.new('pythonStringDelimiter',                c.Green,       c.none,        no)
Group.new('pythonSymbol',                         c.Green,       c.none,        no)

-- Ruby
Group.new('rubyBlock',                            c.Magenta,     c.none,        no)
Group.new('rubyBlockParameter',                   c.Red,         c.none,        no)
Group.new('rubyBlockParameterList',               c.Red,         c.none,        no)
Group.new('rubyCapitalizedMethod',                c.Magenta,     c.none,        no)
Group.new('rubyClass',                            c.Magenta,     c.none,        no)
Group.new('rubyConstant',                         c.Yellow,      c.none,        no)
Group.new('rubyControl',                          c.Magenta,     c.none,        no)
Group.new('rubyDefine',                           c.Magenta,     c.none,        no)
Group.new('rubyEscape',                           c.Red,         c.none,        no)
Group.new('rubyFunction',                         c.Cyan,        c.none,        no)
Group.new('rubyGlobalVariable',                   c.Red,         c.none,        no)
Group.new('rubyInclude',                          c.Cyan,        c.none,        no)
Group.new('rubyIncluderubyGlobalVariable',        c.Red,         c.none,        no)
Group.new('rubyInstanceVariable',                 c.Red,         c.none,        no)
Group.new('rubyInterpolation',                    c.Green,       c.none,        no)
Group.new('rubyInterpolationDelimiter',           c.Red,         c.none,        no)
Group.new('rubyKeyword',                          c.Cyan,        c.none,        no)
Group.new('rubyModule',                           c.Magenta,     c.none,        no)
Group.new('rubyPseudoVariable',                   c.Red,         c.none,        no)
Group.new('rubyRegexp',                           c.Green,       c.none,        no)
Group.new('rubyRegexpDelimiter',                  c.Green,       c.none,        no)
Group.new('rubyStringDelimiter',                  c.Green,       c.none,        no)
Group.new('rubySymbol',                           c.Green,       c.none,        no)

-- Spelling
Group.new('SpellBad',                             c.BrightBlack, c.Red,         uc)
Group.new('SpellLocal',                           c.BrightBlack, c.none,        uc)
Group.new('SpellCap',                             c.BrightBlack, c.none,        uc)
Group.new('SpellRare',                            c.BrightBlack, c.none,        uc)
Group.new('DiagnosticUnderlineInfo',              c.none,        c.none,        uc)

-- Vim
Group.new('vimCommand',                           c.Magenta,     c.none,        no)
Group.new('vimCommentTitle',                      c.BrightBlack, c.none,        b)
Group.new('vimFunction',                          c.Green,       c.none,        no)
Group.new('vimFuncName',                          c.Magenta,     c.none,        no)
Group.new('vimHighlight',                         c.Cyan,        c.none,        no)
Group.new('vimLineComment',                       c.BrightBlack, c.none,        i)
Group.new('vimParenSep',                          c.White,       c.none,        no)
Group.new('vimSep',                               c.White,       c.none,        no)
Group.new('vimUserFunc',                          c.Green,       c.none,        no)
Group.new('vimVar',                               c.Red,         c.none,        no)

-- XML
Group.new('xmlAttrib',                            c.Yellow,      c.none,        no)
Group.new('xmlEndTag',                            c.Red,         c.none,        no)
Group.new('xmlTag',                               c.Red,         c.none,        no)
Group.new('xmlTagName',                           c.Red,         c.none,        no)

---- ZSH
Group.new('zshCommands',                          c.White,       c.none,        no)
Group.new('zshDeref',                             c.Red,         c.none,        no)
Group.new('zshShortDeref',                        c.Red,         c.none,        no)
Group.new('zshFunction',                          c.Green,       c.none,        no)
Group.new('zshKeyword',                           c.Magenta,     c.none,        no)
Group.new('zshSubst',                             c.Red,         c.none,        no)
Group.new('zshSubstDelim',                        c.BrightBlack, c.none,        no)
Group.new('zshTypes',                             c.Magenta,     c.none,        no)
Group.new('zshVariableDef',                       c.Yellow,      c.none,        no)

-- Rust
Group.new('rustExternCrate',                      c.Red,         c.none,        b)
Group.new('rustIdentifier',                       c.Cyan,        c.none,        no)
Group.new('rustDeriveTrait',                      c.Green,       c.none,        no)
Group.new('SpecialComment',                       c.Blue,        c.none,        no)
Group.new('rustCommentLine',                      c.Blue,        c.none,        no)
Group.new('rustCommentLineDoc',                   c.Blue,        c.none,        no)
Group.new('rustCommentLineDocError',              c.Red,         c.none,        no)
Group.new('rustCommentBlock',                     c.Blue,        c.none,        no)
Group.new('rustCommentBlockDoc',                  c.Blue,        c.none,        no)
Group.new('rustCommentBlockDocError',             c.Red,         c.none,        no)

-- Man
Group.new('manTitle',                             g.String,      g.String,      g.String)
Group.new('manFooter',                            c.BrightBlack, c.none,        no)

-------------------------
-- Plugin Highlighting --
-------------------------

-- ALE (Asynchronous Lint Engine)
Group.new('ALEWarningSign',                       c.Yellow,      c.none,        no)
Group.new('ALEErrorSign',                         c.Red,         c.none,        no)

-- Neovim NERDTree Background fix
Group.new('NERDTreeFile',                         c.White,       c.none,        no)

-- Coc.nvim Floating Background fix
-- Group.new('CocFloating',                       c.White,       c.none,        no)
-- Group.new('NormalFloat',                       c.White,       c.BrightBlack, no)


-------------------------------
----     LSP Highlighting    --
-------------------------------
Group.new('LspDiagnosticsDefaultError',           c.BrightRed,   c.none,        no)
Group.new('LspDiagnosticsDefaultWarning',         c.Yellow,      c.none,        no)
Group.new('LspDiagnosticsDefaultInformation',     c.Green,       c.none,        no)
Group.new('LspDiagnosticsDefaultHint',            c.Green,       c.none,        no)
Group.new('LspDiagnosticsVirtualTextError',       c.BrightRed,   c.none,        no)
Group.new('LspDiagnosticsVirtualTextWarning',     c.Yellow,      c.none,        no)
Group.new('LspDiagnosticsVirtualTextInformation', c.Green,       c.none,        no)
Group.new('LspDiagnosticsVirtualTextHint',        c.Green,       c.none,        no)
Group.new('LspDiagnosticsUnderlineError',         c.BrightRed,   c.none,        ul)
Group.new('LspDiagnosticsUnderlineWarning',       c.Yellow,      c.none,        ul)
Group.new('LspDiagnosticsUnderlineInformation',   c.Green,       c.none,        ul)
Group.new('LspDiagnosticsUnderlineHint',          c.Green,       c.none,        ul)
Group.new('LspDiagnosticsFloatingError',          c.BrightRed,   c.BrightBlack, ul)
Group.new('LspDiagnosticsFloatingWarning',        c.Yellow,      c.BrightBlack, ul)
Group.new('LspDiagnosticsFloatingInformation',    c.Green,       c.BrightBlack, ul)
Group.new('LspDiagnosticsFloatingHint',           c.Green,       c.BrightBlack, ul)
Group.new('LspDiagnosticsSignError',              c.BrightRed,   c.none,        no)
Group.new('LspDiagnosticsSignWarning',            c.Yellow,      c.none,        no)
Group.new('LspDiagnosticsSignInformation',        c.Green,       c.none,        no)
Group.new('LspDiagnosticsSignHint',               c.Green,       c.none,        no)

---- Git and git related plugins
Group.new('gitcommitComment',                     c.BrightBlack,            c.none,                   no)
Group.new('gitcommitUnmerged',                    c.Green,                  c.none,                   no)
Group.new('gitcommitOnBranch',                    c.none,                   c.none,                   no)
Group.new('gitcommitBranch',                      c.Magenta,                c.none,                   no)
Group.new('gitcommitDiscardedType',               c.Red,                    c.none,                   no)
Group.new('gitcommitSelectedType',                c.Green,                  c.none,                   no)
Group.new('gitcommitHeader',                      c.none,                   c.none,                   no)
Group.new('gitcommitUntrackedFile',               c.Green,                  c.none,                   no)
Group.new('gitcommitDiscardedFile',               c.Red,                    c.none,                   no)
Group.new('gitcommitSelectedFile',                c.Green,                  c.none,                   no)
Group.new('gitcommitUnmergedFile',                c.Yellow,                 c.none,                   no)
Group.new('gitcommitFile',                        c.none,                   c.none,                   no)
Group.new('gitcommitNoBranch',                    g.gitcommitBranch,        g.gitcommitBranch,        g.gitcommitBranch)
Group.new('gitcommitUntracked',                   g.gitcommitComment,       g.gitcommitComment,       g.gitcommitComment)
Group.new('gitcommitDiscarded',                   g.gitcommitComment,       g.gitcommitComment,       g.gitcommitComment)
Group.new('gitcommitDiscardedArrow',              g.gitcommitDiscardedFile, g.gitcommitDiscardedFile, g.gitcommitDiscardedFile)
Group.new('gitcommitSelectedArrow',               g.gitcommitSelectedFile,  g.gitcommitSelectedFile,  g.gitcommitSelectedFile)
Group.new('gitcommitUnmergedArrow',               g.gitcommitUnmergedFile,  g.gitcommitUnmergedFile,  g.gitcommitUnmergedFile)
Group.new('SignifySignAdd',                       c.Green,                  c.none,                   no)
Group.new('SignifySignChange',                    c.Blue,                   c.none,                   no)
Group.new('SignifySignDelete',                    c.Red,                    c.none,                   no)
Group.new('GitGutterAdd',                         g.SignifySignAdd,         g.SignifySignAdd,         g.SignifySignAdd)
Group.new('GitGutterChange',                      g.SignifySignChange,      g.SignifySignChange,      g.SignifySignChange)
Group.new('GitGutterDelete',                      g.SignifySignDelete,      g.SignifySignDelete,      g.SignifySignDelete)
Group.new('diffAdded',                            c.Green,                  c.none,                   no)
Group.new('diffRemoved',                          c.Red,                    c.none,                   no)

--- Indent Blanklinhe
Group.new('IndentBlanklineChar',         c.BrightBlack, c.none,        no)
Group.new('IndentBlanklineContextStart', c.none,        c.BrightBlack, no)
Group.new('IndentBlanklineContextChar',  c.Blue,        c.none,        no)

-- Vim illuminate
Group.new('IlluminatedWordText',         c.none,        c.BrightBlack, no)
