" vim: set fdm=marker et ts=4 sw=4 sts=4:
" Folding support
" From: https://github.com/vim-pandoc/vim-pandoc
"       autoload/pandoc/folding.vim
" Original authors:
"   -   Felipe Morales (https://github.com/fmoralesc)
"   -   Alexey Radkov (https://github.com/lyokha)
"   -   Johannes Ranke (https://github.com/jranke)
"   -   Jorge Israel Peña (https://github.com/blaenk)
" Imported and Adapted for Pandoctitude by:
"   -   Jeet Sukumaran (https://github.com/jeetsukumaran)
"
" Init: {{{1
function! pandoctitude#folding#Init()
    " set up defaults {{{2
    "  Show foldcolum {{{3
    if !exists("g:pandoctitude_folding_fdc")
        let g:pandoctitude_folding_fdc = 1
    endif
    " Initial foldlevel {{{3
    if !exists("g:pandoctitude_folding_level")
        let g:pandoctitude_folding_level = &foldlevel
    endif
    " How to decide fold levels {{{3
    " 'syntax': Use syntax
    " 'relative': Count how many parents the header has
    if !exists("g:pandoctitude_folding_mode")
        let g:pandoctitude_folding_mode = 'stacked'
    endif
    " Fold the YAML frontmatter {{{3
    if !exists("g:pandoctitude_folding_yaml")
        let g:pandoctitude_folding_yaml = 0
    endif
    " What <div> classes to fold {{{3
    if !exists("g:pandoctitude_folding_fold_div_classes")
        let g:pandoctitude_folding_fold_div_classes = ["notes"]
    endif
    "}}}3
    " Fold vim markers (see help fold-marker) {{{3
    if !exists("g:pandoctitude_folding_fold_vim_markers")
        let g:pandoctitude_folding_fold_vim_markers = 1
    endif
    " Only fold vim markers inside comments {{{3
    if !exists("g:pandoctitude_folding_fold_vim_markers_in_comments_only")
        let g:pandoctitude_folding_fold_vim_markers_in_comments_only = 1
    endif
    " Fold fenced codeblocks? {{{3
    if !exists("g:pandoctitude_folding_fold_fenced_codeblocks")
        let g:pandoctitude_folding_fold_fenced_codeblocks = 0
    endif
    " Use custom foldtext? {{{3
    if !exists('g:pandoctitude_folding_use_foldtext')
        let g:pandoctitude_folding_use_foldtext = 1
    endif
    " Include number of lines in foldtext {{{3
    if !exists('g:pandoctitude_folding_report_num_folded_lines')
        let g:pandoctitude_folding_report_num_folded_lines = 0
    endif
    " Use basic folding fot this buffer? {{{3
    if !exists("b:pandoctitude_folding_basic")
        let b:pandoctitude_folding_basic = 0
    endif

    " set up folding {{{2
    exe "setlocal foldlevel=".g:pandoctitude_folding_level
    setlocal foldmethod=expr
    " might help with slowness while typing due to syntax checks
    augroup EnableFastFolds
        au!
        autocmd InsertEnter <buffer> setlocal foldmethod=manual
        autocmd InsertLeave <buffer> setlocal foldmethod=expr
    augroup end
    setlocal foldexpr=PandoctitudeFoldExpr()
    if g:pandoctitude_folding_use_foldtext
        setlocal foldtext=PandoctitudeFoldText()
    endif
    if g:pandoctitude_folding_fdc > 0
        let &l:foldcolumn = g:pandoctitude_folding_fdc
    endif
    "}}}
    " set up a command to change the folding mode on demand {{{2
    command! -buffer -nargs=1 -complete=custom,pandoctitude#folding#ModeCmdComplete PandoctitudeFolding call pandoctitude#folding#ModeCmd(<f-args>)
    " }}}2
endfunction

function! pandoctitude#folding#Disable()
    setlocal foldcolumn&
    setlocal foldlevel&
    setlocal foldexpr&
    au! InsertEnter
    au! InsertLeave
    if exists(':PandoctitudeFolding')
        delcommand PandoctitudeFolding
    endif
    setlocal foldmethod& " here because before deleting the autocmds, it might interfere
