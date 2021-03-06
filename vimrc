" Early settings {{{
set nocompatible
let mapleader = ";"
let maplocalleader = mapleader
set modeline modelines=5

" enable mouse
set mouse=a
set bs=2

set number

" one space after period
set nojoinspaces

" Prevent jedi from loading (may be installed system-wide)
let g:loaded_jedi = 1


" Ignore files when completing
set suffixes+=.class,.pyc,.pyo
set suffixes+=.lo,.swo
" Don't ignore headers when completing
set suffixes-=.h

" use blowfish2 if i ask for crypto
set cm=blowfish2

" }}}

" defines a command, MkDirs, that will make all the directories necessary so
" that the path to current buffer-file exists
command MkDirs call mkdir(expand('%:h'), 'p')

command CtagsCpp !ctags --c++-kinds=+p --c-kinds=+p --fields=+iaS --extra=+q -Rnu .

command HighlightCurrentLine :call matchadd('Search', '\%'.line('.').'l')<CR>
command ClearHighlightCurrentLine :call clearmatches()<CR>

" https://vim.fandom.com/wiki/Search_across_multiple_lines
" Search for the ... arguments separated with whitespace (if no '!'),
" or with non-word characters (if '!' added to command).
function! SearchMultiLine(bang, ...)
  if a:0 > 0
    let sep = (a:bang) ? '\_W\+' : '\_s\+'
    let @/ = join(a:000, sep)
  endif
endfunction
command! -bang -nargs=* -complete=tag S call SearchMultiLine(<bang>0, <f-args>)|normal! /<C-R>/<CR>

" Opens a zettel rst file based on the current time, inserting a link to it
" from the current buffer.
function! ZettelNew()
    let l:zettel_name = strftime("%Y%m%d%H%M")
    let l:zettel_fname = l:zettel_name . '.rst'
    " inserts link to new zettel
    call append(line('.'), l:zettel_name . '_')
    execute "split" l:zettel_fname
    " puts anchor into the new split buffer
    let l:anchor = ".. _" . l:zettel_name . ":"
    return append(0, l:anchor)
endfunction

" Opens a zettel rst file based on the current time, inserting a link in the
" new zettel back to the current buffer.
function! ZettelNewLinkBack()
    let l:zettel_name = strftime("%Y%m%d%H%M")
    let l:zettel_fname = l:zettel_name . '.rst'
    " Gets the anchor from the first line of the note.
    let l:line = getline(1)
    let l:prev_zettel_name = substitute(substitute(l:line, '^.. _', '', ''), ':$', '', '')
    " inserts link to new zettel
    execute "split" l:zettel_fname
    " puts anchor into the new split buffer
    let l:anchor = ".. _" . l:zettel_name . ":"
    " puts backlink into new split buffer
    call append(line('.'), l:prev_zettel_name . '_')
    return append(0, l:anchor)
endfunction

" Pops up a list of results linking to this zettel.
function! ZettelFindLinksTo()
    " Gets the anchor from the first line of the note.
    let l:line = getline(1)
    let l:prev_zettel_name = substitute(substitute(l:line, '^.. _', '', ''), ':$', '', '')
    " patterns: anchor_, `anchor`_, `link text <anchor>`_
    let search_term = l:prev_zettel_name . '([>][`])?' . '[_]'
    let command = 'rg -m 1 --column --line-number --no-heading --color=always --smart-case '.shellescape(search_term)
    " don't use '-1' option because i want a list regardless
    call fzf#vim#grep(command, 1, fzf#vim#with_preview({'options': []}), 0)
endfunction

command! ZettelNew :call ZettelNew()
command! ZettelNewLinkBack :call ZettelNewLinkBack()
command! ZettelFindBackLinks :call ZettelFindLinksTo()
command! ZettelFollowLink :call FzfRgRstLinkSource()

" my simple statusline, airline was a steaming pile
set statusline=%q%t\ @\ %P\ [ft=%Y%M%R%W%H]\ char:0x%B\ pos\ %l:%c\ %=%<%{expand('%:~:.:h')}

" Airline configuration {{{
"if !exists('g:airline_symbols')
"    let g:airline_symbols = {}
"endif
"
"let g:airline_left_sep="▓▒░"
"let g:airline_right_sep="░▒▓"
"
"let g:airline_inactive_collapse=0
"let g:airline#extensions#tabline#enabled=1
"let g:airline#extensions#tabline#show_buffers=0
"let g:airline_theme='zenburn'
"let g:airline_theme='dracula'
" }}}

" CtrlP Configuration {{{
let g:ctrlp_custom_ignore = {
    \ 'file':   '\v\.(class|o|so|py[co])$',
    \ 'dir':    '\v/\.(git|hg|svn)$',
    \ }
let g:ctrlp_cache_dir = $HOME . '/.cache/ctrlp'

" if executable('ag')
"   let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
"   set grepprg=ag\ --vimgrep\ $*
"   set grepformat=%f:%l:%c:%m
" endif

if executable('rg')
  set grepprg=rg\ --vimgrep\ $*
  set grepformat=%f:%l:%c:%m
