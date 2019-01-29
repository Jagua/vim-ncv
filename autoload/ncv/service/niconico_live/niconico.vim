let s:save_cpo = &cpo
set cpo&vim


"
" niconico
"


let s:niconico = {}


function! ncv#service#niconico_live#niconico#new() abort
  return deepcopy(s:niconico)
endfunction


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
  let m = float2nr(floor((a:vpos / (60 * 100)) % 60))
  let s = float2nr(floor((a:vpos / 100) % 60))
  return printf('%02d:%02d:%02d', h, m, s)
endfunction
let s:niconico.chat.vpos_to_time = function('s:vpos_to_time')


let &cpo = s:save_cpo
unlet s:save_cpo