endfunction

" Change folding mode on demand {{{1
function! pandoctitude#folding#ModeCmdComplete(...)
    return "syntax\nrelative\nstacked\nnone"
endfunction
function! pandoctitude#folding#ModeCmd(mode)
    if a:mode == "none"
        setlocal foldmethod=manual
        normal! zE
    else
        exe "let g:pandoctitude_folding_mode = '".a:mode."'"
        setlocal foldmethod=expr
        normal! zx
    endif
endfunction

" Main foldexpr function, includes support for common stuff. {{{1
" Delegates to filetype specific functions.
function! PandoctitudeFoldExpr()
    " with multiple splits in the same buffer, the folding code can be called
    " way too many times too often, so it's best to disable it to keep good
    " performance.
    if count(map(range(1, winnr('$')), 'bufname(winbufnr(v:val))'), bufname("")) > 1
        return
    endif

    let vline = getline(v:lnum)
    " fold YAML headers
    if g:pandoctitude_folding_yaml == 1
        if vline =~ '\(^---$\|^...$\)' && synIDattr(synID(v:lnum , 1, 1), "name") =~? '\(delimiter\|yamldocumentstart\)'
            if vline =~ '^---$' && v:lnum == 1
                return ">1"
            elseif synIDattr(synID(v:lnum - 1, 1, 1), "name") == "yamlkey"
                return "<1"
            elseif synIDattr(synID(v:lnum - 1, 1, 1), "name") == "pandocYAMLHeader"
                return "<1"
            elseif synIDattr(synID(v:lnum - 1, 1, 1), "name") == "yamlBlockMappingKey"
                return "<1"
            else
                return "="
            endif
        endif
    endif

    " fold divs for special classes
    let div_classes_regex = "\\(".join(g:pandoctitude_folding_fold_div_classes, "\\|")."\\)"
    if vline =~ "<div class=.".div_classes_regex
        return "a1"
    " the `endfold` attribute must be set, otherwise we can remove folds
    " incorrectly (see issue #32)
    " pandoc ignores this attribute, so this is safe.
    elseif vline =~ '</div endfold>'
        return "s1"
    endif

    " fold markers?
    if g:pandoctitude_folding_fold_vim_markers == 1
        if vline =~ '[{}]\{3}'
            if g:pandoctitude_folding_fold_vim_markers_in_comments_only == 1
                let mark_head = '<!--.*'
            else
                let mark_head = ''
            endif
            if vline =~ mark_head.'{\{3}'
                let level = matchstr(vline, '\({\{3}\)\@<=\d')
                if level != ""
                    return ">".level
                else
                    return "a1"
                endif
            endif
            if vline =~ mark_head.'}\{3}'
                let level = matchstr(vline, '\(}\{3}\)\@<=\d')
                if level != ""
                    return "<".level
                else
                    return "s1"
                endif
            endif
        endif
    endif

    " Delegate to filetype specific functions
    if &ft =~ "markdown" || &ft == "pandoc" || &ft == "rmd" || &ft == "rst" || &ft == "rest"
        " vim-pandoc-syntax sets this variable, so we can check if we can use
        " syntax assistance in our foldexpr function
        " if exists("g:vim_pandoc_syntax_exists") && b:pandoctitude_folding_basic != 1
        if 0 " causes problems with documents with fenced/embedded code etc.
            return pandoctitude#folding#MarkdownLevelSA()
        " otherwise, we use a simple, but less featureful foldexpr
        else
            return pandoctitude#folding#MarkdownLevelBasic()
        endif
    elseif &ft == "textile"
        return TextileLevel()
    endif

endfunction

