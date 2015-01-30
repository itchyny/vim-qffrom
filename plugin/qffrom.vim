" =============================================================================
" Filename: plugin/qffrom.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/01/15 13:18:31.
" =============================================================================

if exists('g:loaded_qffrom') || v:version < 700
  finish
endif
let g:loaded_qffrom = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -complete=customlist,qffrom#complete
      \ Qffrom call qffrom#start([<f-args>])

let &cpo = s:save_cpo
unlet s:save_cpo
