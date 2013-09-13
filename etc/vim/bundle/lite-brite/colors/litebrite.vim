" Title: LiteBrite
" Author: Joel Holdbrooks <cjholdbrooks@gmail.com>
" URI: https://github.com/noprompt/lite-brite

set background=dark
highlight clear

if exists("syntax_on")
  syntax reset
endif

let g:colors_name = "LiteBrite"

" To fix gutter color when using vim-gitgutter plugin
" https://github.com/airblade/vim-gitgutter
highlight clear SignColumn

" Color variables {{{

let s:NO_FG = " ctermfg=NONE guifg=NONE"
let s:NO_BG = " ctermbg=NONE guibg=NONE"

let s:BLACK = " ctermfg=0 guifg=#000000"
let s:BLUE = " ctermfg=117 guifg=#87d7ff"
let s:FUCHSIA = " ctermfg=213 guifg=#ff87ff"
let s:GREEN = " ctermfg=120 guifg=#87ff87"
let s:ORANGE = " ctermfg=221 guifg=#fad482"
let s:PINK = " ctermfg=219 guifg=#ffafff"
let s:PURPLE = " ctermfg=183 guifg=#d7afff"
let s:RED = " ctermfg=210 guifg=#ff8787"
let s:TURQUOISE = " ctermfg=45 guifg=#00ddff"
let s:TEAL = " ctermfg=87 guifg=#5fffff"
let s:WHITE = " ctermfg=15 guifg=#ffffff"
let s:YELLOW = " ctermfg=227 guifg=#ffff5f"

let s:GREY1 = " ctermfg=233 guifg=#121212"
let s:GREY2 = " ctermfg=234 guifg=#1c1c1c"
let s:GREY3 = " ctermfg=235 guifg=#262626"
let s:GREY4 = " ctermfg=236 guifg=#303030"
let s:GREY5 = " ctermfg=237 guifg=#3a3a3a"
let s:GREY6 = " ctermfg=238 guifg=#444444"
let s:GREY7 = " ctermfg=239 guifg=#4e4e4e"
let s:GREY8 = " ctermfg=240 guifg=#585858"
let s:GREY9 = " ctermfg=241 guifg=#626262"
let s:GREY10 = " ctermfg=242 guifg=#6c6c6c"
let s:GREY11 = " ctermfg=243 guifg=#767676"
let s:GREY12 = " ctermfg=244 guifg=#808080"
let s:GREY13 = " ctermfg=245 guifg=#8a8a8a"

" Background colors
let s:BLACK_BG = " ctermbg=0 guibg=#000000"
let s:GREY1_BG = " ctermbg=233 guibg=#121212"
let s:GREY2_BG = " ctermbg=234 guibg=#1c1c1c"
let s:GREY3_BG = " ctermbg=235 guibg=#262626"
let s:GREY4_BG = " ctermbg=236 guibg=#303030"
let s:GREY5_BG = " ctermbg=237 guibg=#3a3a3a"
let s:GREY6_BG = " ctermbg=238 guibg=#444444"
let s:GREY7_BG = " ctermbg=239 guibg=#4e4e4e"
let s:GREY8_BG = " ctermbg=240 guibg=#585858"
let s:GREY9_BG = " ctermbg=241 guibg=#626262"
let s:GREY10_BG = " ctermbg=242 guibg=#6c6c6c"
let s:GREY11_BG = " ctermbg=243 guibg=#767676"
let s:GREY12_BG = " ctermbg=244 guibg=#808080"
let s:GREY13_BG = " ctermbg=245 guibg=#8a8a8a"

" }}}
" Formatting variables {{{

" NOTE: Italics generally aren't suppored in the terminal so cterm italics are
" skipped.

