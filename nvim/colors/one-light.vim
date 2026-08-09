" Atom One Light-inspired colors for terminal Vim.
set background=light
highlight clear
if exists('syntax_on')
	syntax reset
endif
let g:colors_name = 'one-light'

function! s:Highlight(group, guifg, guibg, ctermfg, ctermbg, attr) abort
	let l:command = 'highlight ' . a:group
	let l:command .= ' guifg=' . a:guifg . ' guibg=' . a:guibg
	let l:command .= ' ctermfg=' . a:ctermfg . ' ctermbg=' . a:ctermbg
	let l:command .= ' gui=' . a:attr . ' cterm=' . a:attr
	execute l:command
endfunction

call s:Highlight('Normal',          '#383a42', '#fafafa', '237', '15',  'NONE')
call s:Highlight('NormalNC',        '#696c77', '#fafafa', '242', '15',  'NONE')
call s:Highlight('ExplorerNormal',  '#5b5f68', '#eaeaeb', '240', '254', 'NONE')
call s:Highlight('EndOfBuffer',     '#fafafa', '#fafafa', '15',  '15',  'NONE')
call s:Highlight('Cursor',          '#fafafa', '#4078f2', '15',  '69',  'NONE')
call s:Highlight('CursorLine',      'NONE',    '#f0f0f0', 'NONE','255', 'NONE')
call s:Highlight('CursorColumn',    'NONE',    '#f0f0f0', 'NONE','255', 'NONE')
call s:Highlight('ColorColumn',     'NONE',    '#eeeeee', 'NONE','255', 'NONE')
call s:Highlight('LineNr',          '#9da5b4', '#fafafa', '247', '15',  'NONE')
call s:Highlight('CursorLineNr',    '#383a42', '#f0f0f0', '237', '255', 'bold')
call s:Highlight('SignColumn',      '#a0a1a7', '#fafafa', '247', '15',  'NONE')
call s:Highlight('Visual',          'NONE',    '#bfceff', 'NONE','153', 'NONE')
call s:Highlight('Search',          '#383a42', '#e5c07b', '237', '180', 'NONE')
call s:Highlight('IncSearch',       '#ffffff', '#4078f2', '15',  '69',  'bold')
call s:Highlight('MatchParen',      '#4078f2', '#dbe3ff', '69',  '189', 'bold')
call s:Highlight('StatusLine',      '#5b5b5b', '#eaeaeb', '240', '254', 'NONE')
call s:Highlight('StatusLineNC',    '#9da5b4', '#eaeaeb', '247', '254', 'NONE')
call s:Highlight('VertSplit',       '#d7d7d7', '#d7d7d7', '188', '188', 'NONE')
call s:Highlight('WinSeparator',    '#d7d7d7', '#d7d7d7', '188', '188', 'NONE')
call s:Highlight('Pmenu',           '#383a42', '#eaeaeb', '237', '254', 'NONE')
call s:Highlight('PmenuSel',        '#ffffff', '#4078f2', '15',  '69',  'NONE')
call s:Highlight('PmenuSbar',       'NONE',    '#d7d7d7', 'NONE','188', 'NONE')
call s:Highlight('PmenuThumb',      'NONE',    '#9da5b4', 'NONE','247', 'NONE')
call s:Highlight('WildMenu',        '#ffffff', '#4078f2', '15',  '69',  'bold')
call s:Highlight('Directory',       '#4078f2', 'NONE',    '69',  'NONE','bold')
call s:Highlight('Title',           '#4078f2', 'NONE',    '69',  'NONE','bold')
call s:Highlight('Folded',          '#696c77', '#eaeaeb', '242', '254', 'italic')
call s:Highlight('FoldColumn',      '#a0a1a7', '#fafafa', '247', '15',  'NONE')
call s:Highlight('NonText',         '#d7d7d7', 'NONE',    '188', 'NONE','NONE')
call s:Highlight('SpecialKey',      '#d7d7d7', 'NONE',    '188', 'NONE','NONE')
call s:Highlight('ErrorMsg',        '#ffffff', '#e45649', '15',  '167', 'bold')
call s:Highlight('WarningMsg',      '#986801', 'NONE',    '94',  'NONE','bold')
call s:Highlight('Question',        '#50a14f', 'NONE',    '71',  'NONE','bold')
call s:Highlight('DiffAdd',         '#50a14f', '#e3f1e3', '71',  '194', 'NONE')
call s:Highlight('DiffChange',      '#986801', '#f7efd2', '94',  '230', 'NONE')
call s:Highlight('DiffDelete',      '#e45649', '#f8e2e0', '167', '224', 'NONE')
call s:Highlight('DiffText',        '#ffffff', '#986801', '15',  '94',  'bold')

