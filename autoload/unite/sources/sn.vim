let s:save_cpo = &cpo
set cpo&vim

let s:unite_source = {
      \ 'name': 'sn'
      \ }

function! s:unite_source.gather_candidates(args, context)
  let tag = '"[".v:val."]"'
  return values(map(
        \ copy(metarw#sn#get_list()),
        \ '{
        \ "word": join(map(copy(v:val.tags),tag),"").v:val.title,
        \ "source": "sn",
        \ "kind": "command",
        \ "action__command": "Edit sn:".v:key,
        \ }'))
endfunction

function! unite#sources#sn#define()
  return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
