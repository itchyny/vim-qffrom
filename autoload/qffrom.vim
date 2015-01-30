" =============================================================================
" Filename: autoload/qffrom.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/01/30 22:31:06.
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
  for arg in a:args
    let argcmd = substitute(arg, '\m\c^-\+', '', '')
    if get(cmds, argcmd) && cmd ==# ''
      let cmd = argcmd
    else
      call add(args, arg)
    endif
  endfor
  let [ dir, pattern ] = qffrom#dir_pattern(cmd, args)
  call qffrom#run(cmd, dir, pattern)
endfunction

function! qffrom#dir_pattern(cmd, args) abort
  let dir = '.'
  let pattern = []
  for arg in a:args
    if isdirectory(expand(arg)) && dir ==# '.' && (len(a:args) != 1 || qffrom#get(a:cmd, 'dironly', 0))
      let dir = qffrom#fnameescape(arg)
    else
      call add(pattern, arg)
    endif
  endfor
  return [ dir, qffrom#fnameescape(join(pattern, ' ')) ]
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

function! qffrom#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction

function! qffrom#run(cmd, dir, pattern) abort
  let errorformat = &errorformat
  try
    execute qffrom#get(a:cmd, 'pre', '')
    let &errorformat = qffrom#get(a:cmd, 'format', errorformat)
    let command = qffrom#get(a:cmd, 'command', &grepprg)
    let command = substitute(substitute(command, '\c<dir>', a:dir, 'g'), '\$\*', a:pattern, 'g')
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

let &cpo = s:save_cpo
unlet s:save_cpo