call s:Highlight('Comment',         '#a0a1a7', 'NONE', '247', 'NONE', 'italic')
call s:Highlight('Constant',        '#986801', 'NONE', '94',  'NONE', 'NONE')
call s:Highlight('String',          '#50a14f', 'NONE', '71',  'NONE', 'NONE')
call s:Highlight('Character',       '#50a14f', 'NONE', '71',  'NONE', 'NONE')
call s:Highlight('Number',          '#986801', 'NONE', '94',  'NONE', 'NONE')
call s:Highlight('Boolean',         '#986801', 'NONE', '94',  'NONE', 'NONE')
call s:Highlight('Float',           '#986801', 'NONE', '94',  'NONE', 'NONE')
call s:Highlight('Identifier',      '#e45649', 'NONE', '167', 'NONE', 'NONE')
call s:Highlight('Function',        '#4078f2', 'NONE', '69',  'NONE', 'NONE')
call s:Highlight('Statement',       '#a626a4', 'NONE', '127', 'NONE', 'NONE')
call s:Highlight('Conditional',     '#a626a4', 'NONE', '127', 'NONE', 'NONE')
call s:Highlight('Repeat',          '#a626a4', 'NONE', '127', 'NONE', 'NONE')
call s:Highlight('Label',           '#a626a4', 'NONE', '127', 'NONE', 'NONE')
call s:Highlight('Operator',        '#0184bc', 'NONE', '31',  'NONE', 'NONE')
call s:Highlight('Keyword',         '#a626a4', 'NONE', '127', 'NONE', 'NONE')
call s:Highlight('Exception',       '#a626a4', 'NONE', '127', 'NONE', 'NONE')
call s:Highlight('PreProc',         '#a626a4', 'NONE', '127', 'NONE', 'NONE')
call s:Highlight('Include',         '#a626a4', 'NONE', '127', 'NONE', 'NONE')
call s:Highlight('Define',          '#a626a4', 'NONE', '127', 'NONE', 'NONE')
call s:Highlight('Macro',           '#a626a4', 'NONE', '127', 'NONE', 'NONE')
call s:Highlight('Type',            '#c18401', 'NONE', '136', 'NONE', 'NONE')
call s:Highlight('StorageClass',    '#c18401', 'NONE', '136', 'NONE', 'NONE')
call s:Highlight('Structure',       '#c18401', 'NONE', '136', 'NONE', 'NONE')
call s:Highlight('Typedef',         '#c18401', 'NONE', '136', 'NONE', 'NONE')
call s:Highlight('Special',         '#0184bc', 'NONE', '31',  'NONE', 'NONE')
call s:Highlight('Underlined',      '#4078f2', 'NONE', '69',  'NONE', 'underline')
call s:Highlight('Todo',            '#383a42', '#e5c07b', '237', '180', 'bold')
call s:Highlight('Error',           '#e45649', '#fafafa', '167', '15',  'undercurl')

call s:Highlight('DiagnosticError', '#e45649', 'NONE', '167', 'NONE', 'NONE')
call s:Highlight('DiagnosticWarn',  '#986801', 'NONE', '94',  'NONE', 'NONE')
call s:Highlight('DiagnosticInfo',  '#4078f2', 'NONE', '69',  'NONE', 'NONE')
call s:Highlight('DiagnosticHint',  '#0184bc', 'NONE', '31',  'NONE', 'NONE')

delfunction s:Highlight
