" Portable, dependency-free terminal Neovim configuration.
" Ported from ~/.config/vim/vimrc.
scriptencoding utf-8

let s:config_file = resolve(expand('<sfile>:p'))
let s:config_dir = fnamemodify(s:config_file, ':h')
execute 'set runtimepath^=' . fnameescape(s:config_dir)
execute 'set runtimepath+=' . fnameescape(s:config_dir . '/after')

" Neovim is always nocompatible; keep for parity with the Vim source.
set nocompatible
set encoding=utf-8
if has('termguicolors')
	set termguicolors
endif
syntax enable
filetype plugin indent on

" Editor behavior aligned with the local VS Code configuration.
set number
set cursorline
set mouse=a
set clipboard=unnamedplus    " nvim: use * + and unnamed registers for system clipboard
set hidden
set autowriteall
set confirm
set noexpandtab
set tabstop=4
set shiftwidth=4
set softtabstop=0
set smartindent
set wrap
set linebreak
set breakindent
set colorcolumn=80
set scrolloff=3
set sidescrolloff=3
set splitright
set splitbelow
set laststatus=2
set showtabline=0
set noshowmode
set shortmess+=I
set wildmenu
set wildmode=longest:full,full
set wildignorecase
set path=.,**
set wildignore+=*/.git/*,*/node_modules/*,*/.vercel/*
set wildignore+=*.o,*.obj,*.pyc,*.class
set incsearch
set hlsearch
set ignorecase
set smartcase
set backspace=indent,eol,start
set statusline=\ %f\ %m%r%=%y\ \ %l:%c\ 

" Detect the terminal background at startup. COLORFGBG is supported by iTerm,
" Terminal.app, and several other terminal emulators.
function! s:DetectedBackground() abort
	if exists('$COLORFGBG') && $COLORFGBG =~# ';'
		let l:value = split($COLORFGBG, ';')[-1]
		if l:value =~# '^\d\+$'
			let l:index = str2nr(l:value)
			if (l:index >= 7 && l:index <= 15) || l:index >= 244
				return 'light'
			endif
			return 'dark'
		endif
	endif
	return &background ==# 'light' ? 'light' : 'dark'
endfunction

function! s:ApplyTheme(background) abort
	let &background = a:background
	execute 'colorscheme one-' . a:background
endfunction

function! s:ToggleTheme() abort
	call s:ApplyTheme(&background ==# 'dark' ? 'light' : 'dark')
endfunction

command! ThemeDark call <SID>ApplyTheme('dark')
command! ThemeLight call <SID>ApplyTheme('light')
command! ThemeToggle call <SID>ToggleTheme()

call s:ApplyTheme(s:DetectedBackground())

" Built-in netrw configured as a persistent VS Code-style Explorer.
let g:netrw_banner = 0
let g:netrw_browse_split = 0
let g:netrw_keepdir = 1
let g:netrw_liststyle = 3
let g:netrw_preview = 1
let g:netrw_winsize = 30
let g:netrw_hide = 1
let g:netrw_list_hide = '\(^\|\s\s\)\zs\(\.git\|node_modules\|\.vercel\)/\=$'
let g:netrw_sort_by = 'name'

let g:vscode_project_root = fnamemodify(getcwd(), ':p')
let g:vscode_editor_winid = -1
let g:vscode_explorer_width = 30

function! s:ExplorerWinid() abort
	for l:winnr in range(1, winnr('$'))
		if getwinvar(l:winnr, 'vscode_explorer', 0)
			return win_getid(l:winnr)
		endif
	endfor
	return -1
endfunction

function! s:EditorWinid() abort
	if g:vscode_editor_winid > 0 && win_id2win(g:vscode_editor_winid) > 0
		return g:vscode_editor_winid
	endif
	for l:winnr in range(1, winnr('$'))
		if getwinvar(l:winnr, '&filetype') !=# 'netrw'
			return win_getid(l:winnr)
		endif
	endfor
	return -1
endfunction

function! s:SetNetrwTarget(editor_winid) abort
	if a:editor_winid <= 0 || win_id2win(a:editor_winid) == 0
		return
	endif
	let l:current_winid = win_getid()
	call win_gotoid(a:editor_winid)
	let g:netrw_chgwin = winnr()
	let g:vscode_editor_winid = win_getid()
	call win_gotoid(l:current_winid)
endfunction

function! s:OpenExplorer(focus) abort
	let l:explorer_winid = s:ExplorerWinid()
	if l:explorer_winid > 0
		if a:focus
			call win_gotoid(l:explorer_winid)
		endif
		return
	endif

	let l:editor_winid = s:EditorWinid()
	if l:editor_winid <= 0
		let l:editor_winid = win_getid()
	endif

	execute 'silent keepalt topleft ' . g:vscode_explorer_width . 'vnew'
	execute 'silent keepalt Explore ' . fnameescape(g:vscode_project_root)
	let w:vscode_explorer = 1
	setlocal winfixwidth
	execute 'vertical resize ' . g:vscode_explorer_width
	let l:explorer_winid = win_getid()

	call s:SetNetrwTarget(l:editor_winid)
	if a:focus
		call win_gotoid(l:explorer_winid)
	else
		call win_gotoid(l:editor_winid)
	endif
endfunction

function! s:CloseExplorer() abort
	let l:explorer_winid = s:ExplorerWinid()
	if l:explorer_winid <= 0
		return
	endif
	let l:editor_winid = s:EditorWinid()
	call win_gotoid(l:explorer_winid)
	silent close
	if l:editor_winid > 0 && win_id2win(l:editor_winid) > 0
		call win_gotoid(l:editor_winid)
	endif
endfunction

function! s:ToggleExplorer() abort
	if s:ExplorerWinid() > 0
		call s:CloseExplorer()
	else
		call s:OpenExplorer(0)
	endif
endfunction

function! s:FocusExplorer() abort
	call s:OpenExplorer(1)
endfunction

function! s:FocusEditor() abort
	let l:editor_winid = s:EditorWinid()
	if l:editor_winid > 0
		call win_gotoid(l:editor_winid)
	endif
endfunction

function! s:StartWorkspace() abort
	" `vim .` initially occupies the only window with netrw. Replace that
	" buffer with an editor before creating the persistent sidebar.
	if &filetype ==# 'netrw' || isdirectory(expand('%:p'))
		enew
	endif
	let g:vscode_editor_winid = win_getid()
	call s:OpenExplorer(0)
endfunction

function! s:ConfigureExplorer() abort
	setlocal nonumber norelativenumber
	setlocal nowrap
	setlocal nolist
	setlocal nospell
	setlocal winfixwidth
	" nvim uses winhighlight instead of Vim's wincolor option.
	setlocal winhighlight=Normal:ExplorerNormal,NormalNC:ExplorerNormal
	setlocal statusline=\ EXPLORER%=%{fnamemodify(g:vscode_project_root,':t')}\ 

	" Arrow-key tree navigation and VS Code-style file operations.
	nmap <silent><buffer> <Right> <Plug>NetrwLocalBrowseCheck:call <SID>FocusExplorer()<CR>
	nmap <silent><buffer> <C-Right> <Plug>NetrwLocalBrowseCheck
	nmap <silent><buffer> <CR> <Plug>NetrwLocalBrowseCheck
	nmap <silent><buffer> <Left> <Plug>NetrwTreeSqueeze
	nmap <silent><buffer> <C-T> <Plug>NetrwOpenFile
	nmap <silent><buffer> <C-N> <Plug>NetrwMakeDir
endfunction

function! s:AutoSaveCurrentBuffer() abort
	if &buftype !=# '' || !&modifiable || &readonly || !&modified
		return
	endif
	if empty(expand('%:p'))
		return
	endif
	try
		silent update
	catch
		echohl ErrorMsg
		echom 'Auto-save failed: ' . v:exception
		echohl None
	endtry
endfunction

function! s:CloseActiveFile() abort
	if &filetype ==# 'netrw'
		call s:FocusEditor()
	endif
	call s:AutoSaveCurrentBuffer()

	let l:target = bufnr('%')
	let l:replacement = -1
	for l:info in reverse(getbufinfo({'buflisted': 1}))
		if l:info.bufnr != l:target && getbufvar(l:info.bufnr, '&buftype') ==# ''
			let l:replacement = l:info.bufnr
			break
		endif
	endfor

	if l:replacement > 0
		execute 'buffer ' . l:replacement
	else
		enew
	endif

	try
		execute 'bdelete ' . l:target
	catch
		echohl ErrorMsg
		echom 'Close failed: ' . v:exception
		echohl None
	endtry
endfunction

function! s:QuickOpen() abort
	call s:FocusEditor()
	call feedkeys(':find ', 'n')
endfunction

" VS Code-style bottom panel using Vim's terminal and quickfix windows.
function! s:PanelWinids() abort
	let l:winids = []
	for l:winnr in range(1, winnr('$'))
		if !empty(getwinvar(l:winnr, 'vscode_panel', ''))
			call add(l:winids, win_getid(l:winnr))
		endif
	endfor
	return l:winids
endfunction

function! s:ClosePanels() abort
	let l:editor_winid = s:EditorWinid()
	for l:winid in reverse(s:PanelWinids())
		if win_id2win(l:winid) == 0
			continue
		endif
		call win_gotoid(l:winid)
		if &buftype ==# 'quickfix'
			silent! cclose
		else
			silent! hide
		endif
	endfor
	if l:editor_winid > 0 && win_id2win(l:editor_winid) > 0
		call win_gotoid(l:editor_winid)
	endif
endfunction

function! s:ConfigureQuickfixPanel() abort
	let w:vscode_panel = 'problems'
	setlocal nowrap
	setlocal nonumber norelativenumber
	setlocal statusline=\ PROBLEMS%=%{len(getqflist())}\ 
	nnoremap <silent><buffer> q :cclose<CR>
	nnoremap <silent><buffer> <C-.> :call <SID>ToggleTerminal()<CR>
endfunction

function! s:OpenProblems() abort
	botright copen 10
	let w:vscode_panel = 'problems'
endfunction

function! s:TerminalBuffer() abort
	for l:info in getbufinfo()
		if getbufvar(l:info.bufnr, 'vscode_terminal', 0)
			return l:info.bufnr
		endif
	endfor
	return -1
endfunction

function! s:OpenTerminal() abort
	for l:winid in s:PanelWinids()
		if win_id2win(l:winid) > 0 && getwinvar(win_id2win(l:winid), 'vscode_panel', '') ==# 'terminal'
			call win_gotoid(l:winid)
			startinsert
			return
		endif
	endfor

	call s:ClosePanels()
	botright 12new
	let l:terminal_buffer = s:TerminalBuffer()
	if l:terminal_buffer > 0
		execute 'buffer ' . l:terminal_buffer
	else
		terminal ++curwin
		let b:vscode_terminal = 1
	endif
	let w:vscode_panel = 'terminal'
	setlocal statusline=\ TERMINAL%=%{getcwd()}\ 
	startinsert
endfunction

function! s:ToggleTerminal() abort
	for l:winid in s:PanelWinids()
		if win_id2win(l:winid) > 0 && getwinvar(win_id2win(l:winid), 'vscode_panel', '') ==# 'terminal'
			call s:ClosePanels()
			return
		endif
	endfor
	call s:OpenTerminal()
endfunction

function! s:TogglePanel() abort
	if !empty(s:PanelWinids())
		call s:ClosePanels()
	else
		call s:OpenProblems()
	endif
endfunction

" Dependency-free project search. globpath() honors wildignore, so generated
" and dependency directories are skipped before vimgrep reads files.
function! s:ProjectSearch(...) abort
	call s:FocusEditor()
	let l:pattern = a:0 ? a:1 : input('Search project: ', expand('<cword>'))
	if empty(l:pattern)
		return
	endif

	let l:files = globpath(g:vscode_project_root, '**/*', 0, 1)
	call filter(l:files, 'filereadable(v:val)')
	call setqflist([], 'r', {'title': 'Search: ' . l:pattern})
	if empty(l:files)
		call s:OpenProblems()
		return
	endif

	let l:escaped_pattern = '\V' . escape(l:pattern, '\/')
	let l:first = 1
	for l:start in range(0, len(l:files) - 1, 100)
		let l:chunk = l:files[l:start : min([l:start + 99, len(l:files) - 1])]
		let l:arguments = join(map(copy(l:chunk), 'fnameescape(v:val)'), ' ')
		let l:command = l:first ? 'vimgrep' : 'vimgrepadd'
		execute 'silent! ' . l:command . ' /' . l:escaped_pattern . '/gj ' . l:arguments
		let l:first = 0
	endfor

	let l:items = getqflist()
	call setqflist([], 'r', {'items': l:items, 'title': 'Search: ' . l:pattern})
	call s:OpenProblems()
