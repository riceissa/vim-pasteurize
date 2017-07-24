if exists("g:loaded_pasteurize")
  finish
endif
let g:loaded_pasteurize = 1

if !has("clipboard")
  finish
endif

" Destructively remove blank lines from both ends of a register and set it
" to be characterwise. This is intended especially for pasting from the
" quoteplus register; in almost all cases, pasting from the clipboard means
" pasting from a different application that doesn't have any conception of
" linewise or blockwise registers, so unconditional characterwise pasting is
" more intuitive.
function! s:characterize_register(reg)
  " In older versions of Vim, the call to setreg() at the end on the list
  " reg_cont crashes Vim with 'Caught deadly signal ABRT'. Git bisect
  " reveals that this is fixed with Vim 7.4 patch 513, 'Crash because
  " reference count is wrong for list returned by getreg().' Searching the
  " Git log reveals that there have been several bugs related to
  " setreg()/getreg(). The following conditional *should* fix things, but if
  " you are really worried, it's best to upgrade Vim or use the mapping from
  " $VIMRUNTIME/mswin.vim and $VIMRUNTIME/autoload/paste.vim.
  if has('nvim') || v:version > 704 || (v:version == 704 && has("patch513"))
    let reg_cont = getreg(a:reg, 1, 1)

    if !exists('g:pasteurize_no_strip_newlines') || !g:pasteurize_no_strip_newlines
      " Remove empty lines at the beginning and end of the register
      while (!empty(reg_cont)) && (reg_cont[-1] ==# '')
        call remove(reg_cont, -1)
      endwhile
      while (!empty(reg_cont)) && (reg_cont[0] ==# '')
        call remove(reg_cont, 0)
      endwhile
    endif
  else
    let reg_cont = getreg(a:reg)

    if !exists('g:pasteurize_no_strip_newlines') || !g:pasteurize_no_strip_newlines
      " Same idea as above; remove empty lines from the beginning and end.
      " Note that because the result of calling getreg() is not a list in this
      " case, any NULLs will be converted to newlines.
      while strpart(reg_cont, len(reg_cont)-1) == "\<NL>"
        let reg_cont = strpart(reg_cont, 0, len(reg_cont)-1)
      endwhile
      while strpart(reg_cont, 0, 1) == "\<NL>"
        let reg_cont = strpart(reg_cont, 1)
      endwhile
    endif
  endif

  call setreg(a:reg, reg_cont, 'c')
endfunction

function! s:paste(reg)
  call <SID>characterize_register(a:reg)
  if col('.') >= col('$')
    norm! "+gp
    return "\<Right>"
  else
    norm! "+gP
    return ""
  endif
endfunction

if !exists("g:pasteurize_no_mappings") || !g:pasteurize_no_mappings
  xmap <C-X> <Plug>PasteurizeVCut
  xmap <C-C> <Plug>PasteurizeVCopy
  nmap <C-V> <Plug>PasteurizeNPaste
  cmap <C-V> <Plug>PasteurizeCPaste
  imap <C-V> <Plug>PasteurizeIPaste
  xmap <C-V> <Plug>PasteurizeVPaste
endif

xnoremap <silent> <script> <Plug>PasteurizeVCut "+x:<C-U>call <SID>characterize_register('+')<CR>
xnoremap <silent> <script> <Plug>PasteurizeVCopy "+y:<C-U>call <SID>characterize_register('+')<CR>

nnoremap <silent> <script> <Plug>PasteurizeNPaste :<C-U>call <SID>characterize_register('+')<CR>"+gP
cnoremap <script> <Plug>PasteurizeCPaste <C-R><C-R>+
inoremap <silent> <Plug>PasteurizeIPaste <C-G>u<C-R>=<SID>paste('+')<CR>
xnoremap <silent> <script> <Plug>PasteurizeVPaste "-y:<C-U>call <SID>characterize_register('+')<CR>gv"+gp
