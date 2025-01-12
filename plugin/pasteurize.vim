if exists('g:loaded_pasteurize')
  finish
endif
let g:loaded_pasteurize = 1

if !has('clipboard')
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
  if has('nvim') || v:version > 704 || (v:version == 704 && has('patch513'))
    let l:reg_cont = getreg(a:reg, 1, 1)

    if !exists('g:pasteurize_no_strip_newlines') || !g:pasteurize_no_strip_newlines
      " Remove empty lines at the beginning and end of the register
      while (!empty(l:reg_cont)) && (l:reg_cont[-1] ==# '')
        call remove(l:reg_cont, -1)
      endwhile
      while (!empty(l:reg_cont)) && (l:reg_cont[0] ==# '')
        call remove(l:reg_cont, 0)
      endwhile
    endif
  else
    let l:reg_cont = getreg(a:reg)

    if !exists('g:pasteurize_no_strip_newlines') || !g:pasteurize_no_strip_newlines
      " Same idea as above; remove empty lines from the beginning and end.
      " Note that because the result of calling getreg() is not a list in this
      " case, any NULLs will be converted to newlines.
      while strpart(l:reg_cont, len(l:reg_cont)-1) ==# "\<NL>"
        let l:reg_cont = strpart(l:reg_cont, 0, len(l:reg_cont)-1)
      endwhile
      while strpart(l:reg_cont, 0, 1) ==# "\<NL>"
        let l:reg_cont = strpart(l:reg_cont, 1)
      endwhile
    endif
  endif

  call setreg(a:reg, l:reg_cont, 'c')

  " The following is needed at least on Neovim in WSL2 because for some reason
  " when copying text from the browser and pasting it into Neovim, there's a bunch
  " of ^M control characters that litter the pasted text. So the below line just
  " does a search-replace on all the ^M (i.e. \r) so that we never have to think
  " about them again.
  " l:reg_cont above can be a string or list, but substitute() wants a string only,
  " so we first set the register temporarily using setreg() call above, so that we can
  " call getreg() again in the line below (to get a string), then do the substitute
  " to get rid of all the ^M, and finally we setreg() again.
  call setreg(a:reg, substitute(getreg(a:reg, 1), '\r', '', 'g'), 'c')
endfunction

function! s:paste(reg)
  call <SID>characterize_register(a:reg)
  if col('.') >= col('$')
    norm! "+gp
    return "\<Right>"
  else
    norm! "+gP
    return ''
  endif
endfunction

if !exists('g:pasteurize_no_mappings') || !g:pasteurize_no_mappings
  xmap <C-X> <Plug>PasteurizeXCut
  xmap <C-C> <Plug>PasteurizeXCopy
  nmap <C-V> <Plug>PasteurizeNPaste
  cmap <C-V> <Plug>PasteurizeCPaste
  imap <C-V> <Plug>PasteurizeIPaste
  xmap <C-V> <Plug>PasteurizeXPaste
endif

xnoremap <silent> <script> <Plug>PasteurizeXCut "+x:<C-U>call <SID>characterize_register('+')<CR>
xnoremap <silent> <script> <Plug>PasteurizeXCopy "+y:<C-U>call <SID>characterize_register('+')<CR>

nnoremap <silent> <script> <Plug>PasteurizeNPaste :<C-U>call <SID>characterize_register('+')<CR>"+gP
cnoremap <script> <Plug>PasteurizeCPaste <C-R><C-R>+

" Fall back to the paste.vim style of pasting if 'virtualedit' is not empty
inoremap <silent> <script> <expr> <Plug>PasteurizeIPaste &virtualedit ==# '' ? "\<Lt>C-G>u\<Lt>C-R>=<SID>paste('+')\<Lt>CR>" : "\<Lt>C-G>ux\<Lt>Esc>:\<Lt>C-U>call <SID>characterize_register('+')\<Lt>CR>\"+gP\"_s"

xnoremap <silent> <script> <Plug>PasteurizeXPaste "-y:<C-U>call <SID>characterize_register('+')<CR>gv"+gp
