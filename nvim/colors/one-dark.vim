" Atom One Dark-inspired colors for terminal Vim.
set background=dark
highlight clear
if exists('syntax_on')
	syntax reset
endif
let g:colors_name = 'one-dark'

function! s:Highlight(group, guifg, guibg, ctermfg, ctermbg, attr) abort
	let l:command = 'highlight ' . a:group
	let l:command .= ' guifg=' . a:guifg . ' guibg=' . a:guibg
	let l:command .= ' ctermfg=' . a:ctermfg . ' ctermbg=' . a:ctermbg
	let l:command .= ' gui=' . a:attr . ' cterm=' . a:attr
	execute l:command
endfunction

call s:Highlight('Normal',          '#abb2bf', '#282c34', '145', '235', 'NONE')
call s:Highlight('NormalNC',        '#9da5b4', '#282c34', '248', '235', 'NONE')
call s:Highlight('ExplorerNormal',  '#9da5b4', '#21252b', '248', '234', 'NONE')
call s:Highlight('EndOfBuffer',     '#282c34', '#282c34', '235', '235', 'NONE')
call s:Highlight('Cursor',          '#282c34', '#61afef', '235', '75',  'NONE')
call s:Highlight('CursorLine',      'NONE',    '#2c313c', 'NONE','236', 'NONE')
call s:Highlight('CursorColumn',    'NONE',    '#2c313c', 'NONE','236', 'NONE')
call s:Highlight('ColorColumn',     'NONE',    '#2c313c', 'NONE','236', 'NONE')
call s:Highlight('LineNr',          '#4b5263', '#282c34', '239', '235', 'NONE')
call s:Highlight('CursorLineNr',    '#d7dae0', '#2c313c', '253', '236', 'bold')
call s:Highlight('SignColumn',      '#5c6370', '#282c34', '59',  '235', 'NONE')
call s:Highlight('Visual',          'NONE',    '#3e4451', 'NONE','238', 'NONE')
call s:Highlight('Search',          '#282c34', '#e5c07b', '235', '180', 'NONE')
call s:Highlight('IncSearch',       '#282c34', '#61afef', '235', '75',  'bold')
call s:Highlight('MatchParen',      '#61afef', '#3e4451', '75',  '238', 'bold')
call s:Highlight('StatusLine',      '#abb2bf', '#21252b', '145', '234', 'NONE')
call s:Highlight('StatusLineNC',    '#5c6370', '#21252b', '59',  '234', 'NONE')
call s:Highlight('VertSplit',       '#181a1f', '#181a1f', '234', '234', 'NONE')
call s:Highlight('WinSeparator',    '#181a1f', '#181a1f', '234', '234', 'NONE')
call s:Highlight('Pmenu',           '#abb2bf', '#21252b', '145', '234', 'NONE')
call s:Highlight('PmenuSel',        '#ffffff', '#3e4451', '15',  '238', 'NONE')
call s:Highlight('PmenuSbar',       'NONE',    '#2c313c', 'NONE','236', 'NONE')
call s:Highlight('PmenuThumb',      'NONE',    '#5c6370', 'NONE','59',  'NONE')
call s:Highlight('WildMenu',        '#282c34', '#61afef', '235', '75',  'bold')
call s:Highlight('Directory',       '#61afef', 'NONE',    '75',  'NONE','bold')
call s:Highlight('Title',           '#61afef', 'NONE',    '75',  'NONE','bold')
call s:Highlight('Folded',          '#5c6370', '#21252b', '59',  '234', 'italic')
call s:Highlight('FoldColumn',      '#5c6370', '#282c34', '59',  '235', 'NONE')
call s:Highlight('NonText',         '#3b4048', 'NONE',    '237', 'NONE','NONE')
call s:Highlight('SpecialKey',      '#3b4048', 'NONE',    '237', 'NONE','NONE')
call s:Highlight('ErrorMsg',        '#ffffff', '#e06c75', '15',  '168', 'bold')
call s:Highlight('WarningMsg',      '#e5c07b', 'NONE',    '180', 'NONE','bold')
call s:Highlight('Question',        '#98c379', 'NONE',    '114', 'NONE','bold')
call s:Highlight('DiffAdd',         '#98c379', '#313b2f', '114', '236', 'NONE')
call s:Highlight('DiffChange',      '#e5c07b', '#3a382b', '180', '236', 'NONE')
call s:Highlight('DiffDelete',      '#e06c75', '#3b2c31', '168', '236', 'NONE')
call s:Highlight('DiffText',        '#282c34', '#e5c07b', '235', '180', 'bold')

