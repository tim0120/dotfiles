" ============================================================================
" BASIC SETTINGS
" ============================================================================

set showcmd
set number relativenumber
set ttyfast
syntax on

" ============================================================================
" INDENTATION
" ============================================================================

set autoindent expandtab tabstop=2 shiftwidth=2

" ============================================================================
" KEY MAPPINGS
" ============================================================================

nnoremap <Space> <Nop>
inoremap jk <Esc>

" Navigate visual lines instead of logical lines
nmap j gj
nmap k gk

" ============================================================================
" PLUGIN MANAGER (DEIN)
" ============================================================================

let s:dein_base = expand('~/.cache/dein')
let s:dein_src = expand('~/.cache/dein/repos/github.com/Shougo/dein.vim')

execute 'set runtimepath+=' . s:dein_src

call dein#begin(s:dein_base)
call dein#add(s:dein_src)

" Plugins
call dein#add('lervag/vimtex')
call dein#add('tmsvg/pear-tree')

call dein#end()

" Auto-install plugins on startup
if dein#check_install()
  call dein#install()
endif

filetype indent plugin on

" ============================================================================
" VIMTEX CONFIGURATION
" ============================================================================

let g:vimtex_view_method = 'skim'
let g:vimtex_compiler_method = 'latexmk'
