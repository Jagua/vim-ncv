let s:save_cpo = &cpo
set cpo&vim


let s:service = deepcopy(ncv#service#prototype())


function! ncv#service#niconico_live#watch#new() abort
  return deepcopy(s:service)
endfunction


"
"
"


function! s:available(url) abort
  return match(a:url, 'lv\d\+') >= 0
endfunction
let s:service.available = function('s:available')


function! s:do() abort
  return deepcopy(ncv#service#niconico_live#ncv_prototype#new())
endfunction
let s:service.do = function('s:do')


let &cpo = s:save_cpo
unlet s:save_cpo