let s:REVERSE = " cterm=reverse gui=reverse"
let s:BOLD = " cterm=bold gui=bold"
let s:ITALIC = " gui=italic"
let s:UNDERLINE = " cterm=underline gui=underline"
let s:BOLD_ITALIC = " cterm=bold gui=bold,italic"
let s:BOLD_UNDERLINE = " cterm=bold,underline gui=bold,underline"
let s:BOLD_ITALIC_UNDERLINE = " cterm=bold,underline gui=bold,italic,underline"
let s:ITALIC_UNDERLINE = " cterm=underline gui=italic,underline"
let s:NO_FORMAT = " cterm=NONE gui=NONE"

" }}}
" LiteBrite highlights  {{{

" Normal
exe "hi litebriteBlue" . s:BLUE . s:NO_FORMAT
exe "hi litebriteFuchsia" . s:FUCHSIA . s:NO_FORMAT
exe "hi litebriteGreen" . s:GREEN . s:NO_FORMAT
exe "hi litebriteOrange" . s:ORANGE . s:NO_FORMAT
exe "hi litebritePink" . s:PINK . s:NO_FORMAT
exe "hi litebritePurple" . s:PURPLE . s:NO_FORMAT
exe "hi litebriteRed" . s:RED . s:NO_FORMAT
exe "hi litebriteTurquoise" . s:TURQUOISE . s:NO_FORMAT
exe "hi litebriteTeal" . s:TEAL . s:NO_FORMAT
exe "hi litebriteWhite" . s:WHITE . s:NO_FORMAT
exe "hi litebriteYellow" . s:YELLOW . s:NO_FORMAT
exe "hi litebriteGrey1" . s:GREY1 . s:NO_FORMAT
exe "hi litebriteGrey2" . s:GREY2 . s:NO_FORMAT
exe "hi litebriteGrey3" . s:GREY3 . s:NO_FORMAT
exe "hi litebriteGrey4" . s:GREY4 . s:NO_FORMAT
exe "hi litebriteGrey5" . s:GREY5 . s:NO_FORMAT
exe "hi litebriteGrey6" . s:GREY6 . s:NO_FORMAT
exe "hi litebriteGrey7" . s:GREY7 . s:NO_FORMAT
exe "hi litebriteGrey8" . s:GREY8 . s:NO_FORMAT
exe "hi litebriteGrey9" . s:GREY9 . s:NO_FORMAT
exe "hi litebriteGrey10" . s:GREY10 . s:NO_FORMAT
exe "hi litebriteGrey11" . s:GREY11 . s:NO_FORMAT
exe "hi litebriteGrey12" . s:GREY12 . s:NO_FORMAT
exe "hi litebriteGrey13" . s:GREY13 . s:NO_FORMAT

" Bold
exe "hi litebriteBoldBlue" . s:BLUE . s:BOLD
exe "hi litebriteBoldFuchsia" . s:FUCHSIA . s:BOLD
exe "hi litebriteBoldGreen" . s:GREEN . s:BOLD
exe "hi litebriteBoldOrange" . s:ORANGE . s:BOLD
exe "hi litebriteBoldPink" . s:PINK . s:BOLD
exe "hi litebriteBoldPurple" . s:PURPLE . s:BOLD
exe "hi litebriteBoldRed" . s:RED . s:BOLD
exe "hi litebriteBoldTurquoise" . s:TURQUOISE . s:BOLD
exe "hi litebriteBoldTeal" . s:TEAL . s:BOLD
exe "hi litebriteBoldWhite" . s:WHITE . s:BOLD
exe "hi litebriteBoldYellow" . s:YELLOW . s:BOLD
exe "hi litebriteBoldGrey1" . s:GREY1 . s:BOLD
exe "hi litebriteBoldGrey2" . s:GREY2 . s:BOLD
exe "hi litebriteBoldGrey3" . s:GREY3 . s:BOLD
exe "hi litebriteBoldGrey4" . s:GREY4 . s:BOLD
exe "hi litebriteBoldGrey5" . s:GREY5 . s:BOLD
exe "hi litebriteBoldGrey6" . s:GREY6 . s:BOLD
exe "hi litebriteBoldGrey7" . s:GREY7 . s:BOLD
exe "hi litebriteBoldGrey8" . s:GREY8 . s:BOLD
exe "hi litebriteBoldGrey9" . s:GREY9 . s:BOLD
exe "hi litebriteBoldGrey10" . s:GREY10 . s:BOLD
exe "hi litebriteBoldGrey11" . s:GREY11 . s:BOLD
exe "hi litebriteBoldGrey12" . s:GREY12 . s:BOLD
exe "hi litebriteBoldGrey13" . s:GREY13 . s:BOLD