endfunction

function! s:SaveActiveFile() abort
	call s:FocusEditor()
	call s:AutoSaveCurrentBuffer()
endfunction

" Keyboard-filterable command palette implemented with Vim's popup API.
let s:palette_actions = [
\ {'label': 'Open File',            'command': 'QuickOpen'},
\ {'label': 'Search Project',       'command': 'ProjectSearch'},
\ {'label': 'Show Problems',        'command': 'Problems'},
\ {'label': 'Open Terminal',        'command': 'TerminalPanel'},
\ {'label': 'Toggle Bottom Panel',  'command': 'PanelToggle'},
\ {'label': 'Toggle Explorer',      'command': 'ExplorerToggle'},
\ {'label': 'Focus Explorer',       'command': 'ExplorerFocus'},
\ {'label': 'Save File',            'command': 'SaveActiveFile'},
\ {'label': 'Close File',           'command': 'CloseActiveFile'},
\ {'label': 'Toggle Light / Dark',  'command': 'ThemeToggle'},
\ {'label': 'Quit Vim',             'command': 'confirm qall'}
\ ]
let s:palette_filtered = []
let s:palette_query = ''

" Neovim renderers: float window + a temporary buffer for the show/model.
let s:palette_winid = -1
let s:palette_bufnr = -1
let s:palette_ns = -1
let s:palette_index = 0