endif
" }}}

" Syntastic options from their website {{{
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*
"
"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0
"let g:syntastic_ocaml_checkers = ["merlin"]
" }}}
"
" FZF config {{{
if executable('fzf')
  let fzfpath=fnamemodify(resolve(exepath('fzf')), ':h:h')
  execute "set rtp+=" . fzfpath . "/share/vim-plugins/fzf"
  set rtp+=bundle/junegunn-fzf.vim

  if executable('ag')
      let $FZF_DEFAULT_COMMAND = 'ag -g "" --ignore "*.o" --ignore "*.so" --ignore "*.tmp" --ignore "*.class" --ignore-dir ".git"'
  endif
  let $FZF_DEFAULT_COMMAND = 'rg --iglob "!/_opam" --iglob "!/_build" --iglob "!*.o" --files'
  let g:fzf_preview_window = ''

  " :BD function to use fzf to delete buffers
  function! s:list_buffers()
      redir => list
      silent ls
      redir END
      return split(list, "\n")
  endfunction

  function! s:delete_buffers(lines)
      execute 'bwipeout' join(map(a:lines, {_, line -> split(line)[0]}))
  endfunction

  " Call :BuffersDelete to pop up window of buffers to delete, use tab to
  " select a buffer for deletion, enter to delete all
  command! BuffersDelete call fzf#run(fzf#wrap({
              \ 'source': s:list_buffers(),
              \ 'sink*': { lines -> s:delete_buffers(lines) },
              \ 'options': '--multi --reverse --bind ctrl-a:select-all+accept'
              \ }))

  " https://github.com/junegunn/fzf.vim/issues/556
  " remap `gf` to pick up files anywhere inside current directory rather than
  " just the literal `<cfile>` when you want the same for some *other*
  " directory, you put your cursor on the filename and type `:GF other-dir`
  function! GF(...)
      call fzf#run({'dir': a:1, 'source': 'find . -type f', 'options':['-1', '--query', expand('<cfile>')], 'sink': 'e'})
  endfunction
  command! -nargs=* GF :call GF(<f-args>)

  " Opens in a split the link source from a file in the current directory (in
  " FZF window if there are multiple).
  function! FzfRgRstLinkSource()
      let word_under_cursor = expand("<cword>")
      " remove underscore at end of word and put one at beginning
      let search_term = '_' . substitute(word_under_cursor, '[_]$', '', '')
      let command = 'rg -m 1 --column --line-number --no-heading --color=always --smart-case '.shellescape(search_term)
      execute "split"
      call fzf#vim#grep(command, 1, fzf#vim#with_preview({'options': ['-1']}), 0)
  endfunction

  " goto fzf file at cursor
  nnoremap gf :call fzf#vim#files('.', {'options':'-1 --query '.expand('<cword>')})<CR>
  " search from cwd
  nnoremap \ :Rg<CR>
  " fzf over lines in current buffer, :Lines for all buffers
  nnoremap <Leader>s :BLines<CR>
  nnoremap <Leader>S :Lines<CR>
endif
" }}}


" GUI options {{{
if has('gui')
    set guioptions-=m " no menu
    set guioptions-=T " no toolbar
    set guioptions-=r " no scrollbars
    set guioptions-=R
    set guioptions-=l
    set guioptions-=L
    set guioptions-=b
    set guifont=Iosevka\ Term\ Medium:h13
    " set guifont=SF\ Mono\ Regular:h13
    " set guifont=Source\ Code\ Pro\ Regular:h13
endif
" }}}

" Pathogen invocation {{{
" let s:opamshare = substitute(system('opam config var share'),'\n$','','''')
let g:pathogen_disabled = ['bling-vim-airline', 'vim-airline-vim-airline-themes', 'scrooloose-syntastic', 'scrooloose-nerdtree', 'ctrlp.vim']
" s:opamshare.'/ocp-index/vim',
runtime bundle/tpope-vim-pathogen/autoload/pathogen.vim
exec pathogen#infect('bundle/{}')
"exec pathogen#infect('bundle/{}',s:opamshare.'/{}/vim')
filetype plugin indent on
syntax on
" }}}

function s:camel_word(dir)
    call search('\U\zs\u\|\<', a:dir)
endfunction

" Global mappings {{{
" disable keymapping for Ex mode
nnoremap Q <nop>

nnoremap <Leader>T :TagbarToggle<CR>

" functions from junegunn-fzf.vim
" each brings up fuzzy completion list
" <Leader>u - list of buffers
nnoremap <Leader>u :Buffers<CR>
" <Leader>f - list of files under the current Git repo
nnoremap <Leader>f :<C-u>GitFiles<CR>
" <Leader>f - list of files under the current directory
nnoremap <Leader>F :<C-u>Files<CR>
" <Leader>f - list of tags
nnoremap <Leader>t :Tags<CR>

" <Leader>d deletes the current buffer
nnoremap <Leader>d :bd<CR>

" Insert current date into buffer. Used for note taking.
nnoremap <Leader>it "=strftime("%c")<CR>p