" Italic
exe "hi litebriteItalicBlue" . s:BLUE . s:ITALIC
exe "hi litebriteItalicFuchsia" . s:FUCHSIA . s:ITALIC
exe "hi litebriteItalicGreen" . s:GREEN . s:ITALIC
exe "hi litebriteItalicOrange" . s:ORANGE . s:ITALIC
exe "hi litebriteItalicPink" . s:PINK . s:ITALIC
exe "hi litebriteItalicPurple" . s:PURPLE . s:ITALIC
exe "hi litebriteItalicRed" . s:RED . s:ITALIC
exe "hi litebriteItalicTurquoise" . s:TURQUOISE . s:ITALIC
exe "hi litebriteItalicTeal" . s:TEAL . s:ITALIC
exe "hi litebriteItalicWhite" . s:WHITE . s:ITALIC
exe "hi litebriteItalicYellow" . s:YELLOW . s:ITALIC
exe "hi litebriteItalicGrey1" . s:GREY1 . s:ITALIC
exe "hi litebriteItalicGrey2" . s:GREY2 . s:ITALIC
exe "hi litebriteItalicGrey3" . s:GREY3 . s:ITALIC
exe "hi litebriteItalicGrey4" . s:GREY4 . s:ITALIC
exe "hi litebriteItalicGrey5" . s:GREY5 . s:ITALIC
exe "hi litebriteItalicGrey6" . s:GREY6 . s:ITALIC
exe "hi litebriteItalicGrey7" . s:GREY7 . s:ITALIC
exe "hi litebriteItalicGrey8" . s:GREY8 . s:ITALIC
exe "hi litebriteItalicGrey9" . s:GREY9 . s:ITALIC
exe "hi litebriteItalicGrey10" . s:GREY10 . s:ITALIC
exe "hi litebriteItalicGrey11" . s:GREY11 . s:ITALIC
exe "hi litebriteItalicGrey12" . s:GREY12 . s:ITALIC
exe "hi litebriteItalicGrey13" . s:GREY13 . s:ITALIC

" Highlights for common syntax types.
hi link litebriteEscapeChar litebriteBoldTeal
hi link litebriteRegexp litebriteGreen
hi link litebriteRegexpBackRef Special
hi link litebriteRegexpBoundary litebriteBoldYellow
hi link litebriteRegexpCharClass litebriteBlue
hi link litebriteRegexpDelim litebriteBoldGreen
hi link litebriteRegexpQuantifier litebriteWhite
hi link litebriteRegexpSep litebriteYellow
hi link litebriteRegexpMod litebriteFuchsia
hi link litebriteRegexpBracketExp String

" }}}
" Top level highlights {{{

