let s:save_cpo = &cpo
set cpo&vim

let s:unite_source = {
      \ 'name': 'sn_search',
      \ 'is_volatile': 1,
      \ 'required_pattern_length': 1,
      \ 'hooks': {}
      \ }

function! s:unite_source.hooks.on_init(args,context)
  call simplenote#auth()
endfunction

function! s:unite_source.gather_candidates(args, context)
  return map(copy(simplenote#search(a:context.input)),
        \ '{
        \ "word": split(v:val.content, "\n")[0],
        \ "source": "sn_search",
        \ "kind": "command",
        \ "action__command": "Edit sn:".(v:val.key),
        \ }')
endfunction

function! unite#sources#sn_search#define()
  return s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
