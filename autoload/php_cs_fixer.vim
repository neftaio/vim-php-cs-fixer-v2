"=============================================================================
" File: autoload/php_cs_fixer.vim
" Author: Stéphane PY

" Global options definition."{{{
let g:php_cs_fixer_path = get(g:, 'php_cs_fixer_path', '')
let g:php_cs_fixer_php_path = get(g:, 'php_cs_fixer_php_path', 'php')

if exists('g:php_cs_fixer_path') && g:php_cs_fixer_path != ""
  let g:php_cs_fixer_command = g:php_cs_fixer_php_path.' '.g:php_cs_fixer_path.' fix'
else
  if executable('php-cs-fixer')
    let g:php_cs_fixer_command = 'php-cs-fixer fix'
  else
    echoerr('php-cs-fixer not found and g:php_cs_fixer_path not set')
    finish
  end
end

let g:php_cs_fixer_rules = get(g:, 'php_cs_fixer_rules', '@PSR2')

if exists('g:php_cs_fixer_config_file') && filereadable(g:php_cs_fixer_config_file)
    let g:php_cs_fixer_command = g:php_cs_fixer_command . ' --config=' . g:php_cs_fixer_config_file
endif

if exists('g:php_cs_fixer_cache')
  let g:php_cs_fixer_command = g:php_cs_fixer_command . ' --cache-file=' . g:php_cs_fixer_cache
endif
"}}}

fun! php_cs_fixer#fix(path, dry_run)

  if !executable('php-cs-fixer')
    if !filereadable(expand(g:php_cs_fixer_path))
      echoerr(g:php_cs_fixer_path.' is not found')
    endif
  endif

  let command = g:php_cs_fixer_command.' '.a:path

  if a:dry_run == 1
    echohl Title | echo "[DRY RUN MODE]" | echohl None
    let command = command.' --dry-run'
  endif

  if exists('g:php_cs_fixer_rules') && g:php_cs_fixer_rules != '@PSR2'
    let command = command." --rules='".g:php_cs_fixer_rules."'"
  endif

  let command .= ' --allow-risky=yes'
  let s:output = system(command)

  if a:dry_run != 1
    exec 'edit!'
  endif

  let fix_num = 0
  let errors_report = 0
  let error_num = 0
  for line in split(s:output, '\n')
    if match(line, 'Files that were not fixed due to errors reported during linting before fixing:') != -1
      let errors_report = 1
    endif

    if match(line, '^\s\+\d\+)') != -1
      if errors_report == 0
        let fix_num = fix_num + 1
      else
        let error_num = error_num + 1
      endif
    endif
  endfor

  if !(v:shell_error == 0 || v:shell_error == 8 || (v:shell_error == 1 && fix_num > 0))
    echohl Error | echo s:output | echohl None
  else

    if g:php_cs_fixer_verbose == 1
      echohl Title | echo s:output | echohl None
    else
      if fix_num > 0
        echohl Title | echo fix_num." file(s) modified(s)" | echohl None
      else
        echohl Title | echo "There is no cs to fix" | echohl None
      endif
      if error_num > 0
        echohl Error | echo error_num." error(s)" | echohl None
      endif
    endif

    " if there is no cs to fix, we have not to ask for remove dry run
    if a:dry_run == 1 && fix_num > 0
      let l:confirmed = confirm("Do you want to launch command without dry-run option ?", "&Yes\n&No", 2)
      if l:confirmed == 1
        call PhpCsFixerFix(a:path, 0)
      endif
    endif
  endif
endfun