" Main foldtext function. Like ...PandoctitudeFoldExpr() {{{1
function! PandoctitudeFoldText()
    " first line of the fold
    let f_line = getline(v:foldstart)
    " second line of the fold
    let n_line = getline(v:foldstart + 1)
    " count of lines in the fold
    if g:pandoctitude_folding_report_num_folded_lines
        let line_count = v:foldend - v:foldstart + 1
        let line_count_text = " / " . line_count . " lines / "
    else
        let line_count_text = ""
    endif
    if n_line =~ 'title\s*:'
        return v:folddashes . " [y] " . matchstr(n_line, '\(title\s*:\s*\)\@<=\S.*') . line_count_text
    endif
    if f_line =~ "fold-begin"
        return v:folddashes . " [c] " . matchstr(f_line, '\(<!-- \)\@<=.*\( fold-begin -->\)\@=') . line_count_text
    endif
    if f_line =~ "<!-- .*{{{"
        return v:folddashes . " [m] " . matchstr(f_line, '\(<!-- \)\@<=.*\( {{{.* -->\)\@=') . line_count_text
    endif
    if f_line =~ "<div class="
        return v:folddashes . " [". matchstr(f_line, "\\(class=[\"']\\)\\@<=.*[\"']\\@="). "] " . n_line[:30] . "..." . line_count_text
    endif
    if &ft =~ "markdown" || &ft == "pandoc" || &ft == "rmd"
        return pandoctitude#folding#MarkdownFoldText() . line_count_text
    elseif &ft == "textile"
        return pandoctitude#folding#TextileFoldText() . line_count_text
    endif
endfunction

