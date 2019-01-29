let s:save_cpo = &cpo
set cpo&vim


function! ncv#util#breakindentopt(indent) abort
  if !has('linebreak')
    return
  endif
  execute printf('setlocal breakindentopt=%s', ncv#util#breakindentopt_value(a:indent))
endfunction


function! ncv#util#breakindentopt_value(indent) abort
  if !has('linebreak')
    return
  endif
  let number = &number ? max([&numberwidth, float2nr(floor(log10(line('$')))) + 2]) : 0
  let shift = number + a:indent
  return printf('min:%d,shift:%d', winwidth(0) - shift, shift)
endfunction


function! ncv#util#strdisplayheight(lines) abort
  let i = 0
  let winwidth = winwidth(0) - &foldcolumn - (&number ? &numberwidth : 0)
  for line in a:lines
    let i += empty(line) ? 1 : float2nr(ceil(round(strdisplaywidth(line)) / round(winwidth)))
  endfor
  return i
endfunction


if exists('*appendbufline')
  function! ncv#util#appendbufline(expr, lnum, text_list) abort
    return appendbufline(a:expr, a:lnum, a:text_list)
  endfunction
else
  function! ncv#util#appendbufline(expr, lnum, text_list) abort
    return setbufline(a:expr, a:lnum, a:text_list + [''])
  endfunction
endif


let &cpo = s:save_cpo
unlet s:save_cpo
