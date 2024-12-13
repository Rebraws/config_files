" All system-wide defaults are set in $VIMRUNTIME/debian.vim and sourced by
" the call to :runtime you can find below.  If you wish to change any of those
" settings, you should do it in this file (/etc/vim/vimrc), since debian.vim
" will be overwritten everytime an upgrade of the vim packages is performed.
" It is recommended to make changes after sourcing debian.vim since it alters
" the value of the 'compatible' option.

runtime! debian.vim

" Vim will load $VIMRUNTIME/defaults.vim if the user does not have a vimrc.
" This happens after /etc/vim/vimrc(.local) are loaded, so it will override
" any settings in these files.
" If you don't want that to happen, uncomment the below line to prevent
" defaults.vim from being loaded.
" let g:skip_defaults_vim = 1

" Uncomment the next line to make Vim more Vi-compatible
" NOTE: debian.vim sets 'nocompatible'.  Setting 'compatible' changes numerous
" options, so any other options should be set AFTER setting 'compatible'.
"set compatible

" Vim5 and later versions support syntax highlighting. Uncommenting the next
" line enables syntax highlighting by default.
if has("syntax")
  syntax on
endif

" If using a dark background within the editing area and syntax highlighting
" turn on this option as well
"set background=dark

" Uncomment the following to have Vim jump to the last position when
" reopening a file
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
" Add header guards to .h files
autocmd BufNewFile *.h execute "normal i#ifndef " . toupper(expand("%:t:r")) . "_H_\n#define " . toupper(expand("%:t:r")) . "_H_\n\n#endif /* " . toupper(expand("%:t:r")) . "_H_ */"

" Uncomment the following to have Vim load indentation rules and plugins
" according to the detected filetype.
"filetype plugin indent on

" The following are commented out as they cause vim to behave a lot
" differently from regular Vi. They are highly recommended though.
"set showcmd		" Show (partial) command in status line.
"set showmatch		" Show matching brackets.
"set ignorecase		" Do case insensitive matching
"set smartcase		" Do smart case matching
"set incsearch		" Incremental search
"set autowrite		" Automatically save before commands like :next and :make
"set hidden		" Hide buffers when they are abandoned
"set mouse=a		" Enable mouse usage (all modes)

" Source a global configuration file if available
if filereadable("/etc/vim/vimrc.local")
  source /etc/vim/vimrc.local
endif
set tabstop=2
set shiftwidth=2
set cc=80
set nobackup
set noundofile
set noswapfile
set expandtab
filetype indent on
set smartindent
set number
set relativenumber
set autoread
set makeprg=ninja
nnoremap <C-b> :make -f build.ninja -C build/<CR>
:nnoremap <C-t> :!ctest --test-dir build/ --output-on-failure<CR>
vnoremap <C-r> "hy:%s/<C-r>h//gc<left><left><left>
if &term =~ '^screen'
    " tmux will send xterm-style keys when its xterm-keys option is on
    execute "set <xUp>=\e[1;*A"
    execute "set <xDown>=\e[1;*B"
    execute "set <xRight>=\e[1;*C"
    execute "set <xLeft>=\e[1;*D"
endif


" use <tab> for trigger completion and navigate to the next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

"inoremap <silent><expr> <Tab>
"      \ pumvisible() ? "\<C-n>" :
"      \ <SID>check_back_space() ? "\<Tab>" :
"      \ coc#refresh()



call plug#begin()
Plug 'lervag/vimtex'
Plug 'godlygeek/tabular'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'morhetz/gruvbox'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'peterhoeg/vim-qml'
Plug 'dracula/vim', { 'name': 'dracula' }
call plug#end()

" Latex configuration 
let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0
set conceallevel=1
let g:tex_conceal='abdmg'

let g:gruvbox_contrast_dark='hard'
colorscheme gruvbox
" Coc shortcuts
nmap <silent> gs :call CocAction('jumpDefinition', 'split')<CR>
nmap <silent> gd :call CocAction('jumpDefinition', 'vsplit')<CR>
nmap <silent> gt :call CocAction('jumpDefinition', 'tabe')<CR>
nmap <silent> gg :call CocAction('jumpDefinition', '')<CR>
nmap <silent> gr <Plug>(coc-references)  

nmap <C-i> :CocCommand document.toggleInlayHint<CR>

" Rip grep with fzf integration
" fzf ripgrep
let g:rg_command = 'rg --column --line-number --no-heading --fixed-strings --ignore-case --no-ignore --hidden --follow --color "always" -g "*.{cpp,hpp,h,c}" -g "!{.git,node_modules}/*"'

" Define custom commands
command! -bang -nargs=* Rg call fzf#vim#grep(g:rg_command .shellescape(<q-args>), 1, <bang>0)

" Key mappings
nnoremap <Leader>f :Files<CR>
nnoremap <Leader>r :Rg<CR>
nnoremap <Leader>b :Buffers<CR>

" Optional: Use fzf for tag jumping (useful for C++)
nnoremap <Leader>t :Tags<CR>

" Optional: Customize fzf appearance
let g:fzf_layout = { 'down': '~40%' }

" Optional: Preview window (requires Bat for syntax highlighting)
command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

" Optional: Use ripgrep to search for the word under the cursor
nnoremap <silent> <Leader>* :Rg <C-R><C-W><CR>