" NOTE: `hi link`ing these does not work for some reason.
exe "hi Normal" . s:WHITE . s:BLACK_BG . s:NO_FORMAT
exe "hi Boolean" . s:ORANGE . s:NO_FORMAT
exe "hi Character" . s:TURQUOISE . s:NO_FORMAT
exe "hi Comment" . s:GREY6 . s:ITALIC
exe "hi Constant" . s:WHITE . s:BOLD
exe "hi Conditional" . s:PINK . s:NO_FORMAT
exe "hi Delimiter" . s:NO_FORMAT
exe "hi Function" . s:BLUE . s:NO_FORMAT
exe "hi Keyword" . s:RED . s:NO_FORMAT
exe "hi Number" . s:GREEN . s:NO_FORMAT
exe "hi Special" . s:RED . s:NO_FORMAT
exe "hi Statement" . s:BLUE . s:NO_FORMAT
exe "hi String" . s:TURQUOISE . s:NO_FORMAT
exe "hi Todo" . s:NO_BG . s:GREY13
exe "hi Type" . s:BLUE . s:NO_FORMAT
exe "hi ColorColumn" . s:GREY1_BG . s:NO_FORMAT
exe "hi CursorLine" . s:GREY1_BG . s:NO_FORMAT
exe "hi CursorLineNr" . s:GREY5 . s:NO_FORMAT
exe "hi MatchParen" . s:WHITE . s:GREY4_BG . s:BOLD
exe "hi SpellBad" . s:RED . s:BOLD_UNDERLINE . s:NO_BG
" Folds and line numbers should standout but not too much.
exe "hi Folded" . s:GREY10 . s:GREY2_BG . s:ITALIC
exe "hi LineNr" . s:GREY3 . s:GREY1_BG . s:ITALIC
exe "hi NonText" . s:GREY3 . s:GREY1_BG . s:NO_FORMAT
" Popup menu
exe "hi Pmenu" . s:GREY5 . s:GREY1_BG . s:ITALIC
" Popup menu scroll bar
exe "hi PmenuSbar" . s:BLACK_BG . s:GREY1
" Popup menu selection
exe "hi PmenuSel" . s:ORANGE . s:BLACK_BG . s:NO_FORMAT
" Simply underline search results.
exe "hi Search" . s:NO_FG . s:NO_BG . s:UNDERLINE
exe "hi VertSplit" . s:GREY5 . s:GREY2_BG . s:BOLD
exe "hi Visual" . s:BLACK_BG . s:PURPLE . s:REVERSE
exe "hi StatusLine" . s:GREY2 . s:GREY8_BG
exe "hi StatusLineNC" . s:BLACK . s:GREY4_BG
exe "hi Tabline" . s:GREY10 . s:GREY3_BG . s:NO_FORMAT
exe "hi TablineFill" . s:GREY1 . s:NO_FORMAT
hi TablineSel ctermfg=248 ctermbg=236
hi Conceal ctermfg=202 guifg=#FF8800 ctermbg=0 guibg=#000000 cterm=bold gui=bold

hi link PreProc Comment
hi link Float Number
hi link Identifier Normal
hi link SpecialChar litebriteEscapeChar

" }}}
" vim {{{

hi link vimAddress litebriteYellow
hi link vimAutoCmd litebritePurple
hi link vimAutoEvent litebritePink
hi link vimCommentTitle Todo
hi link vimContinue litebriteWhite
" Not sure why this doesn't work.
hi link vimCollection litebriteRegexpCharClass
hi link vimFuncSID litebriteYellow
hi link vimFunction litebriteWhite
hi link vimGroup litebriteWhite
hi link vimHiAttrib litebriteYellow
hi link vimHiCterm litebriteFuchsia
hi link vimHiCtermFgBg litebriteFuchsia
hi link vimHiGui litebriteFuchsia
hi link vimHiGuiFgBg litebriteFuchsia
hi link vimLet litebriteRed
hi link vimMap litebritePurple
hi link vimMapModKey litebriteYellow
hi link vimNotation litebriteYellow
hi link vimOper litebriteWhite
hi link vimPatSep litebriteRegexpSep
" This helps with \(\) madness.
hi link vimPatSepR litebriteRegexpSep
hi link vimSetSep litebriteWhite
hi link vimSubstDelim litebriteRegexp
hi link vimSubstPat litebriteRegexp
hi link vimSynPatRange litebriteRegexpCharClass
hi link vimSynReg litebriteRed
hi link vimSynRegPat litebriteRegexp
hi link vimSynType litebritePurple
hi link vimSyntax litebriteFuchsia
hi link vimVar litebriteWhite

" }}}
" help {{{

