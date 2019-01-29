let s:save_cpo = &cpo
set cpo&vim


"
" listener: channel
"


let s:listener = ncv#service#niconico_live#listener_prototype#new()


function! ncv#service#niconico_live#listener_channel#new() abort
  return deepcopy(s:listener)
endfunction


"
"
"


function! s:channel_available() abort dict
  let ok = has('channel') && exists('*ch_readblob')
  let msg = ok ? '' : 'ncv: require Vim enabled blob support'
  return [ok, msg]
endfunction
let s:listener.available = function('s:channel_available')


function! s:channel_do() abort dict
  let self.ch = ch_open(printf('%s:%s', self.addr, self.port), {
        \ 'mode' : 'raw',
        \ 'callback' : function(self.callback, [self.bufname]),
        \ 'waittime' : -1,
        \})
  if ch_status(self.ch) !=# 'open'
    throw 'ncv: failed channel open'
  endif
  call ch_sendraw(self.ch, self.thread_tag())
endfunction
let s:listener.do = function('s:channel_do')


function! s:channel_thread_tag() abort dict
  let blob = eval('0z')
  let template = '<thread thread="%s" version="20061206" res_from="-1000"/>'
  let thread_tag = printf(template, self.thread)
  call map(split(thread_tag, '\zs'), {_, c -> add(blob, char2nr(c))})
  return blob + eval('0z00')
endfunction
let s:listener.thread_tag = function('s:channel_thread_tag')


function! s:channel_callback(bufname, ch, msg) abort dict
  for chat in split(a:msg, '</chat>\zs')
    let line = ncv#service#niconico_live#niconico#new().chat.format(chat)
    if !empty(line) && bufexists(a:bufname)
      call ncv#util#appendbufline(a:bufname, '$', [line])
    endif
  endfor
endfunction
let s:listener.callback = function('s:channel_callback')


function! s:channel_stop() abort dict
  if has_key(self, 'ch') && ch_status(self.ch) =~# 'open\|buffered'
    call ch_close(self.ch)
    call remove(self, 'ch')
  endif
endfunction
let s:listener.stop = function('s:channel_stop')


let &cpo = s:save_cpo
unlet s:save_cpo
