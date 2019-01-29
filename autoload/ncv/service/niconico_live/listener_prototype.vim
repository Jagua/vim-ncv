let s:save_cpo = &cpo
set cpo&vim


"
" listener : prototype
"


let s:listener_prototype = {}


function! ncv#service#niconico_live#listener_prototype#new() abort
  return deepcopy(s:listener_prototype)
endfunction


"
"
"


function! s:listener_prototype_new(getplayerstatus) abort dict
  let [ok, msg] = self.available()
  if !ok
    throw printf('ncv: %s', msg)
  endif
  let self.getplayerstatus = a:getplayerstatus
  let self.bufname = g:ncv_comment_bufname
  call self.parse_getplayerstatus()
  return self
endfunction
let s:listener_prototype.new = function('s:listener_prototype_new')


function! s:listener_prototype_parse_getplayerstatus() abort dict
  let ms = self.getplayerstatus.childNode('ms')
  let self.addr = ms.childNode('addr').value()
  let self.port = ms.childNode('port').value()
  let self.thread = ms.childNode('thread').value()
endfunction
let s:listener_prototype.parse_getplayerstatus = function('s:listener_prototype_parse_getplayerstatus')


function! s:listener_prototype_close_windows() abort
  if tabpagenr('$') == 1
    new
  endif
  for bufname in [g:ncv_info_bufname, g:ncv_comment_bufname]
    let winnr = bufwinnr(bufname)
    if winnr == -1
      continue
    endif
    execute winnr 'wincmd w'
    setlocal nomodified
    close
  endfor
endfunction
let s:listener_prototype.close_windows = function('s:listener_prototype_close_windows')


let &cpo = s:save_cpo
unlet s:save_cpo