" Markdown: {{{1
"
" Originally taken from http://stackoverflow.com/questions/3828606
"
" Syntax assisted (SA) foldexpr {{{2
function! pandoctitude#folding#MarkdownLevelSA()
    let vline = getline(v:lnum)
    let vline1 = getline(v:lnum + 1)
    if vline =~ '^#\{1,6}[^.]'
        if synIDattr(synID(v:lnum, 1, 1), "name") =~ '^pandoc\(DelimitedCodeBlock$\)\@!'
            if g:pandoctitude_folding_mode == 'relative'
                return ">". len(markdown#headers#CurrentHeaderAncestors(v:lnum))
            elseif g:pandoctitude_folding_mode == 'stacked'
                return ">1"
            else
                return ">". len(matchstr(vline, '^#\{1,6}'))
            endif
        endif
    elseif vline =~ '^[^-=].\+$' && vline1 =~ '^=\+$'
        if synIDattr(synID(v:lnum, 1, 1), "name") =~ '^pandoc\(DelimitedCodeBlock$\)\@!'  &&
                    \ synIDattr(synID(v:lnum + 1, 1, 1), "name") == "pandocSetexHeader"
            return ">1"
        endif
    elseif vline =~ '^[^-=].\+$' && vline1 =~ '^-\+$'
        if synIDattr(synID(v:lnum, 1, 1), "name") =~ '^pandoc\(DelimitedCodeBlock$\)\@!'  &&
                    \ synIDattr(synID(v:lnum + 1, 1, 1), "name") == "pandocSetexHeader"
            if g:pandoctitude_folding_mode == 'relative'
                return  ">". len(markdown#headers#CurrentHeaderAncestors(v:lnum))
            elseif g:pandoctitude_folding_mode == 'stacked'
                return ">1"
            else
                return ">2"
            endif
        endif
    elseif vline =~ '^<!--.*fold-begin -->'
        return "a1"
    elseif vline =~ '^<!--.*fold-end -->'
        return "s1"
    elseif vline =~ '^\s*[`~]\{3}'
        if g:pandoctitude_folding_fold_fenced_codeblocks == 1
            let synId = synIDattr(synID(v:lnum, match(vline, '[`~]') + 1, 1), "name")
            if synId == 'pandocDelimitedCodeBlockStart'
                return "a1"
            elseif synId =~ '^pandoc\(DelimitedCodeBlock$\)\@!'
                return "s1"
            endif
        endif
    endif
    return "="
endfunction

" RST fold level {{{2
function! pandoctitude#folding#Is_rst_heading(focal_line, test_char)
    if getline(a:focal_line) =~ '^\s*'.a:test_char.'\{3,}'
        let overline_lnum = a:focal_line
        let title_line_lnum = a:focal_line + 1
        let underline_lnum = a:focal_line + 2
        let is_overline_line = 1
    else
        let overline_lnum = a:focal_line - 1
        let title_line_lnum = a:focal_line
        let underline_lnum = a:focal_line + 1
        let is_overline_line = 0
    endif
    let title_len = len(substitute(getline(title_line_lnum), '^\s*', '', ''))
    if title_len == 0
        return 0
    endif
    let has_underline = len(matchstr(getline(underline_lnum), '^\s*' . a:test_char . '\+')) >= title_len
    let has_overline = len(matchstr(getline(overline_lnum), '^\s*' . a:test_char . '\+')) >= title_len
    if is_overline_line && has_overline && has_underline
        let rval =  2
    elseif has_overline && has_underline
        let rval =  0 " because we captured it previously
    elseif has_underline
        let rval =  1
    else
        let rval =  0
    endif
    return rval
endfunction

function! pandoctitude#folding#Calc_rst_heading_level(focal_line)
    " Sphinx style guide for heading levels:
    " 1. # with overline
    " 2. * with overline
    " 3. =
    " 4. -
    " 5. ^
    " 6. "
    if !exists("b:pandoctitude_rst_headings")
        let b:pandoctitude_rst_headings = {}
    endif
    let found = 0
    let level_count = 0
    for hc in ['#', '\*', '=', '-', '^', '"']
        let level_count = level_count + 1
        let result = pandoctitude#folding#Is_rst_heading(a:focal_line, hc)
        if result
            let b:pandoctitude_rst_headings[a:focal_line] = [level_count, result]
            let found = 1
            break
        endif
    endfor
    if found
        return level_count
    else
        return 0
    endif
endfunction

" Basic foldexpr {{{2
function! pandoctitude#folding#MarkdownLevelBasic()
    if getline(v:lnum) =~ '^#\{1,6}' && getline(v:lnum-1) =~ '^\s*$'
        if g:pandoctitude_folding_mode == 'stacked'
            return ">1"
        else
            return ">". len(matchstr(getline(v:lnum), '^#\{1,6}'))
        endif
    else
        let rst_level = pandoctitude#folding#Calc_rst_heading_level(v:lnum)
        if rst_level
            if g:pandoctitude_folding_mode == 'stacked'
                return ">1"
            else
                return ">" . rst_level
            endif
        endif
    endif
    return "="
endfunction

" Markdown foldtext {{{2
function! pandoctitude#folding#MarkdownFoldText()
    let c_line = getline(v:foldstart)
    let atx_title = match(c_line, '#') > -1
    if atx_title
        " let level_count = len(substitute(c_line, '\(^#\+\).*', '\1', 'g')) - 1
        let level_count = len(matchstr(c_line, '^#\{1,6}')) - 1
        let c_line = substitute(c_line, '^#\+[^#]', '', 'g')
        let leader = repeat(" ", (level_count * 2))
        return leader . '- ' . c_line
    else
        let stored_heading_calc = get(b:pandoctitude_rst_headings, v:foldstart, [0,0])
        let level_count = stored_heading_calc[0]
        " if c_line =~ '^\s*[#*=-^".]\{3,}'
        if stored_heading_calc[1] == 2
            " fold start is actually an overline, so grab next line for title
            let c_line = getline(v:foldstart + 1)
        endif
        let leader = repeat(" ", (level_count * 2))
        return leader . '- ' . c_line
    endif
endfunction

" Textile: {{{1
"
function! pandoctitude#folding#TextileLevel()
    let vline = getline(v:lnum)
    if vline =~ '^h[1-6]\.'
        if g:pandoctitude_folding_mode == 'stacked'
            return ">"
        else
            return ">" . matchstr(getline(v:lnum), 'h\@1<=[1-6]\.\=')
        endif
    elseif vline =~ '^.. .*fold-begin'
        return "a1"
    elseif vline =~ '^.. .*fold end'
        return "s1"
    endif
    return "="
endfunction

function! pandoctitude#folding#TextileFoldText()
    return "- ". substitute(v:folddashes, "-", "#", "g"). " " . matchstr(getline(v:foldstart), '\(h[1-6]\. \)\@4<=.*')
endfunction

