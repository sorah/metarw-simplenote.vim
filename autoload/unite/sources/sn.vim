let s:save_cpo = &cpo
set cpo&vim

let s:unite_source = {
      \ 'name': 'sn'
      \ }

function! s:unite_source.gather_candidates(args, context)
  let notes = copy(simplenote#get_list())
  if !empty(a:args)
    let new_notes = {}
    let flag = 0
    for note in keys(notes)
      for arg in a:args
        if index(notes[note].tags,arg) >= 0
          let flag = 1
        else
          let flag = 0
          break
        endif
      endfor
      if flag == 1
        let new_notes[note] = notes[note]
      endif
    endfor
    let notes = new_notes
  end
  let tag = '"[".v:val."]"'
  return values(map(
        \ notes,
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
