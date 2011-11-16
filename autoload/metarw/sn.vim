if !exists('s:token')
  let s:token = ''
  let s:notes = {}
endif

function! metarw#sn#complete(arglead, cmdline, cursorpos)
  if len(s:authorization())
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
  let err = s:authorization()
  if len(err)
    return ['error', err)
  endif
  let url = printf('https://simple-note.appspot.com/api/note?key=%s&auth=%s&email=%s', l[1], s:token, g:metarw_simplenote_email)
  let res = http#get(url)
  if res.header[0] == 'HTTP/1.1 200 OK'
    setlocal noswapfile
    put =iconv(res.content, 'utf-8', &encoding)
    let b:sn_key = l[1]
    return ['done', '']
  endif
  return ['error', res.header[0]]
endfunction

function! metarw#sn#write(fakepath, line1, line2, append_p)
  let l = split(a:fakepath, ':', 1)
  if len(l) < 2
    return ['error', printf('Unexpected fakepath: %s', string(a:fakepath))]
  endif
  let err = s:authorization()
  if len(err)
    return ['error', err)
  endif
  if len(l[1]) > 0 && line('$') == 1 && getline(1) == ''
    let url = printf('https://simple-note.appspot.com/api/delete?key=%s&auth=%s&email=%s', l[1], s:token, g:metarw_simplenote_email)
    let res = http#get(url)
    if res.header[0] == 'HTTP/1.1 200 OK'
      echomsg 'deleted'
      return ['done', '']
    endif
  endif
    if len(l[1]) > 0
      let url = printf('https://simple-note.appspot.com/api/note?key=%s&auth=%s&email=%s', l[1], s:token, g:metarw_simplenote_email)
    else
      let url = printf('https://simple-note.appspot.com/api/note?auth=%s&email=%s', s:token, g:metarw_simplenote_email)
    endif
    let res = http#post(url, base64#b64encode(iconv(join(getline(a:line1, a:line2), "\n"), &encoding, 'utf-8')))
    if res.header[0] == 'HTTP/1.1 200 OK'
      if len(l[1]) == 0
        let key = res.content
        silent! exec 'file '.printf('sn:%s', escape(key, ' \/#%'))
        set nomodified
      endif
      return ['done', '']
    endif
  endif
  return ['error', res.header[0]]
endfunction

function! s:authorization()
  if len(s:token) > 0
    return ''
  endif
  if !exists('g:metarw_simplenote_email')
    let g:metarw_simplenote_email = input('email: ')
  endif
  let password = inputsecret('password: ')
  let creds = base64#b64encode(printf('email=%s&password=%s', g:metarw_simplenote_email, password))
  let res = http#post('https://simple-note.appspot.com/api/login', creds)
  if res.header[0] == 'HTTP/1.1 200 OK'
    let s:token = res.content
    return ''
  endif
  return 'failed to authenticate'
endfunction

function! metarw#sn#get_list()
  if len(s:authorization())
    return {"error": "unauthorized"}
  endif
  let url = printf('https://simple-note.appspot.com/api/index?auth=%s&email=%s', s:token, g:metarw_simplenote_email)
  let res = http#get(url)
  let nodes = json#decode(iconv(res.content, 'utf-8', &encoding))
  for node in nodes
    if !node.deleted
      if !has_key(s:notes, node.key)
        call metarw#sn#get_note(node.key)
      endif
    endif
  endfor
  return s:notes
endfunction

function! metarw#sn#get_note(key)
  if len(s:authorization())
    return {"error": "unauthorized"}
  endif
  let url = printf('https://simple-note.appspot.com/api2/data/%s?auth=%s&email=%s', a:key, s:token, g:metarw_simplenote_email)
  let res = http#get(url)
  let json =  json#decode(iconv(res.content, 'utf-8', &encoding))
  let lines = split(iconv(json.content, 'utf-8', &encoding), "\n")
  let s:notes[a:key] = {"title": len(lines) > 0 ? lines[0] : '',
                     \  "tags": json.tags}
  return s:notes[a:key]
endfunction