function! s:PaletteCompute() abort
	let s:palette_filtered = []
	let l:query = tolower(s:palette_query)
	for l:action in s:palette_actions
		if empty(l:query) || stridx(tolower(l:action.label), l:query) >= 0
			call add(s:palette_filtered, l:action)
		endif
	endfor
	if s:palette_index >= len(s:palette_filtered)
		let s:palette_index = 0
	endif
endfunction

function! s:PaletteLabels() abort
	return empty(s:palette_filtered)
		\ ? ['No matching commands']
		\ : map(copy(s:palette_filtered), 'v:val.label')
endfunction

function! s:PaletteSelected() abort
	if s:palette_index >= 0 && s:palette_index < len(s:palette_filtered)
		execute s:palette_filtered[s:palette_index].command
	endif
endfunction

" Neovim float-window palette. Replaces Vim's popup_menu (not available in nvim).
function! s:NvimPaletteClose() abort
	if s:palette_winid > 0 && nvim_win_is_valid(s:palette_winid)
		silent! close
	endif
	let s:palette_winid = -1
	let s:palette_bufnr = -1
endfunction

function! s:NvimPaletteRender() abort
	if s:palette_winid <= 0 && s:palette_bufnr > 0
		return
	endif
	call s:PaletteCompute()
	let l:labels = s:PaletteLabels()
	if s:palette_bufnr > 0
		call nvim_buf_set_lines(s:palette_bufnr, 0, -1, v:false, l:labels)
		call nvim_buf_clear_namespace(s:palette_bufnr, s:palette_ns, 0, -1)
		let l:li = 0
		while l:li < len(l:labels)
			if l:li ==# s:palette_index && !empty(s:palette_filtered)
				call nvim_buf_add_highlight(s:palette_bufnr, s:palette_ns, 'PmenuSel', l:li, 0, -1)
			endif
			if !empty(s:palette_query)
				let l:c = stridx(tolower(l:labels[l:li]), tolower(s:palette_query))
				if l:c >= 0
					call nvim_buf_add_highlight(s:palette_bufnr, s:palette_ns, 'IncSearch', l:li, l:c, l:c + strlen(s:palette_query))
				endif
			endif
			let l:li += 1
		endwhile
	endif
	if s:palette_winid > 0 && nvim_win_is_valid(s:palette_winid)
		call nvim_win_set_config(s:palette_winid, {'height': min([len(l:labels) + 1, 15]), 'title': ' Commands: ' . s:palette_query . ' '})
	endif
