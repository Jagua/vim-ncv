let s:save_cpo = &cpo
set cpo&vim


let s:service = {}


function! ncv#service#new() abort
  return deepcopy(s:service)
endfunction


function! s:service_service(service_name) abort
  return s:get_service(a:service_name).do()
endfunction
let s:service.service = function('s:service_service')


function! s:service_watch(url) abort
  let service = s:find_service(a:url)
  if empty(service)
    throw 'ncv: not found service'
  endif
  return service.do().watch(a:url)
endfunction
let s:service.watch = function('s:service_watch')


"
"
"


let s:service_prototype = {}


function! ncv#service#prototype() abort
  return deepcopy(s:service_prototype)
endfunction


function! s:service_prototype_available() abort
  throw 'ncv: not implemented available() function'
endfunction
let s:service_prototype.available = function('s:service_prototype_available')


function! s:service_prototype_do() abort
  throw 'ncv: not implemented do() function'
endfunction
let s:service_prototype.do = function('s:service_prototype_do')


"
"
"


let s:services = {}
lockvar s:services


function! s:find_service(url) abort
  let s = {}
  for service in values(s:services)
    if service.available(a:url)
      let s = service
      break
    endif
  endfor
  return deepcopy(s)
endfunction


function! s:get_service(service_name) abort
  if !has_key(s:services, a:service_name)
    throw printf('ncv: invalid service name: %s', a:service_name)
  endif
  return deepcopy(s:services[a:service_name])
endfunction


function! ncv#service#define(service_source) abort
  unlockvar s:services
  let s:services[a:service_source.name] = deepcopy(a:service_source)
  lockvar s:services
endfunction


function! s:service_in_rtp() abort
  let service_list = []
  let service_path_list = globpath(&runtimepath, 'autoload/ncv/service/*/watch.vim', 1, 1)
  let service_name_list = map(service_path_list, 'fnamemodify(v:val, ":h:t")')
  for service_name in service_name_list
    try
      let service = ncv#service#{service_name}#watch#new()
    catch /.*/
      echo v:exception v:throwpoint
      let service = ''
    endtry
    if empty(service)
      continue
    endif
    call add(service_list, extend(service, {'name' : service_name}))
  endfor
  return service_list
endfunction


function! s:define_service_in_rtp() abort
  return map(copy(s:service_in_rtp()), 'ncv#service#define(v:val)')
endfunction


call s:define_service_in_rtp()


let &cpo = s:save_cpo
unlet s:save_cpo
