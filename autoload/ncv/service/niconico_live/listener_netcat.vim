let s:save_cpo = &cpo
set cpo&vim


"
" listener: netcat
"


let s:listener = ncv#service#niconico_live#listener_prototype#new()


function! ncv#service#niconico_live#listener_netcat#new() abort
  return deepcopy(s:listener)
endfunction


"
"
"


function! s:netcat_available() abort dict
  let ok = has('job') && executable('netcat')
  let msg = ok ? '' : 'ncv: not found netcat'
  return [ok, msg]
endfunction
let s:listener.available = function('s:netcat_available')


function! s:netcat_do() abort dict
  let tempfile = tempname()
  call writefile([self.thread_tag()], tempfile, 'b')
  let cmdln = printf('netcat -q -1 %s %s < %s', self.addr, self.port, tempfile)
  let self.job = job_start([&shell, &shellcmdflag, cmdln], {
        \ 'callback' : function(self.callback, [self.bufname]),
        \ 'mode' : 'raw',
        \})
endfunction
let s:listener.do = function('s:netcat_do')


function! s:netcat_thread_tag() abort dict
  let template = '<thread thread="%s" version="20061206" res_from="-1000"/>%s'
  return printf(template, self.thread, "\n")
endfunction
let s:listener.thread_tag = function('s:netcat_thread_tag')


function! s:netcat_callback(bufname, ch, msg) abort dict
  for chat in split(a:msg, '</chat>\zs')
    let line = ncv#service#niconico_live#niconico#new().chat.format(chat)
    if !empty(line) && bufexists(a:bufname)
      call ncv#util#appendbufline(a:bufname, '$', [line])
    endif
  endfor
endfunction
let s:listener.callback = function('s:netcat_callback')


function! s:netcat_stop() abort dict
  if has_key(self, 'job') && job_status(self.job) ==# 'run'
    call job_stop(self.job)
    call remove(self, 'job')
  endif
endfunction
let s:listener.stop = function('s:netcat_stop')


if has('nvim')
  function! s:netcat_available() abort dict
    let ok = exists('*jobstart')
    let msg = ok ? '' : 'ncv: not found netcat'
    return [ok, msg]
  endfunction
  let s:listener.available = function('s:netcat_available')


  function! s:netcat_do() abort dict
    let tempfile = tempname()
    call writefile([self.thread_tag()], tempfile, 'b')
    let cmdln = printf('netcat -q -1 %s %s < %s', self.addr, self.port, tempfile)
    let self.job = jobstart([&shell, &shellcmdflag, cmdln], {
          \ 'on_stdout' : function(self.on_stdout, [self.bufname]),
          \})
  endfunction
  let s:listener.do = function('s:netcat_do')


  function! s:netcat_stop() abort dict
    if has_key(self, 'job')
      call jobstop(self.job)
      call remove(self, 'job')
    endif
  endfunction
  let s:listener.stop = function('s:netcat_stop')


  function! s:on_stdout(bufname, job_id, data, event) abort dict
    execute bufwinnr(a:bufname) 'wincmd w'
    let msg = join(a:data)
    for chat in split(msg, '</chat>\zs')
      let line = ncv#service#niconico_live#niconico#new().chat.format(chat)
      if !empty(line) && bufname('%') ==# a:bufname
        call setline('$', [line, ''])
      endif
    endfor
  endfunction
  let s:listener.on_stdout = function('s:on_stdout')
endif


let &cpo = s:save_cpo
unlet s:save_cpo