endfunction

function! s:OpenCommandPalette() abort
	let s:palette_query = ''
	let s:palette_index = 0
	call s:PaletteCompute()

	if !has('nvim')
		let l:choices = ['Commands:']
		for l:index in range(0, len(s:palette_actions) - 1)
			call add(l:choices, printf('%d. %s', l:index + 1, s:palette_actions[l:index].label))
		endfor
		let l:chosen = inputlist(l:choices)
		if l:chosen > 0 && l:chosen <= len(s:palette_actions)
			let s:palette_index = l:chosen - 1
			call s:PaletteSelected()
		endif
		return
	endif

	call s:NvimPaletteClose()
	let s:palette_bufnr = nvim_create_buf(v:false, v:true)
	call nvim_buf_set_option(s:palette_bufnr, 'bufhidden', 'wipe')
	let s:palette_ns = nvim_create_namespace('VscodeCommandPalette')
	let l:labels = s:PaletteLabels()
	call nvim_buf_set_lines(s:palette_bufnr, 0, -1, v:false, l:labels)
	let s:palette_winid = nvim_open_win(s:palette_bufnr, v:true, {
		\ 'relative': 'editor',
		\ 'row': (&lines - 1) / 2 - 4,
		\ 'col': (&columns - 38) / 2,
		\ 'width': 38,
		\ 'height': min([len(l:labels) + 1, 15]),
		\ 'style': 'minimal',
		\ 'border': 'rounded',
		\ 'title': ' Commands ',
		\ })
	call nvim_win_set_option(s:palette_winid, 'winblend', 8)

	call s:NvimPaletteRender()
	while 1
		let l:key = getcharstr()
		if l:key ==# "\<Esc>"
			call s:NvimPaletteClose()
			break
		elseif l:key ==# "\<CR>"
			call s:NvimPaletteClose()
			call s:PaletteSelected()
			break
		elseif l:key ==# "\<C-N>" || l:key ==# "\<Down>"
			if !empty(s:palette_filtered)
				let s:palette_index = (s:palette_index + 1) % len(s:palette_filtered)
				call s:NvimPaletteRender()
			endif
		elseif l:key ==# "\<C-P>" || l:key ==# "\<Up>"
			if !empty(s:palette_filtered)
				let s:palette_index = (s:palette_index + len(s:palette_filtered) - 1) % len(s:palette_filtered)
				call s:NvimPaletteRender()
			endif
		elseif l:key ==# "\<BS>" || l:key ==# "\<C-H>"
			if !empty(s:palette_query)
				let s:palette_query = strcharpart(s:palette_query, 0, strchars(s:palette_query) - 1)
				let s:palette_index = 0
				call s:NvimPaletteRender()
			endif
		elseif l:key =~# '^[[:print:]]$'
			let s:palette_query .= l:key
			let s:palette_index = 0
			call s:NvimPaletteRender()
		endif
	endwhile
