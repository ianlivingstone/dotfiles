
" expand tabs to two spaces
set tabstop=2
set shiftwidth=2
set expandtab
" delete a shiftwidth sensibly:
set smarttab

setlocal makeprg=/usr/local/bin/jslint\ %
setlocal errorformat=%-P%f,
                    \%-G/*jslint\ %.%#*/,
                    \%*[\ ]%n\ %l\\,%c:\ %m,
                    \%-G\ \ \ \ %.%#,
                    \%-GNo\ errors\ found.,
                    \%-Q
