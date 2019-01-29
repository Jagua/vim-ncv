let s:save_cpo = &cpo
set cpo&vim


let s:bufname = bufname('%')


function! s:in_comment_buf() abort
  return bufname('%') ==# s:bufname
endfunction


function! s:ncv_stop() abort
  call s:scroll_off()
  call s:stop_timer_reload()
  call b:ncv_stop()
  call b:ncv_close_windows()
endfunction


function! s:on_BufWinLeave(buf) abort
  " Note:
  " On |BufWinLeave|, can not get buffer local variables like "b:variable_name".
  " For example, ":echo b:ncv_stop" is failed.
  " But can get the variable by |getbufvar| or |get|.
  let timer_id = getbufvar(str2nr(a:buf), 'ncv_timer')
  if !empty(timer_id)
    call timer_stop(timer_id)
    echomsg 'timer stop'
  endif
  " let l:Func = getbufvar(a:buf, 'ncv_stop')
  " if !empty(l:Func)
  "   call l:Func()
  "   echomsg 'ncv stop'
  " endif
  call get(b:, 'ncv_stop', 'func')
endfunction


function! s:auto_scroll() abort
  if !s:in_comment_buf()
    return
  endif
  if get(b:, 'ncv_auto_scroll_enable', 1)
    normal! G
    redraw!
  endif
endfunction


function! s:scroll_on() abort
  let b:ncv_auto_scroll_enable = 1
  call s:auto_scroll()
  redraw!
  echo 'scroll on'
endfunction


function! s:scroll_off() abort
  let b:ncv_auto_scroll_enable = 0
  redraw!
  echo 'scroll off'
endfunction


function! s:start_timer_reload() abort
  if get(b:, 'ncv_auto_scroll_enable', 1)
    let b:ncv_timer = timer_start(1000,
          \ {timer -> s:auto_scroll()}, {'repeat': -1})
  endif
endfunction


function! s:stop_timer_reload() abort
  if exists('b:ncv_timer')
    call timer_stop(b:ncv_timer)
    unlet b:ncv_timer
  endif
endfunction


function! s:update_breakindentopt(buf) abort
  let indent = strlen('00:00:00 : 0123456789 : ')
  call setbufvar(a:buf, '&breakindentopt', ncv#util#breakindentopt_value(indent))
endfunction


call s:update_breakindentopt(s:bufname)
let b:ncv_auto_scroll_enable = 1


nnoremap <silent><buffer> <Plug>(ncv-stop) :<C-u>call <SID>ncv_stop()<CR>
nnoremap <silent><buffer> <Plug>(ncv-scroll-on) :<C-u>call <SID>scroll_on()<CR>
nnoremap <silent><buffer> <Plug>(ncv-scroll-off) :<C-u>call <SID>scroll_off()<CR>


if !exists('g:no_plugin_maps') && !exists('g:no_ncv_maps') && !exists('b:no_ncv_maps')
  nmap <buffer> q <Plug>(ncv-stop)
  nmap <buffer> <LocalLeader>s <Plug>(ncv-scroll-off)
  nmap <buffer> <LocalLeader>S <Plug>(ncv-scroll-on)
endif


augroup ft-ncv-events
  autocmd!
  autocmd VimResized <buffer=abuf> call s:update_breakindentopt(str2nr(expand('<abuf>')))
  autocmd TextChanged,CursorHold <buffer> call s:auto_scroll()
  autocmd FocusLost,WinLeave <buffer> call s:start_timer_reload()
  autocmd FocusGained,WinEnter <buffer> call s:stop_timer_reload()
  autocmd BufWinLeave <buffer=abuf> call s:on_BufWinLeave(str2nr(expand('<abuf>')))
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