endfunction

command! ExplorerToggle call <SID>ToggleExplorer()
command! ExplorerFocus call <SID>FocusExplorer()
command! QuickOpen call <SID>QuickOpen()
command! -nargs=? ProjectSearch call <SID>ProjectSearch(<f-args>)
command! Problems call <SID>OpenProblems()
command! TerminalPanel call <SID>OpenTerminal()
command! TerminalToggle call <SID>ToggleTerminal()
command! PanelToggle call <SID>TogglePanel()
command! CommandPalette call <SID>OpenCommandPalette()
command! SaveActiveFile call <SID>SaveActiveFile()
command! CloseActiveFile call <SID>CloseActiveFile()

augroup PortableVscodeVim
	autocmd!
	autocmd VimEnter * call <SID>StartWorkspace()
	autocmd FileType netrw call <SID>ConfigureExplorer()
	autocmd FileType qf call <SID>ConfigureQuickfixPanel()
	autocmd BufLeave,FocusLost * call <SID>AutoSaveCurrentBuffer()
augroup END

" Command-to-Control translations from the local VS Code keybindings.
nnoremap <silent> <C-\> :call <SID>ToggleExplorer()<CR>
inoremap <silent> <C-\> <C-O>:call <SID>ToggleExplorer()<CR>
nnoremap <silent> <C-E> :call <SID>FocusExplorer()<CR>
inoremap <silent> <C-E> <C-O>:call <SID>FocusExplorer()<CR>
nnoremap <silent> <C-G> :call <SID>QuickOpen()<CR>
inoremap <silent> <C-G> <Esc>:call <SID>QuickOpen()<CR>
nnoremap <silent> <C-W> :call <SID>CloseActiveFile()<CR>
inoremap <silent> <C-W> <Esc>:call <SID>CloseActiveFile()<CR>
nnoremap <silent> <C-P> :CommandPalette<CR>
inoremap <silent> <C-P> <Esc>:CommandPalette<CR>
nnoremap <silent> <C-F> :ProjectSearch<CR>
inoremap <silent> <C-F> <Esc>:ProjectSearch<CR>
nnoremap <silent> <C-.> :TerminalToggle<CR>
inoremap <silent> <C-.> <C-O>:TerminalToggle<CR>
tnoremap <silent> <C-.> <C-W>:TerminalToggle<CR>

nnoremap <silent> <C-M-Left> <C-W>h
nnoremap <silent> <C-M-Right> <C-W>l
nnoremap <silent> <C-M-Up> <C-W>k
nnoremap <silent> <C-M-Down> <C-W>j
inoremap <silent> <C-M-Left> <C-O><C-W>h
inoremap <silent> <C-M-Right> <C-O><C-W>l
inoremap <silent> <C-M-Up> <C-O><C-W>k
inoremap <silent> <C-M-Down> <C-O><C-W>j
