if exists('g:loaded_ncv')
  finish
endif
let g:loaded_ncv = 1


let s:save_cpo = &cpo
set cpo&vim


command! -nargs=1 Ncv call ncv#watch(<q-args>)


let &cpo = s:save_cpo
unlet s:save_cpo
