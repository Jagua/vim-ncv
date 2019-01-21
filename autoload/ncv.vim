let s:save_cpo = &cpo
set cpo&vim


"
" api
"


function! ncv#watch(url) abort
  return ncv#new().watch(a:url)
endfunction


function! ncv#new() abort
  return deepcopy(s:ncv_prototype)
endfunction


"
" ncv prototype
"


let s:ncv_prototype = {}
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
  let cookie = s:niconico.api.login()
  if empty(cookie)
    throw 'ncv: login failed'
  endif
  let self.cookie = cookie
endfunction
let s:ncv_prototype._set_cookie = function('s:_set_cookie')


function! s:_set_getplayerstatus() abort dict
  let getplayerstatus = s:niconico.api.getplayerstatus(self.lv_id, self.cookie)
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
  call s:create_view_buffer(self.getplayerstatus)
  let viewer = get(s:listener, self.listener_name).new(self.getplayerstatus)
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
  let owner_name = self.getplayerstatus.childNode('stream').childNode('owner_name').value()
  let title = self.getplayerstatus.childNode('stream').childNode('title').value()
  let start_time = self.getplayerstatus.childNode('stream').childNode('start_time').value()
  let ms = self.getplayerstatus.childNode('ms')
  let addr = ms.childNode('addr').value()
  let port = ms.childNode('port').value()
  let thread = ms.childNode('thread').value()
  if executable('date') && has('unix')
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
  let template = '<thread thread="%s" version="20061206" res_from="-10"/>%s'
  let thread_tag = printf(template, thread, "\n")
  call writefile([thread_tag], tempfile, 'b')
  let cmdln = printf('netcat -q 0 %s %s < %s', addr, port, tempfile)

  echo system(cmdln)
endfunction
let s:ncv_prototype.echo.comment = function('s:util_comment', [], s:ncv_prototype)


"
" viewer
"


function! s:create_view_buffer(getplayerstatus) abort
  call s:create_info_view_buffer(a:getplayerstatus)
  call s:create_comment_view_buffer()
endfunction


function! s:create_info_view_buffer(getplayerstatus) abort
  let stream = a:getplayerstatus.childNode('stream')
  let owner_name = stream.childNode('owner_name').value()
  let title = stream.childNode('title').value()
  let description = stream.childNode('description').value()
  let start_time = stream.childNode('start_time').value()
  if executable('date') && has('unix')
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
  let information = map(copy(information_list), 'v:val[0] . v:val[1]')
  tabnew
  let s:info_bufname = '___NCV_INFO___'
  execute printf('topleft split +resize\ %d %s', s:strdisplayheight(information), s:info_bufname)
  setlocal breakindent buftype=nofile nobuflisted modifiable noswapfile wrap nonumber
  call execute('put = information')
  1 delete _
  redraw
  setlocal nomodifiable nomodified
  let indent = strlen(information_list[0][0])
  call s:breakindentopt(indent)

  wincmd p
endfunction


function! s:create_comment_view_buffer() abort
  let s:comment_bufname = '___NCV_COMMENT___'
  execute 'edit' s:comment_bufname
  setlocal breakindent buftype=nofile nobuflisted modifiable noswapfile wrap nonumber

  setfiletype ncv
  setlocal nomodified
endfunction


