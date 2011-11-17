function! metarw#sn#complete(arglead, cmdline, cursorpos)
  if len(simplenote#auth())
    return [[], 'sn:', '']
  endif
  let candidate = values(map(deepcopy(metarw#sn#get_list()), '"sn:".v:key.":".v:val.title'))
  return [candidate, 'sn:', '']
endfunction

function! metarw#sn#read(fakepath)
  let l = split(a:fakepath, ':')
  if len(l) < 2
    return ['error', printf('Unexpected fakepath: %s', string(a:fakepath))]
  endif
  let err = simplenote#auth()
  if len(err)
    return ['error', err)
  endif
  let res = simplenote#get_text(l[1])
  if res[0] == 'done'
    setlocal noswapfile
    put =iconv(res[1], 'utf-8', &encoding)
    let b:sn_key = l[1]
    return ['done', '']
  endif
  return res
endfunction

function! metarw#sn#write(fakepath, line1, line2, append_p)
  let l = split(a:fakepath, ':', 1)
  if len(l) < 2
    return ['error', printf('Unexpected fakepath: %s', string(a:fakepath))]
  endif
  let err = simplenote#auth()
  if len(err)
    return ['error', err)
  endif
  if len(l[1]) > 0 && line('$') == 1 && getline(1) == ''
    let res = simplenote#delete(l[1])
    if res == 'deleted'
      echomsg 'deleted'
      return ['done', '']
    endif
  else
    let text = join(getline(a:line1, a:line2), "\n")
    if len(l[1]) > 0
      let res = simplenote#update(l[1], text)
    else
      let res = simplenote#create(text)
    endif
    if res[0] == 'success'
      if len(l[1]) == 0
        let key = res[1]
        silent! exec 'file '.printf('sn:%s', escape(key, ' \/#%'))
        set nomodified
      endif
      return ['done', '']
    endif
  endif
  return ['error', res[1]]
endfunction


