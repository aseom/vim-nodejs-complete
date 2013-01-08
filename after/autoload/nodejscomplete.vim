" Vim completion script
" Language:	Javascript(node)
" Maintainer:	Lin Zhang ( myhere.2009 AT gmail DOT com )
" Last Change:	2012-8-18 1:32:00

" save current dir
let s:nodejs_doc_file = expand('<sfile>:p:h') . '/nodejs-doc.vim'
let s:js_varname_reg = '[$a-zA-Z_][$a-zA-Z0-9_]*'

function! nodejscomplete#CompleteJS(findstart, base)
  if a:findstart
    if exists('g:node_usejscomplete') && g:node_usejscomplete && 0
      let start = jscomplete#CompleteJS(a:findstart, a:base)
    else
      let start = javascriptcomplete#CompleteJS(a:findstart, a:base)
    endif

    Decho 'start: ' . start
    " str[start: end] end 为负数时从末尾截取
    if start - 1 < 0
      let b:nodecompl_context = ''
    else
      let line = getline('.')
      let b:nodecompl_context = line[:start-1]
    endif
    return start
  else
    let result = s:getNodeComplete(a:base, b:nodecompl_context)
    unlet b:nodecompl_context

    if result.continue
      if exists('g:node_usejscomplete') && g:node_usejscomplete && 0
        let jsCompl = jscomplete#CompleteJS(a:findstart, a:base)
      else
        let jsCompl = javascriptcomplete#CompleteJS(a:findstart, a:base)
      endif

      return result.complete + jsCompl
    else
      return result.complete
    endif
  endif
endfunction


" get complete
function! s:getNodeComplete(base, context)
  Decho 'base: ' . a:base
  Decho 'context: ' . a:context

  " TODO: 排除 module.property.h 情况
  let mod_reg = '\(' . s:js_varname_reg . '\)\_s*\(\.\|\[["'']\?\)\_s*$'
  let matched = matchlist(a:context, mod_reg)
  " 模块属性补全
  if len(matched) > 0
    Decho string(matched)
    let var_name = matched[1]
    let operator = matched[2]

    let mod_name = s:getModuleName(var_name)
    if len(mod_name) > 0
      let compl_list = s:getModuleComplete(mod_name, a:base, operator)
    else
      let compl_list = []
    endif
    let ret = {
      \ 'complete': compl_list
      \ }
    if len(compl_list) == 0
      let ret.continue = 1
    else
      let ret.continue = 0
    endif
  " 全局补全
  else
    let ret = {
      \ 'continue': 1,
      \ 'complete': s:getVariableComplete(a:context, a:base)
      \ }
  endif

  return ret

  " get complete context
  " let context = a:nodecompl_context

  " let ret = []

  " " get object name
  " let obj_name = matchstr(context, '\k\+\ze\.$')

  " if (len(obj_name) == 0) " variable complete
  "   let ret = s:getVariableComplete(context, a:base)
  " else " module complete
  "   Decho 'obj_name: ' . obj_name

  "   " get variable declared line number
  "   let decl_line = search(obj_name . '\s*=\s*require\s*(.\{-})', 'bn')
  "   Decho 'decl_line: ' . decl_line

  "   if (decl_line == 0) 
  "     " maybe a global module
  "     let ret = s:getModuleComplete(obj_name, a:base, 'globals')
  "   else
  "     " find the node module name
  "     let mod_name = matchstr(getline(decl_line), obj_name . '\s*=\s*require\s*(\s*\([''"]\)\zs.\{-}\ze\(\1\)\s*)')

  "     if exists('mod_name')
  "       let ret = s:getModuleComplete(mod_name, a:base, 'modules')
  "     endif
  "   endif
  " endif

  " return []
endfunction


