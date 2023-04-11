if exists('g:loaded_file_line') | finish | endif
let g:loaded_file_line = 1

let g:file_line_crosshairs = get(g:, 'file_line_crosshairs', 1)
let g:file_line_crosshairs_number = get(g:, 'file_line_crosshairs_number', 2)
let g:file_line_crosshairs_duration = get(g:, 'file_line_crosshairs_duration', 200)
let g:file_line_fallback_column0 = get(g:, 'file_line_fallback_column0', 1)

augroup file_line
  autocmd!
  autocmd! BufNewFile * nested call s:goto_file_line()
  autocmd! BufRead    * nested call s:goto_file_line()
augroup END

function! s:goto_file_line(...)
  let file_line_col = a:0 > 0 ? a:1 : bufname('%')
  if filereadable(file_line_col) || file_line_col ==# ''
    return file_line_col
  endif

  " Regex to match variants like these:
  " * file(10)
  " * file(line:col)
  " * file:line:column:
  " * file:line:column
  " * file:line
  let matches =  matchlist(file_line_col,
        \ '\(.\{-1,}\)[(:]\(\d\+\)\%(:\(\d\+\):\?\)\?')
  if empty(matches) | return file_line_col | endif

  let fname = matches[1]
  let line = !empty(matches[2]) ? matches[2] : '0'
  let col = !empty(matches[3])
        \ ? matches[3] . '|'
        \ : (g:file_line_fallback_column0 ? '|' : '^')

  if filereadable(fname)
    let bufnr = bufnr('%')
    execute 'keepalt edit' fnameescape(fname)
    execute 'bdelete' bufnr

    execute line
    execute 'normal!' col
    normal! m"
    normal! zv
    normal! zz
    filetype detect
    if g:file_line_crosshairs
      call s:crosshair_flash(g:file_line_crosshairs_number, g:file_line_crosshairs_duration)
    endif
  endif

  return fname
endfunction


" Flash crosshairs (reticle) on current cursor line/column to highlight it.
" Particularly useful when the cursor is at head/tail end of file,
" in which case it will not get centered.
" Ref1: https://vi.stackexchange.com/a/3481/29697
" Ref2: https://stackoverflow.com/a/33775128/38281
function! s:crosshair_flash(n, d) abort
  let l:cul = &cursorline
  let l:cuc = &cursorcolumn

  for i in range(1, a:n)
    set cursorline cursorcolumn
    redraw
    execute 'sleep' a:d . 'm'
    set nocursorline nocursorcolumn
    redraw
    execute 'sleep' a:d . 'm'
  endfor

  let &cursorline = l:cul
  let &cursorcolumn = l:cuc
endfunction
