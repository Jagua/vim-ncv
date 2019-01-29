let s:save_cpo = &cpo
set cpo&vim


"
" viewer
"


function! ncv#viewer#create_view_buffer(information_list) abort
  call s:create_info_view_buffer(a:information_list)
  call s:create_comment_view_buffer()
endfunction


function! s:create_info_view_buffer(information_list) abort
  let information = map(copy(a:information_list), 'v:val[0] . v:val[1]')
  tabnew
  execute printf('topleft split +resize\ %d %s', ncv#util#strdisplayheight(information), g:ncv_info_bufname)
  setlocal breakindent buftype=nofile nobuflisted modifiable noswapfile wrap nonumber
  call execute('put = information')
  1 delete _
  redraw
  setlocal nomodifiable nomodified
  let indent = strlen(a:information_list[0][0])
  call ncv#util#breakindentopt(indent)

  wincmd p
endfunction


function! s:create_comment_view_buffer() abort
  execute 'edit' g:ncv_comment_bufname
  setlocal breakindent buftype=nofile nobuflisted modifiable noswapfile wrap nonumber

  setfiletype ncv
  setlocal nomodified
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
