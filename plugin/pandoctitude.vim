

" Reload Guard {{{1
" ============================================================================
if exists("g:did_pandoctitude_plugin") && g:did_pandoctitude_plugin == 1
    finish
endif
let g:did_pandoctitude_plugin = 1
" }}} 1

" Compatibility Guard {{{1
" ============================================================================
" avoid line continuation issues (see ':help user_41.txt')
let s:save_cpo = &cpo
set cpo&vim
" }}}1

" Globals {{{1
" ============================================================================
let g:pandoctitude_claim_markdown = get(g:, "pandoctitude_claim_markdown", 1)
let g:pandoctitude_claim_text = get(g:, "pandoctitude_claim_text", 1)
let g:pandoctitude_claim_rst = get(g:, "pandoctitude_claim_rst", 1)
" }}}1

" Functions {{{1
" ============================================================================
function! s:Pandoctitude_ClaimFiletype()
    if &ft == "cmake"
        return
    endif

    if &ft == "markdown"
        let restore_syntax = ""
    elseif &ft == "rst"
        let restore_syntax = "rst"
    else
        let restore_syntax = ""
    endif

    try
        set ft=pandoc
    catch //
        " Due to error with vim-pandoc-syntax in v:version < 704
    endtry

    if !empty(restore_syntax)
        execute "silent set syntax=" . restore_syntax
    endif
endfunction
" }}}1

augroup pandoctitude
    au BufNewFile,BufRead *.pandoc,*.pdk,*.pd,*.pdc call s:Pandoctitude_ClaimFiletype()
    if g:pandoctitude_claim_markdown
        au BufNewFile,BufRead *.markdown,*.mkd,*.md call s:Pandoctitude_ClaimFiletype()
    endif
    if g:pandoctitude_claim_text
        au BufNewFile,BufRead *.txt,*.text call s:Pandoctitude_ClaimFiletype()
    endif
    if g:pandoctitude_claim_rst
        au BufNewFile,BufRead *.rst call s:Pandoctitude_ClaimFiletype()
        au BufNewFile,BufRead *.rst set commentstring=..\ %s
    endif
augroup END


" Restore State {{{1
" ============================================================================
" restore options
let &cpo = s:save_cpo
" }}}1
