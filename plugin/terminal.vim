if exists('g:tm_terminal_loaded')
  finish
end

if !exists('g:tm_terminal_custom_pos')
  let g:tm_terminal_custom_pos = 'bottom'
endif

if !exists('g:tm_terminal_custom_height')
  let g:tm_terminal_custom_height = 10
endif

if !exists('g:tm_terminal_custom_command')
    let g:tm_terminal_custom_command = ''
endif

let g:tm_terminal_loaded = 1

let g:tm_terminal_current_number = 0
let g:tm_terminal_delete_bufer_number = 0
let g:tm_is_terminal_open = 0

let g:tm_called_by_toggle = 0
let g:tm_terminal_map = {}
let g:tm_lazyload_cmd = 0

function! TMTerminalToggle()
    call TMLazyLoadCMD()
    if g:tm_is_terminal_open == 1
        call TMTerminalCloseWin()
    else
        call  TMTerminalOpenWin()
        call TMTerminalOpenBuffer()
    endif
endfunction

function! TMTerminalJudgeAndOpenWin()
    if g:tm_is_terminal_open == 0
        call  TMTerminalOpenWin()
        let g:tm_is_terminal_open = 1
    else
        let l:current_win_number = bufwinnr(str2nr(g:tm_terminal_current_number))
        exec l:current_win_number . 'wincmd w'
    endif
endfunction

function! TMTerminalSwitch()
    if g:tm_is_terminal_open == 1
        call TMTerminalCloseWin()
    endif
endfunction

function! TMTerminalOpenNew()
    call TMTerminalSwitch()
    " call TMLazyLoadCMD()
    call TMTerminalJudgeAndOpenWin()
    call TMTerminalCreateNew()
    " call TMTerminalOpenBuffer()
endfunction

function! TMTerminalOpenWithIndex(i)
    call TMTerminalSwitch()
    " call TMLazyLoadCMD()
    let l:keys = keys(g:tm_terminal_map)
    let l:index = a:i - 1
    if (a:i > len(g:tm_terminal_map))
        echoe 'Terminal not exists!'
        return
    endif
    let l:bufnr = l:keys[l:index]
    if !bufexists(str2nr(l:bufnr))
        echoe 'Terminal not exists!'
        return
    endif
    call TMTerminalJudgeAndOpenWin()
    exec 'b ' . l:bufnr
    let g:tm_terminal_current_number = l:bufnr
    call TMTerminalRenderStatuslineEvent()
endfunction

function! TMTerminalDeleteWithIndex(i)
    let l:keys = keys(g:tm_terminal_map)
    let l:index = a:i - 1
    if (a:i > len(g:tm_terminal_map))
        echoe 'Terminal not exists!'
        return
    endif
    let l:bufnr = l:keys[l:index]
    if !bufexists(str2nr(l:bufnr))
        echoe 'Terminal not exists!'
        return
    endif
    let g:tm_terminal_delete_bufer_number = l:bufnr
    call TMGetCurrentNumberAfterDelete(l:bufnr)
    call TMTerminalRenderStatuslineEvent()
    exec 'bd! ' . l:bufnr
endfunction

function! TMTerminalCloseWin()
    if winnr() == bufwinnr(str2nr(g:tm_terminal_current_number))
        exec 'wincmd p'
        exec bufwinnr(str2nr(g:tm_terminal_current_number)) . 'wincmd w'
        " hide
    else
        " exec 'e #'
        exec bufwinnr(str2nr(g:tm_terminal_current_number)) . 'wincmd w'
    endif
    hide
    " close
    let g:tm_is_terminal_open = 0
endfunction

function! TMTerminalCreateNew()
    " Terminal init finished.
    let g:tm_called_by_toggle = 1
    exec 'terminal ++curwin ' . g:tm_terminal_custom_command
endfunction

function! TMTerminalOpenWin()
    let l:tm_terminal_pos = g:tm_terminal_custom_pos ==# 'bottom' ? 'botright ' : 'topleft '
    let l:tm_terminal_pos = g:tm_terminal_custom_pos ==# 'left' ? 'topleft ' : g:tm_terminal_custom_pos ==# 'right' ? 'botright ' : l:tm_terminal_pos
    let l:tm_terminal_split = g:tm_terminal_custom_pos ==# 'left' ? ' vsplit' : g:tm_terminal_custom_pos ==# 'right' ? ' vsplit' : ' split'
    exec l:tm_terminal_pos . g:tm_terminal_custom_height . l:tm_terminal_split
    let g:tm_is_terminal_open = 1
endfunction

function! TMTerminalOpenBuffer()
    if g:tm_terminal_current_number == 0 
        call TMTerminalCreateNew()
    else
        if bufexists(str2nr(g:tm_terminal_current_number))
            exec 'b ' . g:tm_terminal_current_number
        else
            let g:tm_terminal_current_number = 0
            call TMTerminalCreateNew()
        endif
    endif
    call TMSetDefaultConfig()
