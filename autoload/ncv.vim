let s:save_cpo = &cpo
set cpo&vim


"
" api
"


function! ncv#watch(url) abort
  return ncv#new().watch(a:url)
endfunction


function! ncv#new() abort
  return deepcopy(ncv#service#niconico_live#ncv_prototype#new())
endfunction


let g:ncv_info_bufname = '___NCV_INFO___'
let g:ncv_comment_bufname = '___NCV_COMMENT___'


let &cpo = s:save_cpo
unlet s:save_cpo