" require 创建
" new  创建
" 赋值
function! s:getModuleName(var_name)
  " var_name assignment statement operand
  " NOTICE:  can't change the List order, because we need the searchpos() return sub-pattern match number
  let assign_operand_regs = [
    \ 'require\_s*([^)]\+)',
    \ 'new\_s' . s:js_varname_reg,
    \ s:js_varname_reg,
    \]

  let operand_reg = '\%(\(' . join(assign_operand_regs, '\)\|\(') . '\)\)'
  let decl_stmt_reg = '\<' . a:var_name . '\_s*=\_s*' . operand_reg
  " search backward, move the cursor, don't wrap, also return which submatch is found
  let [line_num, col_num, assign_operand_idx] = searchpos(decl_stmt_reg, 'bWp')
  Decho 'declare_reg: ' . decl_stmt_reg
  Decho 'declare_posi: ' . line_num . ':' . col_num . '; idx: ' . assign_operand_idx

  " cann't find declaration, maybe a gloabl object like: console, process
  if line_num == 0
    return a:var_name
  endif

  " make sure it's not in comments...
  if !s:isDeclaration(line_num, col_num)
    return s:getModuleName(a:var_name)
  endif

  " find the operand
  let line = getline(line_num)
  let stmt = line[col_num-1:]
  Decho 'declarePosition: ' . line_num . ':' . col_num . ';idx:' . assign_operand_idx

  " a = require()
  if assign_operand_idx == 2

  " a = new A
  elseif assign_operand_idx == 3

  " a = a
  else

  endif

  return 'fs'
endfunction


function! s:isDeclaration(line_num, col_num)
  " syntaxName @see: $VIMRUNTIME/syntax/javascript.vim
  let syntaxName = synIDattr(synID(a:line_num, a:col_num, 0), 'name')
  if syntaxName =~ '^javaScript\%(Comment\|LineComment\|String\|RegexpString\)'
    return 0
  else
    return 1
  endif
endfunction


" only complete nodejs's module info
function! s:getModuleComplete(mod_name, prop_name, type)
  return []


  Decho 'mod_name: ' . a:mod_name
  Decho 'prop_name: ' . a:prop_name
  Decho 'type: ' . a:type

  call s:loadNodeDocData()

  let ret = []
  let mods = {}
  let mod = []

  if (has_key(g:nodejs_complete_data, a:type))
    let mods = g:nodejs_complete_data[a:type]
  endif

  if (has_key(mods, a:mod_name))
    let mod = mods[a:mod_name]
  endif

  " no prop_name suplied
  if (len(a:prop_name) == 0)
    let ret = mod
  else
    " filter properties with prop_name
    let ret = filter(copy(mod), 'v:val["word"] =~# "' . a:prop_name . '"')
  endif
  Decho string(ret)

  return ret
endfunction


function! s:getVariableComplete(context, var_name)
  Decho 'var_name: ' . a:var_name

  " complete require's arguments
  let matched = matchlist(a:context, 'require\s*(\s*\%(\([''"]\)\(\.\{1,2}.*\)\=\)\=$')
  if (len(matched) > 0)
    Decho 'require: ' . string(matched)

    if (len(matched[2]) > 0)          " complete -> require('./
      let mod_names = s:getModuleInCurrentDir(a:context, a:var_name, matched)
    else
      let mod_names = s:getModuleNames()

      if (len(matched[1]) == 0)     " complete -> require(
        call map(mod_names, '"''" . v:val . "'')"')
      elseif (len(a:var_name) == 0) " complete -> require('
        call map(mod_names, 'v:val . "' . escape(matched[1], '"') . ')"')
      else                          " complete -> require('ti
        let mod_names = filter(mod_names, 'v:val =~# "^' . a:var_name . '"')
        call map(mod_names, 'v:val . "' . escape(matched[1], '"') . ')"')
      endif
    endif

    return mod_names
  endif

  " complete global variables
  let vars = []
  if (len(a:var_name) == 0)
    return vars
  endif

  call s:loadNodeDocData()

  if (has_key(g:nodejs_complete_data, 'vars'))
    let vars = g:nodejs_complete_data.vars
  endif

  let ret = filter(copy(vars), 'v:val["word"] =~# "^' . a:var_name . '"')

  return ret
endfunction