exec "hi helpHyperTextJump " . s:UNDERLINE . s:NO_BG . s:BLUE
hi link helpExample litebriteWhite
hi link helpHeader litebriteWhite
hi link helpHyperTextEntry litebriteGreen
hi link helpNote Todo
hi link helpSectionDelim litebriteGrey5
hi link helpSpecial litebriteYellow

" }}}
" netrw {{{

hi link netrwClassify litebriteBoldWhite
hi link netrwCmdSep litebriteWhite
hi link netrwDir litebriteBlue
hi link netrwExe litebriteRed
hi link netrwHelpCmd litebriteYellow
hi link netrwList litebritePurple
hi link netrwQuickHelp litebriteYellow
hi link netrwTreeBar litebriteWhite
hi link netrwVersion litebriteBoldWhite

" }}}
" python {{{

hi link pythonStatement litebriteRed
hi link pythonBuiltin litebriteWhite
hi link pythonOperator litebriteRed
hi link pythonException litebriteRed
hi link pythonInclude litebriteRed

" }}}
" ruby {{{

hi link rubyAccess litebritePurple
hi link rubyAttribute litebriteBlue
hi link rubyBlockParameter litebriteOrange
hi link rubyClass Keyword
hi link rubyClassDeclaration Constant
hi link rubyClassVariable litebriteOrange
hi link rubyConstant Constant
hi link rubyControl Keyword
hi link rubyData Comment
hi link rubyDataDirective litebriteYellow
hi link rubyDefine Keyword
hi link rubyFunction Function
hi link rubyGlobalVariable Constant
hi link rubyInclude Keyword
hi link rubyInstanceVariable litebriteGreen
hi link rubyInterpolationDelimiter Comment
hi link rubyModuleDeclaration Constant
hi link rubyPredefinedConstant litebriteBoldYellow
hi link rubyPredefinedVariable litebriteYellow
hi link rubyPseudoVariable litebriteWhite
hi link rubyPseudoVariable litebriteYellow
hi link rubyRailsUserClass Constant
hi link rubyRegexp litebriteRegexp
hi link rubyRegexpAnchor litebriteRegexpBoundary
hi link rubyRegexpBrackets Special
hi link rubyRegexpCharClass Special
hi link rubyRegexpDelimiter litebriteRegexpDelim
hi link rubyRegexpEscape litebriteEscapeChar
hi link rubyRegexpQuantifier litebriteRegexpQuantifier
hi link rubyRegexpSpecial litebriteRegexpMod
hi link rubySharpBang Comment
hi link rubyStringDelimiter String
hi link rubyStringEscape litebriteEscapeChar
hi link rubySymbol litebriteFuchsia

" YARD
" SEE: https://github.com/noprompt/vim-yardoc

exec "hi yardArrow" . s:GREY8 . s:NO_FORMAT
exec "hi yardComma" . s:GREY8 . s:NO_FORMAT
exec "hi yardDuckType" . s:GREY8 . s:NO_FORMAT
exec "hi yardHashAngle" . s:GREY8 . s:NO_FORMAT
exec "hi yardHashCurly" . s:GREY8 . s:NO_FORMAT
exec "hi yardOrderDependentList" . s:GREY8 . s:NO_FORMAT
exec "hi yardParametricType" . s:GREY8. s:NO_FORMAT
exec "hi yardType" . s:GREY8. s:BOLD
exec "hi yardTypeList" . s:GREY8 . s:NO_FORMAT

" }}}
" yaml {{{

hi link yamlBlockMappingKey litebriteFuchsia
hi link yamlKeyValueDelimiter litebriteFuchsia
hi link yamlFlowIndicator litebriteWhite

" }}}
" html {{{

