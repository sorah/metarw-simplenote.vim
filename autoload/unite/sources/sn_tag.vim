let s:save_cpo = &cpo
set cpo&vim

let s:unite_source = {
      \ 'name': 'sn_tag'
      \ }

function! s:unite_source.gather_candidates(args, context)
  return map(copy(simplenote#get_tags()),
        \ '{
        \ "word": v:val,
        \ "source": "sn_tag",
        \ "kind": "command",
        \ "action__command": "Unite sn:".v:val,
        \ }')
endfunction

function! unite#sources#sn_tag#define()
  return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
