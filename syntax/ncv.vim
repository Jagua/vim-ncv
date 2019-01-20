if exists('b:current_syntax')
  finish
endif


syntax match ncv_Comment_Line /^\s*\d\+:\d\+\%(:\d\+\)\= : \S\+ : .*$/
syntax match ncv_Comment_Time /\zs\d\+:\d\+\%(:\d\+\)\=\ze/
      \      containedin=ncv_Comment_Line
syntax match ncv_Comment_UserID /^\s*\d\+:\d\+\%(:\d\+\)\= : \zs\S\+\ze : .*$/
      \      containedin=ncv_Comment_Line


highlight default link ncv_Comment_Time Comment
highlight default link ncv_Comment_UserID String


let b:current_syntax = 'ncv'
