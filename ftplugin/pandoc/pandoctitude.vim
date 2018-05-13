""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""  Pandoctitude
""
""  Copyright 2015 Jeet Sukumaran.
""
""  This program is free software; you can redistribute it and/or modify
""  it under the terms of the GNU General Public License as published by
""  the Free Software Foundation; either version 3 of the License, or
""  (at your option) any later version.
""
""  This program is distributed in the hope that it will be useful,
""  but WITHOUT ANY WARRANTY; without even the implied warranty of
""  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
""  GNU General Public License <http://www.gnu.org/licenses/>
""  for more details.
""
""  Pandoctitude uses code modified from the following:
""
""     https://github.com/plasticboy/vim-markdown.git
""     https://github.com/vim-pandoc/vim-pandoc.git
""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Reload Guard {{{1
" ============================================================================
if exists("b:did_pandoctitude") && b:did_pandoctitude == 1
    finish
endif
let b:did_pandoctitude = 1
" }}}1

" Compatibility Guard {{{1
" ============================================================================
" avoid line continuation issues (see ':help user_41.txt')
let s:save_cpo = &cpo
set cpo&vim
" }}}1

" Global Variables {{{1
" ============================================================================
let g:pandoctitude_tag_generator_path = get(g:, 'pandoctitude_tag_generator_path', 'markdown2ctags.py')
let g:pandoctitude_toc_position = get(g:, 'pandoctitude_toc_position', 'right')
let g:pandoctitude_autoclose_toc = get(g:, 'pandoctitude_autoclose_toc', 1)
" }}}1

" Script Variables {{{1
" ============================================================================
" For each level, contains the regexp that matches at that level only.
let s:levelRegexpDict = {
    \ 1: '\v^(#[^#]@=|.+\n\=+$)',
    \ 2: '\v^(##[^#]@=|.+\n-+$)',
    \ 3: '\v^###[^#]@=',
    \ 4: '\v^####[^#]@=',
    \ 5: '\v^#####[^#]@=',
    \ 6: '\v^######[^#]@=',
    \ 7: '\v^#######[^#]@=',
    \ 8: '\v^#######[^#]@='
\ }
let s:headersRegexp = '\v^(#|.+\n(\=+|-+)$)'
" }}}1

" Functions {{{1
" ============================================================================

" Utility, Supporting, and Service {{{2
" ============================================================================

" Returns the line number of the first header before `line`, called the
" current header.
"
" If there is no current header, return `0`.
"
" @param a:1 The line to look the header of. Default value: `getpos('.')`.
"
function! s:_get_header_line_number(...)
    if a:0 == 0
        let l:l = line('.')
    else
        let l:l = a:1
    endif
    while(l:l > 0)
        if join(getline(l:l, l:l + 1), "\n") =~ s:headersRegexp
            return l:l
        endif
        let l:l -= 1
    endwhile
    return 0
endfunction

" - if line is inside a header, return the header level (h1 -> 1, h2 -> 2, etc.).
"
" - if line is at top level outside any headers, return `0`.
"
function! s:_get_header_level(...)
    if a:0 == 0
        let l:line = line('.')
    else
        let l:line = a:1
    endif
    let l:linenum = s:_get_header_line_number(l:line)
    if l:linenum != 0
        return s:_get_level_of_header_at_line(l:linenum)
    else
        return 0
    endif
endfunction

" Returns the level of the header at the given line.
"
" If there is no header at the given line, returns `0`.
"
function! s:_get_level_of_header_at_line(linenum)
    let l:lines = join(getline(a:linenum, a:linenum + 1), "\n")
    for l:key in keys(s:levelRegexpDict)
        if l:lines =~ get(s:levelRegexpDict, l:key)
            return l:key
        endif
    endfor
    return 0
endfunction

" Return the line number of the parent header of line `line`.
"
" If it has no parent, return `0`.
"
function! s:_get_parent_header_line_number(...)
    if a:0 == 0
        let l:line = line('.')
    else
        let l:line = a:1
    endif
    let l:level = s:_get_header_level(l:line)
    if l:level > 1
        let l:linenum = s:_get_previous_header_line_number_at_level(l:level - 1, l:line)
        return l:linenum
    endif
    return 0
endfunction

" Return the line number of the previous header of given level.
" in relation to line `a:1`. If not given, `a:1 = getline()`
"
" `a:1` line is included, and this may return the current header.
"
" If none return 0.
"
function! s:_get_next_header_line_number_at_level(level, ...)
    if a:0 < 1
        let l:line = line('.')
    else
        let l:line = a:1
    endif
    let l:l = l:line
    while(l:l <= line('$'))
        if join(getline(l:l, l:l + 1), "\n") =~ get(s:levelRegexpDict, a:level)
            return l:l
        endif
        let l:l += 1
    endwhile
    return 0
endfunction

" Return the line number of the previous header of given level.
" in relation to line `a:1`. If not given, `a:1 = getline()`
"
" `a:1` line is included, and this may return the current header.
"
" If none return 0.
"
function! s:_get_previous_header_line_number_at_level(level, ...)
    if a:0 == 0
        let l:line = line('.')
    else
        let l:line = a:1
    endif
    let l:l = l:line
    while(l:l > 0)
        if join(getline(l:l, l:l + 1), "\n") =~ get(s:levelRegexpDict, a:level)
            return l:l
        endif
        let l:l -= 1
    endwhile
    return 0
endfunction
" }}}2

" Public Functions {{{2
" ============================================================================

" Informational {{{3
" ============================================================================

" Echo the header hierarchy
function! s:Pandoctitude_EchoHierarchy()
    let header_lines = []
    let current_lnum = s:_get_header_line_number()
    if current_lnum == 0
        echo 'Outside any header'
        return
    endif
    call add(header_lines, getline(current_lnum))
    while 1
        let current_lnum = s:_get_parent_header_line_number(current_lnum)
        if current_lnum == 0
            break
        endif
        call add(header_lines, getline(current_lnum))
    endwhile
    call reverse(header_lines)
    redraw
    for line_content in header_lines
        echo line_content
    endfor
endfunction

" }}}3

" Movement {{{3
" ============================================================================

" - if inside a header goes to it.
"    Return its line number.
"
" - if on top level outside any headers,
"    print a warning
"    Return `0`.
"
function! s:Pandoctitude_MoveToCurrentHeader(mode)
    let l:lineNum = s:_get_header_line_number()
    if l:lineNum != 0
        if a:mode == "v"
            normal! gv
        endif
        execute "normal! " . l:lineNum . "G^"
    else
        echo 'Outside any header'
        "normal! gg
    endif
    return l:lineNum
endfunction

" Move cursor to next header of any level.
function! s:Pandoctitude_MoveToNextHeader(mode) range
    let num_reps = v:count1
    let target_line = a:lastline
    let start_line = target_line
    while num_reps > 0
        call cursor(l:target_line, 0)
        let search_match = search(s:headersRegexp, 'Wn')
        if search_match == 0
            echo 'No next header'
            break
        else
            let target_line = search_match
        endif
        let num_reps = num_reps - 1
    endwhile
    if a:mode == "v"
        normal! gv
    endif
    if target_line != 0 && target_line != start_line
        execute "normal! " . target_line . "G"
    else
        call cursor(l:start_line, 0)
    endif
endfunction

" Move cursor to previous header (before current) of any level.
function! s:Pandoctitude_MoveToPreviousHeader(mode) range
    let num_reps = v:count1
    let target_line = a:firstline
    let start_line = target_line
    while num_reps > 0
        let l:curHeaderLineNumber = s:_get_header_line_number(target_line)
        let l:noPreviousHeader = 0
        if l:curHeaderLineNumber <= 1
            let l:noPreviousHeader = 1
        else
            let l:previousHeaderLineNumber = s:_get_header_line_number(l:curHeaderLineNumber - 1)
            if l:previousHeaderLineNumber == 0
                let l:noPreviousHeader = 1
            else
                let l:target_line =  l:previousHeaderLineNumber
            endif
        endif
        if l:noPreviousHeader
            echo 'No previous header'
            break
        endif
        let num_reps = num_reps - 1
    endwhile
    if a:mode == "v"
        normal! gv
    endif
    if target_line != 0 && target_line != start_line
        execute "normal! " . target_line . "G"
    endif
endfunction

" Move cursor to parent header of the current header.
"
" If it does not exit, print a warning and do nothing.
"
function! s:Pandoctitude_MoveToParentHeader(mode) range
    let num_reps = v:count1
    let target_line = a:firstline
    let start_line = target_line
    while num_reps > 0
        let search_line = s:_get_parent_header_line_number(target_line)
        if search_line == 0
            echo 'No parent header'
            break
        endif
        let target_line = search_line
        let num_reps = num_reps - 1
    endwhile
    if a:mode == "v"
        normal! gv
    endif
    if target_line != 0 && target_line != start_line
        execute "normal! " . target_line . "G"
    endif
endfunction

" Move cursor to next sibling header.
function! s:Pandoctitude_MoveToNextSiblingHeader(mode) range
    let num_reps = v:count1
    let target_line = a:lastline
    let start_line = target_line
    while num_reps > 0
        let l:curHeaderLineNumber = s:_get_header_line_number(target_line)
        let l:curHeaderLevel = s:_get_level_of_header_at_line(l:curHeaderLineNumber)
        let l:curHeaderParentLineNumber = s:_get_parent_header_line_number()
        let l:nextHeaderSameLevelLineNumber = s:_get_next_header_line_number_at_level(l:curHeaderLevel, l:curHeaderLineNumber + 1)
        let l:noNextSibling = 0
        if l:nextHeaderSameLevelLineNumber == 0
            let l:noNextSibling = 1
        else
            let l:nextHeaderSameLevelParentLineNumber = s:_get_parent_header_line_number(l:nextHeaderSameLevelLineNumber)
            if l:curHeaderParentLineNumber == l:nextHeaderSameLevelParentLineNumber
                let target_line = l:nextHeaderSameLevelLineNumber
            else
                let l:noNextSibling = 1
            endif
        endif
        if l:noNextSibling
            echo 'No next sibling header'
            break
        endif
        let num_reps = num_reps - 1
    endwhile
    if a:mode == "v"
        normal! gv
    endif
    if target_line != 0 && target_line != start_line
        execute "normal! " . target_line . "G"
    endif
endfunction

" Move cursor to previous sibling header.
function! s:Pandoctitude_MoveToPreviousSiblingHeader(mode) range
    let num_reps = v:count1
    let target_line = a:firstline
    let start_line = target_line
    while num_reps > 0
        let l:curHeaderLineNumber = s:_get_header_line_number(target_line)
        let l:curHeaderLevel = s:_get_level_of_header_at_line(l:curHeaderLineNumber)
        let l:curHeaderParentLineNumber = s:_get_parent_header_line_number()
        let l:previousHeaderSameLevelLineNumber = s:_get_previous_header_line_number_at_level(l:curHeaderLevel, l:curHeaderLineNumber - 1)
        let l:noPreviousSibling = 0
        if l:previousHeaderSameLevelLineNumber == 0
            let l:noPreviousSibling = 1
        else
            let l:previousHeaderSameLevelParentLineNumber = s:_get_parent_header_line_number(l:previousHeaderSameLevelLineNumber)
            if l:curHeaderParentLineNumber == l:previousHeaderSameLevelParentLineNumber
                let l:target_line = l:previousHeaderSameLevelLineNumber
            else
                let l:noPreviousSibling = 1
            endif
        endif
        if l:noPreviousSibling
            echo 'No previous sibling header'
            break
        endif
        let num_reps = num_reps - 1
    endwhile
    if a:mode == "v"
        normal! gv
    endif
    if target_line != 0 && target_line != start_line
        execute "normal! " . target_line . "G"
    endif
endfunction

" Move to next header of absolute level.
function! s:Pandoctitude_MoveToNextAbsoluteHeaderLevel(mode) range
    let num_reps = 1
    let target_line = a:lastline
    let l:targetHeaderLevel = v:count1
    let start_line = target_line
    while num_reps > 0
        let l:nextHeaderOfTargetLevelLineNumber = s:_get_next_header_line_number_at_level(l:targetHeaderLevel, l:target_line + 1)
        let l:noNextHeaderOfTargetLevel = 0
        if l:nextHeaderOfTargetLevelLineNumber == 0
            let l:noNextHeaderOfTargetLevel = 1
        else
            let target_line = l:nextHeaderOfTargetLevelLineNumber
        endif
        if l:noNextHeaderOfTargetLevel
            echo 'No next header of level ' . l:targetHeaderLevel
            break
        endif
        let num_reps = num_reps - 1
    endwhile
    if a:mode == "v"
        normal! gv
    endif
    if target_line != 0 && target_line != start_line
        execute "normal! " . target_line . "G"
    endif
endfunction

" Move to previous header of absolute level.
function! s:Pandoctitude_MoveToPreviousAbsoluteHeaderLevel(mode) range
    let num_reps = 1
    let target_line = a:firstline
    let l:targetHeaderLevel = v:count1
    let start_line = target_line
    while num_reps > 0
        let l:previousHeaderOfTargetLevelLineNumber = s:_get_previous_header_line_number_at_level(l:targetHeaderLevel, l:target_line - 1)
        let l:noPreviousHeaderOfTargetLevel = 0
        if l:previousHeaderOfTargetLevelLineNumber == 0
            let l:noPreviousHeaderOfTargetLevel = 1
        else
            let target_line = l:previousHeaderOfTargetLevelLineNumber
        endif
        if l:noPreviousHeaderOfTargetLevel
            echo 'No previous header of level ' . l:targetHeaderLevel
            break
        endif
        let num_reps = num_reps - 1
    endwhile
    if a:mode == "v"
        normal! gv
    endif
    if target_line != 0 && target_line != start_line
        execute "normal! " . target_line . "G"
    endif
endfunction

" }}}3

" TOC {{{3
" ============================================================================

function! s:toc_show()
    let bufname=expand("%")

    " prepare the location-list buffer
    call s:toc_update()
    if g:pandoctitude_toc_position == "right"
        let toc_pos = "vertical"
    elseif g:pandoctitude_toc_position == "left"
        let toc_pos = "topleft vertical"
    elseif g:pandoctitude_toc_position == "top"
        let toc_pos = "topleft"
    elseif g:pandoctitude_toc_position == "bottom"
        let toc_pos = "botright"
    else
        let toc_pos == "vertical"
    endif
    try
        exe toc_pos . " lopen"
    catch /E776/ " no location list
        echohl ErrorMsg
        echom "Pandoctitude: no places to show in Table of Contents"
        echohl None
        return
    endtry
    call s:toc_refresh(bufname)
    " move to the top
    normal! gg
endfunction


function! s:toc_update()
    try
        silent lvimgrep /\(^\S.*\(\n[=-]\+\n\)\@=\|^#\{1,6}[^.]\|\%^%\)/ %
    catch /E480/
        return
    catch /E499/ " % has no name
        return
    endtry
endfunction


function! s:toc_refresh(bufname)
    let bullet_char = '•'
    if len(getloclist(0)) == 0
        lclose
        return
    endif
    let &winwidth=(&columns/3)
    execute "setlocal statusline=TOC:".escape(a:bufname, ' ')
    " change the contents of the location-list buffer
    set modifiable
    silent %s/\v^([^|]*\|){2,2} #//e
    for l in range(1, line("$"))
        " this is the location-list data for the current item
        let d = getloclist(0)[l-1]
        " titleblock
        if match(d.text, "^%") > -1
            let l:level = 0
        " atx headers
        elseif match(d.text, "^#") > -1
            let l:level = len(matchstr(d.text, '#*', 'g'))-1
            let d.text = bullet_char . ' '.d.text[l:level+2:]
        " setex headers
        else
            let l:next_line = getbufline(bufname(d.bufnr), d.lnum+1)
            if match(l:next_line, "=") > -1
        	let l:level = 0
            elseif match(l:next_line, "-") > -1
        	let l:level = 1
            endif
            let d.text = bullet_char . ' '.d.text
        endif
        call setline(l, repeat(' ', 2*l:level-1). d.text)
    endfor
    set nomodified
    set nomodifiable
    " re-highlight the quickfix buffer
    syn match pandocTocHeader /^.*\n/
    execute 'syn match pandocTocBullet /'. bullet_char . '/ contained containedin=pandocTocHeader'
    syn match pandocTocTitle /^%.*\n/
    hi link pandocTocHeader Title
    hi link pandocTocTitle Directory
    hi link pandocTocBullet Delimiter
    setlocal linebreak
    setlocal wrap
    setlocal showbreak=..
    try
        setlocal breakindent
    catch /E518:/
    endtry
    noremap <buffer> <silent> q  :lclose<CR>
    noremap <buffer> <silent> cw :setlocal wrap!<CR>
    if g:pandoctitude_autoclose_toc == 1
        let mod = ""
        noremap <buffer> <silent> <C-CR> <CR>
    else
        let mod = "C-"
    endif
    exe "noremap <buffer> <".mod."CR> <CR>:lclose<CR>"
endfunction

" }}}3

" }}}2

" }}}1

" Commands {{{1
" ============================================================================
command! -buffer -range=% HeaderPromote call s:HeaderPromote(<line1>, <line2>)
command! -buffer -range=% HeaderDemote call s:HeaderPromote(<line1>, <line2>, 1)
command! -buffer -range=% SetexToAtx call s:SetexToAtx(<line1>, <line2>)
command! -buffer Toc call s:toc_show()
" }}}1

" Public Plug Definitions {{{1
" ============================================================================
noremap   <buffer> <silent> <Plug>(PandoctitudeMoveToPreviousHeader) :<C-U>call <SID>Pandoctitude_MoveToPreviousHeader("n")<cr>
vnoremap  <buffer> <silent> <Plug>(PandoctitudeMoveToPreviousHeader) :call <SID>Pandoctitude_MoveToPreviousHeader("v")<cr>

noremap   <buffer> <silent> <Plug>(PandoctitudeMoveToNextHeader) :<C-U>call <SID>Pandoctitude_MoveToNextHeader("n")<cr>
vnoremap  <buffer> <silent> <Plug>(PandoctitudeMoveToNextHeader) :call <SID>Pandoctitude_MoveToNextHeader("v")<cr>

noremap   <buffer> <silent> <Plug>(PandoctitudeMoveToPreviousSiblingHeader) :<C-U>call <SID>Pandoctitude_MoveToPreviousSiblingHeader("n")<cr>
vnoremap  <buffer> <silent> <Plug>(PandoctitudeMoveToPreviousSiblingHeader) :call <SID>Pandoctitude_MoveToPreviousSiblingHeader("v")<cr>

noremap   <buffer> <silent> <Plug>(PandoctitudeMoveToNextSiblingHeader) :<C-U>call <SID>Pandoctitude_MoveToNextSiblingHeader("n")<cr>
vnoremap  <buffer> <silent> <Plug>(PandoctitudeMoveToNextSiblingHeader) :call <SID>Pandoctitude_MoveToNextSiblingHeader("v")<cr>

noremap   <buffer> <silent> <Plug>(PandoctitudeMoveToCurrentHeader) :call <SID>Pandoctitude_MoveToCurrentHeader("n")<cr>
vnoremap  <buffer> <silent> <Plug>(PandoctitudeMoveToCurrentHeader) :<C-U>call <SID>Pandoctitude_MoveToCurrentHeader("v")<cr>

noremap   <buffer> <silent> <Plug>(PandoctitudeMoveToParentHeader) :<C-U>call <SID>Pandoctitude_MoveToParentHeader("n")<cr>
vnoremap  <buffer> <silent> <Plug>(PandoctitudeMoveToParentHeader) :call <SID>Pandoctitude_MoveToParentHeader("v")<cr>

noremap   <buffer> <silent> <Plug>(PandoctitudeMoveToPreviousAbsoluteHeaderLevel) :<C-U>call <SID>Pandoctitude_MoveToPreviousAbsoluteHeaderLevel("n")<cr>
vnoremap  <buffer> <silent> <Plug>(PandoctitudeMoveToPreviousAbsoluteHeaderLevel) :<C-U>call <SID>Pandoctitude_MoveToPreviousAbsoluteHeaderLevel("v")<cr>

noremap   <buffer> <silent> <Plug>(PandoctitudeMoveToNextAbsoluteHeaderLevel) :<C-U>call <SID>Pandoctitude_MoveToNextAbsoluteHeaderLevel("n")<cr>
vnoremap  <buffer> <silent> <Plug>(PandoctitudeMoveToNextAbsoluteHeaderLevel) :<C-U>call <SID>Pandoctitude_MoveToNextAbsoluteHeaderLevel("v")<cr>

nnoremap <buffer>  <silent> <Plug>(PandoctitudeEchoLocation) :call <SID>Pandoctitude_EchoHierarchy()<CR>

" }}}1

" Key Mappings {{{1
" ============================================================================
if !exists('g:pandoctitude_suppress_keymaps') || !g:pandoctitude_suppress_keymaps
    if !hasmapto('<Plug>(PandoctitudeMoveToPreviousHeader)')
        map <buffer> [[ <Plug>(PandoctitudeMoveToPreviousHeader)
    endif
    if !hasmapto('<Plug>(PandoctitudeMoveToNextHeader)')
        map <buffer> ]] <Plug>(PandoctitudeMoveToNextHeader)
    endif
    if !hasmapto('<Plug>(PandoctitudeMoveToPreviousSiblingHeader)')
        map <buffer> [= <Plug>(PandoctitudeMoveToPreviousSiblingHeader)
    endif
    if !hasmapto('<Plug>(PandoctitudeMoveToNextSiblingHeader)')
        map <buffer> ]= <Plug>(PandoctitudeMoveToNextSiblingHeader)
    endif
    if !hasmapto('<Plug>(PandoctitudeMoveToCurrentHeader)')
        map <buffer> [. <Plug>(PandoctitudeMoveToCurrentHeader)
    endif
    if !hasmapto('<Plug>(PandoctitudeMoveToParentHeader)')
        map <buffer> [- <Plug>(PandoctitudeMoveToParentHeader)
    endif
    if !hasmapto('<Plug>(PandoctitudeMoveToPreviousAbsoluteHeaderLevel)')
        map <buffer> [_ <Plug>(PandoctitudeMoveToPreviousAbsoluteHeaderLevel)
    endif
    if !hasmapto('<Plug>(PandoctitudeMoveToNextAbsoluteHeaderLevel)')
        map <buffer> ]_ <Plug>(PandoctitudeMoveToNextAbsoluteHeaderLevel)
    endif
    if !hasmapto('<Plug>(PandoctitudeEchoLocation)')
        map <buffer> gG <Plug>(PandoctitudeEchoLocation)
    endif
endif
" }}}1

" Setup for Tagbar {{{1
" ============================================================================
if !empty(g:pandoctitude_tag_generator_path) && executable(g:pandoctitude_tag_generator_path)
    let g:tagbar_type_pandoc = {
        \ 'ctagstype': 'pandoc',
        \ 'ctagsbin' : g:pandoctitude_tag_generator_path,
        \ 'ctagsargs' : '-f - --sort=yes',
        \ 'kinds' : [
            \ 's:sections',
            \ 'i:images'
        \ ],
        \ 'sro' : '|',
        \ 'kind2scope' : {
            \ 's' : 'section',
        \ },
        \ 'sort': 0,
    \ }
endif
" }}}1

" Restore State {{{1
" ============================================================================
" restore options
let &cpo = s:save_cpo
" }}}1

