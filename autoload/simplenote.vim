if !exists('s:token')
  let s:token = ''
  let s:notes = {}
endif

function! simplenote#auth()
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

function! simplenote#get_list()
  if len(simplenote#auth())
    return {"error": "unauthorized"}
  endif
  let url = printf('https://simple-note.appspot.com/api/index?auth=%s&email=%s', s:token, g:metarw_simplenote_email)
  let res = http#get(url)
  let nodes = json#decode(iconv(res.content, 'utf-8', &encoding))
  for node in nodes
    if !node.deleted
      if !has_key(s:notes, node.key)
        call simplenote#get_note(node.key)
      endif
    endif
  endfor
  return s:notes
endfunction

function! simplenote#get_note(key)
  if len(simplenote#auth())
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

function! simplenote#get_text(key)
  let url = printf('https://simple-note.appspot.com/api/note?key=%s&auth=%s&email=%s', a:key, s:token, g:metarw_simplenote_email)
  let res = http#get(url)
  if res.header[0] == 'HTTP/1.1 200 OK'
    return ['done', iconv(res.content, 'utf-8', &encoding)]
  endif
  return ['error', res.header[0]]
endfunction

function! simplenote#delete(key)
    let url = printf('https://simple-note.appspot.com/api/delete?key=%s&auth=%s&email=%s', a:key, s:token, g:metarw_simplenote_email)
    let res = http#get(url)
    if res.header[0] == 'HTTP/1.1 200 OK'
      call remove(s:notes, a:key)
      return 'deleted'
    endif
    return res.header[0]
endfunction

function! s:put_note(key,text)
  if type(a:key) == type("")
    let url = printf('https://simple-note.appspot.com/api2/data/%s?auth=%s&email=%s', a:key, s:token, g:metarw_simplenote_email)
  else
    let url = printf('https://simple-note.appspot.com/api2/data?auth=%s&email=%s', s:token, g:metarw_simplenote_email)
  endif
  let content = iconv(a:text, &encoding, 'utf-8')
  let json = iconv(json#encode({
  \   'content': content,
  \   'tags': (type(a:key) == type("")) ? s:notes[a:key].tags : []
  \ }), 'utf-8', &encoding)
  let res = http#post(url,http#encodeURI(json))
  if res.header[0] == 'HTTP/1.1 200 OK'
    let lines = split(content, "\n")
    let title = len(lines) > 0 ? lines[0] : ''
    if type(a:key) == type("")
      let s:notes[a:key].title = title
    else
      let s:notes[a:key] = {"title": title, "tags": []}
    endif
    return 'success'
  endif
  return res.header[0]
endfunction

function! simplenote#create(text)
  return s:put_note(0, a:text)
endfunction

function! simplenote#update(key, text)
  return s:put_note(a:key, a:text)
endfunction

