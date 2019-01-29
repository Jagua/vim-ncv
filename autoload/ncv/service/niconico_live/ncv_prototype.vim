let s:save_cpo = &cpo
set cpo&vim


"
" ncv prototype
"


let s:ncv_prototype = {}


function! ncv#service#niconico_live#ncv_prototype#new() abort
  return deepcopy(s:ncv_prototype)
endfunction


"
"
"


function! s:listener(listener_name) abort dict
  let self.listener_name = a:listener_name
  return self
endfunction
let s:ncv_prototype.listener = function('s:listener')


function! s:watch(url) abort dict
  try
    call self._set_lv_id(a:url)
    call self._set_cookie()
    call self._set_getplayerstatus()
    call self._set_listener()
  catch /^ncv:/
    echo v:exception
    return
  endtry

  return self.view()
endfunction
let s:ncv_prototype.watch = function('s:watch')


function! s:_set_lv_id(url) abort dict
  let lv_id = matchstr(a:url, 'lv\d\+')
  if empty(lv_id)
    throw printf('ncv: not live URL: %s', a:url)
  endif
  let self.lv_id = lv_id
endfunction
let s:ncv_prototype._set_lv_id = function('s:_set_lv_id')


function! s:_set_cookie() abort dict
  let cookie = ncv#service#niconico_live#niconico#new().api.login()
  if empty(cookie)
    throw 'ncv: login failed'
  endif
  let self.cookie = cookie
endfunction
let s:ncv_prototype._set_cookie = function('s:_set_cookie')


function! s:_set_getplayerstatus() abort dict
  let getplayerstatus = ncv#service#niconico_live#niconico#new().api.getplayerstatus(self.lv_id, self.cookie)
  if empty(getplayerstatus)
    throw 'ncv: getplayerstatus failed'
  elseif get(getplayerstatus, 'name', '') ==# 'getplayerstatus'
        \ && getplayerstatus.attr.status ==# 'fail'
    throw printf('ncv: getplayerstatus error code: %s',
          \ getplayerstatus.childNode('error').childNode('code').value())
  endif
  let self.getplayerstatus = getplayerstatus
endfunction
let s:ncv_prototype._set_getplayerstatus = function('s:_set_getplayerstatus')


function! s:_set_listener() abort dict
  if has_key(self, 'listener_name')
    return
  endif
  if has('channel') && exists('*ch_readblob')
    let self.listener_name = 'channel'
  elseif executable('netcat')
    let self.listener_name = 'netcat'
  else
    throw 'ncv: channel can not deal with blob or netcat is not found'
  endif
endfunction
let s:ncv_prototype._set_listener = function('s:_set_listener')


function! s:view() abort dict
  let b:ncv_listener = self.listener_name
  call ncv#viewer#create_view_buffer(self._information_list())
  let viewer = ncv#service#niconico_live#listener_{self.listener_name}#new().new(self.getplayerstatus)
  try
    call viewer.do()
  catch /^ncv:/
    echo v:exception
    return
  endtry
  let b:ncv_stop = {-> viewer.stop()}
  let b:ncv_close_windows = {-> viewer.close_windows()}
  return self
endfunction
let s:ncv_prototype.view = function('s:view')


function! s:_information_list() abort dict
  let stream = self.getplayerstatus.childNode('stream')
  let owner_name = stream.childNode('owner_name').value()
  let title = stream.childNode('title').value()
  let description = stream.childNode('description').value()
  let start_time = stream.childNode('start_time').value()
  if has('unix') && executable('date')
    let start_time = trim(system(
          \ printf('date -d @%s %s', start_time, shellescape('+%Y/%m/%d %H:%M:%S'))))
  endif
  let information_list = [
        \ ['      OWNER: ', owner_name],
        \ ['      START: ', start_time],
        \ ['      TITLE: ', title],
        \ ['DESCRIPTION: ', description],
        \ ['   listener: ', b:ncv_listener],
        \]
  return information_list
endfunction
let s:ncv_prototype._information_list = function('s:_information_list')


"
" echo utility
"


let s:ncv_prototype.echo = {}


function! s:util_cookie() abort dict
  call self._set_cookie()
  echo self.cookie
endfunction
let s:ncv_prototype.echo.cookie = function('s:util_cookie', [], s:ncv_prototype)


function! s:util_info(url) abort dict
  try
    call self._set_lv_id(a:url)
    call self._set_cookie()
    call self._set_getplayerstatus()
  catch /^ncv:/
    echomsg v:exception
    return
  endtry

  let status = self.getplayerstatus.attr.status
  let stream = self.getplayerstatus.childNode('stream')
  let owner_name = stream.childNode('owner_name').value()
  let title = stream.childNode('title').value()
  let start_time = stream.childNode('start_time').value()
  let ms = self.getplayerstatus.childNode('ms')
  let addr = ms.childNode('addr').value()
  let port = ms.childNode('port').value()
  let thread = ms.childNode('thread').value()
  if has('unix') && executable('date')
    let start_time = trim(system(
          \ printf('date -d @%s %s', start_time, shellescape('+%Y/%m/%d %H:%M:%S'))))
  endif
  let info = [
        \ printf('STATUS: %s', status),
        \ printf('LV_ID: %s', self.lv_id),
        \ printf('OWNER_NAME: %s', owner_name),
        \ printf('START: %s', start_time),
        \ printf('TITLE: %s', title),
        \ printf('ADDR: %s, PORT: %s, THREAD: %s', addr, port, thread),
        \]
  echo join(info, "\n")
endfunction
let s:ncv_prototype.echo.info = function('s:util_info', [], s:ncv_prototype)


function! s:util_comment(url) abort dict
  if !executable('netcat')
    throw 'ncv: require netcat'
  endif
  try
    call self._set_lv_id(a:url)
    call self._set_cookie()
    call self._set_getplayerstatus()
  catch /^ncv:/
    echomsg v:exception
    return
  endtry

  let ms = self.getplayerstatus.childNode('ms')
  let addr = ms.childNode('addr').value()
  let port = ms.childNode('port').value()
  let thread = ms.childNode('thread').value()

  let tempfile = tempname()
  let template = '<thread thread="%s" version="20061206" res_from="-50"/>%s'
  let thread_tag = printf(template, thread, "\n")
  call writefile([thread_tag], tempfile, 'b')
  let cmdln = printf('netcat -q 0 %s %s < %s', addr, port, tempfile)

  echo system(cmdln)
endfunction
let s:ncv_prototype.echo.comment = function('s:util_comment', [], s:ncv_prototype)


let &cpo = s:save_cpo
unlet s:save_cpo
