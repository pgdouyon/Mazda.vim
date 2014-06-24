" ======================================================================
" File:         mazda.vim
" Description:  Zooms in on an a specified region of text and opens it
"               in a separate buffer for editing.  Text in the zoomed
"               buffer can then be saved back to the original file or
"               discarded as needed.
" Maintainer:   Pierre-Guy Douyon <pgdouyon@alum.mit.edu>
" Version:      1.0
" Last Change:  2014-06-23
" License:      MIT <../LICENSE>
" ======================================================================

if exists("g:loaded_mazda")
    finish
endif
let g:loaded_mazda = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:mazda_buf_id = 0
let s:last_region_start = 0
let s:last_region_end = 0

if !exists("g:mazda_zoom_out_on_write")
    let g:mazda_zoom_out_on_write = 1
endif

if !exists("g:mazda_default_mappings")
    let g:mazda_default_mappings = 1
endif

function! s:ZoomZoom(mode)
    if a:mode ==# "v"
        let zoom_text = getline("'<", "'>")
        let b:mazda_start = line("'<")
        let b:mazda_end = line("'>")
    else
        let zoom_text = getline("'[", "']")
        let b:mazda_start = line("'[")
        let b:mazda_end = line("']")
    endif
    let s:last_region_start = b:mazda_start
    let s:last_region_end = b:mazda_end
    call s:OpenZoomBuffer(&filetype)
    call setline(1, zoom_text)
endfunction


function! s:OpenZoomBuffer(filetype)
    let s:mazda_buf_id += 1
    let origin = bufname("%")
    " preserve alternate buffer and jumplist
    keepjumps buffer #
    enew
    execute "file! .__Mazda__." . s:mazda_buf_id
    execute "set filetype=" . a:filetype
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal buflisted
    autocmd BufWritePre <buffer> call s:NoZoomZoom(1, g:mazda_zoom_out_on_write)
    autocmd BufWritePost <buffer> silent call delete(getcwd() . bufname("%"))
    let b:mazda_origin = origin
endfunction


function! s:NoZoomZoom(writeback, zoom_out)
    let zoom_buf = bufname("%")
    let zoom_text = getline(1, "$")
    let origin = b:mazda_origin
    " preserve alternate buffer and jumplist
    keepjumps buffer #
    execute "buffer " . origin
    if a:writeback
        call s:WriteZoomText(zoom_text)
    endif
    if a:zoom_out
        execute "bdelete! " . zoom_buf
    else
        execute "keepjumps buffer " . zoom_buf
    endif
endfunction


function! s:WriteZoomText(zoom_text)
    call cursor(b:mazda_start, 1)
    execute "normal! V" . b:mazda_end . "G\"_d"
    call append(b:mazda_start-1, a:zoom_text)
    write!
endfunction


function! s:ZoomToggle(mode)
    if bufname("%") =~# "__Mazda__"
        call s:NoZoomZoom(1, 1)
    else
        if a:mode = "n"
            set opfunc="s:ZoomZoom"
            normal! g@
        else
            call s:ZoomZoom("v")
        endif
    endif
endfunction


function! s:ReselectLastRegion()
    if s:last_region_start && s:last_region_end
        let zoom_text = getline(s:last_region_start, s:last_region_end)
        let b:mazda_start = s:last_region_start
        let b:mazda_end = s:last_region_end
        call s:OpenZoomBuffer(&filetype)
        call setline(1, zoom_text)
    endif
endfunction

nnoremap <Plug>MazdaZoomIn :set opfunc=<SID>ZoomZoom<CR>g@
vnoremap <Plug>MazdaZoomIn :<C-U>call <SID>ZoomZoom("v")<CR>

nnoremap <Plug>MazdaToggle :<C-U>call <SID>ZoomToggle("n")<CR>
vnoremap <Plug>MazdaToggle :<C-U>call <SID>ZoomToggle("v")<CR>

nnoremap <Plug>MazdaZoomOut :<C-U>call <SID>NoZoomZoom(1, 1)<CR>
nnoremap <Plug>MazdaDiscard :<C-U>call <SID>NoZoomZoom(0, 1)<CR>
nnoremap <Plug>MazdaReselect :<C-U>call <SID>ReselectLastRegion()<CR>


if g:mazda_default_mappings
    nmap gz <Plug>MazdaToggle
    vmap gz <Plug>MazdaToggle
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
