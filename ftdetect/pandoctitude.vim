
let g:pandoctitude_claim_markdown = get(g:, "pandoctitude_claim_markdown", 1)
let g:pandoctitude_claim_text = get(g:, "pandoctitude_claim_text", 1)
let g:pandoctitude_claim_rst = get(g:, "pandoctitude_claim_rst", 1)
augroup pandoctitude
    au BufNewFile,BufRead *.pandoc,*.pdk,*.pd,*.pdc set filetype=pandoc
    if g:pandoctitude_claim_markdown
        au BufNewFile,BufRead *.markdown,*.mkd,*.md set filetype=pandoc
    endif
    if g:pandoctitude_claim_text
        au BufNewFile,BufRead *.txt,*.text set filetype=pandoc
    endif
    if g:pandoctitude_claim_rst
        au BufNewFile,BufRead *.rst set filetype=pandoc
    endif
augroup END