function! s:getModuleInCurrentDir(context, var_name, matched) 
  let mod_names = []
  let path = a:matched[2] . a:var_name

  " typed as require('..
  " complete as require('../
  " cause the latter one is more common
  let compl_prefix = ''
  if (path =~# '\.\.$')
    let compl_prefix = '/'
    let path = path . compl_prefix
  endif

  Decho 'path: ' . path

  let current_dir = expand('%:p:h')
  let glob_path = current_dir . '/' . path . '*'
  let files = s:fuzglob(glob_path)
  Decho 'glob: ' . glob_path
  Decho 'current dir files: ' . string(files)
  for file in files
    " not '.' and '..'
    if ((isdirectory(file) ) || file =~? '\.json$\|\.js$') 
      let mod_file = file
      " directory
      if (file !~? '\.json$\|\.js$')
        let mod_file = mod_file . '/'
      endif

      " get complete word
      let mod_file = substitute(mod_file, '\', '/', 'g')
      let start = len(glob_path) - 1 " substract character '*'
      let compl_infix = strpart(mod_file, start)
      Decho 'idx: ' . start
      Decho 'compl_infix: ' . compl_infix
      Decho 'relative file: ' . mod_file

      let mod_name = compl_prefix . a:var_name . compl_infix
      " file module, not a directory
      if (compl_infix !~# '/$')
        let mod_name = mod_name . a:matched[1] . ')'
      endif

      Decho 'mod_name: ' . mod_name
      call add(mod_names, mod_name)
    endif
  endfor

  Decho 'relative path: ' . path

  return mod_names
endfunction

function! s:getModuleNames()
  call s:loadNodeDocData()

  let mod_names = []

  " build-in module name
  if (has_key(g:nodejs_complete_data, 'modules'))
    let mod_names = keys(g:nodejs_complete_data.modules)
  endif


  " find module in 'module_dir' folder
  if (!exists('b:npm_module_names'))
    let current_dir = expand('%:p:h')

    let b:npm_module_names = s:getModuleNamesInNode_modulesFolder(current_dir)
  endif

  let mod_names = mod_names + b:npm_module_names

  return sort(mod_names)
endfunction

function! s:getModuleNamesInNode_modulesFolder(current_dir)
  " ensure platform coincidence
  let base_dir = substitute(a:current_dir, '\', '/', 'g')
  Decho 'base_dir: ' . base_dir

  let ret = []

  let parts = split(base_dir, '/', 1)
  Decho 'parts: ' . string(parts)
  let idx = 0
  let len = len(parts)
  let sub_parts = []
  while idx < len
    let sub_parts = add(sub_parts, parts[idx])
    let module_dir = join(sub_parts, '/') . '/node_modules'
    Decho 'directory: ' . module_dir

    if (isdirectory(module_dir))
      let files = s:fuzglob(module_dir . '/*')
      Decho 'node_module files: ' . string(files)
      for file in files
        if (isdirectory(file) || file =~? '\.json$\|\.js$')
          let mod_name = matchstr(file, '[^/\\]\+$')
          let ret = add(ret, mod_name)
        endif
      endfor
    endif

    let idx = idx + 1
  endwhile

  Decho 'npm modules: ' . string(ret)

  return ret
endfunction

function! s:loadNodeDocData()
  " load node module data
  if (!exists('g:nodejs_complete_data'))
    " load data from external file
    let filename = s:nodejs_doc_file
    Decho 'filename: ' . filename
    if (filereadable(filename))
      Decho 'readable'
      execute 'so ' . filename
      Decho string(g:nodejs_complete_data)
    else
      Decho 'not readable'
    endif
  endif
endfunction

" copied from FuzzyFinder/autoload/fuf.vim
" returns list of paths.
" An argument for glob() is normalized in order to avoid a bug on Windows.
function! s:fuzglob(expr)
  " Substitutes "\", because on Windows, "**\" doesn't include ".\",
  " but "**/" include "./". I don't know why.
  return split(glob(substitute(a:expr, '\', '/', 'g')), "\n")
endfunction


"
" use plugin Decho(https://github.com/vim-scripts/Decho) for debug
"
" turn off debug mode
" :%s;^\(\s*\)\(Decho\);\1"\2;g | :w | so %
"
" turn on debug mode
" :%s;^\(\s*\)"\(Decho\);\1\2;g | :w | so %
"