" select some text, then type // and it will search for the literal text
vnoremap // y/\V<C-R>"<CR>

" highlight matches in search
" set hlsearch
" <Leader>h will turn off highlights
nnoremap <Leader>h :set hls!<CR>
"nnoremap <Space> zz

" close the current window
nnoremap <Leader>c <C-w>c
" make the current window the only window
nnoremap <Leader>o <C-w>o
" easier movement in splits
nnoremap <C-h> <C-w><C-h>
nnoremap <C-j> <C-w><C-j>
nnoremap <C-k> <C-w><C-k>
nnoremap <C-l> <C-w><C-l>

" C-w ] will open tag in a split
" C-w g } will let you select tag for preview
"nnoremap <C-n> :cnext<CR>
"nnoremap <C-p> :cprevious<CR>
"nnoremap <Leader>n :tnext<CR>
"nnoremap <Leader>p :tprev<CR>

" Put timestamp in filename?
cmap <F3> <C-R>=strftime("%Y%m%d%H%M")<CR>

nnoremap <silent> _ :aboveleft sp<CR>:exe "normal \<Plug>VinegarUp"<CR>
nnoremap <silent> <Bar> :aboveleft vsp<CR>:exe "normal \<Plug>VinegarUp"<CR>
" }}}


" Basic configuration {{{
" let g:jellybeans_overrides = {
"           \ 'background': { 'guibg': '191919' },
"           \ }
" kthxbye
" let g:dracula_italic = 0
" colorscheme dracula

" set background=light
" colorscheme cosmic_latte

" too muted for now
let g:nord_bold_vertical_split_line = 1
augroup nord-theme-overrides
    autocmd!
    " Brighten the vertical split so I don't confuse it with the color column.
    " Even brighter than the bold_vertical_split option.
    autocmd ColorScheme nord hi VertSplit guibg=#616E88 guifg=#434C5E
    " autocmd ColorScheme nord hi ColorColumn guibg=#2E3440 guifg=#434C5E
augroup END
colorscheme nord

" set background=dark
" colorscheme solarized

" colorscheme molokai

" let g:gruvbox_contrast_dark = 'medium'
" autocmd vimenter * colorscheme gruvbox

" default for .tex files is latex
let g:tex_flavor = "latex"

" R mode customizations
let R_assign = 2

" extra space between lines because this helps with smaller font sizes
"set linespace=0
"deus "spacegray
""else
  "colors jellybeans
  "hi CursorLine guibg=#404040
  "hi CursorColumn guibg=#404040
"endif

" show line number and character pos
set ruler
" expand tabs, default shiftwidth is 4
set et sts=4 sw=4
" keep 4 lines above and below the cursor
set so=4

set showcmd
" ignore case except mixed lower and uppercase in patterns
set ignorecase smartcase

" unexplainable but helpful completion settings
set wildmenu wildmode=list,list:longest

" always include status line
set laststatus=2

" keep buffers around when they are not visible
set hidden

" don't remember options in seccions
set sessionoptions-=options

" don't let search open a fold
" set fdo-=search

" i have cores for a reason
set makeprg=make\ -j8

" disables mappings from default ocaml ftplugin
let g:no_ocaml_maps = 1

set tags=./tags,./TAGS,tags,TAGS,./.tags,./.TAGS,.tags,.TAGS,../../tags,../tags

" set this to add to places where vim searches #includes
"set path+=

" }}}

" vimtex config {{{
let g:vimtex_disable_recursive_main_file_detection = 1
" }}}

let g:syntastic_mode_map = { 'mode': 'passive' }

" turn off markify automatically; use :MarkifyToggle or :Markify[Clear]
" let g:markify_autocmd = 0

" Python indenting {{{
function PythonParenIndent(lnum)
    call cursor(a:lnum, 1)
    let [pline, pcol] = searchpairpos('(\|{\|\[', '', ')\|}\|\]', 'bW',
                        \ "synIDattr(synID(line('.'), col('.'), 1), 'name')" .
                        \ " =~ '\\(Comment\\|String\\)$'",
                        \ max([0,a:lnum-50]))
    let plinecontent = getline(pline)
    let lineend = match(plinecontent, '\s*$')
    if pcol >= lineend
        return &sw
    else
        return pcol-indent(pline)
    endif
endfunction

let g:pyindent_nested_paren='PythonParenIndent(a:lnum)'
let g:pyindent_open_paren='PythonParenIndent(a:lnum)'
" }}}

" XXX is this necessary?
runtime ftplugin/man.vim

" vim: set foldmethod=marker :

" z3 specific style settings for c++
autocmd BufRead
     \ ~/work/inprogress/z3/*/{src,tools,tests}/*.{cc,cpp,h,inc}
     \ setlocal makeprg=make\ -C\ .vimbuild\ -j24\ all sw=4 cino=:0,l1,g0,t0,(0,w1,W4

" Trailing whitespace
command StripTrailingWhitespace %s/\s\+$//e

if !has('gui') && stridx($TERM, "kitty")
  " turn off background color erase for kitty
  let &t_ut=''
endif

runtime vimrc_local