call s:Highlight('Comment',         '#5c6370', 'NONE', '59',  'NONE', 'italic')
call s:Highlight('Constant',        '#d19a66', 'NONE', '173', 'NONE', 'NONE')
call s:Highlight('String',          '#98c379', 'NONE', '114', 'NONE', 'NONE')
call s:Highlight('Character',       '#98c379', 'NONE', '114', 'NONE', 'NONE')
call s:Highlight('Number',          '#d19a66', 'NONE', '173', 'NONE', 'NONE')
call s:Highlight('Boolean',         '#d19a66', 'NONE', '173', 'NONE', 'NONE')
call s:Highlight('Float',           '#d19a66', 'NONE', '173', 'NONE', 'NONE')
call s:Highlight('Identifier',      '#e06c75', 'NONE', '168', 'NONE', 'NONE')
call s:Highlight('Function',        '#61afef', 'NONE', '75',  'NONE', 'NONE')
call s:Highlight('Statement',       '#c678dd', 'NONE', '176', 'NONE', 'NONE')
call s:Highlight('Conditional',     '#c678dd', 'NONE', '176', 'NONE', 'NONE')
call s:Highlight('Repeat',          '#c678dd', 'NONE', '176', 'NONE', 'NONE')
call s:Highlight('Label',           '#c678dd', 'NONE', '176', 'NONE', 'NONE')
call s:Highlight('Operator',        '#56b6c2', 'NONE', '73',  'NONE', 'NONE')
call s:Highlight('Keyword',         '#c678dd', 'NONE', '176', 'NONE', 'NONE')
call s:Highlight('Exception',       '#c678dd', 'NONE', '176', 'NONE', 'NONE')
call s:Highlight('PreProc',         '#c678dd', 'NONE', '176', 'NONE', 'NONE')
call s:Highlight('Include',         '#c678dd', 'NONE', '176', 'NONE', 'NONE')
call s:Highlight('Define',          '#c678dd', 'NONE', '176', 'NONE', 'NONE')
call s:Highlight('Macro',           '#c678dd', 'NONE', '176', 'NONE', 'NONE')
call s:Highlight('Type',            '#e5c07b', 'NONE', '180', 'NONE', 'NONE')
call s:Highlight('StorageClass',    '#e5c07b', 'NONE', '180', 'NONE', 'NONE')
call s:Highlight('Structure',       '#e5c07b', 'NONE', '180', 'NONE', 'NONE')
call s:Highlight('Typedef',         '#e5c07b', 'NONE', '180', 'NONE', 'NONE')
call s:Highlight('Special',         '#56b6c2', 'NONE', '73',  'NONE', 'NONE')
call s:Highlight('Underlined',      '#61afef', 'NONE', '75',  'NONE', 'underline')
call s:Highlight('Todo',            '#282c34', '#e5c07b', '235', '180', 'bold')
call s:Highlight('Error',           '#e06c75', '#282c34', '168', '235', 'undercurl')

call s:Highlight('DiagnosticError', '#e06c75', 'NONE', '168', 'NONE', 'NONE')
call s:Highlight('DiagnosticWarn',  '#e5c07b', 'NONE', '180', 'NONE', 'NONE')
call s:Highlight('DiagnosticInfo',  '#61afef', 'NONE', '75',  'NONE', 'NONE')
call s:Highlight('DiagnosticHint',  '#56b6c2', 'NONE', '73',  'NONE', 'NONE')

delfunction s:Highlight