exe "hi htmlBold" . s:BOLD
exe "hi htmlBoldItalic" . s:BOLD_ITALIC
exe "hi htmlBoldItalicUnderline" . s:BOLD_ITALIC_UNDERLINE
exe "hi htmlBoldUnderline" . s:BOLD_UNDERLINE
exe "hi htmlItalic" . s:ITALIC
exe "hi htmlUnderline" . s:UNDERLINE
exe "hi htmlItalicUnderline" . s:ITALIC_UNDERLINE
exe "hi htmlTitle" . s:BOLD
hi link htmlArg litebriteFuchsia
hi link htmlH litebriteBoldWhite
hi link htmlTag litebriteBlue
hi link htmlSpecialChar litebriteBoldOrange
hi link htmlBoldUnderlineItalic htmlBoldItalicUnderline
hi link htmlH1 htmlH
hi link htmlH2 htmlH
hi link htmlH3 htmlH
hi link htmlH4 htmlH
hi link htmlH5 htmlH
hi link htmlH6 htmlH
hi link htmlItalicBold htmlBoldItalic
hi link htmlItalicBoldUnderline htmlBoldItalicUnderline
hi link htmlItalicUnderlineBold htmlBoldItalicUnderline
hi link htmlSpecialTagName htmlTag
hi link htmlTagN htmlTag
hi link htmlTagName htmlTag
hi link htmlUnderlineBold htmlBoldUnderline
hi link htmlUnderlineBoldItalic htmlBoldUnderlineItalic
hi link htmlUnderlineItalic htmlItalicUnderline
hi link htmlUnderlineItalicBold htmlBoldUnderlineItalic

" }}}
" xml {{{

hi link xmlAttrib htmlArg
hi link xmlEndTag htmlTagN

" }}}
" haml {{{

hi link hamlIdChar cssIdentifier
hi link hamlId cssIdentifier
hi link hamlClassChar cssClassName
hi link hamlClass cssClassName
hi link hamlTag htmlTag
hi link hamlTagName htmlTag

" }}}
" php  {{{

hi link phpException litebriteRed
hi link phpIdentifier litebriteWhite
hi link phpInterfaces litebriteWhite
hi link phpIntVar litebriteBoldWhite
hi link phpOperator litebriteWhite
hi link phpRepeat litebriteBlue
hi link phpSpecialFunction litebriteYellow
hi link phpStatement litebriteRed
hi link phpStorageClass litebritePurple
hi link phpType litebritePurple
hi link phpVarSelector litebriteWhite
hi link phpFunctions Function
hi link phpDefine Function
hi link phpRelation phpOperator
hi link phpComparison phpOperator
hi link phpMemberSelector phpOperator

" }}}
" twig {{{
" SEE: https://github.com/beyondwords/vim-twig

hi link twigBlockName litebriteBoldOrange
hi link twigFilter litebriteGreen
hi link twigNumber litebriteRed
hi link twigSpecial litebriteYellow
hi link twigStatement litebritePurple
hi link twigTagBlock litebriteGrey13
hi link twigTagDelim litebriteGrey13
hi link twigVarBlock litebriteGrey13
hi link twigVariable litebriteFuchsia

" }}}
" c {{{

hi link cCharacter litebriteTurquoise
hi link cDefine Comment
hi link cInclude Comment
hi link cIncluded litebriteBlue
hi link cLabel litebriteFuchsia
hi link cRepeat litebriteBlue
hi link cStatement litebriteRed
hi link cStorageClass cType
hi link cStructure litebriteYellow
hi link cType litebritePurple
hi link cUserLabel litebriteFuchsia

" }}}
" cpp {{{

hi link cppAccess cLabel
hi link cppStructure cStructure
hi link cppType cType

" }}}
" java {{{

hi link javaType litebritePurple
hi link javaExternal litebriteRed
hi link javaScopeDecl litebriteFuchsia
hi link javaMethodDecl litebriteFuchsia
hi link javaStorageClass litebriteBlue
hi link javaTypeDef litebriteYellow
hi link javaAnnotation litebriteGreen
hi link javaStatement litebriteRed
hi link javaExceptions litebriteRed
hi link javaCharacter litebriteTurquoise

" }}}
" css {{{

