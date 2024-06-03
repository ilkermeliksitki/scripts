#!/usr/bin/env bash

# solve correct history appending order problem
# somehow we need to refresh the history of the current shell with `history -r'
rg --color=always --line-number --no-heading --smart-case "${*:-}" |
  fzf --ansi \
      --color "hl:-1:underline,hl+:-1:underline:reverse" \
      --delimiter : \
      --preview 'batcat --color=always {1} --highlight-line {2}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
      --bind 'ctrl-j:execute(cd $(dirname {1}) && vim +{2} $(basename {1}) && echo "vim {1} +{2}" | tee -a ~/.bash_history)' \



#--bind 'ctrl-j:become(vim {1} +{2} && echo "vim {1} +{2}" | tee -a ~/.bash_history)'\
