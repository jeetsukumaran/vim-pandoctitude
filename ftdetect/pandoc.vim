augroup pandoctitude
    au BufNewFile,BufRead *.pandoc,*.pdk,*.pd,*.pdc set filetype=pandoc
    au BufNewFile,BufRead *.markdown,*.mkd,*.md set filetype=pandoc
augroup END