hi link cssAuralAttr litebriteWhite
hi link cssBoxAttr litebriteWhite
hi link cssClassName litebriteYellow
hi link cssCommonAttr litebriteWhite
hi link cssDefinition litebritePurple
hi link cssIdentifier litebriteBoldWhite
hi link cssImportant litebriteItalicRed
hi link cssInclude litebriteBlue
hi link cssMedia litebriteGreen
hi link cssMediaType litebriteRed
hi link cssPagingAttr litebriteWhite
hi link cssPseudoClass litebriteFuchsia
hi link cssPseudoClassId litebriteFuchsia
hi link cssPseudoClassLang litebriteFuchsia
hi link cssRenderAttr litebriteWhite
hi link cssTableAttr litebriteWhite
hi link cssTextAttr litebriteWhite
hi link cssUIAttr litebriteWhite
hi link cssValue litebriteGreen
hi link cssAttributeSelector String
hi link cssAuralProp cssDefinition
hi link cssBoxProp cssDefinition
hi link cssBraces Normal
hi link cssColor Number
hi link cssColorProp cssDefinition
hi link cssComment Comment
hi link cssFontAttr Normal
hi link cssFontDescriptorAttr cssCommonAttr
hi link cssFontProp cssDefinition
hi link cssFunction Function
hi link cssFunctionName Function
hi link cssGeneratedContentAttr cssCommonAttr
hi link cssGeneratedContentProp cssDefinition
hi link cssPagingProp cssDefinition
hi link cssRenderProp cssDefinition
hi link cssTableProp cssDefinition
hi link cssTagName htmlTag
hi link cssTextProp cssDefinition
hi link cssUIProp cssDefinition
hi link cssValueAngle cssValue
hi link cssValueFrequency cssValue
hi link cssValueInteger cssValue
hi link cssValueLength cssValue
hi link cssValueNumber cssValue
hi link cssValueTime cssValue

" }}}
" sass {{{

hi link sassVariable litebriteOrange
hi link sassMixing litebriteBlue
hi link sassInclude litebriteBlue
hi link sassVariableAssignment sassVariable
hi link sassProperty  cssDefinition
hi link sassId        cssIdentifier
hi link sassClass     cssClassName
hi link sassIdChar    sassId
hi link sassClassChar sassClass

" }}}
" javascript {{{

hi link javaScript litebriteWhite
hi link javaScriptBraces Normal
hi link javaScriptBranch litebriteRed
hi link javaScriptExceptions litebriteWhiteBold
hi link javaScriptFunction Function
hi link javaScriptFutureKeys litebriteFuchsia
hi link javaScriptGlobal Constant
hi link javaScriptGlobalObjects Constant
hi link javaScriptIdentifier litebritePurple
hi link javaScriptLabel litebriteFuchsia
hi link javaScriptMember litebriteYellow
hi link javaScriptNull litebriteOrange
hi link javaScriptOperator litebriteRed
hi link javaScriptOperator litebriteYellow
hi link javaScriptRegexpString litebriteRegexp
hi link javaScriptRegexpCharClass litebriteRegexpCharClass
hi link javaScriptStatement litebriteRed
hi link javaScriptSpecial litebriteEscapeChar
hi link javaScriptType litebritePurple
hi link javascriptNumber Number

" }}}
" coffeescript {{{

exe "hi coffeeSpaceError" . s:NO_FG . s:NO_BG
hi link coffeeSpecialIdent litebriteOrange
hi link coffeeSpecialVar litebriteYellow
hi link coffeeSpecialOp litebriteWhite
hi link coffeeRegex litebriteGreen
hi link coffeeObjAssign litebriteFuchsia
hi link coffeeParen litebriteWhite
hi link coffeeParens litebriteWhite
hi link coffeeBracket litebriteWhite
hi link coffeeCurly litebriteWhite
hi link coffeeCurlies litebriteWhite
hi link coffeeExtendedOp litebriteWhite

" }}}
" livescript {{{