endfunction

function! TMSetDefaultConfig()
    exec 'setlocal wfh'
endfunction


function! TMTerminalSetDefautlBufferNumber()
    " Save terminal buffer number.
    let l:window_number = winnr()
    let l:buffer_number = winbufnr(l:window_number)
    let g:tm_terminal_current_number = l:buffer_number
endfunction

function! TMTerminalOpenEvent()
    if g:tm_called_by_toggle == 1
        " Mark the first terminal as default.
        call TMTerminalSetDefautlBufferNumber()
        let l:window_number = winnr()
        let l:buffer_number = winbufnr(l:window_number)
        let g:tm_terminal_map[l:buffer_number] = 0
        let g:tm_called_by_toggle = 0
        call TMTerminalRenderStatuslineEvent()
    endif
endfunction

function! TMTerminalDeleteEvent()
    let l:buffer_number = 0
    if g:tm_terminal_delete_bufer_number
        let l:buffer_number = g:tm_terminal_delete_bufer_number
    else
        let l:window_number = winnr()
        let l:buffer_number = winbufnr(l:window_number)
    endif

    call TMGetCurrentNumberAfterDelete(l:buffer_number)
    call TMTerminalRenderStatuslineEvent()
    let g:tm_terminal_delete_bufer_number = 0

endfunction

function! TMGetCurrentNumberAfterDelete(n)
    if has_key(g:tm_terminal_map, a:n)
        call remove(g:tm_terminal_map, a:n)
        if a:n == g:tm_terminal_current_number
            let g:tm_terminal_current_number = len(g:tm_terminal_map) > 0 ? keys(g:tm_terminal_map)[0] : 0
        endif
    endif

    if len(g:tm_terminal_map) == 0
        let g:tm_is_terminal_open = 0
    endif
endfunction


function! TMTerminalRenderStatuslineEvent()
    set statusline=
    let l:count = len(g:tm_terminal_map)
    let l:keys = keys(g:tm_terminal_map)
    if l:count > 0
        if l:keys[0] == g:tm_terminal_current_number
            set statusline +=%1*\ 1\ %*
        else
            set statusline +=%2*\ 1\ %*
        endif
    endif
    if l:count > 1
        if l:keys[1] == g:tm_terminal_current_number
            set statusline +=%1*\ 2\ %*
        else
            set statusline +=%2*\ 2\ %*
        endif
    endif
    if l:count > 2
        if l:keys[2] == g:tm_terminal_current_number
            set statusline +=%1*\ 3\ %*
        else
            set statusline +=%2*\ 3\ %*
        endif
    endif
    if l:count > 3
        if l:keys[3] == g:tm_terminal_current_number
            set statusline +=%1*\ 4\ %*
        else
            set statusline +=%2*\ 4\ %*
        endif
    endif
    if l:count > 4
        if l:keys[4] == g:tm_terminal_current_number
            set statusline +=%1*\ 5\ %*
        else
            set statusline +=%2*\ 5\ %*
        endif
    endif
    if l:count > 5
        if l:keys[5] == g:tm_terminal_current_number
            set statusline +=%1*\ 6\ %*
        else
            set statusline +=%2*\ 6\ %*
        endif
    endif
    hi User1 cterm=bold ctermfg=214 ctermbg=238
    hi User2 cterm=none ctermfg=238 ctermbg=214
    hi StatuslineTerm ctermbg=236 ctermfg=236
    hi StatuslineTermNC ctermbg=236 ctermfg=236
endfunction


command! -nargs=1 -bar TMTerminalDeleteWithIndex :call TMTerminalDeleteWithIndex('<args>')
command! -nargs=1 -bar TMTerminalOpenWithIndex :call TMTerminalOpenWithIndex('<args>')
command! -nargs=0 -bar TMTerminalToggle :call TMTerminalToggle()
command! -nargs=0 -bar TMTerminalOpenNew :call TMTerminalOpenNew()

function! TMLazyLoadCMD()
    if g:tm_lazyload_cmd == 0
        augroup TM
            au TerminalOpen * if &buftype == 'terminal' | call TMTerminalOpenEvent() | endif
            au BufDelete * if &buftype == 'terminal' | call TMTerminalDeleteEvent() | endif
            au BufWinEnter,BufEnter * if &buftype == 'terminal' | call TMTerminalRenderStatuslineEvent() | endif
        augroup END
        let g:tm_lazyload_cmd = 1

        """"""""""""""""""""""""""" Compatible with old verion.""""""""""""""""""""""""""""
        if exists("g:mx_terminal_custom_pos")
            let g:tm_terminal_custom_pos = g:mx_terminal_custom_pos
        endif

        if exists("g:mx_terminal_custom_height")
            let g:tm_terminal_custom_height = g:mx_terminal_custom_height
        endif
        """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    endif
endfunction
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
