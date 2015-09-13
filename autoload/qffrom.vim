" =============================================================================
" Filename: autoload/qffrom.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/09/12 18:15:21.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:qffrom = {}

let s:qffrom.grep = {
      \ 'command': 'grep -HIsinr -- $* <dir>',
      \ 'format': '%f:%l:%m',
      \ }

let s:qffrom.find = {
      \ 'command': 'find <dir> -type f -iname ''$*'' -print',
      \ 'format': '%f',
      \ }

function! qffrom#get(cmd, name, value) abort
  let user = get(get(g:, 'qffrom', {}), a:cmd, {})
  let all = get(get(g:, 'qffrom', {}), '_', {})
  let default = get(get(s:, 'qffrom', {}), a:cmd, {})
  return get(user, a:name, get(all, a:name, get(default, a:name, a:value)))
endfunction

function! qffrom#start(args) abort
  let args = []
  let cmd = ''
  let cmds = qffrom#command()
  for arg in split(a:args, '\v +\zs')
    let argcmd = substitute(substitute(arg, '\v +$', '', ''), '\m\c^-\+', '', '')
    if get(cmds, argcmd) && cmd ==# ''
      let cmd = argcmd
    else
      call add(args, arg)
    endif
  endfor
  let [ dir, hasdir, pattern ] = qffrom#dir_pattern(cmd, join(args, ''))
  call qffrom#run(cmd, dir, hasdir, pattern)
endfunction

function! qffrom#dir_pattern(cmd, args) abort
  let default_dir = qffrom#default_dir(a:cmd)
  let dir = default_dir
  let hasdir = 0
  let pattern = []
  for arg in split(a:args, '\v +\zs')
    if isdirectory(expand(substitute(arg, '\v +$', '', ''))) && dir ==# default_dir && (len(a:args) != 1 || qffrom#get(a:cmd, 'dironly', 0))
      let dir = qffrom#fnameescape(substitute(arg, '\v +$', '', ''))
      let hasdir = 1
    else
      call add(pattern, arg)
    endif
  endfor
  return [ dir, hasdir, qffrom#pattern(join(pattern, '')) ]
endfunction

function! qffrom#default_dir(cmd) abort
  if qffrom#get(a:cmd, 'git_root', 0)
    return qffrom#git_root()
  else
    return '.'
  endif
endfunction

function! qffrom#command() abort
  let commands = {}
  for cmd in keys(s:qffrom)
    let commands[cmd] = 1
  endfor
  for cmd in keys(get(g:, 'qffrom', {}))
    let commands[cmd] = 1
  endfor
  return commands
endfunction

function! qffrom#complete(...) abort
  return []
endfunction

function! qffrom#run(cmd, dir, hasdir, pattern) abort
  let errorformat = &errorformat
  try
    execute qffrom#get(a:cmd, 'pre', '')
    let &errorformat = qffrom#get(a:cmd, 'format', errorformat)
    let command = qffrom#get(a:cmd, 'command', &grepprg)
    let command = substitute(command, '\$\*', a:pattern, 'g')
    let command = substitute(command, '\c<dir>', a:dir, 'g')
    let command = substitute(command, '\c<hasdir>', a:hasdir ? 'true' : 'false', 'g')
    silent cexpr system(command)
    call qffrom#iconv(a:cmd)
    execute qffrom#get(a:cmd, 'post', '')
  finally
    let &errorformat = errorformat
  endtry
endfunction

function! qffrom#iconv(cmd) abort
  if qffrom#get(a:cmd, 'convert_encoding', &encoding !=# &termencoding) && has('iconv')
    let qflist = getqflist()
    for item in qflist
      let item.text = iconv(item.text, &termencoding, &encoding)
    endfor
    call setqflist(qflist)
  endif
endfunction

if exists('*fnameescape')
  function! qffrom#fnameescape(str) abort
    return fnameescape(a:str)
  endfunction
else
  function! qffrom#fnameescape(str) abort
    return escape(a:str, " \t\n*?[{`$\\%#'\"|!<")
  endfunction
endif

function! qffrom#pattern(str) abort
  let str = a:str =~# '\v^".*"$|^''.*''$' ? a:str : "'" . substitute(a:str, "'", ".", 'g') . "'"
  return escape(substitute(str, '\v(^ +| +$)', '', 'g'), '\&[]')
endfunction

function! qffrom#git_root() abort
  let path = expand('%:p:h')
  let prev = ''
  while path !=# prev
    let dir = path . '/.git'
    let type = getftype(dir)
    if type ==# 'dir' && isdirectory(dir.'/objects') && isdirectory(dir.'/refs') && getfsize(dir.'/HEAD') > 10
      return fnamemodify(dir, ':h')
    elseif type ==# 'file'
      let reldir = get(readfile(dir), 0, '')
      if reldir =~# '^gitdir: '
        return fnamemodify(simplify(path . '/' . reldir[8:]), ':h')
      endif
    endif
    let prev = path
    let path = fnamemodify(path, ':h')
  endwhile
  return '.'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