hi link lsSpaceError coffeeSpaceError
hi link lsIdentifier litebriteWhite
hi link lsRegex litebriteGreen
hi link lsInfixFunc litebriteRed
hi link lsProp litebriteFuchsia
hi link lsVarInterpolation litebriteWhite

" }}}
" haskell {{{

hi link hsCharacter String
hi link hsStatement litebriteRed
hi link hsStructure litebriteYellow
hi link hsImport litebriteBlue
hi link hsImportMod litebritePink
hi link ConId litebriteBoldWhite

" }}}
" sml {{{

hi link smlModPath litebriteBoldWhite
hi link smlKeyWord litebriteBlue
hi link smlKeyChar litebriteWhite
hi link smlCharacter litebritePurple
hi link smlEncl smlKeyChar

" }}}
" lisp {{{

hi link lispAtom litebriteWhite
hi link lispAtomList litebriteWhite
hi link lispAtomMark litebriteRed
hi link lispDecl litebriteRed
hi link lispEscapeSpecial litebriteBoldWhite
hi link lispFunc litebriteBlue
hi link lispKey litebriteFuchsia

" }}}
" clojure {{{
" SEE: https://github.com/guns/vim-clojure-static

hi link clojureAnonArg litebriteBoldRed
hi link clojureCharacter String
hi link clojureDefine litebriteBlue
hi link clojureDeref litebriteBoldRed
hi link clojureDispatch litebriteBoldRed
hi link clojureKeyword litebriteFuchsia
hi link clojureMacro litebriteYellow
hi link clojureMeta litebriteBoldRed
hi link clojurePattern litebriteGreen
hi link clojureQuote litebriteBoldRed
hi link clojureRegexp litebriteRegexp
hi link clojureRegexpBackRef litebriteRegexpBackRef
hi link clojureRegexpBoundary litebriteRegexpBoundary
hi link clojureRegexpCharClass Special
hi link clojureRegexpEscape litebriteEscapeChar
hi link clojureRegexpJavaCharClass litebriteRegexpBracketExp
hi link clojureRegexpMod litebriteRegexpMod
hi link clojureRegexpOr Conditional
hi link clojureRegexpPosixCharClass litebriteRegexpBracketExp
hi link clojureRegexpPredefinedCharClass litebriteRegexpCharClass
hi link clojureRegexpQuantifier litebriteRegexpQuantifier
hi link clojureRegexpQuoted litebriteTeal
hi link clojureRegexpSpecialChar SpecialChar
hi link clojureRegexpUnicodeCharClass litebriteRegexpBracketExp
hi link clojureUnquote litebriteBoldRed
hi link clojureVariable litebriteBoldWhite

" }}}
" shell {{{

hi link shTestPattern litebriteGreen
hi link shSubShRegion litebriteWhite
hi link shRepeat litebriteRed
hi link shRange litebriteWhite
hi link shOption litebritePurple
hi link shOperator litebriteWhite
hi link shLoop litebriteRed
hi link shExpr litebriteWhite
" Don't highlight bare words when using the echo command. This is a reminder
" to use string literals instead.
hi link shEcho litebriteWhite
hi link shDerefVarArray litebriteGreen
hi link shDerefSimple litebriteWhite
hi link shDeref litebriteWhite
hi link shCommandSub litebriteYellow
hi link shCmdSubRegion litebriteWhite
hi link shAlias Normal
hi link shVariable Normal
hi link shSetList Normal
hi link shTestOpr Normal
hi link shQuote String

" }}}
" mysql {{{

hi link mysqlType litebriteFuchsia
hi link mysqlSpecial litebriteOrange
hi link mysqlOperator litebritePurple
hi link mysqlKeyword litebriteBlue
hi link mysqlFunction litebriteRed
hi link mysqlVariable litebriteYellow

" }}}
" make {{{

hi link makeTarget litebriteFuchsia
hi link makeIdent litebriteBoldWhite

" }}}

" vim:foldmethod=marker