function! s:breakindentopt(indent) abort
  if !has('linebreak')
    return
  endif
  execute printf('setlocal breakindentopt=%s', ncv#breakindentopt_value(a:indent))
endfunction


function! ncv#breakindentopt_value(indent) abort
  if !has('linebreak')
    return
  endif
  let number = &number ? max([&numberwidth, float2nr(floor(log10(line('$')))) + 2]) : 0
  let shift = number + a:indent
  return printf('min:%d,shift:%d', winwidth(0) - shift, shift)
endfunction


function! s:strdisplayheight(lines) abort
  let i = 0
  let winwidth = winwidth(0) - &foldcolumn - (&number ? &numberwidth : 0)
  for line in a:lines
    let i += empty(line) ? 1 : float2nr(ceil(round(strdisplaywidth(line)) / round(winwidth)))
  endfor
  return i
endfunction


"
" listener
"


let s:listener = {}


"
" listener : prototype
"


let s:listener.prototype = {}


function! s:listener_new(getplayerstatus) abort dict
  let [ok, msg] = self.available()
  if !ok
    throw printf('ncv: %s', msg)
  endif
  let self.getplayerstatus = a:getplayerstatus
  let self.bufname = s:comment_bufname
  call self.parse_getplayerstatus()
  return self
endfunction
let s:listener.prototype.new = function('s:listener_new')


function! s:listener_parse_getplayerstatus() abort dict
  let ms = self.getplayerstatus.childNode('ms')
  let self.addr = ms.childNode('addr').value()
  let self.port = ms.childNode('port').value()
  let self.thread = ms.childNode('thread').value()
endfunction
let s:listener.prototype.parse_getplayerstatus = function('s:listener_parse_getplayerstatus')


function! s:listener_close_windows() abort
  if tabpagenr('$') == 1
    new
  endif
  for bufname in [s:info_bufname, s:comment_bufname]
    let winnr = bufwinnr(bufname)
    if winnr == -1
      continue
    endif
    execute winnr 'wincmd w'
    setlocal nomodified
    close
  endfor
endfunction
let s:listener.prototype.close_windows = function('s:listener_close_windows')


"
" listener: channel
"


let s:listener.channel = deepcopy(s:listener.prototype)


function! s:channel_available() abort dict
  let ok = has('channel') && exists('*ch_readblob')
  let msg = ok ? '' : 'ncv: require Vim enabled blob support'
  return [ok, msg]
endfunction
let s:listener.channel.available = function('s:channel_available')


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
let s:listener.channel.do = function('s:channel_do')


function! s:channel_thread_tag() abort dict
  let blob = eval('0z')
  let template = '<thread thread="%s" version="20061206" res_from="-1000"/>'
  let thread_tag = printf(template, self.thread)
  call map(split(thread_tag, '\zs'), {_, c -> add(blob, char2nr(c))})
  return blob + eval('0z00')
endfunction
let s:listener.channel.thread_tag = function('s:channel_thread_tag')


function! s:channel_callback(bufname, ch, msg) abort dict
  for chat in split(a:msg, '</chat>\zs')
    let line = s:niconico.chat.format(chat)
    if !empty(line) && bufexists(a:bufname)
      call appendbufline(a:bufname, '$', [line])
    endif
  endfor
endfunction
let s:listener.channel.callback = function('s:channel_callback')


function! s:channel_stop() abort dict
  if has_key(self, 'ch') && ch_status(self.ch) =~# 'open\|buffered'
    call ch_close(self.ch)
    call remove(self, 'ch')
  endif
endfunction
let s:listener.channel.stop = function('s:channel_stop')


"
" listener: netcat
"


let s:listener.netcat = deepcopy(s:listener.prototype)


function! s:netcat_available() abort dict
  let ok = has('job') && executable('netcat')
  let msg = ok ? '' : 'ncv: not found netcat'
  return [ok, msg]
endfunction
let s:listener.netcat.available = function('s:netcat_available')


function! s:netcat_do() abort dict
  let tempfile = tempname()
  call writefile([self.thread_tag()], tempfile, 'b')
  let cmdln = printf('netcat -q -1 %s %s < %s', self.addr, self.port, tempfile)
  let self.job = job_start([&shell, &shellcmdflag, cmdln], {
        \ 'callback' : function(self.callback, [self.bufname]),
        \ 'mode' : 'raw',
        \})
endfunction
let s:listener.netcat.do = function('s:netcat_do')


function! s:netcat_thread_tag() abort dict
  let template = '<thread thread="%s" version="20061206" res_from="-1000"/>%s'
  return printf(template, self.thread, "\n")
endfunction
let s:listener.netcat.thread_tag = function('s:netcat_thread_tag')


function! s:netcat_callback(bufname, ch, msg) abort dict
  for chat in split(a:msg, '</chat>\zs')
    let line = s:niconico.chat.format(chat)
    if !empty(line) && bufexists(a:bufname)
      call appendbufline(a:bufname, '$', [line])
    endif
  endfor
endfunction
let s:listener.netcat.callback = function('s:netcat_callback')


function! s:netcat_stop() abort dict
  if has_key(self, 'job') && job_status(self.job) ==# 'run'
    call job_stop(self.job)
    call remove(self, 'job')
  endif
endfunction
let s:listener.netcat.stop = function('s:netcat_stop')


"
" niconico
"


let s:niconico = {}


"
" niconico api
"


let s:niconico.api = {}


function! s:login() abort
  let mail = get(g:, 'ncv_mail', '')
  let password = get(g:, 'ncv_password', '')
  if empty(mail) || empty(password)
    throw 'ncv: require g:ncv_mail and g:ncv_password settings'
  endif

  let url = 'https://secure.nicovideo.jp/secure/login'
  let _data = {
        \ 'site' : 'niconico',
        \ 'mail' : mail,
        \ 'password' : password,
        \}
  let res = webapi#http#post(url, _data, {}, 'POST', 0)

  if res.status !=# '302'
    throw 'ncv: login failed'
  endif
  let user_session = get(filter(copy(res.header),
        \ {_, val -> val =~# '^Set-Cookie: user_session=user_session'}), 0, '')
  let user_session = matchstr(user_session, '^Set-Cookie: \zsuser_session=[^;]\+')
  if empty(user_session)
    throw 'ncv: failed to get cookie'
  endif
  return {
        \ 'user_session' : user_session,
        \}
endfunction
let s:niconico.api.login = function('s:login')


function! s:getplayerstatus(lv_id, cookie) abort
  let cookie = {
        \ 'Cookie' : printf('%s', a:cookie.user_session),
        \}
  let url = printf('http://watch.live.nicovideo.jp/api/getplayerstatus?v=%s', a:lv_id)
  let res = webapi#http#get(url, '', cookie)
  if res.status !=# '200'
    throw 'ncv: getplayerstatus failed'
  endif
  return webapi#xml#parse(res.content)
endfunction
let s:niconico.api.getplayerstatus = function('s:getplayerstatus')


"
" niconico chat formatter
"


let s:niconico.chat = {}


function! s:chat_format(chat) abort dict
  let c = self.parse_chat(a:chat)
  if empty(c)
    return
  endif

  let vpos = self.vpos_to_time(c.vpos)
  let user_id = printf('%-10s', c.user_id)[:9]
  let text = c.text
  return printf('%s : %s : %s', vpos, user_id, text)
endfunction
let s:niconico.chat.format = function('s:chat_format')


function! s:parse_chat(chatstr) abort dict
  let vpos = matchstr(a:chatstr, 'vpos="\zs\d\+\ze"')
  if empty(vpos)
    return {}
  endif
  let user_id = matchstr(a:chatstr, 'user_id="\zs.\{-}\ze"')
  let text = matchstr(a:chatstr, '<chat.*>\zs\_.\{-}\ze</chat>')
  return {
        \ 'vpos' : vpos,
        \ 'user_id' : user_id,
        \ 'text' : text,
        \}
endfunction
let s:niconico.chat.parse_chat = function('s:parse_chat')


function! s:vpos_to_time(vpos) abort dict
  let h = float2nr(floor(a:vpos / (60 * 60 * 100)))
  let m = float2nr(floor((a:vpos / 6000) % 60))
  let s = float2nr(floor((a:vpos / 100) % 60))
  return printf('%02d:%02d:%02d', h, m, s)
endfunction
let s:niconico.chat.vpos_to_time = function('s:vpos_to_time')


let &cpo = s:save_cpo
unlet s:save_cpo
