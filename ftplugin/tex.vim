" this is mostly a matter of taste. but LaTeX looks good with just a bit
" of indentation.
set sw=2

" TIP: if you write your \label's as \label{fig:something}, then if you
" type in \ref{fig: and press <C-n> you will automatically cycle through
" all the figure labels. Very useful!
set iskeyword+=:

" autowrite for builds
set aw

" set cursorline

nnoremap <buffer> <Leader>is o%-----------------------------------------------------------------------------

" remaps Command-B
" don't just automatically during build
nnoremap D-b :make!<CR>
nnoremap D-B :make!<CR>
